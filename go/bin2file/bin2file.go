package main

import (
    "fmt"
    getopt "github.com/kesselborn/go-getopt"
    "os"
    "log"
    //"io"
    //"strings"
    //"io/ioutil"
    //"encoding/hex"
    //"crypto/md5"
)


var   app_author = "Dmitry Stefankov"
var   app_copyright = "Copyright (c) 2020"
var   app_name = "BIN2FILE"
var   app_version = "1.0.0"
var   app_purpose = "Put binary portion into file"


// FileExists reports whether the named file exists as a boolean
func FileExists(name string) bool {
    if fi, err := os.Stat(name); err == nil {
        if fi.Mode().IsRegular() {
            return true
        }
    }
    return false
}


// DirExists reports whether the dir exists as a boolean
func DirExists(name string) bool {
    if fi, err := os.Stat(name); err == nil {
        if fi.Mode().IsDir() {
            return true
        }
    }
    return false
}



func GetFileSize( filename string) (int64) {
  file, err := os.Open( filename ) 
  if err != nil {
    log.Fatal(err)
  }
  fi, err := file.Stat()
  if err != nil {
    log.Fatal(err)
  }
  //fmt.Println( fi.Size() )
  return fi.Size()
}


func check(e error) {
    if e != nil {
        panic(e)
    }
}



func main() {
	optionDefinition := getopt.Options{
		"description",
		getopt.Definitions{
			{"debug|d|DEBUG", "debug mode", getopt.Optional | getopt.Flag, false},
			{"verbose|v|VERBOSE", "verbose mode", getopt.Optional | getopt.Flag, false},
			{"version|V|VERSION", "display version", getopt.Optional | getopt.Flag, false},
			{"restore|t|RESTORE", "restore original file timestamp (default=no)", getopt.Optional | getopt.Flag, false},
			{"noforce|f|NOFORCE", "don't suppress questions", getopt.Optional | getopt.Flag, false},
			{"infile|i|INFILE", "input filename (default=empty)", getopt.Optional | getopt.ExampleIsDefault, ""},
			{"outfile|o|OUTFILE", "output filename (default=empty)", getopt.Optional | getopt.ExampleIsDefault, ""},
			{"ilen|l|ILEN", "VAL byte offset on input stream (default=0)", getopt.Optional | getopt.ExampleIsDefault, 0},
			{"siz|s|SIZ", "copy N bytes from input stream (default=0)", getopt.Optional | getopt.ExampleIsDefault, 0},
			{"olen|p|OLEN", "VAL byte offset on output stream (default=0)", getopt.Optional | getopt.ExampleIsDefault, 0},
			{"pass through", "pass through arguments", getopt.IsPassThrough | getopt.Optional, ""},
		},
	}

	options, arguments, passThrough, e := optionDefinition.ParseCommandLine()

	help, wantsHelp := options["help"]

	if e != nil || wantsHelp {
		exit_code := 0

		switch {
		case wantsHelp && help.String == "usage":
			fmt.Print(optionDefinition.Usage())
		case wantsHelp && help.String == "help":
			fmt.Print(optionDefinition.Help())
		default:
			fmt.Println("**** Error: ", e.Error(), "\n", optionDefinition.Help())
			exit_code = e.ErrorCode
		}
		os.Exit(exit_code)
	}

	var do_version bool = options["version"].Bool
	if (do_version) {
	        fmt.Println(app_name+" "+app_version+": "+app_purpose)
	        fmt.Println(app_copyright+" "+app_author)
		exit_code := 0
		os.Exit(exit_code)
	}

	var verbose bool = options["verbose"].Bool
	var noforce bool = options["noforce"].Bool
	var debugmode bool = options["debug"].Bool
        var i_offset_len int64 = options["ilen"].Int
        var o_offset_len int64 = options["olen"].Int
        var copy_len int64 = options["siz"].Int
        var input_filename = options["infile"].String
        var output_filename = options["outfile"].String
        var restore_ftimes = options["restore"].Bool

	//arg_len := len(arguments)
	//if (arg_len == 0) {
          //fmt.Println("ERROR: Argument missing!\n")
          //fmt.Print(optionDefinition.Help())
          //exit_code := 0
	  //os.Exit(exit_code)
	//}

	if (verbose) {
	  fmt.Printf("options:\n")
	  fmt.Printf("debug: %#v\n", options["debug"].Bool)
	  fmt.Printf("verbose: %#v\n", options["verbose"].Bool)
	  fmt.Printf("noforce: %#v\n", options["noforce"].Bool)
	  fmt.Printf("infile: %#v\n", options["infile"].String)
	  fmt.Printf("outile: %#v\n", options["outfile"].String)
	  fmt.Printf("i_offset_len: %#v\n", options["ilen"].Int)
	  fmt.Printf("o_offset_len: %#v\n", options["olen"].Int)
	  fmt.Printf("copy_len: %#v\n", options["siz"].Int)
	  fmt.Printf("restore_ftimes: %#v\n", options["restore"].Bool)

   	  //fmt.Printf("arguments: %#v\n", arguments)
	  fmt.Printf("passThrough: %#v\n", passThrough)
	  //fmt.Printf("Arg[]: %s\n", arguments[0])
	}

	if (copy_len == 0) {
          fmt.Println("ERROR: Bytes count to transfer not specified!")
          exit_code := 2
	  os.Exit(exit_code)
	}

        fb := FileExists(input_filename)
        if (!fb) {
          fmt.Println("ERROR: cannot open input file!")
          exit_code := 3
	  os.Exit(exit_code)
        }

        ifile, _ := os.Open(input_filename)
        defer ifile.Close()      

        var i_offset int64 = i_offset_len
        var whence int = 0
        newPosition, err1 := ifile.Seek(i_offset, whence)
        if err1 != nil {
          log.Fatal(err1)
        }

        fbuf := make([]byte, copy_len)
        nread, err2 := ifile.Read(fbuf)
        check(err2)


        //if (restore_ftimes) {
          file, s_err := os.Stat(output_filename)
          if s_err != nil {
            fmt.Println(s_err)
          }
          modifiedtime := file.ModTime()
          //atime, mtime, ctime, s_err := statTimes(name)
          // if s_err != nil {
          //   fmt.Println(s_err)
          //   exit_code := 4
	  //   os.Exit(exit_code)
          //}
        //}

        //ofile, err3 := os.Open(output_filename,os.O_RDONLY)
        ofile, err3 := os.OpenFile(output_filename,os.O_RDWR,0644)
        check(err3)

        //if (restore_ftimes) {
        //}

        var o_offset int64 = o_offset_len
        whence = 0
        newPosition2, err5 := ifile.Seek(o_offset, whence)
        if err5 != nil {
          log.Fatal(err5)
        }

        nwrite, err4 := ofile.Write(fbuf)
        check(err4)

        o_offset  = 0
        whence = 2
        newPosition3, err6 := ifile.Seek(o_offset, whence)
        if err6 != nil {
          log.Fatal(err6)
        }

        ofile.Sync()
        ofile.Close()

        if (restore_ftimes) {
           var s1_err = os.Chtimes(output_filename, modifiedtime, modifiedtime)
           if s1_err != nil {
             fmt.Println(s1_err)
           }
        }

        _ = noforce
        _ = debugmode
        _ = arguments
        _ = nread
        _ = nwrite
        _ = newPosition
        _ = newPosition2
        _ = newPosition3
        _ = nread

}

