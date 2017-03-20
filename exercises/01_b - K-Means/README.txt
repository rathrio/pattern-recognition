Exercise 1b - K-Means
=====================

Rathesan Iyadurai (10-107-688)

You should find the following files in this directory:

- training_set.csv: 42'000 labeled vectors that will be clustered
- kmeans.rb: Ruby script that will cluster the vectors in training_set.csv and
  print the C- and Goodman-Kruskal-Index for K = {5, 7, 9, 10, 12, 15}


Running
-------

To execute the script from the current directory, run:

        ruby kmeans.rb

I highly recommend using a faster Ruby implementation, such as TruffleRuby [1].
As an alternative, run 

        ruby kmeans.rb --aint-got-no-time

to cluster and measure quality with a reduced dataset.

With TruffleRuby, you can expect a runtime of ~5min per K.


Validation values
-----------------

C-Index k=5: 0.230573800407556
Goodman-Kruskal-Index k=5: 0.534421130415356

C-Index k=7: 0.236871652328406
Goodman-Kruskal-Index k=7: 0.588105702463037

C-Index k=9: 0.238099051767761
Goodman-Kruskal-Index k=9: 0.686860352340007

C-Index k=10: 0.238817595581613
Goodman-Kruskal-Index k=10: 0.519591606102527

C-Index k=12: 0.237637404528788
Goodman-Kruskal-Index k=12: 0.670344943268275

C-Index k=15: 0.235684497855642
Goodman-Kruskal-Index k=15: 0.704968472756875


[1] https://github.com/graalvm/truffleruby
