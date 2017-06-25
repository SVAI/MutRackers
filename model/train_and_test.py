from learner import MutationLearner
from featurize import Featurizer

import pickle

TRAIN_DATA_FILE_NAME = "../example_data/HG002_250bp.vcf.gz" # TODO: Fill in with real VCFs (this is example data)
TEST_DATA_FILE_NAME = "../example_data/HG002_250bp.vcf.gz" # TODO: Fill in location of Onno VCF.

# Trains the learner.
train_learner = MutationLearner(TRAIN_DATA_FILE_NAME)
learned_model = train_learner.train()

test_data_matrix = Featurizer(TEST_DATA_FILE_NAME, test=True).featurize()
test_batch_size = test_data_matrix.shape[0]

# This should return the probabilities.
predictions = learned_model.predict(test_data_matrix, batch_size=test_batch_size)
predictions_file = open('saved_files/model_probabilities.pkl', 'wb')
pickle.dump(predictions, predictions_file)
