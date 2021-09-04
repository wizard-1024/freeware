/* 
  Put binary portion from file to another file (portion->portion)
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
        if (args.Length < 5) {
           Console.WriteLine("Put file binary portion to file, version 1.0");
           Console.WriteLine("Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.");
           Console.WriteLine("Usage : bin2file <InFileName> <OutFileName> <InOffset> <Size> <OutOffset>");
           return 1;
        }

        String InFilename = args[0];
        String OutFilename = args[1];
        FileStream fs;
        int in_file_ofs = Convert.ToInt32(args[2], 10);
        int in_file_size = Convert.ToInt32(args[3], 10);
        int out_file_ofs = Convert.ToInt32(args[4], 10);
        int sum = 0;

        Console.WriteLine("InFileName: {0}, OutFileName: {1}, InOfs={2}, InSize={3}, OutSize={4}", 
                          InFilename, OutFilename, in_file_ofs, in_file_size, out_file_ofs );

        //var len = file_size;
        var bits = new byte[in_file_size];

        if (System.IO.File.Exists(InFilename)) {

          fs = new FileStream(InFilename, FileMode.Open, FileAccess.Read);
          try
          {
               //fs = new FileStream(InFilename, FileMode.Open, FileAccess.Read);
               //file_ofs = (int)fs.Position;
               fs.Seek(in_file_ofs, SeekOrigin.Begin);
               //var len = file_size;
               //var bits = new byte[len];
               fs.Read(bits, sum, in_file_size);
          }
          catch (Exception ex)
          {
            Console.WriteLine(ex.Message);
          }
          finally
          {
               fs.Close();
          }

          FileInfo fileInfo = new FileInfo(OutFilename);
          // note: We must buffer the current file properties because fileInfo
          //       is transparent and will report the current data!
          FileAttributes attributes = fileInfo.Attributes;
          DateTime lastWriteTime = fileInfo.LastWriteTime;

          // do stuff that adds something to the file here
          fs = new FileStream(OutFilename, FileMode.Open, FileAccess.ReadWrite);
          sum = 0;
          try
          {
               //DateTime creation_time = fs.GetCreationTime(OutFilename);
               fs.Seek(out_file_ofs, SeekOrigin.Begin);
               fs.Write(bits, sum, in_file_size);
          }
          catch (Exception ex)
          {
            Console.WriteLine(ex.Message);
          }
          finally
          {
               fs.Close();
               //File.SetAttributes(OutFilename, attributes);
               File.SetLastWriteTime(OutFilename, lastWriteTime);
          }


        }

        return 0;
    }

}
