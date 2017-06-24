from model.learner import MutationLearner

TRAIN_DATA_FILE_NAME = "" # TODO: Fill in location of VCF in repository.
TEST_DATA_FILE_NAME = "" # TODO: Fill in location of Onno VCF.

# Trains the learner.
train_learner = MutationLearner(TRAIN_DATA_FILE_NAME)
learned_model = train_learner.train()

# A bit of a misnomer. We don't actually call the "train"
# function here, but I need the preprocessing capabilities of the class.
# TODO: Separate preprocessing method into utils file?
test_learner = MutationLearner(TEST_DATA_FILE_NAME)
test_data_matrix = test_learner.preprocessing()

test_batch_size = test_data_matrix.shape[0]
predictions = model.predict(test_data_matrix, batch_size=test_batch_size)

# Attach here some exploratory data analysis on our findings. 
# This could be interesting for a final presentation. Visualizations,
# abnormal findings, etc...
