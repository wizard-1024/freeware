package main

import (
    "fmt"
    getopt "github.com/kesselborn/go-getopt"
    "os"
    "log"
    "bytes"
    "encoding/hex"
    //"io"
    //"strings"
    //"io/ioutil"
    //"encoding/hex"
    //"crypto/md5"
)


var   app_author = "Dmitry Stefankov"
var   app_copyright = "Copyright (c) 2020"
var   app_name = "FINDREP"
var   app_version = "1.0.0"
var   app_purpose = "search & replace patterns for any files"


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
			{"ask|a|ASK", "ask to replace", getopt.Optional | getopt.Flag, false},
			{"infile|i|INFILE", "input filename (default=empty)", getopt.Optional | getopt.ExampleIsDefault, ""},
			{"outfile|o|OUTFILE", "output filename (default=empty)", getopt.Optional | getopt.ExampleIsDefault, ""},
			{"instring|s|INSTRING", "input (search) string  (default=empty)", getopt.Optional | getopt.ExampleIsDefault, ""},
			{"outstring|r|OUTSTRING", "output (replace) string (default=empty)", getopt.Optional | getopt.ExampleIsDefault, ""},
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
        var input_filename = options["infile"].String
        var output_filename = options["outfile"].String
        var input_string = options["instring"].String
        var output_string = options["outstring"].String

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
	  fmt.Printf("instring: %#v\n", options["instring"].String)
	  fmt.Printf("outstring %#v\n", options["outstring"].String)

   	  //fmt.Printf("arguments: %#v\n", arguments)
	  fmt.Printf("passThrough: %#v\n", passThrough)
	  //fmt.Printf("Arg[]: %s\n", arguments[0])
	}

	var fsize int64
        fsize = GetFileSize(input_filename);

        fb := FileExists(input_filename)
        if (!fb) {
          fmt.Println("ERROR: cannot open input file!")
          exit_code := 3
	  os.Exit(exit_code)
        }

        ifile, _ := os.Open(input_filename)
        defer ifile.Close()      

        data := make([]byte, fsize)
        nread, err := ifile.Read(data)
	if err != nil {
          fmt.Println("ERROR: cannot read input file!")
          exit_code := 4
	  os.Exit(exit_code)
	}


        decoded_src, err := hex.DecodeString(input_string)
        decoded_dst, err := hex.DecodeString(output_string)

        //resdata := bytes.ReplaceAll(data, []byte(input_string), []byte(output_string)) 
        resdata := bytes.ReplaceAll(data, decoded_src, decoded_dst) 

        ofile, err3 := os.Create(output_filename)
        check(err3)

        nwrite, err4 := ofile.Write(resdata)
        check(err4)

        ofile.Sync()
        ofile.Close()

        _ = noforce
        _ = debugmode
        _ = arguments
        _ = nread
        _ = nwrite

}

