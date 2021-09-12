import sys, getopt

def main(argv):
   inputfile = ''
   outputfile = ''
   in_file_offset = 0
   in_file_length = 0
   try:
      opts, args = getopt.getopt(argv,"hi:o:l:s:",["ifile=","ofile=","offset=","length="])
   except getopt.GetoptError:
      print ('file2bin.py -i <inputfile> -o <outputfile> -s <fileoffset> -l <filelen>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print ('Extract binary portion from file, version 1.0')
         print ('Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.')
         print ('Usage: file2bin.py -i <inputfile> -o <outputfile> -s <fileoffset> -l <filelen>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
      elif opt in ("-l", "--offset"):
         in_file_offset = int(arg)
      elif opt in ("-s", "--length"):
         in_file_length = int(arg)
   print ('Input file: ', inputfile)
   print ('Output file: ', outputfile)
   print ('Input file offset: ', in_file_offset)
   print ('Input file length: ', in_file_length)

   with open(inputfile, 'rb') as f1:
       f1.seek(in_file_offset,0)
       bufdata = f1.read(in_file_length)
       f1.close()

   with open(outputfile, 'wb') as f2:
      f2.write(bufdata)
      f2.close()

if __name__ == "__main__":
   main(sys.argv[1:])
