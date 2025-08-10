// Scala Program on command line argument
import java.io.File
import java.io.PrintWriter
import scala.sys.process._
import scala.language.postfixOps
import scala.io.Source._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Path}
//import java.util.Scanner
//import java.io.File

object File2bin
{
    // Main method
    def main(args: Array[String])
    {
       if (args.length == 0)
       {
         println("Copy binary portion of file to another file, version 1.0");
         println("Copyright (c) 2025, Dmitry Stefankov");
         println("Usage: file2bin infile outfile offset length");
         sys.exit(1);
       }

        // You pass any thing at runtime 
        // that will be print on the console
        var count : Int = 1;
        var infile : String = ""
        var outfile : String = ""
        var filelen : Int = 0
        var fileofs : Int = 0
        for(arg<-args)
        {
            println("Arg " + count + ": " + arg);
            if (count == 1) { infile = arg; println(infile) }
            if (count == 2) { outfile = arg; println(outfile) }
            if (count == 3) { fileofs = arg.toInt; println(fileofs) }
            if (count == 4) { filelen = arg.toInt; println(filelen) }
            count += 1
        }

        // --- read input file
        val path = Path.of(infile)
        //var content: String = os.read(path)
        //val lines = fromFile(path).getLines
        val source = scala.io.Source.fromFile(infile)
        val lines = try source.mkString finally source.close()
        //println(lines)
        val sub1 = lines.substring(fileofs,fileofs+filelen)

        // Creating a file 
        val file_Object = new File(outfile)
        // Passing reference of file to the printwriter     
        val print_Writer = new PrintWriter(file_Object)
        // Writing to the file       
        //print_Writer.write(lines)
        print_Writer.write(sub1)
        // Closing printwriter    
        print_Writer.close()

    }
}

