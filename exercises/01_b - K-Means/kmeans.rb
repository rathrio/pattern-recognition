#!/usr/bin/env ruby

# For colored output.
class String
  def green
    "\e[32m#{self}\e[0m"
  end
end

# Calculates euclidean distance between v1 and v2.
def d(v1, v2)
  sum = 0
  for i in 0..783
    sum += ((v2[i] - v1[i]) ** 2)
  end
  Math.sqrt(sum)
end

# Structure to keep track of which vector belongs to which cluster.
LabeledVector = Struct.new(:label, :vector, :cluster)

# Loads labeled vectors from filepath and returns them as an Array of
# LabeledVectors.
def read_labeled_vectors(filepath)
  File.readlines(filepath).map do |line|
    label, *vector = line.split(',').map(&:to_i)
    LabeledVector.new(label, vector)
  end
end

# Benchmark helper. Will print seconds it took to run passed block.
# e.g. b { sleep(2) } # => Will print "2.0000..."
def b(msg = nil)
  require 'benchmark'
  t = Benchmark.realtime do
    yield
  end
  puts "\n#{msg} in #{t.round(3)}s".strip
end

class Cluster
  attr_reader :center, :labeled_vectors, :id

  def initialize(center, labeled_vectors, id)
    @center = center
    @labeled_vectors = labeled_vectors
    @id = id
  end

  # Assigned mean vector of all labeled_vectors as new center and clears all
  # previously assigned vectors, because they are reassigned in the next
  # clustering iteration.
  def recompute_center
    vector_count = labeled_vectors.count.to_f
    @center = labeled_vectors.map(&:vector).transpose.
      map { |v| v.inject(&:+) / vector_count }
    @labeled_vectors = []
  end

  def add(labeled_vector)
    # Let vectors know about the clusters they belong to for later quality
    # measures.
    labeled_vector.cluster = id
    @labeled_vectors << labeled_vector
  end

  def labels
    labeled_vectors.map(&:label)
  end

  def vectors
    labeled_vectors.map(&:vector)
  end
end

# Structure to keep track of which distances belong to which cluster. Needed
# for C-index calculation.
ClusterDistance = Struct.new(:distance, :cluster)

# By default, this calculates the C-index for 1000 randomly selected vectors.
# Reason being that Ruby ran out of memory for larger samples when building the
# combinations.
def c_index(clusters, samples: 1000)
  gamma = 0
  alpha = 0

  labeled_vectors = clusters.flat_map(&:labeled_vectors).sample(samples)
  pairs = labeled_vectors.combination(2)

  distances = pairs.map do |v1, v2|
    distance = d(v1.vector, v2.vector)
    cluster = (v1.cluster == v2.cluster) ? v1.cluster : nil
    ClusterDistance.new(distance, cluster)
  end.sort_by(&:distance)

  clusters.each do |cluster|
    distances_within_cluster = distances
      .select { |d| d.cluster == cluster.id }
      .map(&:distance).compact

    next if distances_within_cluster.empty?

    gamma += distances_within_cluster.inject(&:+)
    alpha += distances_within_cluster.count
  end

  min = distances.first(alpha).map(&:distance).inject(&:+)
  max = distances.last(alpha).map(&:distance).inject(&:+)

  (gamma - min) / (max - min)
end

# By default, this calculates the Goodman-Kruskal-index for 50 randomly selected vectors.
# Reason being that Ruby ran out of memory for larger samples when building the
# combinations.
def goodman_kruskal_index(clusters, samples: 50)
  samples = 10 if $aintgotnotime

  labeled_vectors = clusters.flat_map(&:labeled_vectors).sample(samples)
  tuples = labeled_vectors.combination(4)

  concordant = 0
  discordant = 0

  tuples.each do |tuple|
    tuple.combination(2).to_a.combination(2).each do |(x_i, x_j), (x_r, x_s)|
      distance_pair1 = d(x_i.vector, x_j.vector)
      distance_pair2 = d(x_r.vector, x_s.vector)

      is_concordant = (distance_pair1 < distance_pair2 &&
                      (x_i.cluster == x_j.cluster && x_r.cluster != x_s.cluster)) ||
                      (distance_pair1 > distance_pair2 &&
                      (x_i.cluster != x_j.cluster && x_r.cluster == x_s.cluster))

      is_discordant = (distance_pair1 < distance_pair2 &&
                      (x_i.cluster != x_j.cluster && x_r.cluster == x_s.cluster)) ||
                      (distance_pair1 > distance_pair2 &&
                      (x_i.cluster == x_j.cluster && x_r.cluster != x_s.cluster))


      concordant += 1 if is_concordant
      discordant += 1 if is_discordant
    end
  end

  (concordant - discordant) / (concordant + discordant).to_f
end

def kmeans(k:, training_set:, iterations:)
  # Randomly choose K initial cluster centers.
  centers = training_set.sample(k)
  clusters = centers.map.with_index { |c, i| Cluster.new(c.vector, [], i) }

  # Stop after a certain number of iterations.
  iterations.times do |i|
    training_set.each do |c|
      nearest_cluster = clusters.min_by do |cluster|
        d(cluster.center, c.vector)
      end
      nearest_cluster.add(c)
    end

    # Don't recompute centers in last iteration because we're done reassigning
    # vectors.
    unless (i + 1) == iterations
      clusters.each(&:recompute_center)
    end
  end

  clusters
end

def cluster(ks: [], training_set: [], iterations: 1)
  ks.each do |k|
    clusters = nil

    # The b method just measures how long it takes to perform the given task.
    b "Clustered with k=#{k}"  do
      clusters = kmeans(k: k, training_set: training_set, iterations: iterations)
    end

    b "Calculated C-Index"  do
      puts "C-Index k=#{k}: #{c_index(clusters)}".green
    end

    b "Calculated Goodman-Kruskal-Index"  do
      puts "Goodman-Kruskal-Index k=#{k}: #{goodman_kruskal_index(clusters)}".green
    end
  end
end


if ARGV.first =~ /-h|--help/
  puts "Usage: ./#{File.basename(__FILE__)}"
  exit
end

training_set = []

b('Loaded training set') { training_set = read_labeled_vectors('training_set.csv') }
ks = [5, 7, 9, 10, 12, 15]
iterations = 50

if ARGV.first == "--aint-got-no-time"
  $aintgotnotime = true
  training_set = training_set[0..99]
end

cluster(ks: ks, training_set: training_set, iterations: iterations)
