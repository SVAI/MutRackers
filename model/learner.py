import pickle
import numpy as np

import keras
from keras.models import Sequential
from keras.layers import Dense, Activation

from sklearn.model_selection import KFold

class MutationLearner(object):
    """
    This class will consist of several methods. The initializer will
    pass in the data file, which will presumably be located in another
    section of this repository. The bulk of the algorithm is located in the
    train method, which calls upon the Keras Python library. This in turn
    calls a preprocessing method, which turns the raw data into the data matrix,
    and a postprocessing method, which pickles the parameters from the trained
    network.
    """

    def __init__(self, data_file):
        self.data_file = data_file
        self.data = None # TODO: load the data into RAM.
        self.input_dim = 0 # TODO: Determine the input dimension from the data.

    def preprocessing(self):
        """
        Takes the data loaded into RAM, and turns it into a data matrix
        that can be passed into a library for neural network training.

        E.g.
        Data in VCF format (TODO: fill in what this looks like)

        ...

                feature_1 feature_2 feature_3 ... feature_d
               ______________________________________________
        mut_1 [
        mut_2 [
        mut_3 [
        ...   [
        mut_n  [

        """
        return train_data, train_labels

    def postprocessing(self, learner):
        """
        Takes weights from the neural network ("learner"), and pickles them into
        the file trained_weights.pkl. Learner is a Keras object.
        """
        output = open('./trained_weights.pkl', 'wb')
        pickle.dump(learner, output)

    def train(self):
        """
        Initialize the Keras model. Using a sequential model for now.
        """
        # Obtain the training data, and it's labels.
        data, labels = self.preprocessing()
        kf = KFold(n_splits=3)

        # Define the model.
        model = Sequential()

        # Input Layer (?)
        model.add(Dense(units=self.input_dim, input_dim=self.input_dim))
        model.add(Activation('relu'))

        # Hidden Layer 1 (?)
        model.add(Dense(units=self.input_dim / 2))
        model.add(Activation('softmax'))

        # Compile and train the model. This is going to be time-intensive, starting here.
        for train_index, validation_index in kf.split(data):
            train_data, train_labels = data[train_index], labels[train_index]
            validation_data, validation_labels = data[validation_index], labels[validation_index]

            epsilon_tests = [0.005, 0.01, 0.05, 0.1, 0.5, 1.0]
            keras_docs_momentum = 0.9 # Tinker with this if needed.
            for epsilon in epsilon_tests:
                model.compile(
                    loss='categorical_crossentropy',
                    optimizer=keras.optimizers.SGD(
                        lr=epsilon,
                        momentum=keras_docs_momentum,
                        nesterov=True
                    ),
                    metrics=['accuracy']
                )

            # Fit the model to the data.
            keras_docs_epochs = 5
            train_batch_size = train_data.shape[0]
            model.fit(train_data, train_labels, epochs=keras_docs_epochs, batch_size=train_batch_size)

            # Performance of the model (moment of truth!)
            validation_batch_size = validation_data.shape[0]

            loss_and_metrics = model.evaluate(
                validation_data, validation_labels, batch_size=validation_batch_size)

            print("Loss and metrics! %s" % str(loss_and_metrics)) # TODO: Fix this once you know whats in it.

        # # Persist the model to disk (hardware), for use in test.py.
        # self.postprocessing(model)

        return model
