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

# Add read groups to the truth BAM files 
#  (NIST novoalign BAMs do not have RGs)
task AddReadGroups {
  File input_bam
  File input_bam_index
  Int disk_size
  Int preemptible_tries
  String bam_out

  command {
    java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xmx8000m \
      -jar /usr/gitc/picard.jar \
      AddOrReplaceReadGroups \
      I=${input_bam} \
      O=${bam_out}.bam \
      CREATE_INDEX=true \
      RGID=foo \
      RGLB=foolib \
      RGSM=HG002 \
      RGPL=Illumina \
      RGPU=unit1; \
    java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xmx8000m \
      -jar /usr/gitc/picard.jar \
      SortSam \
      I=${bam_out}.bam \
      O=${bam_out}_sorted.bam \
      SORT_ORDER=coordinate; \
    java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xmx8000m \
      -jar /usr/gitc/picard.jar \
      BuildBamIndex \
      I=${bam_out}_sorted.bam
  }
  runtime {
    docker: "broadinstitute/genomes-in-the-cloud:2.2.5-1486412288"
    memory: "10 GB"
    cpu: "2"
    disks: "local-disk " + disk_size + " HDD"
    preemptible: preemptible_tries
  }
  output {
    File output_bam = "${bam_out}_sorted.bam"
    File output_bam_index = "${bam_out}_sorted.bai"
  }
}
  
# Call variants on a single sample with HaplotypeCaller to produce a GVCF
task HaplotypeCaller {
  File input_bam
  File input_bam_index
  File interval_list
  String vcf_basename
  File ref_dict
  File ref_fasta
  File ref_fasta_index
  Int disk_size
  Int preemptible_tries

  command {
    java -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -Xmx8000m \
      -jar /usr/gitc/GATK35.jar \
      -T HaplotypeCaller \
      -R ${ref_fasta} \
      -o ${vcf_basename}.vcf.gz \
      -I ${input_bam} \
      -L ${interval_list} \
      -ERC GVCF \
      --max_alternate_alleles 3 \
      -variant_index_parameter 128000 \
      -variant_index_type LINEAR \
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
    File output_vcf = "${vcf_basename}.vcf.gz"
    File output_vcf_index = "${vcf_basename}.vcf.gz.tbi"
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

# Validate a VCF 
task ValidateVCF {
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

workflow bamToVCF{
  # Variable declaration
  Array[File] scattered_calling_intervals
  File wgs_calling_interval_list
  File inputBam
  File input_bam_index
  String vcf_basename
  String final_vcf_name
  String rg_bam

  File ref_fasta
  File ref_fasta_index
  File ref_dict
  File dbSNP_vcf
  File dbSNP_vcf_index

  Int flowcell_small_disk
  Int flowcell_medium_disk
  Int agg_small_disk
  Int agg_medium_disk
  Int agg_large_disk
  Int preemptible_tries
  Int agg_preemptible_tries

  # Add read groups to the BAM
  call AddReadGroups {
    input:
      input_bam = inputBam,
      input_bam_index = input_bam_index,
      disk_size = agg_large_disk,
      preemptible_tries = agg_preemptible_tries,
      bam_out = rg_bam
  }

  # Call variants in parallel over WGS calling intervals
  scatter (subInterval in scattered_calling_intervals) {
  
    # Generate VCF by interval
    call HaplotypeCaller {
      input:
        # TODO - Replace input bam files
        #input_bam = GatherBamFiles.output_bam,
        #input_bam_index = GatherBamFiles.output_bam_index,
        input_bam = AddReadGroups.output_bam,
        input_bam_index = AddReadGroups.output_bam_index,
        interval_list = subInterval,
        vcf_basename = vcf_basename,
        ref_dict = ref_dict,
        ref_fasta = ref_fasta,
        ref_fasta_index = ref_fasta_index,
        disk_size = agg_small_disk,
        preemptible_tries = agg_preemptible_tries
     }
  }
  
  # Combine by-interval VCFs into a single sample VCF file
  call MergeVCFs {
    input:
      input_vcfs = HaplotypeCaller.output_vcf,
      input_vcfs_indexes = HaplotypeCaller.output_vcf_index,
      output_vcf_name = final_vcf_name,
      disk_size = agg_small_disk,
      preemptible_tries = agg_preemptible_tries
  }
  
  # Validate the GVCF output of HaplotypeCaller
  call ValidateVCF {
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
  
  # Outputs that will be retained when execution is complete  
  output {
    MergeVCFs.*
    } 
}
