//
// Put binary portion from file to file
// Copyright (C) 2021 Dmitry Stefankov
//

import java.io.*;
import java.util.List;
import java.nio.charset.Charset;
import java.nio.file.*;

public class bin2file {

  public static byte[] MyReadAllBytes(String filename) throws IOException {
	Path file = Paths.get(filename);
	return Files.readAllBytes(file);
  }

  public static void main(String[] args) throws IOException {
     //System.out.println("There are " + args.length + " arguments given.");
     //for(int i = 0; i < args.length; i++) 
    //    System.out.println("The argument #" + (i+1) + " is " + args[i] + " and is at index " + i);
     if (args.length < 5) {
       System.out.println("Put binary portion from file to file, version 1.0");
       System.out.println("Copyright (c) 2021, Dmitry Stefankov");
       System.out.println("Usage: bin2file.exe infile outfile offset size newoffset");
       return;
     }
 
     String InFile = args[0];
     String OutFile = args[1];
     System.out.println("InFile: "+InFile);
     System.out.println("OutFile: "+OutFile);
     int in_offset = 0, in_length = 0, out_offset = 0;
     try {
       in_offset = Integer.parseInt(args[2]);
       System.out.println("in_Offset: "+in_offset);
       in_length = Integer.parseInt(args[3]);
       System.out.println("in_Length: "+in_length);
       out_offset = Integer.parseInt(args[4]);
       System.out.println("out_Offset: "+out_offset);
     }
     catch (NumberFormatException ex){
        ex.printStackTrace();
     }

     byte[] ReadBuffer = MyReadAllBytes(InFile);
     int InBufSize = ReadBuffer.length;
     System.out.println("InBufSize: "+InBufSize);

     byte[] WriteBuffer = MyReadAllBytes(OutFile);
     int OutBufSize = WriteBuffer.length;
     System.out.println("OutBufSize: "+OutBufSize);

     for (int i = 0; i < in_length; i++) {
        WriteBuffer[i+out_offset] = ReadBuffer[i+in_offset];
     }

     try (FileOutputStream stream = new FileOutputStream(OutFile)) {
       stream.write(WriteBuffer);
     }

  }

}
