extern crate getopts;
use getopts::Options;

use std::env;
use std::process;
use std::fs;
//use std::string;
use std::fs::File;
use std::io::Read;
use std::io::Write;
use std::fs::OpenOptions;
use std::io::{self, BufRead};
use std::path::Path;
use crc16::*;
use crc::{Crc, CRC_32_ISO_HDLC};
use sha1::{Sha1, Digest};
use sha2::{Sha224,Sha256,Sha384,Sha512};
use sha3::{Sha3_224,Sha3_256,Sha3_384,Sha3_512};
use streebog::{Streebog256, Streebog512};
use gost94::{Gost94Test};
//use gost94::{Gost94Test,Gost94CryptoPro,Gost94s2015};

static VERSION: &'static str = "1.0.0";


fn print_usage(program: &str, opts: Options) {
    let brief = format!("Usage: {} FILE [options]", program);
    print!("{}", opts.usage(&brief));
}


fn write_text_file( filename: String, str: String ) {
    let mut file = OpenOptions::new()
           .create(true)
           .write(true)
           .append(true)
           .open(filename)
           .unwrap();
    if let Err(e) = write!(file,"{}",str) {
        eprintln!("Couldn't write to file: {}", e);
    }
}


// The output is wrapped in a Result to allow matching on errors
// Returns an Iterator to the Reader of the lines of the file.
fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where P: AsRef<Path>, {
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}


fn build_file_crc16( filename: String, debug: bool ) -> u16 {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    //if debug { println!("create variable memory buffer: {} bytes",file_length); };
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    //if debug { println!("try to open input file"); };
    let mut infile=File::open(filename).unwrap();
    //if debug { println!("try to read input file"); };
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    //if debug { println!("bytes_read: {}",bytes_read); };
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let mut state = State::<XMODEM>::new();
    state.update(&in_filebuf);
    let crc16_final:u16 = state.get();
    return crc16_final;
}


fn build_file_crc32( filename: String, debug: bool ) -> u32 {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let crc = Crc::<u32>::new(&CRC_32_ISO_HDLC);
    let mut digest = crc.digest();
    digest.update(&in_filebuf);
    let crc32_final:u32 = digest.finalize();
    return crc32_final;
}


fn build_file_md5( filename: String, debug: bool ) -> String {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let digest = md5::compute(&in_filebuf);
    let md5_str:String = format!("0x{:x}", digest);
    return md5_str;
}


fn build_file_sha1( filename: String, debug: bool ) -> String {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let mut hasher = Sha1::new();
    hasher.update(&in_filebuf);
    let result = hasher.finalize();
    let sha1_str:String = format!("0x{:x}", result);
    return sha1_str;
}


fn build_file_sha2( filename: String, hashsize: u32, debug: bool ) -> String {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let mut sha2_str:String = String::from("").to_string();
    if hashsize == 224 {
      let mut hasher = Sha224::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha2_str = format!("0x{:x}", result);
    }
    if hashsize == 256 {
      let mut hasher = Sha256::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha2_str = format!("0x{:x}", result);
    }
    if hashsize == 384 {
      let mut hasher = Sha384::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha2_str = format!("0x{:x}", result);
    }
    if hashsize == 512 {
      let mut hasher = Sha512::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha2_str = format!("0x{:x}", result);
    }
    return sha2_str;
}


fn build_file_sha3( filename: String, hashsize: u32, debug: bool ) -> String {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let mut sha3_str:String = String::from("").to_string();
    if hashsize == 224 {
      let mut hasher = Sha3_224::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha3_str = format!("0x{:x}", result);
    }
    if hashsize == 256 {
      let mut hasher = Sha3_256::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha3_str = format!("0x{:x}", result);
    }
    if hashsize == 384 {
      let mut hasher = Sha3_384::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha3_str = format!("0x{:x}", result);
    }
    if hashsize == 512 {
      let mut hasher = Sha3_512::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      sha3_str = format!("0x{:x}", result);
    }
    return sha3_str;
}


fn build_file_gost1994( filename: String, debug: bool ) -> String {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let mut hasher = Gost94Test::new();
    hasher.update(&in_filebuf);
    let result = hasher.finalize();
    let gost1994_str:String = format!("0x{:x}", result);
    return gost1994_str;
}


fn build_file_gost2012( filename: String, hashsize: u32, debug: bool ) -> String {
    let metadata = fs::metadata(filename.to_string()).unwrap();
    let file_size = metadata.len();
    let file_length = file_size as u64;
    let mut in_filebuf = Vec::new();
    for _i in 0..file_length {
       in_filebuf.push(0);
    };
    let mut infile=File::open(filename).unwrap();
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if bytes_read != in_filebuf.len() {
      if debug { println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len()); };
      // handle error or bail out
    }
    let mut gost2012_str:String = String::from("").to_string();
    if hashsize == 256 {
      let mut hasher = Streebog256::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      gost2012_str = format!("0x{:x}", result);
    }
    if hashsize == 512 {
      let mut hasher = Streebog512::new();
      hasher.update(&in_filebuf);
      let result = hasher.finalize();
      gost2012_str = format!("0x{:x}", result);
    }
    return gost2012_str;
}


//fn scan_dir(scan_dirname:String, debug:bool, verbose:bool, subdirs:bool, crc16:bool, crc32:bool, md5:bool, sha1:bool, sha2:bool, sha3:bool, gost1994:bool, gost2012:bool, hash_size:u32, do_file:bool, outfile1:String) -> u64 {
fn scan_dir(scan_dirname:String, outfile:String, debug:bool, verbose:bool, subdirs:bool, crc16:bool, crc32:bool, md5:bool, sha1:bool, sha2:bool, sha3:bool, gost1994:bool, gost2012:bool, hash_size:u32, do_file:bool) -> u64 {
    let mut files_count:u64 = 0;
    if debug { println!("scan_dir: {}",scan_dirname); };
    println!("{}", scan_dirname);
    if debug { println!("crc16: {}",crc16); };
    let paths = fs::read_dir(scan_dirname).unwrap();
    for path in paths {
        let dirname = path.unwrap().path();
        if dirname.is_file() {
              files_count += 1;
              if do_file {
                let s = format!("\"{}\"", dirname.display());
                write_text_file(outfile.clone(),s.clone());
              }
              else {
                  print!("\"{}\"", dirname.display());
              }
              if crc16 {
                  let crc16_sum:u16 = build_file_crc16(dirname.display().to_string(),debug);
                  if do_file {
                    let s = format!(" crc16=\"{}\"",format!("{:#X}", crc16_sum));
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" crc16=\"{}\"",format!("{:#X}", crc16_sum));
                  }
              };
              if crc32 {
                  let crc32_sum:u32 = build_file_crc32(dirname.display().to_string(),debug);
                  if do_file {
                    let s = format!(" crc32=\"{}\"",format!("{:#X}", crc32_sum));
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" crc32=\"{}\"",format!("{:#X}", crc32_sum));
                  }
              };
              if md5 {
                  let md5_sum_str:String = build_file_md5(dirname.display().to_string(),debug);
                  if do_file {
                    let s = format!(" md5=\"{}\"",md5_sum_str);
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" md5=\"{}\"",md5_sum_str);
                  }
              };
              if sha1 {
                  let sha1_sum_str:String = build_file_sha1(dirname.display().to_string(),debug);
                  if do_file {
                    let s = format!(" sha1=\"{}\"",sha1_sum_str);
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" sha1=\"{}\"",sha1_sum_str);
                  }
              };
              if sha2 {
                  let sha2_sum_str:String = build_file_sha2(dirname.display().to_string(),hash_size,debug);
                  if do_file {
                    let s = format!(" sha2({})=\"{}\"",hash_size,sha2_sum_str);
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" sha2({})=\"{}\"",hash_size,sha2_sum_str);
                  }
              };
              if sha3 {
                  let sha3_sum_str:String = build_file_sha3(dirname.display().to_string(),hash_size,debug);
                  if do_file {
                    let s = format!(" sha3({})=\"{}\"",hash_size,sha3_sum_str);
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" sha3({})=\"{}\"",hash_size,sha3_sum_str);
                  }
              };
              if gost1994 {
                  let gost1994_sum_str:String = build_file_gost1994(dirname.display().to_string(),debug);
                  if do_file {
                    let s = format!(" GOST1994=\"{}\"",gost1994_sum_str);
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" GOST1994=\"{}\"",gost1994_sum_str);
                  }
              };
              if gost2012 {
                  let gost2012_sum_str:String = build_file_gost2012(dirname.display().to_string(),hash_size,debug);
                  if do_file {
                    let s = format!(" GOST2012({})=\"{}\"",hash_size,gost2012_sum_str);
                    write_text_file(outfile.clone(),s.clone());
                  }
                  else {
                    print!(" GOST2012({})=\"{}\"",hash_size,gost2012_sum_str);
                  }
              };
              if do_file {
                write_text_file(outfile.clone(),"\n".to_string());
              }
              else {
                println!("");
              }
        }
        else {
            if subdirs {
                //files_count += scan_dir(dirname.as_path().display().to_string(), debug, verbose, subdirs, crc16, crc32, md5, sha1, sha2, sha3, gost1994, gost2012, hash_size, do_file, outfile2.to_string() );
                files_count += scan_dir(dirname.as_path().display().to_string(), outfile.clone(), debug, verbose, subdirs, crc16, crc32, md5, sha1, sha2, sha3, gost1994, gost2012, hash_size, do_file );
            }
        }
    }
    return files_count;
}



fn main() {
    let mut total_files_count:u64 = 0;
    let mut debug:bool = false; 
    let mut subdirs: bool = false;
    let mut md5: bool = false;
    let mut crc16: bool = false;
    let mut crc32: bool = false;
    let mut sha1: bool = false;
    let mut sha2: bool = false;
    let mut sha3: bool = false;
    let mut gost1994: bool = false;
    let mut gost2012: bool = false;
    let mut verbose: bool = false;
    let mut do_file: bool = false;
    let mut test_mode:bool = false; 
    let mut bad_crc_only:bool = false; 
    let mut hash_size: u32 = 512;
    let mut outfile: String = String::from("").to_string();
    let mut infile: String = String::from("").to_string();
    let mut args_count = 1;
    let prog_args: Vec<String> = env::args().collect();
    let program = prog_args[0].clone();

    println!("TestSum Utility 2021 (c) Dmitry Stefankov [RUST]");

    if prog_args.len() < 2 {
      println!("Usage: testsum.exe [-d] [-v] [-l ] [-f <infile>] [-o outfile] [-s] [-1] [-2] [-3] [-4] [-5] [-7] [-8] [-9] [-t] [-H hashsize] [-V] dirname");
      process::exit(1);
    };

    let mut opts = Options::new();
    opts.optflag("d", "debug", "debug mode (e.g. false)");
    opts.optflag("v", "verbose", "verbose mode (e.g. false)");
    opts.optflag("s", "subdirs", "search subdirs (e.g. false)");
    opts.optflag("1", "crc16", "CRC16 sums (e.g. false)");
    opts.optflag("3", "crc32", "CRC32 sums (e.g. false)");
    opts.optflag("5", "md5", "MD5 sums (e.g. false)");
    opts.optflag("7", "sha1", "SHA1 sums (e.g. false)");
    opts.optflag("9", "gost1994", "GOST R 34.11-1994 sums (e.g. false)");
    opts.optflag("2", "sha2", "SHA2 sums (e.g. false)");
    opts.optflag("4", "sha3", "SHA3 sums (e.g. false)");
    opts.optflag("8", "gost2012", "GOST R 34.11-2012 sums (e.g. false)");
    opts.optflag("t", "test", "test (check) mode (e.g. false)");
    opts.optflag("b", "badcrc", "print only filenames with failed CRC (e.g. false)");
    opts.optopt("f", "infile", "set logging input file name", "NAME");
    opts.optopt("o", "outfile", "set logging output file name", "NAME");
    opts.optopt("H", "hashsize", "set hash size (e.g. 512)", "VALUE");
    opts.optflag("h", "help", "print this help menu");
    opts.optflag("V", "version", "output version information and exit");
    let matches = match opts.parse(&prog_args[1..]) {
        Ok(m) => { m }
        Err(f) => { panic!(f.to_string()) }
    };
  
    if matches.opt_present("h") {
        print_usage(&program, opts);
        return;
    }
  
    if matches.opt_present("help") {
        //^ We could as well have used the short name: "h"
        println!("echo {} - display a line of text", VERSION);
        println!("");
        println!("Usage:");
        println!(" {} [SHORT-OPTION]... [STRING]...", program);
        println!(" {} LONG-OPTION", program);
        println!("");
        //println(getopts::usage("Echo the STRING(s) to standard output.", &opts).as_slice());
        return;
    }

    if matches.opt_present("version") {
        println!("Program version: {}", VERSION);
        return;
    }

    if matches.opt_present("debug") {
      debug = matches.opt_present("d");
      args_count += 1;
    }
    if matches.opt_present("verbose") {
      verbose = matches.opt_present("v");
      args_count += 1;
    }
    if matches.opt_present("test") {
      test_mode = matches.opt_present("t");
      args_count += 1;
    }
    if matches.opt_present("subdirs") {
      subdirs = matches.opt_present("s");
      args_count += 1;
    }
    if matches.opt_present("md5") {
      md5 = matches.opt_present("5");
      args_count += 1;
    }
    if matches.opt_present("crc16") {
      crc16 = matches.opt_present("1");
      args_count += 1;
    }
    if matches.opt_present("crc32") {
      crc32 = matches.opt_present("3");
      args_count += 1;
    }
    if matches.opt_present("sha1") {
      sha1 = matches.opt_present("7");
      args_count += 1;
    }
    if matches.opt_present("sha2") {
      sha2 = matches.opt_present("2");
      args_count += 1;
    }
    if matches.opt_present("sha3") {
      sha3 = matches.opt_present("4");
      args_count += 1;
    }
    if matches.opt_present("gost1994") {
      gost1994 = matches.opt_present("9");
      args_count += 1;
    }
    if matches.opt_present("gost2012") {
      gost2012 = matches.opt_present("8");
      args_count += 1;
    }
    if matches.opt_present("badcrc") {
      bad_crc_only = matches.opt_present("b");
      args_count += 1;
    }

    if debug {println!("infile: {}",infile);};
    if debug {println!("outfile: {}",outfile);};
    if debug {println!("hash_size: {}",hash_size);};

    if matches.opt_present("f") {
        if debug {println!("-f present");};
        let file_opt_str = matches.opt_str("infile").unwrap();
        //if debug {println!("output: {}",file_opt_str);};
        infile = file_opt_str;
        if debug {println!("infile: {}",infile);};
        args_count += 2;
        do_file = true;
    }

    if matches.opt_present("o") {
        if debug {println!("-o present");};
        let file_opt_str = matches.opt_str("outfile").unwrap();
        //if debug {println!("output: {}",file_opt_str);};
        outfile = file_opt_str;
        if debug {println!("outfile: {}",outfile);};
        args_count += 2;
        do_file = true;
    }

    if matches.opt_present("H") {
        if debug {println!("-H present");};
        let hashsize_opt_str = matches.opt_str("hashsize").unwrap();
        //if debug {println!("output: {}",file_opt_str);};
        hash_size = hashsize_opt_str.parse::<u32>().unwrap();
        if debug {println!("hash_size: {}",hash_size);};
        args_count += 2;
    }

    if debug { println!("args_count: {}", args_count); }


    if test_mode {
        if !do_file {
           println!("ERROR: no input file found!");
           process::exit(1);
        }
        if let Ok(lines) = read_lines(infile) {
           // Consumes the iterator, returns an (Optional) String
           for line in lines {
               if let Ok(str) = line {
                   if debug {println!("{}", str);};
                   // Process results here
                   let mysplit = str.split(' ');
                   let mydata = mysplit.clone();
                   for s in mysplit {
                      if debug {println!("word: {}", s);};
                   }
                   let vec: Vec<&str> = mydata.collect();
                   if debug {println!("vec_len: {}", vec.len() );};
                   if vec.len() > 1 {
                     let test_filename = vec[0].replace("\"", "");
                     if debug {println!("filename: {}", test_filename);};
                     let check_str:String = vec[1].to_string();
                     let mut crc16_check:bool = false;
                     let mut crc32_check:bool = false;
                     let mut md5_check:bool = false;
                     let mut sha1_check:bool = false;
                     let mut sha2_check:bool = false;
                     let mut sha3_check:bool = false;
                     let mut gost1994_check:bool = false;
                     let mut gost2012_check:bool = false;
                     let mut test_hash_size:u32 = 0;
                     if check_str.contains("crc16=") { crc16_check = true; }
                     if check_str.contains("crc32=") { crc32_check = true; }
                     if check_str.contains("md5=") { md5_check = true; }
                     if check_str.contains("sha1=") { sha1_check = true; }
                     if check_str.contains("GOST1994=") { gost1994_check = true; }
                     if check_str.contains("sha2(224)=") { sha2_check = true; test_hash_size = 224; }
                     if check_str.contains("sha3(224)=") { sha3_check = true; test_hash_size = 224; }
                     if check_str.contains("sha2(256)=") { sha2_check = true; test_hash_size = 256; }
                     if check_str.contains("sha3(256)=") { sha3_check = true; test_hash_size = 256; }
                     if check_str.contains("sha2(384)=") { sha2_check = true; test_hash_size = 384; }
                     if check_str.contains("sha3(384)=") { sha3_check = true; test_hash_size = 384; }
                     if check_str.contains("sha2(512)=") { sha2_check = true; test_hash_size = 512; }
                     if check_str.contains("sha3(512)=") { sha3_check = true; test_hash_size = 512; }
                     if check_str.contains("GOST2012(256)=") { gost2012_check = true; test_hash_size = 256; }
                     if check_str.contains("GOST2012(512)=") { gost2012_check = true; test_hash_size = 512; }
                     let s1 = vec[1].split('=');
                     let wdata = s1.clone();
                     let vec1: Vec<&str> = wdata.collect();
                     if debug {println!("vec1[0]: {} vec1[1]:{}",vec1[0],vec1[1]);};
                     let sum_str = vec1[1].replace("\"", "");
                     if debug {println!("vec1[1]_new: {}",sum_str);};
                     let test_filename_copy = test_filename.clone();
                     if crc16_check {
                       let crc16_sum:u16 = build_file_crc16(test_filename.to_string(),debug);
                       let test_s = format!("{}",format!("{:#X}", crc16_sum));
                       if debug {println!("test_crc16_sum: {}", test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  crc16=\"OK\"",test_filename_copy.to_string());} } 
                                                                        else { println!("filename=\"{}\"  crc16=\"FAIL\"",test_filename_copy.to_string()); }
                     }
                     if crc32_check {
                       let crc32_sum:u32 = build_file_crc32(test_filename_copy.to_string(),debug);
                       let test_s = format!("{}",format!("{:#X}", crc32_sum));
                       if debug {println!("test_crc32_sum: {}", test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  crc32=\"OK\"",test_filename_copy.to_string());} } 
                                                                        else { println!("filename=\"{}\"  crc32=\"FAIL\"",test_filename_copy.to_string()); }
                     }
                     if md5_check {
                       let md5_sum_str:String = build_file_md5(test_filename_copy.to_string(),debug);
                       let test_s = format!("{}",md5_sum_str);
                       if debug {println!("test_md5_sum: {}", test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       //if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("  md5=\"OK\"");} } else { println!("  md5=\"FAIL\""); }
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  md5=\"OK\"",test_filename_copy.to_string());} } 
                                                                        else { println!("filename=\"{}\"  md5=\"FAIL\"",test_filename_copy.to_string()); }
                     }
                     if sha1_check {
                       let sha1_sum_str:String = build_file_sha1(test_filename_copy.to_string(),debug);
                       let test_s = format!("{}",sha1_sum_str);
                       if debug {println!("test_sha1_sum: {}", test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       //if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("  sha1=\"OK\"");} } else { println!("  sha1=\"FAIL\""); }
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  sha1=\"OK\"",test_filename_copy.to_string());} } 
                                                                        else { println!("filename=\"{}\"  sha1=\"FAIL\"",test_filename_copy.to_string()); }
                     }
                     if gost1994_check {
                       let gost1994_sum_str:String = build_file_gost1994(test_filename_copy.to_string(),debug);
                       let test_s = format!("{}",gost1994_sum_str);
                       if debug {println!("test_gost1994_sum: {}", test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       //if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("  GOST1994=\"OK\"");} } else { println!("  GOST1994=\"FAIL\""); }
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  GOST1994=\"OK\"",test_filename_copy.to_string());} } 
                                                                        else { println!("filename=\"{}\"  GOST1994=\"FAIL\"",test_filename_copy.to_string()); }
                     }
                     if sha2_check {
                       let sha2_sum_str:String = build_file_sha2(test_filename_copy.to_string(),test_hash_size,debug);
                       let test_s = format!("{}",sha2_sum_str);
                       if debug {println!("test_sha2_sum({}): {}", test_hash_size,test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       //if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("  sha2({})=\"OK\"",test_hash_size);} } else { println!("  sha2({})=\"FAIL\"",test_hash_size); }
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  sha2({})=\"OK\"",test_filename_copy.to_string(),test_hash_size);} } 
                                                                        else { println!("filename=\"{}\"  sha2=({})\"FAIL\"",test_filename_copy.to_string(),test_hash_size); }
                     }
                     if sha3_check {
                       let sha3_sum_str:String = build_file_sha3(test_filename_copy.to_string(),test_hash_size,debug);
                       let test_s = format!("{}",sha3_sum_str);
                       if debug {println!("test_sha3_sum({}): {}", test_hash_size,test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       //if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("  sha3({})=\"OK\"",test_hash_size);} } else { println!("  sha3({})=\"FAIL\"",test_hash_size); }
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  sha3({})=\"OK\"",test_filename_copy.to_string(),test_hash_size);} } 
                                                                        else { println!("filename=\"{}\"  sha3=({})\"FAIL\"",test_filename_copy.to_string(),test_hash_size); }
                     }
                     if gost2012_check {
                       let gost2012_sum_str:String = build_file_gost2012(test_filename_copy.to_string(),test_hash_size,debug);
                       let test_s = format!("{}",gost2012_sum_str);
                       if debug {println!("test_gost2012_sum({}): {}", test_hash_size,test_s); }
                       //print!("filename=\"{}\"", test_filename_copy.to_string());
                       //if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("  GOST2012({})=\"OK\"",test_hash_size);} } else { println!("  GOST2012({})=\"FAIL\"",test_hash_size); }
                       if sum_str.to_string().eq(&test_s.to_string()) { if !bad_crc_only {println!("filename=\"{}\"  GOST2012({})=\"OK\"",test_filename_copy.to_string(),test_hash_size);} } 
                                                                        else { println!("filename=\"{}\"  GOST2012=({})\"FAIL\"",test_filename_copy.to_string(),test_hash_size); }
                     }
                   }
               }
           }
        }
        process::exit(0);
    }

    let in_dir = if !matches.free.is_empty() {
        matches.free[0].clone()
    } else {
        print_usage(&program, opts);
        return;
    };

    //let in_dir = &prog_args[args_count];
    if debug { println!("input_dir: {}",in_dir); };

    total_files_count += scan_dir(in_dir.to_string(), outfile.clone(), debug, verbose, subdirs, crc16, crc32, md5, sha1, sha2, sha3, gost1994, gost2012, hash_size, do_file );

    if verbose { println!("Total found items: {}", total_files_count ); }

    process::exit(0);
}
