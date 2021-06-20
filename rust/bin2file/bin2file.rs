use std::env;
use std::process;
//use std::io;
use std::fs;
use std::fs::File;
use std::io::Read;
use std::io::Write;
use std::io::Seek;
use std::io::SeekFrom;
use std::fs::OpenOptions;
//use std::os::linux::fs::MetadataExt;
//use std::os::windows::prelude::*;

//fn main()-> io::Result<()>  {
fn main()  {
    let debug = true; 
    let prog_args: Vec<String> = env::args().collect();

    println!("Bin2File Utility 2021 (c) Dmitry Stefankov [RUST]");

    if prog_args.len() < 6 {
      println!("Usage: bin2file.exe infile outfile in_ofs in_len out_ofs out_len");
      process::exit(1);
    };

    let in_filename = &prog_args[1];
    if debug { println!("input_filename: {}",in_filename); };

    let out_filename = &prog_args[2];
    if debug { println!("output_filename: {}",out_filename); };

    let in_offset = &prog_args[3].parse::<u64>().unwrap();
    if debug { println!("input_offset: {}",in_offset); };

    let in_length = &prog_args[4].parse::<u32>().unwrap();
    if debug { println!("output_length: {}",in_length); };

    let out_offset = &prog_args[5].parse::<u64>().unwrap();
    if debug { println!("input_offset: {}",out_offset); };

    let out_length = &prog_args[6].parse::<u32>().unwrap();
    if debug { println!("output_length: {}",out_length); };

    if debug { println!("create variable memory buffer: {} bytes",*in_length); };
    let mut in_filebuf = Vec::new();
    for _i in 0..*in_length {
       in_filebuf.push(0);
    };

    let mut infile=File::open(in_filename).unwrap();
    if debug { println!("try to input file seek"); };
    infile.seek(SeekFrom::Start(*in_offset)).expect("input seek failed");
    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if debug { println!("bytes_read: {}",bytes_read); };

    if bytes_read != in_filebuf.len() {
      println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len());
      // handle error or bail out
    }

    let mut outfile = OpenOptions::new()
       .read(true)
       .write(true)
       .open(out_filename)
       .expect("Unable to open output file");
    if debug { println!("try to output file seek"); };
    outfile.seek(SeekFrom::Start(*out_offset)).expect("output seek failed");

    let metadata = fs::metadata(out_filename).unwrap();
    //let metadata = fs::metadata(out_filename);
    //let creation_time = metadata.creation_time();
    //Ok(());
    //let metadata = fs::metadata(out_filename);
    let _time_accessed = metadata.accessed();
    let _time_modified = metadata.modified();
    let _time_created = metadata.created();
    //let mtime = FileTime::from_last_modification_time(&metadata);
    //println!("{}", mtime);

    let bytes_write = outfile.write(&mut in_filebuf).unwrap();
    if debug { println!("bytes_write: {}",bytes_write); };

    if bytes_write != in_filebuf.len() {
      println!("{} bytes write, but {} expected ...", bytes_write, in_filebuf.len());
      // handle error or bail out
    }
    //outfile.close();
    //outfile.sync();
    //metadata.accessed() = time_accessed;
    //set_file_times("target/testdummy", 1000000, 1000000000).unwrap();
    //std::fs::set_file_times(out_filename, &time_accessed, &time_modified, ).unwrap();

    process::exit(0);
}

