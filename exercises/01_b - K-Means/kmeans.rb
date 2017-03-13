#!/usr/bin/env ruby

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

if ARGV.first =~ /-h|--help/
  puts "Usage: ./#{File.basename(__FILE__)}"
  exit
end
