import std;
import std.stdio;
import std.conv : to;
import core.stdc.stdlib;
import std.file;
import std.datetime : DateTime, hnsecs, SysTime;

int main(string[] args) {
  writeln("Bin2file Utility (c) 2021 Dmitry Stefankov [D]");

  if (args.length < 6)
  {
        writefln ("Usage: %s infile outfile inofs insize outofs outlen", args[0]);
        return 1;
  }

  bool mydebug = true;
  string input_filename = args[1];
  string output_filename = args[2];
  size_t in_offset = args[3].to!size_t;
  size_t in_size = args[4].to!size_t;
  size_t out_offset = args[5].to!size_t;
  size_t out_length = args[6].to!size_t;

  if (mydebug) {
    writefln( "input_filename: %s", input_filename );
    writeln(  "output_filename: ", output_filename );
    writeln(  "input_offset: ", in_offset );
    writeln(  "in_size: ", in_size );
    writeln(  "output_offset: ", out_offset );
    writeln(  "out_length: ", out_length );
  }

  writeln("Allocating buffer memory");
    
  auto p_buf = malloc(in_size);
    
  if (p_buf is null)
  {
    import core.exception : onOutOfMemoryError;
    onOutOfMemoryError();
  }


  writeln("Seek and read input file");
  auto in_f = File(input_filename, "rb");
  in_f.seek(in_offset, SEEK_SET);
  ubyte[] buf; /* buffer to store the data */
  buf.length =  in_size/* number of data items to read */;
  ubyte[] rawbuf = in_f.rawRead(buf);
  if (rawbuf is null) {
    writeln( "Cannot read file!" );
    return 2;
  }
  writefln( "Read %d bytes done", rawbuf.length );
  in_f.close();

  SysTime accessTime, modificationTime;

  writeln("Write output file");
  auto out_f = File(output_filename,"r+b");
  getTimes(output_filename, accessTime, modificationTime);
  out_f.seek(out_offset, SEEK_SET);
  out_f.rawWrite(buf);
  out_f.close();

  setTimes(output_filename, accessTime, modificationTime);

  return 0;
}
