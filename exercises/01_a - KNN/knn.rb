#!/usr/bin/env ruby

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
  training_set.min_by(k) { |c| distance(c.vector, sample.vector) }.map(&:label)
end

training_set = read_classifications('train.csv')
test_set = read_classifications('test.csv')
