require 'optparse'

puts "Extract binary portion from file, version 1.0"
puts "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."

options = {}
OptionParser.new do |opt|
  opt.on('-i', '--input_file FIRSTNAME') { |o| options[:input_file] = o }
  opt.on('-o', '--output_file LASTNAME') { |o| options[:output_file] = o }
  opt.on('-s', '--in_file_offset FILEOFFSET') { |o| options[:in_input_offset] = o }
  opt.on('-l', '--out_file_size FILESIZE') { |o| options[:out_file_size] = o }
#  opt.on( '-h', '--help', 'Display this screen' ) { puts opt }
end.parse!

puts options

in_filename = options[:input_file]
out_filename = options[:output_file]
puts in_filename
puts out_filename

file_offset = options[:in_input_offset]
write_len = options[:out_file_size]
puts file_offset
puts write_len

#in_data = IO.read in_filename
File.open(in_filename, 'rb') do |f|
  f.seek(Integer(file_offset))
  in_data = f.read(Integer(write_len))
  f.close
  open(out_filename, 'w'){|fo| fo.write(in_data) }
end

# ruby.exe options_flags.rb -h
# ruby.exe file2bin.rb -i test.in -o test.out
