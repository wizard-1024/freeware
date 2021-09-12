import sys, getopt, os, time

def main(argv):
   inputfile = ''
   outputfile = ''
   searchpattern = ''
   replacepattern = ''
   try:
      opts, args = getopt.getopt(argv,"hi:o:s:r:",["ifile=","ofile=","spat=","rpat="])
   except getopt.GetoptError:
      print ('findrep.py -i <inputfile> -o <outputfile> -s <searchpattern> -r <replacepattern>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print ('Search and replace patterns for any files, version 1.0')
         print ('Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.')
         print ('Usage: findrep.py -i <inputfile> -o <outputfile> -s <fileoffset> -l <filelen>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
      elif opt in ("-s", "--spat"):
         searchpattern = arg
      elif opt in ("-r", "--rpat"):
         replacepattern = arg
   print ('Input file: ', inputfile)
   print ('Output file: ', outputfile)
   print ('Search pattern: ', searchpattern)
   print ('Replace pattern: ', replacepattern)

   in_file_size = os.path.getsize(inputfile);
   print(in_file_size)

   with open(inputfile, 'rb') as f1:
       bufdata = f1.read()
       f1.close()

   src = bufdata.decode('utf-8')
   dst = src.replace(searchpattern, replacepattern)
   newbuf = dst.encode()

   with open(outputfile, 'wb') as f2:
      f2.write(newbuf)
      f2.close()

if __name__ == "__main__":
   main(sys.argv[1:])
