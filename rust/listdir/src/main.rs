extern crate getopts;
extern crate chrono;
use getopts::Options;
use filetime::FileTime;
use chrono::Local;
use chrono::DateTime;

use std::env;
use std::process;
use std::fs;
use std::path::Path;
use std::time::{UNIX_EPOCH, Duration};

static VERSION: &'static str = "1.0.0";


fn print_usage(program: &str, opts: Options) {
    let brief = format!("Usage: {} FILE [options]", program);
    print!("{}", opts.usage(&brief));
}


fn scan_dir(scan_dirname: String, debug: bool, verbose: bool, subdirs: bool, dironly: bool, md5: bool, fullname: bool, fileinfo: bool) -> u64 {
    let mut files_count:u64 = 0;
    if debug { println!("scan_dir: {}",scan_dirname); };
    println!("{}", scan_dirname);
    let paths = fs::read_dir(scan_dirname).unwrap();
    for path in paths {
        let dirname = path.unwrap().path();
        if dirname.is_file() {
            if dironly {
              // do nothing
            }
            else {
              let metadata = fs::metadata(dirname.display().to_string()).unwrap();
              let _time_accessed = metadata.accessed();
              let _time_modified = metadata.modified();
              let _time_created = metadata.created();
              let file_size = metadata.len();
              let file_length = file_size as u64;
              let mtime = FileTime::from_last_modification_time(&metadata);
              let d = UNIX_EPOCH + Duration::from_secs(mtime.unix_seconds() as u64);
              let datetime = DateTime::<Local>::from(d);
              let timestamp_str = datetime.format("%Y-%m-%d %H:%M:%S.%f").to_string();
              files_count += 1;
              if fullname {
                  if fileinfo {
                      print!("datetime=\x22{}\x22 size=\x22{}\x22", timestamp_str, file_length);
                  }
                  println!("  filename=\x22{}\x22", dirname.display());
              }
              else {
                  let ancestors = Path::new(& dirname).file_name().unwrap().to_str().unwrap();
                  if fileinfo {
                      print!("datetime=\"{}\" size=\"{}\"", timestamp_str, file_length);
                  }
                  println!("  filename=\"{}\"", ancestors);
              }
            }
        }
        else {
            if subdirs {
                files_count += scan_dir(dirname.as_path().display().to_string(), debug, verbose, subdirs, dironly, md5, fullname, fileinfo);
            }
        }
    }
    return files_count;
}


fn main() {
    let mut total_files_count:u64 = 0;
    let mut debug:bool = false; 
    let mut subdirs: bool = false;
    let mut fileinfo:bool = false;
    let mut fullname: bool = false;
    let mut md5: bool = false;
    let mut verbose: bool = false;
    let mut dironly: bool = false;
    let mut logfile: String = String::from("").to_string();
    let mut args_count = 1;
    let prog_args: Vec<String> = env::args().collect();
    let program = prog_args[0].clone();

    println!("ListDirs Utility 2021 (c) Dmitry Stefankov [RUST]");

    if prog_args.len() < 2 {
      println!("Usage: listdir.exe [-d] [-v] [-l <logfile>] [-s] [-m] [-f] [-t] [-V] [-r] dirname");
      process::exit(1);
    };

    let mut opts = Options::new();
    opts.optflag("d", "debug", "debug mode (e.g. false)");
    opts.optflag("v", "verbose", "verbose mode (e.g. false)");
    opts.optflag("s", "subdirs", "search subdirs (e.g. false)");
    opts.optflag("m", "md5", "md5 sums (e.g. false)");
    opts.optflag("f", "fullname", "print full name (e.g. false)");
    opts.optflag("t", "fileinfo", "print file info (e.g. false)");
    opts.optflag("r", "dironly", "print dirnames only (e.g. false)");
    opts.optopt("l", "logfile", "set logging output file name", "NAME");
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
        return;
    }

    if matches.opt_present("version") {
        println!("Program version: {}", VERSION);
        return;
    }

    if debug {println!("logfile: {}",logfile);};
    if matches.opt_present("l") {
        if debug {println!("-l present");};
        let file_opt_str = matches.opt_str("logfile").unwrap();
        if debug {println!("output: {}",file_opt_str);};
        logfile = file_opt_str;
        if debug {println!("logfile: {}",logfile);};
        args_count += 2;
    }

    if matches.opt_present("dironly") {
      dironly = matches.opt_present("r");
      args_count += 1;
    }
    if matches.opt_present("debug") {
      debug = matches.opt_present("d");
      args_count += 1;
    }
    if matches.opt_present("verbose") {
      verbose = matches.opt_present("v");
      args_count += 1;
    }
    if matches.opt_present("subdirs") {
      subdirs = matches.opt_present("s");
      args_count += 1;
    }
    if matches.opt_present("md5") {
      md5 = matches.opt_present("m");
      args_count += 1;
    }
    if matches.opt_present("fullname") {
      fullname = matches.opt_present("f");
      args_count += 1;
    }
    if matches.opt_present("fileinfo") {
      fileinfo = matches.opt_present("t");
      args_count += 1;
    }

    println!("args_count: {}", args_count);

    let in_dir = &prog_args[args_count];
    if debug { println!("input_dir: {}",in_dir); };

    total_files_count += scan_dir(in_dir.to_string(), debug, verbose, subdirs, dironly, md5, fullname, fileinfo);

    println!("Total found items: {}", total_files_count );

    process::exit(0);
}
