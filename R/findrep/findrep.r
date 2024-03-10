# Rscript[.exe] findre.r test.in test.out search_pattern replace_pattern

#library(stringr)
#library(readr)

#Sys.setlocale("LC_ALL","English")
#Sys.setenv(LANG = "en_US.UTF-8")
Sys.setenv(LANG='C')

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  #filename <- args[1]
  #dat <- read.csv(file = filename, header = FALSE)
  #mean_per_patient <- apply(dat, 1, mean)
  #cat(mean_per_patient, sep = "\n")
  #args <- commandArgs()
  #cat(args, sep = "\n")
  in_filename <- args[1]
  out_filename <- args[2]
  search_pattern <- args[3]
  replace_pattern <- args[4]
  print(in_filename)
  print(out_filename)
  print(search_pattern)
  print(replace_pattern)
  #my_text <- readLines(in_filename, sep = "")
  my_text <- readLines(in_filename)
  #print(my_text)
  new_text = gsub(search_pattern,replace_pattern,my_text)
  fileConn<-file(out_filename)
  writeLines(new_text, fileConn)
  close(fileConn)
}

if (length(commandArgs(trailingOnly = TRUE)) == 0) {
  print("Search and replace text pattern per file, version 1.0")
  print("Copyright (C) 2024 Dmitry Stefankov. All Rights Reserved.");
  print("Usage: findrep infile outfile search_pattern replace_pattern");
  print("infile    - input filename");
  print("outfile   - output filename");
  print("srch_pat  - search pattern (default=empty)");
  print("repl_pat  - replace pattern (default=empty)");
  quit(status=1)
}

main()

