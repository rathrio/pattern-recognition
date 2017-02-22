#!/usr/bin/env ruby

require 'benchmark'

Classification = Struct.new(:label, :vector)

def read_classifications(filepath)
  File.readlines(filepath).map do |line|
    label, *vector = line.split(',').map(&:to_i)
    Classification.new(label, vector)
  end
end

def distance(v1, v2, type: :euclidiean)
  sum = 0

  v2.each_with_index do |v, index|
    sum += ((v - v1[index]) ** 2)
  end

  Math.sqrt(sum)
end

def knn(k: 1, training_set:, sample:)
  training_set.min_by(k.to_i) { |c| distance(c.vector, sample.vector) }
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
    changes = false
    training_set.each_with_index do |c, index|
      puts index
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

k = ARGV.first || 1
puts "k = #{k}"

puts "Loading data sets"
training_set = read_classifications('train.csv')
test_set = read_classifications('test.csv')

t = Benchmark.realtime do
  condense(training_set)
end

puts "Took #{t} seconds"

# puts "Classifying data"
# test_set.each do |sample|
#   k_nearest = knn(training_set: training_set, sample: sample, k: k)
#   nearest = k_nearest.max_by { |c| k_nearest.count(c) }
#   puts "Classified #{sample.label} as #{nearest.label}"
# end
