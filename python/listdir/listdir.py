import sys, getopt, os, time
from pathlib import Path


def printf(format, *args):
    sys.stdout.write(format % args)

def list_files_recursive(path):
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
                print (newdir)
                list_files_recursive(newdir)
        for file in f:
            newfilename = path+"\\"+file
            newfile = Path(newfilename)
            if newfile.exists():
                stinfo = os.stat(newfilename)
                file_size = os.path.getsize(newfilename);
                print(f"  filename=\"{file}\"  size=\"{file_size}\" datetime=\"%s\"" % time.ctime(os.path.getmtime(newfilename)))
                #files.append(os.path.join(r, file))

    #lst = [file for file in files]
    #return lst
    return

def main(argv):
   inputdir = ''
   try:
      opts, args = getopt.getopt(argv,"hi:",["idir="])
   except getopt.GetoptError:
      print ('listdir.py -i <inputdir>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print ('List all files per directory, version 1.0')
         print ('Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.')
         print ('Usage: findrep.py -i <inputdir>')
         sys.exit()
      elif opt in ("-i", "--idir"):
         inputdir = arg
   print ('Input dir: ', inputdir)

   list_files_recursive(inputdir)

if __name__ == "__main__":
   main(sys.argv[1:])
