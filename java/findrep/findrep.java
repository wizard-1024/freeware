//
// search & replace patterns for any files
// Copyright (C) 2021 Dmitry Stefankov
//

import java.io.*;
import java.util.List;
import java.nio.charset.Charset;
import java.nio.file.*;

public class findrep {

  public static byte[] MyReadAllBytes(String filename) throws IOException {
	Path file = Paths.get(filename);
	return Files.readAllBytes(file);
  }

  public static void main(String[] args) throws IOException {
     //System.out.println("There are " + args.length + " arguments given.");
     //for(int i = 0; i < args.length; i++) 
    //    System.out.println("The argument #" + (i+1) + " is " + args[i] + " and is at index " + i);
     if (args.length < 4) {
       System.out.println("Search & replace pattern(s) for any files, version 1.0");
       System.out.println("Copyright (c) 2021, Dmitry Stefankov");
       System.out.println("Usage: bin2file.exe infile outfile oldpat newpat");
       return;
     }
 
     String InFile = args[0];
     String OutFile = args[1];
     System.out.println("InFile: "+InFile);
     System.out.println("OutFile: "+OutFile);
     String OldPattern = args[2];
     String NewPattern = args[3];
     System.out.println("OldPattern: "+OldPattern);
     System.out.println("NewPattern: "+NewPattern);

     byte[] ReadBuffer = MyReadAllBytes(InFile);
     int InBufSize = ReadBuffer.length;
     System.out.println("InBufSize: "+InBufSize);

     String string = new String(ReadBuffer, "UTF8");
     string = string.replace(OldPattern,NewPattern);
     byte[] WriteBuffer = string.getBytes("UTF8");

     try (FileOutputStream stream = new FileOutputStream(OutFile)) {
       stream.write(WriteBuffer);
     }

  }

}
