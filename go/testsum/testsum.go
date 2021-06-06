package main

import (
    "fmt"
    "os"
    "log"
    "io"
    "bufio"
    "strings"
    "io/ioutil"
    "encoding/hex"
    //"hash"
    "hash/crc32"
    "crypto/md5"
    "crypto/sha1"
    "crypto/sha256"
    "crypto/sha512"
    //"crypto/rand"
    "github.com/kesselborn/go-getopt"
    "github.com/snksoft/crc"
    //"golang.org/x/crypto/sha3"
    //"go.cypherpunks.ru/gogost/v4/gost3410"
    //"go.cypherpunks.ru/gogost/v4/gost34112012256"
    //"go.cypherpunks.ru/gogost/gost3410"
    //"go.cypherpunks.ru/gogost/gost34112012256"
    //"go.cypherpunks.ru/gogost/gost34112012512"
    //"go.cypherpunks.ru/gogost/gost3413"
    //"go.cypherpunks.ru/gogost/gost28147"
)


var   app_author = "Dmitry Stefankov"
var   app_copyright = "Copyright (c) 2020"
var   app_name = "TESTSUM"
var   app_version = "1.0.0"
var   app_purpose = "test file(s) integrity using hash sums"


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



func hash_file_crc32(filePath string, polynomial uint32) (string, error) {
	var returnCRC32String string
	file, err := os.Open(filePath)
	if err != nil {
		return returnCRC32String, err
	}
	defer file.Close()
	tablePolynomial := crc32.MakeTable(polynomial)
	hash := crc32.New(tablePolynomial)
	if _, err := io.Copy(hash, file); err != nil {
		return returnCRC32String, err
	}
	hashInBytes := hash.Sum(nil)[:]
	returnCRC32String = hex.EncodeToString(hashInBytes)
	return returnCRC32String, nil

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


func hash_file_sha1(filePath string) (string, error) {
	var returnSHA1String string
	file, err := os.Open(filePath)
	if err != nil {
		return returnSHA1String, err
	}
	defer file.Close()
	hash := sha1.New()
	if _, err := io.Copy(hash, file); err != nil {
		return returnSHA1String, err
	}
	hashInBytes := hash.Sum(nil)[:20]
	returnSHA1String = hex.EncodeToString(hashInBytes)
	return returnSHA1String, nil

}


func hash_file_sha2(filePath string) (string, error) {
	var returnSHA2String string
	file, err := os.Open(filePath)
	if err != nil {
		return returnSHA2String, err
	}
	defer file.Close()
	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return returnSHA2String, err
	}
	hashInBytes := hash.Sum(nil)[:32]
	returnSHA2String = hex.EncodeToString(hashInBytes)
	return returnSHA2String, nil

}



func hash_file_sha512(filePath string, ) (string, error) {
	var returnSHA3String string
	var fsize int64
        fsize = GetFileSize(filePath);
	file, err := os.Open(filePath)
	if err != nil {
		return returnSHA3String, err
	}
	defer file.Close()
        data := make([]byte, fsize)
        n, err := file.Read(data)
	if err != nil {
		return returnSHA3String, err
	}
        sha512Bytes := sha512.Sum512(data)
	returnSHA3String = hex.EncodeToString(sha512Bytes[:])
	_ = n
	return returnSHA3String, nil

}


func hash_file_sha512_224(filePath string, ) (string, error) {
	var returnSHA3String string
	var fsize int64
        fsize = GetFileSize(filePath);
	file, err := os.Open(filePath)
	if err != nil {
		return returnSHA3String, err
	}
	defer file.Close()
        data := make([]byte, fsize)
        n, err := file.Read(data)
	if err != nil {
		return returnSHA3String, err
	}
        sha512Bytes := sha512.Sum512_224(data)
	returnSHA3String = hex.EncodeToString(sha512Bytes[:])
	_ = n
	return returnSHA3String, nil
}


func hash_file_sha512_384(filePath string, ) (string, error) {
	var returnSHA3String string
	var fsize int64
        fsize = GetFileSize(filePath);
	file, err := os.Open(filePath)
	if err != nil {
		return returnSHA3String, err
	}
	defer file.Close()
        data := make([]byte, fsize)
        n, err := file.Read(data)
	if err != nil {
		return returnSHA3String, err
	}
        sha512Bytes := sha512.Sum384(data)
	returnSHA3String = hex.EncodeToString(sha512Bytes[:])
	_ = n
	return returnSHA3String, nil
}


func hash_file_crc16(filePath string, ) (string, error) {
	var returnSHA3String string
	var fsize int64
        fsize = GetFileSize(filePath);
	file, err := os.Open(filePath)
	if err != nil {
		return returnSHA3String, err
	}
	defer file.Close()
        data := make([]byte, fsize)
        n, err := file.Read(data)
	if err != nil {
		return returnSHA3String, err
	}
        ccittCrc := crc.CalculateCRC(crc.CCITT, []byte(data))
        returnSHA3String = fmt.Sprintf("%X", ccittCrc)
	_ = n
	return returnSHA3String, nil
}


func ParseDir( dirname string, subdirs bool, print_full_name bool, md5 bool, print_file_info bool, dironly bool,
               crc16 bool, crc32 bool, sha1 bool, sha2 bool, sha3 bool, hsiz int64 ) (int64, int64, int64) {
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
                if (subdirs) { i1,j1,ts1 = ParseDir(fullname,subdirs,print_full_name,md5,print_file_info,dironly,crc16,crc32,sha1,sha2,sha3,hsiz); i += i1; j += j1; tsize += ts1 }
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
                  if (crc16) {
                    var hash, herr = hash_file_crc16(fullname)
                    if (herr == nil) { fmt.Printf( "  crc16=0x%s", hash) }
                  }
                  if (crc32) {
                    var hash, herr = hash_file_crc32(fullname, 0xedb88320)
                    if (herr == nil) { fmt.Printf( "  crc32=0x%s", hash) }
                  }
                  if (md5) { 
                    var hash, herr = hash_file_md5(fullname)
                    if (herr == nil) { fmt.Printf( "  md5=0x%s", hash) }
                  };
                  if (sha1) { 
                    var hash, herr = hash_file_sha1(fullname)
                    if (herr == nil) { fmt.Printf( "  sha1=0x%s", hash) }
                  };
                  if (sha2) { 
                    var hash, herr = hash_file_sha2(fullname)
                    if (herr == nil) { fmt.Printf( "  sha2=0x%s", hash) }
                  };
                  if (sha3 && hsiz == 224) { 
                    var hash, herr = hash_file_sha512_224(fullname)
                    if (herr == nil) { fmt.Printf( "  sha512_224=0x%s", hash) }
                  };
                  if (sha3 && hsiz == 384) { 
                    var hash, herr = hash_file_sha512_384(fullname)
                    if (herr == nil) { fmt.Printf( "  sha512_384=0x%s", hash) }
                  };
                  if (sha3 && (hsiz == 0) || (hsiz == 512)) { 
                    var hash, herr = hash_file_sha512(fullname)
                    if (herr == nil) { fmt.Printf( "  sha512=0x%s", hash) }
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



func check(e error) {
    if e != nil {
        panic(e)
    }
}


// readLines reads a whole file into memory
// and returns a slice of its lines.
func readLines(path string) ([]string, error) {
    file, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer file.Close()

    var lines []string
    scanner := bufio.NewScanner(file)
    for scanner.Scan() {
        lines = append(lines, scanner.Text())
    }
    return lines, scanner.Err()
}


// writeLines writes the lines to the given file.
func writeLines(lines []string, path string) error {
    file, err := os.Create(path)
    if err != nil {
        return err
    }
    defer file.Close()

    w := bufio.NewWriter(file)
    for _, line := range lines {
        fmt.Fprintln(w, line)
    }
    return w.Flush()
}


func between(value string, a string, b string) string {
    // Get substring between two strings.
    posFirst := strings.Index(value, a)
    if posFirst == -1 {
        return ""
    }
    posLast := strings.Index(value, b)
    if posLast == -1 {
        return ""
    }
    posFirstAdjusted := posFirst + len(a)
    if posFirstAdjusted >= posLast {
        return ""
    }
    return value[posFirstAdjusted:posLast]
}

func before(value string, a string) string {
    // Get substring before a string.
    pos := strings.Index(value, a)
    if pos == -1 {
        return ""
    }
    return value[0:pos]
}

func after(value string, a string) string {
    // Get substring after a string.
    pos := strings.LastIndex(value, a)
    if pos == -1 {
        return ""
    }
    adjustedPos := pos + len(a)
    if adjustedPos >= len(value) {
        return ""
    }
    return value[adjustedPos:len(value)]
}


func  GetValueByKeyword( line string, pattern string ) (string) {
    var  value string = ""
    i := strings.Index(line, pattern)
    if (i > 0) {
      fmt.Println(i);
    }
    return value
}


func  parse_log_file( filename string ) (bool) {
   var result bool = false
   //var file_len int64

   fb := FileExists(filename)
   if (!fb) {
       fmt.Println("ERROR: cannot open input file!")
       //exit_code := 3
       //os.Exit()
       return result
   }

   //ifile, _ := os.Open(filename)
   //defer ifile.Close()      

   //fbuf := make([]byte, file_len)
   //nread, err2 := ifile.Read(fbuf)
   //check(err2)

   lines, err := readLines(filename)
   if err != nil {
        log.Fatalf("readLines: %s", err)
   }
   for i, line := range lines {
        //fmt.Println(i, line)
        var find_ok = strings.Contains(line, "filename=")
        if (find_ok) {
          var fs string
          _ = i
          //fmt.Println(i, line)
          //fs = GetValueByKeyword( line, "filename=" ) 
          //_ = fs
          //fmt.Println(between(line, "filename", ""))
          //fmt.Println(after(line, "filename="))
          //fmt.Println(before(line, "filename"))
          fs = strings.Trim(after(line, "filename="), "\"\n")
          //fmt.Println(fs)
          //crc16 = strings.Trim(after(line, "crc16="), "\" ")
          //_ = crc16
          //crc16 = strings.Trim(after(line, "crc16="), "\" ")
          //fmt.Println(crc16)
          //fmt.Printf("filename=\"%s\"", fs )
          fb := FileExists(filename)
          if (!fb) {  fmt.Println("ERROR: cannot open input file!") 
          } else {
              //var crc16_test, crc16_ok bool
              var pos int
              fmt.Printf("filename=\"%s\"", fs )
              pos = strings.Index(line, "crc16=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_crc16(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("crc16=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" crc16=\"OK\"") 
                     } else { fmt.Printf(" crc16=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "crc32=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_crc32(fs, 0xedb88320)
                   if (herr == nil) { crc_res=fmt.Sprintf("crc32=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" crc32=\"OK\"") 
                     } else { fmt.Printf(" crc32=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "md5=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_md5(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("md5=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" md5=\"OK\"") 
                     } else { fmt.Printf(" md5=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "sha1=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_sha1(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("sha1=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" sha1=\"OK\"") 
                     } else { fmt.Printf(" sha1=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "sha2=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_sha2(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("sha2=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" sha2=\"OK\"") 
                     } else { fmt.Printf(" sha2=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "sha512=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_sha512(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("sha512=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" sha512=\"OK\"") 
                     } else { fmt.Printf(" sha512=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "sha512_224=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_sha512_224(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("sha512_224=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" sha512_224=\"OK\"") 
                     } else { fmt.Printf(" sha512=\"FAIL\"")  }
                   }
              }
              pos = strings.Index(line, "sha512_384=")
              if (pos > 0) {
                   var crc_res string 
                   crc_res = ""
                   var hash, herr = hash_file_sha512_384(fs)
                   if (herr == nil) { crc_res=fmt.Sprintf("sha512_384=0x%s", hash) }
                   if (len(crc_res) > 0) {
                     //fmt.Printf("crc_res: %s\n", crc_res )
                     crc_pos :=  strings.Index(line,crc_res)
                     if (crc_pos > 0) { fmt.Printf(" sha512_384=\"OK\"") 
                     } else { fmt.Printf(" sha512_384=\"FAIL\"")  }
                   }
              }
          }
          fmt.Printf("\n")
        }
   }

   return result
}


/*
func gost_test_me() (bool) {
    data := []byte("data to be signed")
    hasher := gost34112012256.New()
    _, err := hasher.Write(data)
    _ = err
    dgst := hasher.Sum(nil)
    curve := gost3410.CurveIdtc26gost34102012256paramSetB()
    prvRaw := make([]byte, int(gost3410.Mode2001))
    _, err = io.ReadFull(rand.Reader, prvRaw)
    prv, err := gost3410.NewPrivateKey(curve, gost3410.Mode2001, prvRaw)
    pub, err := prv.PublicKey()
    pubRaw := pub.Raw()
    sign, err := prv.Sign(rand.Reader, dgst, nil)
    pub, err = gost3410.NewPublicKey(curve, gost3410.Mode2001, pubRaw)
    isValid, err := pub.VerifyDigest(dgst, sign)
    if !isValid { panic("signature is invalid") }
    return true
}
*/

func main() {
	optionDefinition := getopt.Options{
		"description",
		getopt.Definitions{
			{"debug|d|DEBUG", "debug mode", getopt.Optional | getopt.Flag, false},
			{"verbose|v|VERBOSE", "verbose mode", getopt.Optional | getopt.Flag, false},
			{"logfile|l|LOGFILE", "logfile", getopt.Optional | getopt.NoEnvHelp, ""},
			{"subdirs|s|SUBDIRS", "search subdirs", getopt.Optional | getopt.Flag, false},
			{"crc16|a|CRC16", "crc16", getopt.Optional | getopt.Flag, false},
			{"crc32|b|CRC32", "crc32", getopt.Optional | getopt.Flag, false},
			{"md5|m|MD5", "md5", getopt.Optional | getopt.Flag, false},
			{"sha1|A|SHA1", "sha1", getopt.Optional | getopt.Flag, false},
			{"sha2|B|SHA2", "sha2", getopt.Optional | getopt.Flag, false},
			{"sha3|C|SHA3", "sha3", getopt.Optional | getopt.Flag, false},
			{"hsiz|e|HSIZ", "hash size (default=0)", getopt.Optional | getopt.ExampleIsDefault, 0},
			{"fullname|f|FULLNAME", "print full name", getopt.Optional | getopt.Flag, false},
			{"fileinfo|t|FILEINFO", "print file info", getopt.Optional | getopt.Flag, false},
			{"version|V|VERSION", "display version", getopt.Optional | getopt.Flag, false},
			{"dironly|r|DIRONLY", "print dirnames only", getopt.Optional | getopt.Flag, false},
			{"test|T|TEST", "Test (check) CRC sum for each file(s) listed in logfile", getopt.Optional | getopt.Flag, false},
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
	var crc16 bool = options["crc16"].Bool
	var crc32 bool = options["crc32"].Bool
	var md5 bool = options["md5"].Bool
	var sha1 bool = options["sha1"].Bool
	var sha2 bool = options["sha2"].Bool
	var sha3 bool = options["sha3"].Bool
	var hsiz int64 = options["hsiz"].Int
	var fileinfo bool = options["fileinfo"].Bool
	var dironly bool = options["dironly"].Bool
	var testmode bool = options["test"].Bool
	var logfile string = options["logfile"].String

	if (verbose) { fmt.Printf("logfile: %#v\n", options["logfile"].String) }

//        var ok bool = gost_test_me()
//        if (ok) { fmt.Printf( "gost ok\n" ) }

	arg_len := len(arguments)
	if ((arg_len == 0) && (!testmode)) {
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
	  fmt.Printf("crc16: %#v\n", options["crc16"].Bool)
	  fmt.Printf("crc32: %#v\n", options["crc32"].Bool)
	  fmt.Printf("md5: %#v\n", options["md5"].Bool)
	  fmt.Printf("sha1: %#v\n", options["sha1"].Bool)
	  fmt.Printf("sha2: %#v\n", options["sha2"].Bool)
	  fmt.Printf("sha3: %#v\n", options["sha3"].Bool)
	  fmt.Printf("hsiz: %#v\n", options["hsiz"].Int)
	  //fmt.Printf("fullname: %#v\n", options["fullname"].String)
          fmt.Printf("fullname: %#v\n", options["fullname"].Bool)
	  fmt.Printf("test: %#v\n", options["test"].Bool)
	  fmt.Printf("passThrough: %#v\n", passThrough)
	  if (!testmode) { 
             fmt.Printf("arguments: %#v\n", arguments)
	     fmt.Printf("Arg[]: %s\n", arguments[0])
	  }
	}


        if (testmode) { 
           var result_ok bool = parse_log_file(logfile)
           if (verbose) { fmt.Printf("parse_log_file: result=%t\n",result_ok) }
        } else {
	  var thisdir string  = arguments[0]
          fmt.Println(thisdir)
          var dirs, files, full_size = ParseDir(thisdir,subdirs,fullname,md5,fileinfo,dironly,crc16,crc32,sha1,sha2,sha3,hsiz)
          fmt.Printf( "Dirs: %d, Files: %d, TotalSize: %d\n", dirs, files, full_size )
        }
}
