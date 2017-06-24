## Copyright Broad Institute, 2017
## 
## This WDL pipeline implements data pre-processing and initial variant calling (GVCF 
## generation) according to the GATK Best Practices (June 2016) for germline SNP and 
## Indel discovery in human whole-genome sequencing (WGS) data.
##
## Requirements/expectations :
## - Human whole-genome pair-end sequencing data in unmapped BAM (uBAM) format
## - One or more read groups, one per uBAM file, all belonging to a single sample (SM)
## - Input uBAM files must additionally comply with the following requirements:
## - - filenames all have the same suffix (we use ".unmapped.bam")
## - - files must pass validation by ValidateSamFile 
## - - reads are provided in query-sorted order
## - - all reads must have an RG tag
## - GVCF output names must end in ".g.vcf.gz"
## - Reference genome must be Hg38 with ALT contigs
##
## Runtime parameters are optimized for Broad's Google Cloud Platform implementation. 
## For program versions, see docker containers. 
##
## LICENSING : 
## This script is released under the WDL source code license (BSD-3) (see LICENSE in 
## https://github.com/broadinstitute/wdl). Note however that the programs it calls may 
## be subject to different licenses. Users are responsible for checking that they are
## authorized to run all programs before running this script. Please see the docker 
## page at https://hub.docker.com/r/broadinstitute/genomes-in-the-cloud/ for detailed
## licensing information pertaining to the included programs.

# TASK DEFINITIONS

  
# Call variants on a single sample with HaplotypeCaller to produce a GVCF
task HaplotypeCaller {
  File input_bam
  File input_bam_index
  File interval_list
  String gvcf_basename
  File ref_dict
  File ref_fasta
  File ref_fasta_index
  Float? contamination
  Int disk_size
  Int preemptible_tries

  command {
    java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xmx8000m \
      -jar /usr/gitc/GATK35.jar \
      -T HaplotypeCaller \
      -R ${ref_fasta} \
      -o ${gvcf_basename}.vcf.gz \
      -I ${input_bam} \
      -L ${interval_list} \
      -ERC GVCF \
      --max_alternate_alleles 3 \
      -variant_index_parameter 128000 \
      -variant_index_type LINEAR \
      -contamination ${default=0 contamination} \
      --read_filter OverclippedRead
  }
  runtime {
    docker: "broadinstitute/genomes-in-the-cloud:2.2.5-1486412288"
    memory: "10 GB"
    cpu: "1"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }
  output {
    File output_gvcf = "${gvcf_basename}.vcf.gz"
    File output_gvcf_index = "${gvcf_basename}.vcf.gz.tbi"
  }
}

# Combine multiple VCFs or GVCFs from scattered HaplotypeCaller runs
task MergeVCFs {
  Array[File] input_vcfs
  Array[File] input_vcfs_indexes
  String output_vcf_name
  Int disk_size
  Int preemptible_tries

  # Using MergeVcfs instead of GatherVcfs so we can create indices
  # See https://github.com/broadinstitute/picard/issues/789 for relevant GatherVcfs ticket
  command {
    java -Xmx2g -jar /usr/gitc/picard.jar \
    MergeVcfs \
    INPUT=${sep=' INPUT=' input_vcfs} \
    OUTPUT=${output_vcf_name}
  }
  output {
    File output_vcf = "${output_vcf_name}"
    File output_vcf_index = "${output_vcf_name}.tbi"
  }
  runtime {
    docker: "broadinstitute/genomes-in-the-cloud:2.2.5-1486412288"
    memory: "3 GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }
}

# Validate a GVCF with -gvcf specific validation
task ValidateGVCF {
  File input_vcf
  File input_vcf_index
  File ref_fasta
  File ref_fasta_index
  File ref_dict
  File dbSNP_vcf
  File dbSNP_vcf_index
  File wgs_calling_interval_list
  Int disk_size
  Int preemptible_tries

  command {
    java -Xmx8g -jar /usr/gitc/GATK36.jar \
    -T ValidateVariants \
    -V ${input_vcf} \
    -R ${ref_fasta} \
    -L ${wgs_calling_interval_list} \
    -gvcf \
    --validationTypeToExclude ALLELES \
    --reference_window_stop 208 -U  \
    --dbsnp ${dbSNP_vcf}
  }
  runtime {
    docker: "broadinstitute/genomes-in-the-cloud:2.2.5-1486412288"
    memory: "10 GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }
}

# Collect variant calling metrics from GVCF output
task CollectGvcfCallingMetrics {
  File input_vcf
  File input_vcf_index
  String metrics_basename
  File dbSNP_vcf
  File dbSNP_vcf_index
  File ref_dict
  Int disk_size
  File wgs_evaluation_interval_list
  Int preemptible_tries

  command {
    java -Xmx2000m -jar /usr/gitc/picard.jar \
      CollectVariantCallingMetrics \
      INPUT=${input_vcf} \
      OUTPUT=${metrics_basename} \
      DBSNP=${dbSNP_vcf} \
      SEQUENCE_DICTIONARY=${ref_dict} \
      TARGET_INTERVALS=${wgs_evaluation_interval_list} \
      GVCF_INPUT=true
  }
  runtime {
    docker: "broadinstitute/genomes-in-the-cloud:2.2.5-1486412288"
    memory: "3 GB"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }
  output {
    File summary_metrics = "${metrics_basename}.variant_calling_summary_metrics"
    File detail_metrics = "${metrics_basename}.variant_calling_detail_metrics"
  }
}

workflow bamToVCF{
  # Call variants in parallel over WGS calling intervals
  scatter (subInterval in scattered_calling_intervals) {
  
    # Generate GVCF by interval
    call HaplotypeCaller {
      input:
        contamination = CheckContamination.contamination,
        input_bam = GatherBamFiles.output_bam,
        input_bam_index = GatherBamFiles.output_bam_index,
        interval_list = subInterval,
        gvcf_basename = base_file_name,
        ref_dict = ref_dict,
        ref_fasta = ref_fasta,
        ref_fasta_index = ref_fasta_index,
        disk_size = agg_small_disk,
        preemptible_tries = agg_preemptible_tries
     }
  }
  
  # Combine by-interval GVCFs into a single sample GVCF file
  call MergeVCFs {
    input:
      input_vcfs = HaplotypeCaller.output_gvcf,
      input_vcfs_indexes = HaplotypeCaller.output_gvcf_index,
      output_vcf_name = final_gvcf_name,
      disk_size = agg_small_disk,
      preemptible_tries = agg_preemptible_tries
  }
  
  # Validate the GVCF output of HaplotypeCaller
  call ValidateGVCF {
    input:
      input_vcf = MergeVCFs.output_vcf,
      input_vcf_index = MergeVCFs.output_vcf_index,
      dbSNP_vcf = dbSNP_vcf,
      dbSNP_vcf_index = dbSNP_vcf_index,
      ref_fasta = ref_fasta,
      ref_fasta_index = ref_fasta_index,
      ref_dict = ref_dict,
      wgs_calling_interval_list = wgs_calling_interval_list,
      disk_size = agg_small_disk,
      preemptible_tries = agg_preemptible_tries
  }
  
  # QC the GVCF
  call CollectGvcfCallingMetrics {
    input:
      input_vcf = MergeVCFs.output_vcf,
      input_vcf_index = MergeVCFs.output_vcf_index,
      metrics_basename = base_file_name,
      dbSNP_vcf = dbSNP_vcf,
      dbSNP_vcf_index = dbSNP_vcf_index,
      ref_dict = ref_dict,
      wgs_evaluation_interval_list = wgs_evaluation_interval_list,
      disk_size = agg_small_disk,
      preemptible_tries = agg_preemptible_tries
  }

  # Outputs that will be retained when execution is complete  
  output {
    #CollectQualityYieldMetrics.*
    #ValidateReadGroupSamFile.*
    #CollectReadgroupBamQualityMetrics.*
    #CollectUnsortedReadgroupBamQualityMetrics.*
    #CrossCheckFingerprints.*
    #ValidateBamFromCram.*
    #CalculateReadGroupChecksum.*
    #ValidateAggregatedSamFile.*
    #CollectAggregationMetrics.*
    #CheckFingerprint.*
    #CollectWgsMetrics.*
    #CollectRawWgsMetrics.*
    #CheckContamination.*
    CollectGvcfCallingMetrics.*
    #MarkDuplicates.duplicate_metrics
    #GatherBqsrReports.*
    #ConvertToCram.*
    MergeVCFs.*
    } 
}