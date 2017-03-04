Exercise 1a - KNN
=================

Rathesan Iyadurai (10-107-688)

You should find the following files in this directory:

- train.csv: the uncondensed set of training vectors (unused)
- test.csv: set of vectors that will be classified
- train_condensed.csv: condensed set of vectors that will be used by knn.rb
- knn.rb: Ruby script that will classify the vectors in test.csv with the
  training vectors in train_condensed.csv and print accuracies for all Ks.


Running
-------

To execute the script from the current directory, run:

        ruby knn.rb

To use the manhanttan distance, run:

        ruby knn.rb manhattan


After ~1h, the script should print the accuracies for K = {1, 3, 5, 10, 15} and
exit.

The manhattan distance is cheaper to calculate, but results in a less accurate
classification, that's why I condensed the set with the euclidean distance and
used that one for the classification of all vectors by default.

The condensed set took ~10h to generate (with the euclidean distance).


Output
------
