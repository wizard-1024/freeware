#
# search & replace patterns for any file
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
  echo "search & replace patterns for any file, version 1.0"
  echo "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
  echo "Usage: findrep infile outfile searchpattern replacepattern"
  quit(1)

let infile = paramStr(1)
let outfile = paramStr(2)
echo "infile: ", infile
echo "outfile: ", outfile
let searchpattern = paramStr(3)
let replacepattern = paramStr(4)
echo "searchpattern: ", searchpattern
echo "replacepattern: ", replacepattern

let strbuf = readFile(infile)
let newbuf = replace(strbuf,searchpattern,replacepattern)

writeFile(outfile, newbuf)
