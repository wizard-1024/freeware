import std;
import std.stdio;
import std.conv : to;
import std.array: array;
import core.stdc.stdlib;
import std.file;
import std.datetime : DateTime, hnsecs, SysTime;

int main(string[] args) {
  writeln("FindReplace Utility (c) 2021 Dmitry Stefankov [D]");

  if (args.length < 6)
  {
        writefln ("Usage: %s infile outfile inpat outpat ask", args[0]);
        return 1;
  }

  bool mydebug = true;
  string input_filename = args[1];
  string output_filename = args[2];
  string in_pattern = args[3];
  string out_pattern = args[4];
  bool   ask = args[5].to!bool; 

  if (mydebug) {
    writeln( "input_filename: ", input_filename );
    writeln(  "output_filename: ", output_filename );
    writeln(  "input_pattern: ", in_pattern );
    writeln(  "output_pattern: ", out_pattern );
    writeln(  "ask: ", ask );
  }

  //size_t in_file_size = getSize(input_filename);
  ulong in_file_size = getSize(input_filename);
  if (mydebug) writeln(  "in_file_size: ", in_file_size );
  if (mydebug) writeln(  "in_file_size: ", to!size_t(in_file_size) );

  if (mydebug) writeln("Allocating buffer memory");
    
  auto p_buf = malloc(to!size_t(in_file_size));
    
  if (p_buf is null)
  {
    import core.exception : onOutOfMemoryError;
    onOutOfMemoryError();
  }

  if (mydebug) writeln("Read input file");
  auto in_f = File(input_filename, "rb");
  ubyte[] buf; /* buffer to store the data */
  buf.length =  to!size_t(in_file_size); /* number of data items to read */
  ubyte[] rawbuf = in_f.rawRead(buf);
  if (rawbuf is null) {
    writeln( "Cannot read file!" );
    return 2;
  }
  if (mydebug) writefln( "Read %d bytes done", rawbuf.length );
  in_f.close();

  char[] strInArr = in_pattern.dup;
  char[] strOutArr = out_pattern.dup;
  ubyte[] a = cast(ubyte[]) strInArr;
  ubyte[] b = cast(ubyte[]) strOutArr;

  auto newbuf = rawbuf.replace(a,b);
  if (mydebug) writefln( "New buffer has %d bytes", newbuf.length );

  if (mydebug) writeln("Write output file");
  auto out_f = File(output_filename,"wb");
  out_f.rawWrite(newbuf);
  if (mydebug) writefln( "Write %d bytes done", newbuf.length );
  out_f.close();

  return 0;
}
