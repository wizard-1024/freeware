//
// List contents of directory
// Copyright (C) 2021 Dmitry Stefankov
//

import java.io.*;
import java.util.List;
import java.util.Date;
import java.nio.charset.Charset;
import java.nio.file.*;

public class listdir {


  public static void ListDir (String dirname) throws IOException {

    File dir=new File(dirname);
    File files[]=dir.listFiles();//files array stores the list of files

    for(int i=0;i<files.length;i++)
    {
        if(files[i].isFile()) //check whether files[i] is file or directory
        {
            String FullFileName = dirname+"\\"+files[i].getName();
            File file = new File(FullFileName);
            long file_size = file.length();
            long t = file.lastModified();
            Date d = new Date(t);
            System.out.println("  datetime=\""+d.toString()+"\""+"  size=\""+file_size+"\""+"  filename=\""+files[i].getName()+"\"");
            //System.out.println();

        }
        else if(files[i].isDirectory())
        {
            //System.out.println("Directory::"+files[i].getName());
            System.out.println(dirname+"\\"+files[i].getName());
            //System.out.println();
            ListDir(files[i].getAbsolutePath());
        }
    }
  }

  public static void main(String[] args) throws IOException {
     //System.out.println("There are " + args.length + " arguments given.");
     //for(int i = 0; i < args.length; i++) 
    //    System.out.println("The argument #" + (i+1) + " is " + args[i] + " and is at index " + i);
     if (args.length < 1) {
       System.out.println("List Directory Files, version 1.0");
       System.out.println("Copyright (c) 2021, Dmitry Stefankov");
       System.out.println("Usage: listdir.exe dirname");
       return;
     }
 
     String MainDir = args[0];
     ListDir(MainDir);
  }

}
