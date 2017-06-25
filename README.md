# MutRackers

Translating data to care requires proper processing and proper interpretation by physicians. Errors in either category pose risks to clinical applications. It has been demonstrated the different variant call methods can produced discordant outputs, indicating the need to careful interpretation of the results.

Previous work attempted to utilize unsupervised learning to sort true mutations, or "real variants," from the false positive. At the time no gold-standard "truth data" existed. This project utilizes recent advancements in the field, namely the Genome in Bottle Consortium (GIAB) data released in 2015, and utilizes supervised learning techniques (namely, neural network technology) to predict the probability that an observed mutation is a "real variant." Therefore, this project is a probability calculated for VCF data taken from any patient, and is trained on the "truth VCFs" generated from the GIAB analysis.

The three folders in this project serve the following functions.
- bamToVCF converts BAM files to VCF files, and the VCF files to "true VCF" files, which contains label information, encoding whether variants are "real variants."
- example_data is a fake VCF, used to initially train the model while the real VCF data was being prepared.
- model contains all information and code for the neural network. It also contains a "featurizer," which converts the VCF files into a data matrix for training. Finally, it contains a script to run the data on the train (true VCF data) and test (Onno's data) sets.
