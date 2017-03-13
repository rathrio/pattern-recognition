#!/usr/bin/env ruby

def distance(v1, v2)
  sum = 0
  for i in 0..783
    sum += ((v2[i] - v1[i]) ** 2)
  end
  Math.sqrt(sum)
end

# Some extensions for colored terminal output.
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end
  def green
    colorize 32
  end
  def red
    colorize 31
  end
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
def b
  require 'benchmark'
  t = Benchmark.realtime do
    yield
  end
  puts t
end

class Cluster
  attr_reader :center, :classifications

  def initialize(center, classifications)
    @center = center
    @classifications = classifications
  end

  def recompute_center
    new_center = Array.new(784, 0)

    classifications.each do |c|
      for i in 0..783
        new_center[i] += c.vector[i]
      end
    end

    for i in 0..783
      new_center[i] = new_center[i] / classifications.count
    end

    @center = center
  end

  def add(classification)
    @classifications << classification
  end
end

def kmeans(ks: [5, 7, 9, 10, 12, 15], training_set:, iterations: 1)
  ks.each do |k|
    # Choose K initial cluster centers
    centers = training_set.sample(k)
    clusters = centers.map { |c| Cluster.new(c.vector, []) }

    iterations.times do
      training_set.each do |c|
        nearest_cluster = clusters.min_by { |cluster| distance(cluster.center, c.vector) }
        nearest_cluster.add(c)
        print '.'.green
      end

      puts "\nRecomputing centers..."
      clusters.each(&:recompute_center)
    end

    puts "\nStats for k=#{5}"
    clusters.each_with_index do |cluster, index|
      puts "\nCluster #{index}\n----------"
      all_labels = cluster.classifications.map(&:label)
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

training_set = read_classifications('training_set.csv')
b { kmeans(ks: [15], training_set: training_set, iterations: 5) }
