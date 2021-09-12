import sys, getopt, os, time

def main(argv):
   inputfile = ''
   outputfile = ''
   in_file_offset = 0
   in_file_length = 0
   out_file_offset = 0
   try:
      opts, args = getopt.getopt(argv,"hi:o:l:s:p:",["ifile=","ofile=","offset=","length=","ofs="])
   except getopt.GetoptError:
      print ('bin2file.py -i <inputfile> -o <outputfile>')
      sys.exit(2)
   for opt, arg in opts:
      if opt == '-h':
         print ('Put binary portion from file, version 1.0')
         print ('Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.')
         print ('Usage: bin2file.py -i <inputfile> -o <outputfile> -s <infileoffset> -l <infilelen> -p <outfileoffset>')
         sys.exit()
      elif opt in ("-i", "--ifile"):
         inputfile = arg
      elif opt in ("-o", "--ofile"):
         outputfile = arg
      elif opt in ("-l", "--offset"):
         in_file_offset = int(arg)
      elif opt in ("-s", "--length"):
         in_file_length = int(arg)
      elif opt in ("-p", "--ofs"):
         out_file_offset = int(arg)
   print ('Input file: ', inputfile)
   print ('Output file: ', outputfile)
   print ('Input file offset: ', in_file_offset)
   print ('Input file length: ', in_file_length)
   print ('Output file offset: ', out_file_offset)

   in_file_size = os.path.getsize(inputfile);
   #inbuf = bytearray(in_file_size)

   with open(inputfile, 'rb') as f1:
       f1.seek(in_file_offset,0)
       bufdata = bytearray(f1.read(in_file_length))
       f1.close()

   out_file_length = os.path.getsize(outputfile);
   #buffer = bytearray(10)
   #print(out_file_length)

   #print("Last modified: %s" % time.ctime(os.path.getmtime(outputfile)))
   #print("Created: %s" % time.ctime(os.path.getctime(outputfile)))

   #modTimesinceEpoc = os.path.getmtime(outputfile)

   stinfo = os.stat(outputfile)

   with open(outputfile, 'rb') as f1:
       newbufdata = bytearray(f1.read())
       f1.close()

   newbufdata[out_file_offset:out_file_offset + len(bufdata)] = bufdata
   #buffer1[pos:pos+len(buffer2)] = buffer2

   with open(outputfile, 'wb') as f2:
       f2.write(newbufdata)
       f2.close()

   os.utime(outputfile,(stinfo.st_atime,stinfo.st_mtime))

if __name__ == "__main__":
   main(sys.argv[1:])
