import sys, getopt, os, time
import binascii
import zlib
import hashlib
from pathlib import Path
if sys.version_info < (3, 6):
    import sha3

def printf(format, *args):
    sys.stdout.write(format % args)

def list_files_recursive(path,hashsize):
    """
    Function that receives as a parameter a directory path
    :return list_: File List and Its Absolute Paths
    """

    import os

    #files = []

    # r = root, d = directories, f = files
    for r, d, f in os.walk(path):
        for dir in d:
            newdir = path+"\\"+dir
            if os.path.isdir(newdir):
                #print (newdir)
                list_files_recursive(newdir,hashsize)
        for file in f:
            newfilename = path+"\\"+file
            newfile = Path(newfilename)
            if newfile.exists():
                stinfo = os.stat(newfilename)
                file_size = os.path.getsize(newfilename);
                if file_size < 1024*1024*512:
                    with open(newfilename, 'rb') as f:
                        bufdata = f.read()
                        f.close()
                    crc32 = hex(binascii.crc32(bufdata))
                    md5s = hashlib.md5(bufdata).hexdigest()
                    hash_object = hashlib.sha1(bufdata)
                    hex_dig = hash_object.hexdigest()
                    sha2s = ''
                    sha3s = ''
                    if hashsize == 224:
                         hash_object = hashlib.sha224(bufdata)
                         sha2s = hash_object.hexdigest()
                         hash_object = hashlib.sha3_224(bufdata)
                         sha3s = hash_object.hexdigest()
                    elif hashsize == 256:
                         hash_object = hashlib.sha256(bufdata)
                         sha2s = hash_object.hexdigest()
                         hash_object = hashlib.sha3_256(bufdata)
                         sha3s = hash_object.hexdigest()
                    elif hashsize == 384:
                         hash_object = hashlib.sha384(bufdata)
                         sha2s = hash_object.hexdigest()
                         hash_object = hashlib.sha3_384(bufdata)
                         sha3s = hash_object.hexdigest()
                    elif hashsize == 512:
                         hash_object = hashlib.sha512(bufdata)
                         sha2s = hash_object.hexdigest()
                         hash_object = hashlib.sha3_512(bufdata)
                         sha3s = hash_object.hexdigest()
                    print(f"filename=\"{newfilename}\"  crc32=\"{crc32}\"  md5=\"0x{md5s}\"  sha1=\"0x{hex_dig}\"  sha2({hashsize})=\"0x{sha2s}\"  sha3({hashsize})=\"0x{sha3s}\"")
                    #files.append(os.path.join(r, file))

    #lst = [file for file in files]
    #return lst
    return

def main(argv):
   inputdir = ''
   hashsize = 224
   try:
      opts, args = getopt.getopt(argv,"hi:s:",["idir=","size="])
   except getopt.GetoptError:
      print ('testsum.py -i <inputdir> -s <hashsize>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print ('Build checksums per any file, version 1.0')
         print ('Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.')
         print ('Usage: testsum.py -i <inputdir> -s <hashsize>')
         sys.exit()
      elif opt in ("-i", "--idir"):
         inputdir = arg
      elif opt in ("-s", "--size"):
         hashsize = int(arg)
   print ('Input dir: ', inputdir)
   print ('Hashsize:  ', hashsize)

   list_files_recursive(inputdir,hashsize)

if __name__ == "__main__":
   main(sys.argv[1:])
