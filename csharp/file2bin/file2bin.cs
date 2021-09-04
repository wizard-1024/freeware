/* 
  Copy binary portion of file to another file
  2021 (c) Dmitry Stefankov 
*/

using System;
using System.IO;
using System.Text;
//using CommandLine;


class Program {

    static int Main(string[] args)
    {
        // Display the number of command line arguments:
        // String ProgramFilename = args[0];
        Console.WriteLine();
        // Invoke this program with an arbitrary set of command line arguments.
        string[] arguments = Environment.GetCommandLineArgs();
        Console.WriteLine("GetCommandLineArgs: {0}", string.Join(", ", arguments));

        System.Console.WriteLine(args.Length);
        //if (args.Length < 5) {
        if (args.Length < 4) {
           Console.WriteLine("Extract binary portion from file, version 1.0");
           Console.WriteLine("Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.");
           Console.WriteLine("Usage : file2bin <InFileName> <OutFileName> <Offset> <Size>");
           return 1;
        }

        String InFilename = args[0];
        String OutFilename = args[1];
        FileStream fs;
        int file_ofs = Convert.ToInt32(args[2], 10);
        int file_size = Convert.ToInt32(args[3], 10);
        int sum = 0;

        Console.WriteLine("InFileName: {0}, OutFileName: {1}, ofs={2}, size={3}", InFilename, OutFilename, file_ofs, file_size );

        //var len = file_size;
        var bits = new byte[file_size];


        if (System.IO.File.Exists(InFilename)) {
          fs = new FileStream(InFilename, FileMode.Open, FileAccess.Read);
          try
          {
               //fs = new FileStream(InFilename, FileMode.Open, FileAccess.Read);
               //file_ofs = (int)fs.Position;
               fs.Seek(file_ofs, SeekOrigin.Begin);
               //var len = file_size;
               //var bits = new byte[len];
               fs.Read(bits, sum, file_size);
          }
          catch (Exception ex)
          {
            Console.WriteLine(ex.Message);
          }
          finally
          {
               fs.Close();
          }
          fs = new FileStream(OutFilename, FileMode.Create, FileAccess.Write);
          sum = 0;
          try
          {
               fs.Write(bits, sum, file_size);
          }
          catch (Exception ex)
          {
            Console.WriteLine(ex.Message);
          }
          finally
          {
               fs.Close();
          }
        }

        return 0;
    }

}
