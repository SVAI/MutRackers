================
Models for Identifying Mutation Call Accuracy
================

This folder in the repository will consist of three files and a folder.

- learner.py - This document will use the Keras library to train a neural
  network on data that is passed in. This has been written as a class, and may
  need to be modified as the data format changes during the project (but hopefully,
  most of this work will be done in the scripts train.py and test.py)
- train_and_test.py - A script to load in the data to RAM, calling the 
  learning algorithm, and producing parameters, that will be saved into pickled files for the test data to recover. Then, to load in Onno's genomic data (or other test data). Will deserialize/"unpickle" the persistent parameters/weights learned during training and utilize them to make predictions.
- saved_files - Used for pickling the weights and recording predictions in a persistent fashion.
