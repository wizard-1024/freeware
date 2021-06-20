use std::env;
use std::process;
use std::fs::File;
use std::io::Read;
use std::io::Write;
use std::io::Seek;
use std::io::SeekFrom;
fn main()  {
    let debug = true; 
    let prog_args: Vec<String> = env::args().collect();
    println!("File2bin Utility 2021 (c) Dmitry Stefankov [RUST]");
    if prog_args.len() < 5 {
      println!("Usage: file2bin.exe infile outfile ofs len");
      process::exit(1);
    };

    let in_filename = &prog_args[1];
    if debug { println!("input_filename: {}",in_filename); };

    let out_filename = &prog_args[2];
    if debug { println!("output_filename: {}",out_filename); };

    let in_offset = &prog_args[3].parse::<u64>().unwrap();
    if debug { println!("input_offset: {}",in_offset); };

    let out_length = &prog_args[4].parse::<u32>().unwrap();
    if debug { println!("output_length: {}",out_length); };

    if debug { println!("create variable memory buffer: {} bytes",*out_length); };
    let mut filebuf = Vec::new();
    for _i in 0..*out_length {
       filebuf.push(0);
    };

    let mut infile=File::open(in_filename).unwrap();
    if debug { println!("try to file seek"); };
    infile.seek(SeekFrom::Start(*in_offset)).expect("seek failed");
    let bytes_read = infile.read(&mut filebuf).unwrap();
    if debug { println!("bytes_read: {}",bytes_read); };

    if bytes_read != filebuf.len() {
      println!("{} bytes read, but {} expected ...", bytes_read, filebuf.len());
      // handle error or bail out
    }

    let mut outfile = File::create(out_filename).expect("create failed");
    outfile.write_all(&filebuf).expect("write failed");
    if debug { println!("data written to file" ); };
    process::exit(0);
}

