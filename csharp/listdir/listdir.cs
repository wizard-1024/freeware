/* 
  List directory contents
  2021 (c) Dmitry Stefankov 
*/

using System;
using System.IO;


class Program
{
        public static long DirsCount = 0;
        public static long FilesCount = 0;
        public static long TotalSize = 0;

        public static void DirectorySearch(string dir)
        {
          Console.WriteLine(dir);
          DirsCount++;
          try
          {
            foreach (string f in Directory.GetFiles(dir))
            {
               string FullFilename = dir+"\\"+Path.GetFileName(f);
               FileInfo fileInfo = new FileInfo(FullFilename);
               //FileAttributes attributes = fileInfo.Attributes;
               DateTime lastWriteTime = fileInfo.LastWriteTime;
               long FileSize = fileInfo.Length;
               FilesCount++;
               TotalSize += FileSize;

               //Console.WriteLine("  filename=\"{0}\\{1}\"",dir,Path.GetFileName(f));
               Console.WriteLine("datetime=\"{0}\"  filesize=\"{1}\"  filename=\"{2}\"",
                                  lastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"), 
                                  FileSize.ToString(), FullFilename);
            }
            foreach (string d in Directory.GetDirectories(dir))
            {
              //Console.WriteLine(Path.GetFileName(d));
              DirectorySearch(d);
            }
          }
          catch (System.Exception ex)
          {
            Console.WriteLine(ex.Message);
          }
        }

        static int Main(string[] args)
        {
            // Display the number of command line arguments:
            // String ProgramFilename = args[0];
            //Console.WriteLine();
            // Invoke this program with an arbitrary set of command line arguments.
            string[] arguments = Environment.GetCommandLineArgs();
            //Console.WriteLine("GetCommandLineArgs: {0}", string.Join(", ", arguments));

            //System.Console.WriteLine(args.Length);
            if (args.Length < 1) {
              Console.WriteLine("List Directory, version 1.0");
              Console.WriteLine("Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved.");
              Console.WriteLine("Usage : listdir <Dirname>");
              return 1;
            }

            string myDir = args[0];
            DirectorySearch(myDir);

            Console.WriteLine("Dirs=\"{0}\", Files=\"{1}\", TotalSize=\"{2}\"",
                              DirsCount.ToString(),FilesCount.ToString(),TotalSize.ToString());

            return 0;
        }
}
