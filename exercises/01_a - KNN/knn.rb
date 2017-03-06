#!/usr/bin/env ruby

require 'thread'

# Using Ruby's iterators slows this script down significantly, that's why both
# distance functions use for-loops.
def euclidiean_distance(v1, v2)
  sum = 0
  for i in 0..783
    sum += ((v2[i] - v1[i]) ** 2)
  end
  Math.sqrt(sum)
end

def manhattan_distance(v1, v2)
  sum = 0
  for i in 0..783
    sum += (v1[i] - v2[i]).abs
  end
  sum
end

def distance(v1, v2, metric: :euclidiean)
  case metric.to_sym
  when :euclidiean
    euclidiean_distance(v1, v2)
  when :manhattan
    manhattan_distance(v1, v2)
  else
    euclidiean_distance(v1, v2)
  end
end

# Returns a Hash that looks like this:
#   { k => k nearest neighbors }
#
# e.g.
#   knn([1, 3]) => { 1 => nearest neighbor, 3 => 3 nearest neighbors }
def knn(k: [1], training_set:, sample:, distance_metric: :euclidiean)
  training_set_sorted = training_set.sort_by do |c|
    distance(c.vector, sample.vector, metric: distance_metric)
  end

  Hash[k.map { |k| [k, training_set_sorted.first(k)] }]
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

# Helper to render vector as png and open it with a Mac's default application.
def open_as_image(vector)
  require 'chunky_png'
  png = ChunkyPNG::Image.new(28, 28)

  vector.each_slice(28).with_index do |row, i|
    row.each_with_index do |pixel_value, j|
      png[j, i] = ChunkyPNG::Color.grayscale(pixel_value)
    end
  end

  png.save('/tmp/foo.png', interlaced: true)
  system "open /tmp/foo.png"
end

# Condensing algorithm as described in the lecture. Was used to reduce the set
# of 26998 training vectors to 3448 vectors.
def condense(training_set)
  changes = true
  condensed = [training_set.shift]
  while changes do
    print '*'
    changes = false
    training_set.each_with_index do |c, index|
      nearest = knn(training_set: condensed, sample: c, k: [1]).first
      unless nearest.label == c.label
        condensed << training_set.delete(c)
        changes = true
      end
    end
  end
ensure
  File.open('train_condensed.csv', 'w') do |f|
    condensed.each do |c|
      f.puts "#{c.label},#{c.vector.join(',')}"
    end
  end
  puts 'Successfully written condensed training set to train_condensed.csv.'
end

def classify(k: [1, 3, 5, 10, 15], training_set:, samples:, distance_metric: :euclidiean)
  puts "Start classifying data with #{distance_metric} distance"
  errors = {
    1  => [],
    3  => [],
    5  => [],
    10 => [],
    15 => []
  }

  samples.each do |sample|
    # Retrieve k nearest for sample
    k_nearest = knn(
      training_set: training_set,
      sample: sample,
      k: k,
      distance_metric: distance_metric
    )

    k_nearest.each do |k, nearest|
      labels = nearest.map(&:label)

      # Retrieve the one with the most occurences ("votes")
      nearest_label = labels.max_by { |l| labels.count(l) }

      unless sample.label == nearest_label
        # Keep track of wrong classifications for accuracy calculation later
        # on.
        errors[k] << sample
        print '.'.red
      end

      print '.'.green
    end
  end

  puts

  # Print accuracy for each k.
  k.each do |k|
    accuracy = ((samples.count - errors[k].count) / samples.count.to_f) * 100
    puts "k=#{k}: #{accuracy.round(2)}%"
  end
end

if ARGV.first =~ /-h|--help/
  puts "Usage: ./#{File.basename(__FILE__)} [euclidean|manhattan]"
  exit
end

distance_metric = (ARGV.shift || :euclidean).to_sym

# training_set = read_classifications('train.csv')
# condense(training_set)

puts "Loading data sets"
training_set = read_classifications('train_condensed.csv')
test_set = read_classifications('test.csv')

b do
  classify(k: [1, 3, 5, 10, 15], training_set: training_set, samples: test_set[0..99], distance_metric: distance_metric)
end
