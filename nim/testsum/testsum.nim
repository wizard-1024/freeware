#
# Build checksums per file
# Copyright (c) 2021 Dmitry Stefankov
#
# nimble install nimcrypto # installation
#

import os
#import times
import strutils
import std/md5
import std/sha1
#import parseutils
#import streams
#import nimSHA2
import nimcrypto

type TCrc32* = uint32
const InitCrc32* = TCrc32(0xffffffff)

proc createCrcTable(): array[0..255, TCrc32] =
  for i in 0..255:
    var rem = TCrc32(i)
    for j in 0..7:
      if (rem and 1) > 0: rem = (rem shr 1) xor TCrc32(0xedb88320)
      else: rem = rem shr 1
    result[i] = rem
 
# Table created at compile time
const crc32table = createCrcTable()
 
proc crc32(s: string): TCrc32 =
  result = InitCrc32
  for c in s:
    result = (result shr 8) xor crc32table[(result and 0xff) xor byte(c)]
  result = not result


echo "program name: ", getAppFilename()
#echo "Arguments:"
#for arg in commandLineParams():
#  echo arg
#echo paramCount(), " ", paramStr(1)
let args_count =  paramCount()
if args_count < 2:
  echo "List files per directory, version 1.0"
  echo "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
  echo "Usage: testsum.exe dirname hashsize"
  quit(1)

proc deepWalk(path: string; hsize: int) =
    echo path
    for x in walkDir(path):
        if x.kind == pcDir:
            deepWalk(x.path,hsize)
        else:
            stdout.write("filename=\"")
            stdout.write(extractFilename(x.path))
            stdout.write("\"");
            var mybuf = readFile(x.path)
            let filesize = getFileSize x.path
            var maxsize: int64 = 1024*1024*1
            if filesize < maxsize:
              var mysum = crc32(mybuf).int64.toHex(8)
              #stdout.write("  crc32=0x\"",crc32(mybuf).int64.toHex(8),"\"")
              stdout.write("  crc32=\"0x",mysum,"\"")
              mysum = getMD5(mybuf)
              stdout.write("  md5=\"0x",mysum,"\"")
              let myhash = secureHash(mybuf)
              #var s: string = secureHashFile("123")
              stdout.write("  sha1=\"0x",myhash,"\"")
              let data = cast[ptr byte](addr mybuf[0])
              let datalen = uint(filesize)
              if hsize == 224:
                let newhash = sha224.digest(data,datalen)
                stdout.write("  sha224=\"0x",newhash,"\"")
              if hsize == 256:
                let newhash = sha256.digest(data,datalen)
                stdout.write("  sha256=\"0x",newhash,"\"")
              if hsize == 384:
                let newhash = sha384.digest(data,datalen)
                stdout.write("  sha384=\"0x",newhash,"\"")
              if hsize == 512:
                let newhash = sha512.digest(data,datalen)
                stdout.write("  sha512=\"0x",newhash,"\"")
            echo ""
            #echo extractFilename(x.path)
            

let dirname = paramStr(1)
let hashsize = paramStr(2).parseInt()

deepWalk(dirname,hashsize)
