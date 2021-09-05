//
//  Copy binary portion of file to another file
//  2021 (c) Dmitry Stefankov 
//

import java.io.*;
import java.util.List;
import java.nio.charset.Charset;
import java.nio.file.*;

public class file2bin {

  public static byte[] MyReadAllBytes(String filename) throws IOException {
	Path file = Paths.get(filename);
	return Files.readAllBytes(file);
  }

  public static void main(String[] args) throws IOException {
     //System.out.println("There are " + args.length + " arguments given.");
     //for(int i = 0; i < args.length; i++) 
    //    System.out.println("The argument #" + (i+1) + " is " + args[i] + " and is at index " + i);
     if (args.length < 4) {
       System.out.println("Copy binary portion of file to another file, version 1.0");
       System.out.println("Copyright (c) 2021, Dmitry Stefankov");
       System.out.println("Usage: file2bin infile outfile offset length");
       return;
     }
 
    String InFile = args[0];
     String OutFile = args[1];
     System.out.println("InFile: "+InFile);
     System.out.println("OutFile: "+OutFile);
     int offset = 0, length = 0;
     try {
       offset = Integer.parseInt(args[2]);
       System.out.println("Offset: "+offset);
       length = Integer.parseInt(args[3]);
       System.out.println("Length: "+length);
     }
     catch (NumberFormatException ex){
        ex.printStackTrace();
     }

     byte[] ReadBuffer = MyReadAllBytes(InFile);
     int InBufSize = ReadBuffer.length;
     System.out.println("InBufSize: "+InBufSize);

     byte[] NewBytes = new byte[length];
     for (int i = 0; i < NewBytes.length; i++) {
        NewBytes[i] = ReadBuffer[i+offset];
     }

     try (FileOutputStream stream = new FileOutputStream(OutFile)) {
       stream.write(NewBytes);
     }
  }

}
