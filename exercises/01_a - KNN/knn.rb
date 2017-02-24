#!/usr/bin/env ruby

require 'benchmark'

Classification = Struct.new(:label, :vector)

def read_classifications(filepath)
  File.readlines(filepath).map do |line|
    label, *vector = line.split(',').map(&:to_i)
    Classification.new(label, vector)
  end
end

def b(switch = true)
  t = Benchmark.realtime do
    yield
  end
  puts t
end

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

def knn(k: 1, training_set:, sample:, distance_metric: :euclidiean)
  training_set.min_by(k.to_i) do |c|
    distance(c.vector, sample.vector, metric: distance_metric)
  end
end

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

def condense(training_set)
  changes = true
  condensed = [training_set.shift]
  while changes do
    print '*'
    changes = false
    training_set.each_with_index do |c, index|
      nearest = knn(training_set: condensed, sample: c, k: 1).first
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

k = ARGV[0] || 1
distance_metric = ARGV[1] || :euclidiean
puts "k = #{k}, metric = #{distance_metric}"

puts "Loading data sets"
training_set = read_classifications('train_condensed.csv')
# training_set = read_classifications('train.csv')
test_set = read_classifications('test.csv')

# condense(training_set)

# t = Benchmark.realtime do
#   condense(training_set)
# end
# puts "Took #{t} seconds"

puts "Classifying data"

test_set.each do |sample|
  b do
    k_nearest = knn(
      training_set: training_set,
      sample: sample,
      k: k,
      distance_metric: distance_metric
    )
    nearest = k_nearest.max_by { |c| k_nearest.count(c) }
    puts "Classified #{sample.label} as #{nearest.label}"
  end
end
