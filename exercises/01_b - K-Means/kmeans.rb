#!/usr/bin/env ruby

def distance(v1, v2)
  sum = 0
  for i in 0..783
    sum += ((v2[i] - v1[i]) ** 2)
  end
  Math.sqrt(sum)
end

Classification = Struct.new(:label, :vector)

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
  puts "\n#{msg}: #{t.round(4)}".strip
end

class Cluster
  attr_reader :center, :classifications

  def initialize(center, classifications)
    @center = center
    @classifications = classifications
  end

  def recompute_center
    vector_count = classifications.count.to_f
    @center = classifications.map(&:vector).transpose.
      map { |v| v.inject(&:+) / vector_count }
    @classifications = []
  end

  def add(classification)
    @classifications << classification
  end

  def labels
    classifications.map(&:label)
  end
end

def kmeans(k:, training_set:, iterations:)
  # Choose K initial cluster centers
  centers = training_set.sample(k)
  clusters = centers.map { |c| Cluster.new(c.vector, []) }

  iterations.times do |i|
    training_set.each do |c|
      nearest_cluster = clusters.min_by do |cluster|
        distance(cluster.center, c.vector)
      end
      nearest_cluster.add(c)
      print '.'
    end

    # Don't recompute centers in last iteration because we're done reassigning
    # vectors.
    unless (i + 1) == iterations
      puts "\nRecomputing centers"
      clusters.each(&:recompute_center)
    end
  end

  clusters
end

def cluster(ks: [5, 7, 9, 10, 12, 15], training_set:, iterations: 1)
  ks.each do |k|
    clusters = kmeans(k: k, training_set: training_set, iterations: iterations)

    puts "\nStats for k=#{k}"
    clusters.each_with_index do |cluster, index|
      puts "\nCluster #{index}\n----------"
      all_labels = cluster.labels
      (0..9).each do |l|
        puts "#{l}: #{all_labels.count(l)}"
      end
    end
  end
end


if ARGV.first =~ /-h|--help/
  puts "Usage: ./#{File.basename(__FILE__)}"
  exit
end

training_set = []
b('Loading training set') { training_set = read_classifications('training_set.csv') }
b('Clustering') { cluster(ks: [9], training_set: training_set, iterations: 100) }
