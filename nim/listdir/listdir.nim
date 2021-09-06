#
# List files per directory
# Copyright (c) 2021 Dmitry Stefankov
#
import os
import times
import strutils
#import parseutils
#import streams

echo "program name: ", getAppFilename()
#echo "Arguments:"
#for arg in commandLineParams():
#  echo arg
#echo paramCount(), " ", paramStr(1)
let args_count =  paramCount()
if args_count < 1:
  echo "List files per directory, version 1.0"
  echo "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
  echo "Usage: listdir.exe dirname"
  quit(1)

proc deepWalk(path: string) =
    echo path
    for x in walkDir(path):
        if x.kind == pcDir:
            deepWalk(x.path)
        else:
            # Get and display last modification time.
            var mtime = x.path.getLastModificationTime()
            #echo "File \"$1\" last modification time: $2".format(fileName, mtime.format("YYYY-MM-dd HH:mm:ss"))
            #stdout.write("File \"$1\" last modification time: $2".format(x.path, mtime.format("YYYY-MM-dd HH:mm:ss")))
            stdout.write("  datetime=\"",format(mtime.format("YYYY-MM-dd HH:mm:ss"),"\""))
            let filesize = getFileSize x.path
            stdout.write("  size=\"",filesize,"\"")
            stdout.write("  filename=\"")
            stdout.write(extractFilename(x.path))
            stdout.write("\"");
            echo ""
            #echo extractFilename(x.path)
            

let dirname = paramStr(1)

deepWalk(dirname)
