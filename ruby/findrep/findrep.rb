require 'optparse'

puts "Search and replace patterns for any files, version 1.0"
puts "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."

options = {}
OptionParser.new do |opt|
  opt.on('-i', '--input_file FIRSTNAME') { |o| options[:input_file] = o }
  opt.on('-o', '--output_file LASTNAME') { |o| options[:output_file] = o }
  opt.on('-s', '--search_pattern SEARCHPATTERN') { |o| options[:search_pattern] = o }
  opt.on('-r', '--replace_pattern REPLACEPATTERN') { |o| options[:replace_pattern] = o }
#  opt.on( '-h', '--help', 'Display this screen' ) { puts opt }
end.parse!

puts options

in_filename = options[:input_file]
out_filename = options[:output_file]
puts in_filename
puts out_filename

search_pattern = options[:search_pattern]
replace_pattern = options[:replace_pattern]
puts search_pattern
puts replace_pattern

#in_data = IO.read in_filename
File.open(in_filename, 'rb') do |f|
  in_data = f.read
  out_data = in_data.gsub(search_pattern, replace_pattern)
  f.close
  open(out_filename, 'w'){|fo| fo.write(out_data) }
end

# ruby.exe options_flags.rb -h
# ruby.exe file2bin.rb -i test.in -o test.out
