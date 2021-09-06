#
# Extract binary portion from file to file
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
if args_count < 4:
  echo "Extract binary portion from file, version 1.0"
  echo "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
  echo "Usage: file2bin.exe infile outfile offset size"
  quit(1)

let infile = paramStr(1)
let outfile = paramStr(2)
echo "infile: ", infile
echo "outfile: ", outfile
let offset = paramStr(3).parseInt()
let length = paramStr(4).parseInt()
echo "offset: ", offset
echo "length: ", length

let filesize = getFileSize infile
echo "filesize: ", filesize

var mybuf = alloc(length)

var fs = newFileStream(infile, fmRead)
fs.setPosition(offset)
var readlen = readData(fs, mybuf, length)
echo "readlen: ",readlen
fs.close()

var newfs = newFileStream(outfile, fmWrite)
writeData(newfs, mybuf, length)
newfs.close()
