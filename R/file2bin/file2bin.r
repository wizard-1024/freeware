# Rscript[.exe] file2bin.r test.in test.out 35 67

Sys.setenv(LANG='C')

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  in_filename <- args[1]
  out_filename <- args[2]
  in_offset <- args[3]
  in_size <- args[4]
  print(in_filename)
  print(out_filename)
  print(in_offset)
  print(in_size)
  cx <- file(in_filename, "rb")
  seek(cx, in_offset)
  d <- readBin(cx,"raw",in_size,size=1)
  close(cx)
  con <- file(out_filename, "wb")
  writeBin(d, con, size = 1)
  close(con)
}

if (length(commandArgs(trailingOnly = TRUE)) == 0) {
  print("Extract binary portion from file, version 1.0")
  print("Copyright (C) 2024 Dmitry Stefankov. All Rights Reserved.");
  print("Usage: file2bin infile outfile in_offset in_size");
  print("infile    - input filename");
  print("outfile   - output filename");
  print("in_offset - byte offset on input stream (default=0)");
  print("in_size   - copy N bytes from input stream (default=0)");
  quit(status=1)
}

main()



