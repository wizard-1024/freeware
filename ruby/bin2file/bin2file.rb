require 'optparse'

puts "Put binary portion to file, version 1.0"
puts "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."

options = {}
OptionParser.new do |opt|
  opt.on('-i', '--input_file FIRSTNAME') { |o| options[:input_file] = o }
  opt.on('-o', '--output_file LASTNAME') { |o| options[:output_file] = o }
  opt.on('-s', '--in_file_offset INFILEOFFSET') { |o| options[:in_file_offset] = o }
  opt.on('-l', '--in_file_size FILESIZE') { |o| options[:in_file_size] = o }
  opt.on('-p', '--out_file_offset OUTFILEOFFSET') { |o| options[:out_file_offset] = o }
#  opt.on( '-h', '--help', 'Display this screen' ) { puts opt }
end.parse!

puts options

in_filename = options[:input_file]
out_filename = options[:output_file]
puts in_filename
puts out_filename

in_file_offset = options[:in_file_offset]
out_file_offset = options[:out_file_offset]
write_len = options[:in_file_size]
puts in_file_offset
puts write_len
puts out_file_offset

File.open(in_filename, 'rb') do |f|
  f.seek(Integer(in_file_offset))
  in_data = f.read(Integer(write_len))
  f.close
  modtime = File.mtime(out_filename)
  acctime = File.atime(out_filename)
  File.open(out_filename, 'r+b') do |fo|
    fo.seek(Integer(out_file_offset)) 
    fo.write(in_data)
    fo.close
    File.utime(acctime, modtime, out_filename)
  end
  #open(out_filename, 'rwb'){|fo| fo.write(in_data) }
end


# ruby.exe options_flags.rb -h
# ruby.exe file2bin.rb -i test.in -o test.out
