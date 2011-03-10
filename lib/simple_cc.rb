require './cxl_comparison'

if ARGV.length != 2
  puts "Usage: simple_cc <reference map file path> <evaluated map file path>"
end

#check that the files exist

comparer = CXLComparison.new(ARGV[0], ARGV[1])
comparer.simple_strict_compare.output_as_text($stdout)