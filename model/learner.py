import numpy as np

import keras
from keras.models import Sequential
from keras.layers import Dense, Dropout

from sklearn.model_selection import KFold

from featurize import Featurizer

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

    def initialize_model(self, train_dim):
        """
        Model architecture:
        Single hidden layer feed-forward neural network classification algorithm.

        Input ---> Hidden Layer 1 ---> Output Layer

        Since the number of features is small, the fruitfulness of additional layers,
        or of specialized layers like convolutional or pooling layers is questionable.
        """
        # Define the model.
        model = Sequential()

        # Input Layer
        model.add(Dense(train_dim, input_dim=train_dim, activation='relu'))
        model.add(Dropout(0.5))

        # Hidden Layer 1
        model.add(Dense(int(train_dim / 2), activation='relu'))
        model.add(Dropout(0.5))

        # Hidden Layer 2
        model.add(Dense(1, activation='softmax'))

        return model

    def train(self):
        """
        Initialize the Keras model. Using a sequential model for now.
        """
        # Obtain the training data, and it's labels.
        data, labels = Featurizer(self.data_file).featurize()

        self.input_dim = data.shape[1]

        kf = KFold(n_splits=3)

        # Compile and train the model. This is going to be time-intensive, starting here.
        for train_index, validation_index in kf.split(data):
            model = self.initialize_model(self.input_dim)

            train_data, train_labels = data[train_index], labels[train_index]
            validation_data, validation_labels = data[validation_index], labels[validation_index]

            epsilon_tests = [0.005, 0.01, 0.05, 0.1, 0.5, 1.0]
            keras_docs_momentum = 0.9 # Tinker with this if needed.
            for epsilon in epsilon_tests:
                model.compile(
                    loss='mean_squared_error',
                    optimizer=keras.optimizers.SGD(
                        lr=epsilon,
                        momentum=keras_docs_momentum,
                        nesterov=True
                    ),
                    metrics=['accuracy']
                )

            # Fit the model to the data.
            keras_docs_epochs = 100
            train_batch_size = train_data.shape[0]

            model.fit(
                train_data,
                train_labels,
                epochs=keras_docs_epochs,
                batch_size=train_batch_size,
                validation_data=(validation_data, validation_labels)
            )

            # Performance of the model (moment of truth!)
            validation_batch_size = validation_data.shape[0]

            loss_and_metrics = model.evaluate(
                validation_data, validation_labels, batch_size=validation_batch_size)

            print("Loss and metrics! %s" % str(loss_and_metrics)) # TODO: Fix this once you know whats in it.

        # Hack from SO:
        # https://stackoverflow.com/questions/40560795/tensorflow-attributeerror-nonetype-object-has-no-attribute-tf-deletestatus
        import gc; gc.collect()
        return model
