import std;
import std.stdio;
import std.conv : to;
import core.stdc.stdlib;
import std.file;

int main(string[] args) {
  writeln("File2bin Utility (c) 2021 Dmitry Stefankov [D]");

  if (args.length < 5)
  {
        writefln ("Usage: %s infile outfile inofs outlen", args[0]);
        return 1;
  }

  bool mydebug = true;
  string input_filename = args[1];
  string output_filename = args[2];
  size_t in_offset = args[3].to!size_t;
  size_t out_length = args[4].to!size_t;

  if (mydebug) {
    writefln( "input_filename: %s", input_filename );
    writeln(  "output_filename: ", output_filename );
    writeln(  "input_offset: ", in_offset );
    writeln(  "out_length: ", out_length );
  }

  writeln("Allocating buffer memory");
    
  auto p_buf = malloc(out_length);
    
  if (p_buf is null)
  {
    import core.exception : onOutOfMemoryError;
    onOutOfMemoryError();
  }

  writeln("Seek and read input file");
  auto in_f = File(input_filename, "rb");
  in_f.seek(in_offset, SEEK_SET);
  ubyte[] buf; /* buffer to store the data */
  buf.length =  out_length/* number of data items to read */;
  ubyte[] rawbuf = in_f.rawRead(buf);
  if (rawbuf is null) {
    writeln( "Cannot read file!" );
    return 2;
  }
  writefln( "Read %d bytes done", rawbuf.length );
  in_f.close();

  writeln("Write output file");
  auto out_f = File(output_filename,"wb");
  out_f.rawWrite(buf);
  out_f.close();

  return 0;
}
