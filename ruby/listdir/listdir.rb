require 'optparse'
require "pathname"

puts "List all files per directory, version 1.0"
puts "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."

options = {}
OptionParser.new do |opt|
  opt.on('-i', '--in_dirname FIRSTNAME') { |o| options[:in_dirname] = o }
#  opt.on( '-h', '--help', 'Display this screen' ) { puts opt }
end.parse!

puts options

in_dirname = options[:in_dirname]
puts in_dirname

def procdir(dirname)
  data = ''
  Dir.foreach(dirname) do |dir|
    dirpath = dirname + '/' + dir
    if File.directory?(dirpath) then
      if dir != '.' && dir != '..' then
        #puts "DIRECTORY: #{dirpath}" ; 
        data += procdir(dirpath)
      end
    else
      data += dirpath
    end
  end
  return data
end


def rec_path(path, file= false, dir= false)
  if dir then puts path end
  path.children.collect do |child|
    if file and child.file?
      child
      filesize = File.size(child)
      datetimestamp = File.ctime(child)
      #puts "filename=",child,"\""
      $stdout.write("filename=\"")
      $stdout.write(File.basename(child))
      $stdout.write("\"")
      $stdout.write("  ")
      $stdout.write("filesize=\"")
      $stdout.write(filesize)
      $stdout.write("\"")
      $stdout.write("  ")
      $stdout.write("datetime=\"")
      $stdout.write(datetimestamp)
      $stdout.write("\"")
      $stdout.write("\n")
    elsif child.directory?
      rec_path(child, file, dir) + [child]
    end
  end.select { |x| x }.flatten(1)
end

# only directories
###rec_path(Pathname.new(in_dirname), false, true)
# directories and normal files
rec_path(Pathname.new(in_dirname), true, true)




#procdir(in_dirname)

# ruby.exe options_flags.rb -h
# ruby.exe file2bin.rb -i test.in -o test.out
