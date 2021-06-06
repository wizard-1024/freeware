package main

import (
    "fmt"
    getopt "github.com/kesselborn/go-getopt"
    "os"
    "log"
    "io"
    "strings"
    "io/ioutil"
    "encoding/hex"
    "crypto/md5"
)


var   app_author = "Dmitry Stefankov"
var   app_copyright = "Copyright (c) 2020"
var   app_name = "LISTDIR"
var   app_version = "1.0.0"
var   app_purpose = "List directory contents"


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


func IsDirectory(path string) (bool, error) {
    fileInfo, err := os.Stat(path)
    if err != nil{
      return false, err
    }
    return fileInfo.IsDir(), err
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


func hash_file_md5(filePath string) (string, error) {
	var returnMD5String string
	file, err := os.Open(filePath)
	if err != nil {
		return returnMD5String, err
	}
	defer file.Close()
	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		return returnMD5String, err
	}
	hashInBytes := hash.Sum(nil)[:16]
	returnMD5String = hex.EncodeToString(hashInBytes)
	return returnMD5String, nil
}


func ParseDir( dirname string, subdirs bool, print_full_name bool, md5 bool, print_file_info bool, dironly bool ) (int64, int64, int64) {
        var i, j, tsize int64
        i = 0; j = 0; tsize = 0
        files, err := ioutil.ReadDir(dirname+"/")
        if err != nil {
          log.Fatal(err)
          return 0,0,0
        }

        for _, f := range files {
            var fullname string = dirname+"/"+f.Name();
            var b, e = IsDirectory(fullname);
            if (e == nil) {
              var fsize int64
              if (b) { 
                i++; 
                //fmt.Print("Dir:  "); 
                if (print_full_name) {fmt.Println(fullname)} else {fmt.Println(f.Name())}; 
                var i1, j1, ts1 int64
                if (subdirs) { i1,j1,ts1 = ParseDir(fullname,subdirs,print_full_name,md5,print_file_info,dironly); i += i1; j += j1; tsize += ts1 }
              } else { 
                if (!dironly) {
                  j++; fsize = GetFileSize(fullname); tsize += fsize; 
                  if (print_file_info) {
                    fi, _ := os.Stat(fullname)
                    //sf := strings.Split(fi.ModTime().Format("2006-01-02 15.04.05.000"), " ")
                    sf := strings.Split(fi.ModTime().Format("2006-01-02 15:04:05"), " ")
                    dt := strings.Replace(sf[0], "[", "", -1)
                    tt := strings.Replace(sf[1], "[", "", -1)
                    fmt.Printf("datetime=\"%s %s\"", dt,tt );
                    fmt.Printf("  size=\"%d\"",fsize); 
                  }
                  if (md5) { 
                    var hash, herr = hash_file_md5(fullname)
                    if (herr == nil) { fmt.Printf( "  md5=0x%s", hash) }
                  };
                  fmt.Print("  filename=\""); 
                  if (print_full_name) {fmt.Print(fullname)} else {fmt.Print(f.Name())}; 
                  fmt.Print("\""); 
                  fmt.Println(); 
                }
              }
            }
        }
        return i, j, tsize
}


func main() {
	optionDefinition := getopt.Options{
		"description",
		getopt.Definitions{
			{"debug|d|DEBUG", "debug mode", getopt.Optional | getopt.Flag, false},
			{"verbose|v|VERBOSE", "verbose mode", getopt.Optional | getopt.Flag, false},
			{"logfile|l|LOGFILE", "logfile", getopt.Optional | getopt.NoEnvHelp, ""},
			{"subdirs|s|SUBDIRS", "search subdirs", getopt.Optional | getopt.Flag, false},
			{"md5|m|MD5", "md5", getopt.Optional | getopt.Flag, false},
			{"fullname|f|FULLNAME", "print full name", getopt.Optional | getopt.Flag, false},
			{"fileinfo|t|FILEINFO", "print file info", getopt.Optional | getopt.Flag, false},
			{"version|V|VERSION", "display version", getopt.Optional | getopt.Flag, false},
			{"dironly|r|DIRONLY", "print dirnames only", getopt.Optional | getopt.Flag, false},
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
	var subdirs bool = options["subdirs"].Bool
	var fullname bool = options["fullname"].Bool
	var md5 bool = options["md5"].Bool
	var fileinfo bool = options["fileinfo"].Bool
	var dironly bool = options["dironly"].Bool

	arg_len := len(arguments)
	if (arg_len == 0) {
          fmt.Println("ERROR: Argument missing!\n")
          //fmt.Print(optionDefinition.Help())
          exit_code := 0
	  os.Exit(exit_code)
	}

	if (verbose) {
	  fmt.Printf("options:\n")
	  fmt.Printf("debug: %#v\n", options["debug"].Bool)
	  fmt.Printf("verbose: %#v\n", options["verbose"].Bool)
	  fmt.Printf("subdirs: %#v\n", options["subdirs"].Bool)
	  fmt.Printf("logfile: %#v\n", options["logfile"].String)
	  fmt.Printf("dironly: %#v\n", options["dironly"].String)
	  fmt.Printf("fileinfo: %#v\n", options["fileinfo"].String)
	  fmt.Printf("md5: %#v\n", options["md5"].String)
	  fmt.Printf("fullname: %#v\n", options["fullname"].String)

   	  fmt.Printf("arguments: %#v\n", arguments)
	  fmt.Printf("passThrough: %#v\n", passThrough)

	  fmt.Printf("Arg[]: %s\n", arguments[0])
	}

	var thisdir string  = arguments[0]
        fmt.Println(thisdir)

        var dirs, files, full_size = ParseDir(thisdir,subdirs,fullname,md5,fileinfo,dironly)
        fmt.Printf( "Dirs: %d, Files: %d, TotalSize: %d\n", dirs, files, full_size )
}
