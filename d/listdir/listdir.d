import core.sys.windows.windows;
import std;
import std.stdio;
import std.getopt;
import std.algorithm;
import std.array;
import std.file;
import std.path;
import std.string;
import std.datetime;

const program_version = "1.0.0";

ulong list_dirs( string base_dir, bool subdirs, bool debug2, bool verbose, bool dironly, bool fullname, bool fileinfo )
{
    ulong total_files = 0;
    if (debug2) writeln("base_dir: ", base_dir );

    //auto dFiles = dirEntries(base_dir, SpanMode.depth).filter!(f => f.name.endsWith("*"));
    auto dFiles = dirEntries(base_dir, SpanMode.depth);
    foreach (d; dFiles) {
       if (isDir(d.name)) {
          writeln(d.name);
          total_files += list_dirs(d.name,subdirs,debug2,verbose,dironly,fullname,fileinfo);
       }
       else {
           if (!dironly) {
             total_files++;
             if (fullname) {
               write("  filename=\""); write(d.name); write("\"");
             }
             else {
               write("  filename=\""); write(baseName(d.name)); write("\"");
             }
             if (fileinfo) {
                 ulong file_size = getSize(d.name);
                 write("  size=\""); write(file_size); write("\"");
                 SysTime accessTime, modificationTime;
                 getTimes(d.name, accessTime, modificationTime);
                 auto st = modificationTime;
                 write(  "datetime=\""); write(st.toISOExtString()); write("\"");
             }
             writeln("");
           }
       }
    }

    return total_files;
}


int main(string[] args)
{
    //string key;
    string  logFile = "";
    bool  verbose = false;
    bool  debug1 = false;
    bool  subdirs = false;
    bool  print_version = false;
    bool  help = false;
    bool  print_dirs_only = false;
    bool  fullname = false;
    bool  fileinfo = false;
    ulong  total_files_count = 0;

    //auto e = EncodingScheme.create("utf-8");
    //auto e = EncodingScheme.create("WINDOWS-1251");

    const UTF8CP = 65001;
    UINT oldCP, oldOutputCP;
    oldCP = GetConsoleCP();
    oldOutputCP = GetConsoleOutputCP();

    SetConsoleCP(UTF8CP);
    SetConsoleOutputCP(UTF8CP);

    writeln("ListDir Utility 2021 (c) Dmitry Stefankov [D]");

    try {
        auto result = getopt(
            args,
            std.getopt.config.passThrough,
            std.getopt.config.caseSensitive,
            //std.getopt.config.required,
            //"key|k", "The key to use", &key,
            //std.getopt.config.required,
            "file|l", "logging output file name", &logFile,
            "verbose|v", "verbose", &verbose,
            "debug1|d", "debug1", &debug1,
            "subdirs|s", "search subdirs", &subdirs,
            "version|V", "program's version", &print_version,
            "help|h", "print this help menu", &help,
            "dironly|r", "print dirnames only", &print_dirs_only,
            "fullname|f", "print full name", &fullname,
            "fileinfo|t", "print file info", &fileinfo,
        );

        if (result.helpWanted || help || args.length == 1) {
            defaultGetoptPrinter("Usage: listdir [-d] [-v] [-l <logfile>] [-s] [-f] [-t] [-V] [-r] dirname", result.options);
        }
    }
    catch (Exception e) {
        stderr.writefln("Error processing command line arguments: %s", e.msg);
        return 1;
    }

    if (debug1) {
      writeln("debug1: ", debug1 );
      writeln("verbose: ", verbose );
      writeln("subdirs: ", subdirs);
      writeln("fullname: ", fullname );
      writeln("fileinfo: ", fileinfo );
      writeln("print_dirs_only: ", print_dirs_only );
      writeln("print_version: ", print_version);
      writeln("help: ", help );
      writeln("logFile: ", logFile );
    }

    if (print_version) {
      writeln( "Version: ", program_version );
      return 0;
    }

    string dirname = args[args.length-1];
    if (debug1) {
        writeln( "args.length: ", args.length );
        writeln("initial dirname: ", dirname );
    }

    total_files_count = list_dirs(dirname,subdirs,debug1,verbose,print_dirs_only,fullname,fileinfo);

    writeln("Total items found: ", total_files_count );

    SetConsoleCP(oldCP);
    SetConsoleOutputCP(oldOutputCP);

    return 0;
}
