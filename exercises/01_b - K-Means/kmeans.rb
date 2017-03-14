#!/usr/bin/env ruby

class String
  def green
    "\e[32m#{self}\e[0m"
  end
end

def d(v1, v2)
  sum = 0
  for i in 0..783
    sum += ((v2[i] - v1[i]) ** 2)
  end
  Math.sqrt(sum)
end

Classification = Struct.new(:label, :vector, :cluster)

# Loads labeled vectors from filepath and returns them as an Array of
# Classifications.
def read_classifications(filepath)
  File.readlines(filepath).map do |line|
    label, *vector = line.split(',').map(&:to_i)
    Classification.new(label, vector)
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
  attr_reader :center, :classifications, :id

  def initialize(center, classifications, id)
    @center = center
    @classifications = classifications
    @id = id
  end

  def recompute_center
    vector_count = classifications.count.to_f
    @center = classifications.map(&:vector).transpose.
      map { |v| v.inject(&:+) / vector_count }
    @classifications = []
  end

  def add(classification)
    classification.cluster = id
    @classifications << classification
  end

  def labels
    classifications.map(&:label)
  end

  def vectors
    classifications.map(&:vector)
  end
end

ClusterDistance = Struct.new(:distance, :cluster)

def c_index(clusters, samples: 500_000)
  gamma = 0
  alpha = 0

  pairs = clusters.flat_map(&:classifications).combination(2).to_a

  cluster_distances = pairs.sample(samples).map do |c1, c2|
    distance = d(c1.vector, c2.vector)
    cluster = (c1.cluster == c2.cluster) ? c1.cluster : nil
    ClusterDistance.new(distance, cluster)
  end.sort_by(&:distance)

  clusters.each do |c|
    distances_within_cluster = cluster_distances
      .select { |d| d.cluster == c.id }
      .map(&:distance).compact

    next if distances_within_cluster.empty?

    gamma += distances_within_cluster.inject(&:+)
    alpha += distances_within_cluster.count
  end

  min = cluster_distances.first(alpha).map(&:distance).inject(&:+)
  max = cluster_distances.last(alpha).map(&:distance).inject(&:+)

  (gamma - min) / (max - min)
end

def kmeans(k:, training_set:, iterations:)
  # Choose K initial cluster centers
  centers = training_set.sample(k)
  clusters = centers.map.with_index { |c, i| Cluster.new(c.vector, [], i) }

  iterations.times do |i|
    training_set.each do |c|
      nearest_cluster = clusters.min_by do |cluster|
        d(cluster.center, c.vector)
      end
      nearest_cluster.add(c)
      # print '.'
    end

    # Don't recompute centers in last iteration because we're done reassigning
    # vectors.
    unless (i + 1) == iterations
      # puts "\nRecomputing centers"
      clusters.each(&:recompute_center)
    end
  end

  clusters
end

def cluster(ks: [5, 7, 9, 10, 12, 15], training_set:, iterations: 1)
  ks.each do |k|
    clusters = nil

    b("Clustered with k=#{k}") do
      clusters = kmeans(k: k, training_set: training_set, iterations: iterations)
    end

    b("Calculated C-Index") do
      puts "C-Index k=#{k}: #{c_index(clusters)}".green
    end

    # puts "\nStats for k=#{k}"
    # clusters.each_with_index do |cluster, index|
    #   puts "\nCluster #{index}\n----------"
    #   all_labels = cluster.labels
    #   (0..9).each do |l|
    #     puts "#{l}: #{all_labels.count(l)}"
    #   end
    # end
  end
end


if ARGV.first =~ /-h|--help/
  puts "Usage: ./#{File.basename(__FILE__)}"
  exit
end

training_set = []
b('Loaded training set') { training_set = read_classifications('training_set.csv') }
cluster(ks: [5, 7, 9, 10, 12, 15], training_set: training_set, iterations: 20)
