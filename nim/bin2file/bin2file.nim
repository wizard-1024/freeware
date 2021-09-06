#
# Put binary portion from file to file
# Copyright (c) 2021 Dmitry Stefankov
#
import os
import strutils
#import parseutils
import streams

echo "program name: ", getAppFilename()
#echo "Arguments:"
#for arg in commandLineParams():
#  echo arg
#echo paramCount(), " ", paramStr(1)
let args_count =  paramCount()
if args_count < 5:
  echo "Put binary portion from file, version 1.0"
  echo "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
  echo "Usage: bin2file.exe infile outfile in_offset in_size out_offset"
  quit(1)

let infile = paramStr(1)
let outfile = paramStr(2)
echo "infile: ", infile
echo "outfile: ", outfile
let in_offset = paramStr(3).parseInt()
let in_length = paramStr(4).parseInt()
let out_offset = paramStr(5).parseInt()
echo "in_offset: ", in_offset
echo "in_length: ", in_length
echo "out_offset: ", out_offset

let in_filesize = getFileSize infile
echo "in_filesize: ", in_filesize

let out_filesize = getFileSize outfile
echo "out_filesize: ", out_filesize

var mybuf = alloc(in_length)
var fs = newFileStream(infile, fmRead)
fs.setPosition(in_offset)
var readlen = readData(fs, mybuf, in_length)
echo "readlen: ",readlen
fs.close()

var newfs = newFileStream(outfile, fmReadWriteExisting)
newfs.setPosition(out_offset)
writeData(newfs, mybuf, in_length)
newfs.close()
