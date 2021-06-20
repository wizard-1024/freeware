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
import std.digest;
import std.digest.crc;
import std.digest.md;
import std.digest.sha;
import std.zlib;
import core.stdc.stdlib;
import std.conv;
import std.format;

const program_version = "1.0.0";


uint build_file_crc32( string filename, bool debug3 )  
{
    uint crc32_final = 0;
    size_t file_size = cast(size_t)getSize(filename);
    auto p_buf = malloc(file_size);
    if (p_buf is null)
    {
      import core.exception : onOutOfMemoryError;
      onOutOfMemoryError();
    }
    auto in_f = File(filename, "rb");
    ubyte[] buf; /* buffer to store the data */
    buf.length =  file_size /* number of data items to read */;
    ubyte[] rawbuf = in_f.rawRead(buf);
    if (rawbuf is null) {
       if (debug3) writeln( "Cannot read file!" );
       return 0;
    }
    if (debug3) writefln( "Read %d bytes done", rawbuf.length );
    in_f.close();
                        
    crc32_final = crc32(0,rawbuf);
    return crc32_final;
}


string build_file_md5( string filename, bool debug3 )  
{
    string md5_final_str = "";
    size_t file_size = cast(size_t)getSize(filename);
    auto p_buf = malloc(file_size);
    if (p_buf is null)
    {
      import core.exception : onOutOfMemoryError;
      onOutOfMemoryError();
    }
    auto in_f = File(filename, "rb");
    ubyte[] buf; /* buffer to store the data */
    buf.length =  file_size /* number of data items to read */;
    ubyte[] rawbuf = in_f.rawRead(buf);
    if (rawbuf is null) {
       if (debug3) writeln( "Cannot read file!" );
       return md5_final_str;
    }
    if (debug3) writefln( "Read %d bytes done", rawbuf.length );
    in_f.close();
    auto md5 = new MD5Digest();
    ubyte[] hash = md5.digest(rawbuf);
    md5_final_str = toHexString(hash);
    return md5_final_str;
}


string build_file_sha1( string filename, bool debug3 )  
{
    string sha1_final_str = "";
    size_t file_size = cast(size_t)getSize(filename);
    auto p_buf = malloc(file_size);
    if (p_buf is null)
    {
      import core.exception : onOutOfMemoryError;
      onOutOfMemoryError();
    }
    auto in_f = File(filename, "rb");
    ubyte[] buf; /* buffer to store the data */
    buf.length =  file_size /* number of data items to read */;
    ubyte[] rawbuf = in_f.rawRead(buf);
    if (rawbuf is null) {
       if (debug3) writeln( "Cannot read file!" );
       return sha1_final_str;
    }
    if (debug3) writefln( "Read %d bytes done", rawbuf.length );
    in_f.close();
    auto sha1 = new SHA1Digest();
    ubyte[] hash = sha1.digest(rawbuf);
    sha1_final_str = toHexString(hash);
    return sha1_final_str;
}


string build_file_sha2( string filename, bool debug3, ulong hashsize )  
{
    string sha2_final_str = "";
    size_t file_size = cast(size_t)getSize(filename);
    auto p_buf = malloc(file_size);
    if (p_buf is null)
    {
      import core.exception : onOutOfMemoryError;
      onOutOfMemoryError();
    }
    auto in_f = File(filename, "rb");
    ubyte[] buf; /* buffer to store the data */
    buf.length =  file_size /* number of data items to read */;
    ubyte[] rawbuf = in_f.rawRead(buf);
    if (rawbuf is null) {
       if (debug3) writeln( "Cannot read file!" );
       return sha2_final_str;
    }
    if (debug3) writefln( "Read %d bytes done", rawbuf.length );
    in_f.close();
    if (hashsize == 224) {
      auto sha224 = new SHA224Digest();
      ubyte[] hash224 = sha224.digest(rawbuf);
      sha2_final_str = toHexString(hash224);
      //return sha2_final_str;
    }
    if (hashsize == 256) {
      auto sha256 = new SHA256Digest();
      ubyte[] hash256 = sha256.digest(rawbuf);
      sha2_final_str = toHexString(hash256);
      //return sha2_final_str;
    }
    if (hashsize == 384) {
      auto sha384 = new SHA384Digest();
      ubyte[] hash384 = sha384.digest(rawbuf);
      sha2_final_str = toHexString(hash384);
      //return sha2_final_str;
    }
    if (hashsize == 512) {
      auto sha512 = new SHA512Digest();
      ubyte[] hash512 = sha512.digest(rawbuf);
      sha2_final_str = toHexString(hash512);
      //return sha2_final_str;
    }
    return sha2_final_str;
}


ulong list_dirs( string base_dir, bool subdirs, bool debug2, bool verbose, bool do_file, ulong hash_size, bool use_crc16, bool use_crc32, bool use_md5, bool use_sha1, bool use_sha2, bool use_sha3, bool use_gost1994, bool use_gost2012, string infile, string outfile )
{
    ulong total_files = 0;
    if (debug2) writeln("base_dir: ", base_dir );

    //auto dFiles = dirEntries(base_dir, SpanMode.depth).filter!(f => f.name.endsWith("*"));
    auto dFiles = dirEntries(base_dir, SpanMode.depth);
    foreach (d; dFiles) {
       if (isDir(d.name)) {
          if (debug2) writeln(d.name);
          total_files += list_dirs(d.name,subdirs,debug2,verbose,do_file,hash_size,use_crc16,use_crc32,use_md5,use_sha1,use_sha2,use_sha3,use_gost1994,use_gost2012,infile,outfile);
       }
       else {
             total_files++;
             if (do_file) {
                 append(outfile,"filename=\""); append(outfile,d.name); append(outfile,"\"");
             }
             else {
                 write("filename=\""); write(d.name); write("\"");
             }
             if (use_crc16) {
             }
             if (use_crc32) {
               uint crc32_sum =  build_file_crc32(d.name,debug2);
               if (do_file) {
                   append(outfile, " crc32="); append(outfile,crc32_sum.format!("0x%04X"));
               }
               else {
                   write(" crc32="); write(crc32_sum.format!("0x%04X"));
               }
             }
             if (use_md5) {
               string md5_sum_str =  build_file_md5(d.name,debug2);
               if (do_file) {
                   append(outfile, " md5="); append(outfile,md5_sum_str);
               }
               else {
                   write(" md5="); write(md5_sum_str);
               }
             }
             if (use_sha1) {
               string sha1_sum_str =  build_file_sha1(d.name,debug2);
               if (do_file) {
                   append(outfile, " sha1="); append(outfile,sha1_sum_str);
               }
               else {
                   write(" sha1="); write(sha1_sum_str);
               }
             }
             if (use_sha2) {
               string sha2_sum_str =  build_file_sha2(d.name,debug2,hash_size);
               if (do_file) {
                   append(outfile, " sha2("); append(outfile,hash_size.format!("%d")); append(outfile,")="); append(outfile,sha2_sum_str);
               }
               else {
                   write(" sha2("); write(hash_size); write(")="); write(sha2_sum_str);
               }
             }
             if (use_sha3) {
             }
             if (use_gost1994) {
             }
             if (use_gost2012) {
             }
             if (do_file) append(outfile,"\n");
             else writeln("");
       }
    }

    return total_files;
}



int main(string[] args)
{
    //string key;
    string  inFile = "";
    string  outFile = "";
    bool  verbose = false;
    bool  debug1 = false;
    bool  subdirs = false;
    bool  print_version = false;
    bool  help = false;
    bool  use_crc16 = false;
    bool  use_crc32 = false;
    bool  use_md5 = false;
    bool  use_sha1 = false;
    bool  use_sha2 = false;
    bool  use_sha3 = false;
    bool  use_gost1994 = false;
    bool  use_gost2012 = false;
    bool  test_mode = false;
    bool  print_failed_crc_only = false;
    bool  do_file = false;
    ulong hash_size = 512;
    ulong  total_files_count = 0;

    //auto e = EncodingScheme.create("utf-8");
    //auto e = EncodingScheme.create("WINDOWS-1251");

    const UTF8CP = 65001;
    UINT oldCP, oldOutputCP;
    oldCP = GetConsoleCP();
    oldOutputCP = GetConsoleOutputCP();

    SetConsoleCP(UTF8CP);
    SetConsoleOutputCP(UTF8CP);

    writeln("TestSum Utility 2021 (c) Dmitry Stefankov [D]");

    try {
        auto result = getopt(
            args,
            std.getopt.config.passThrough,
            std.getopt.config.caseSensitive,
            //std.getopt.config.required,
            //"key|k", "The key to use", &key,
            //std.getopt.config.required,
            "infile|f", "input file name", &inFile,
            "outfile|o", "results output file name", &outFile,
            "verbose|v", "verbose", &verbose,
            "debug1|d", "debug1", &debug1,
            "subdirs|s", "search subdirs", &subdirs,
            "version|V", "program's version", &print_version,
            "help|h", "print this help menu", &help,
            "crc16|1", "use CRC-16 algorithm", &use_crc16,
            "crc32|3", "use CRC-32 algorithm", &use_crc32,
            "md5|5", "use MD5 algorithm", &use_md5,
            "sha1|7", "use SHA-1 algorithm", &use_sha1,
            "sha2|2", "use SHA-2 algorithm", &use_sha2,
            "sha3|4", "use SHA-3 algorithm", &use_sha3,
            "gost1994|9", "use GOSTHASH algorithm (34.11-1994)", &use_gost1994,
            "gost2012|8", "use GOSTHASH algorithm (34.11-2012)", &use_gost2012,
            "failcrc|b", "print only filenames with failed CRC", &print_failed_crc_only,
            "test|t", "test (check) CRC sum for each file(s) listed in logfile", &test_mode,
            "hashsize|H", "hash size in bits (224,256,384,512)", &hash_size,
        );

        if (result.helpWanted || help || (args.length == 1)) {
            defaultGetoptPrinter("Usage: testsum [-d] [-v] [-f <logfile>] [-o resfile] [-s] [-t] [-V] [-12345789] [-b] [-h] [-H hashsize] dirname", result.options);
            return 255;
        }

    }
    catch (Exception e) {
        stderr.writefln("Error processing command line arguments: %s", e.msg);
        return 1;
    }

    if (inFile.length > 0) do_file = true;
    if (outFile.length > 0) do_file = true;

    if (debug1) {
      writeln("debug1: ", debug1 );
      writeln("verbose: ", verbose );
      writeln("subdirs: ", subdirs);
      writeln("print_version: ", print_version);
      writeln("help: ", help );
      writeln("inFile: ", inFile );
      writeln("outFile: ", outFile );
      writeln("use_crc16: ", use_crc16);
      writeln("use_crc32: ", use_crc32);
      writeln("use_md5: ", use_md5);
      writeln("use_sha1: ", use_sha1);
      writeln("use_sha2: ", use_sha2);
      writeln("use_sha3: ", use_sha3);
      writeln("use_gost1994: ", use_gost1994);
      writeln("use_gost2012: ", use_gost2012);
      writeln("test_mode: ", test_mode);
      writeln("hash_size: ", hash_size);
      writeln("do_file: ", do_file);
      writeln("print_failed_crc_only: ", print_failed_crc_only);
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

    if (test_mode) {
        if (!do_file) {
           writeln("ERROR: no input file found!");
           return 1;
        }
        string line;
        auto in_f = File(inFile, "rb");
        while ((line = in_f.readln()) !is null) {
          if (debug1) write(line);
          string filename0 = (std.string.split(line, "\""))[0];
          string filename1 = (std.string.split(line, "\""))[1];
          string checksum0 = (std.string.split(line, "\""))[2];
          if (debug1) { write("filename0:"); write(filename0); write(" filename1:"),write(filename1); write(" checksum0:"); write(checksum0); }
          string test_filename = filename1;
          string test_sum_str = tr(checksum0," \n","","d");
          if (debug1) { writeln("test_sum_str:",test_sum_str); }
          bool crc16_check = false;
          bool crc32_check = false;
          bool md5_check = false;
          bool sha1_check = false;
          bool sha2_check = false;
          bool sha3_check = false;
          bool gost1994_check = false;
          bool gost2012_check = false;
          ulong test_hash_size = 0;
          if (!find(test_sum_str,"crc16=").empty) { crc16_check = true; }
          if (!find(test_sum_str,"crc32=").empty) { crc32_check = true; }
          //if (debug1) { writeln("crc16_check:",crc16_check); }
          //if (debug1) { writeln("crc32_check:",crc32_check); }
          if (!find(test_sum_str,"md5=").empty) { md5_check = true; }
          if (!find(test_sum_str,"sha1=").empty) { sha1_check = true; }
          if (!find(test_sum_str,"GOST1994=").empty) { gost1994_check = true; }
          if (!find(test_sum_str,"sha2(224)=").empty) { sha2_check = true; test_hash_size = 224; }
          if (!find(test_sum_str,"sha3(224)=").empty) { sha3_check = true; test_hash_size = 224; }
          if (!find(test_sum_str,"sha2(256)=").empty) { sha2_check = true; test_hash_size = 256; }
          if (!find(test_sum_str,"sha3(256)=").empty) { sha3_check = true; test_hash_size = 256; }
          if (!find(test_sum_str,"sha2(384)=").empty) { sha2_check = true; test_hash_size = 384; }
          if (!find(test_sum_str,"sha3(384)=").empty) { sha3_check = true; test_hash_size = 384; }
          if (!find(test_sum_str,"sha2(512)=").empty) { sha2_check = true; test_hash_size = 512; }
          if (!find(test_sum_str,"sha3(512)=").empty) { sha3_check = true; test_hash_size = 256; }
          if (!find(test_sum_str,"GOST2012(256)=").empty) { gost2012_check = true; test_hash_size = 256; }
          if (!find(test_sum_str,"GOST2012(512)=").empty) { gost2012_check = true; test_hash_size = 512; }
          string test_sum0 = (std.string.split(test_sum_str, "="))[0];
          string test_sum1 = (std.string.split(test_sum_str, "="))[1];
          if (debug1) writeln( "test_sum1:",test_sum1);
          if (debug1) writeln( "test_filename: ", test_filename );
          if (crc16_check) {
          }
          if (crc32_check) {
              ulong crc32_sum = build_file_crc32(test_filename,debug1);
              string test_s = crc32_sum.format!("0x%04X");
              if (debug1) writeln( "test_crc32_sum: ", test_s );
              if (test_s == test_sum1) { if (!print_failed_crc_only) { write("fiilename=\""); write(test_filename); writeln("\"  crc32=\"OK\""); } }
              else { write("fiilename=\""); write(test_filename); writeln("\"  crc32=\"FAIL\""); }
          }
          if (md5_check) {
              string md5_sum = build_file_md5(test_filename,debug1);
              if (debug1) writeln( "md5_sum: ", md5_sum );
              if (md5_sum == test_sum1) { if (!print_failed_crc_only) { write("fiilename=\""); write(test_filename); writeln("\"  md5=\"OK\""); } }
              else { write("fiilename=\""); write(test_filename); writeln("\"  md5=\"FAIL\""); }
          }
          if (sha1_check) {
              string sha1_sum = build_file_sha1(test_filename,debug1);
              if (debug1) writeln( "sha1_sum: ", sha1_sum );
              if (sha1_sum == test_sum1) { if (!print_failed_crc_only) { write("fiilename=\""); write(test_filename); writeln("\"  sha1=\"OK\""); } }
              else { write("fiilename=\""); write(test_filename); writeln("\"  sha1=\"FAIL\""); }
          }
          if (sha2_check) {
              string sha2_sum = build_file_sha2(test_filename,debug1,test_hash_size);
              if (debug1) { write( "sha2_sum: "), write(sha2_sum ); writeln( "test_hash_size:",test_hash_size); }
              if (sha2_sum == test_sum1) { if (!print_failed_crc_only) { write("fiilename=\""); write(test_filename); write("\"  sha2("); write(test_hash_size); writeln(")=\"OK\""); } }
              else { write("fiilename=\""); write(test_filename); write("\"  sha2("); write(test_hash_size); writeln(")=\"FAIL\""); }
          }
        }
        return 0;
    }

    total_files_count = list_dirs(dirname, subdirs, debug1, verbose, do_file, hash_size, use_crc16, use_crc32, use_md5, use_sha1, use_sha2, use_sha3, use_gost1994, use_gost2012, inFile, outFile);

    if (debug1) writeln("Total items found: ", total_files_count );

    SetConsoleCP(oldCP);
    SetConsoleOutputCP(oldOutputCP);

    return 0;
}
