use std::env;
use std::process;
//use std::io;
//use std::fs;
use std::fs::File;
use std::io::Read;
use std::io::Write;
//use std::io::Seek;
//use std::io::SeekFrom;
//use std::fs::OpenOptions;
//use std::os::linux::fs::MetadataExt;
//use std::os::windows::prelude::*;
//use std::convert::TryFrom;
//use std::mem;


fn replace<T>(source: &[T], from: &[T], to: &[T]) -> Vec<T>
where
    T: Clone + PartialEq
{
    let mut result = source.to_vec();
    let from_len = from.len();
    let to_len = to.len();

    let mut i = 0;
    while i + from_len <= result.len() {
        if result[i..].starts_with(from) {
            result.splice(i..i + from_len, to.iter().cloned());
            i += to_len;
        } else {
            i += 1;
        }
    }

    result
}


//fn main()-> io::Result<()>  {
fn main()  {
    let debug = true; 
    let prog_args: Vec<String> = env::args().collect();

    println!("FindReplace Utility 2021 (c) Dmitry Stefankov [RUST]");

    if prog_args.len() < 6 {
      println!("Usage: findrep.exe infile outfile in_pat out_pat askme");
      process::exit(1);
    };

    let in_filename = &prog_args[1];
    if debug { println!("input_filename: {}",in_filename); };

    let out_filename = &prog_args[2];
    if debug { println!("output_filename: {}",out_filename); };

    let in_pattern = &prog_args[3];
    if debug { println!("input_pattern: {}",in_pattern); };

    let out_pattern = &prog_args[4];
    if debug { println!("out_pattern: {}",out_pattern); };

    //let metadata = fs::metadata(in_filename).unwrap();
    //let in_length = fs::metadata(in_filename).len();
    //in_length = metadata.len();
    //let in_length = my_file.metadata().unwrap().len();

    let mut infile=File::open(in_filename).unwrap();

    if debug { println!("try to read input file"); };

    let in_file_size = infile.metadata().unwrap().len();
    //let in_legth =  in_file_size.<u64>..unwrap();
    let in_length = in_file_size as u64;

    //if debug { println!("create variable memory buffer: {} bytes",*in_length); };
    if debug { println!("create variable memory buffer: {} bytes",in_length); };
    let mut in_filebuf = Vec::new();
    for _i in 0..in_length {
       in_filebuf.push(0);
    };

    let bytes_read = infile.read(&mut in_filebuf).unwrap();
    if debug { println!("bytes_read: {}",bytes_read); };

    if bytes_read != in_filebuf.len() {
      println!("{} bytes read, but {} expected ...", bytes_read, in_filebuf.len());
      // handle error or bail out
    }

    let in_buf_str  = in_pattern.as_bytes();
    let out_buf_str = out_pattern.as_bytes();

    //let old_v = mem::replace(&mut in_buf, );

    let out_filebuf = replace(&mut in_filebuf[..], &in_buf_str, &out_buf_str);

    let mut outfile = File::create(out_filename).expect("create failed");
    outfile.write_all(&out_filebuf).expect("write failed");
    if debug { println!("data written to file" ); };

    process::exit(0);
}

