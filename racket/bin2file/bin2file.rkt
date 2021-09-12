#lang racket

;;
;; Copy binary portion of file to another file
;; Copyright (c) 2021 Dmitry Stefankov
;;

;; parameter In-File is one of:
;; - #false
;; - String
(define in-file (make-parameter #false))

;; parameter Out-File is one of:
;; - #false
;; - String
(define out-file (make-parameter #false))

;; parameter In-File-Offset is one of:
;; - #false
;; - String
(define in-file-offset (make-parameter #false))

;; parameter In-File-Size is one of:
;; - #false
;; - String
(define in-file-size (make-parameter #false))

;; parameter Out-File-Offset is one of:
;; - #false
;; - String
(define out-file-offset (make-parameter #false))


;; command line parser
(define parser
  (command-line
   #:usage-help
   "Put binary portion from file, version 1.0"
   "Copyright (c) 2021, Dmitry Stefankov"
   "Usage: file2bin -i infile -o outfile -l in_offset -s in_size -p out_offset"

   #:once-each
   [("-i" "--infile") INFILE
                     "Set input file"
                     (in-file INFILE)]
   [("-o" "--outfile") OUTFILE
                     "Set output file"
                     (out-file OUTFILE)]
   [("-l" "--offset") OFFSETVALUE
                     "Set input file offset"
                     (in-file-offset OFFSETVALUE)]
   [("-s" "--size") SIZEVALUE
                     "Set input file size"
                     (in-file-size SIZEVALUE)]
   [("-p" "--offset") OFFSETVALUE
                     "set output file offset"
                     (out-file-offset OFFSETVALUE)]

   #:args () (void)))

;; get-input-file : In-File -> String
;; Gets the value for the given In-File
(define (get-input-filename infile)
  (cond
    [(boolean? infile) "No input filename found!"]
    [(string? infile) (string-append "" infile)]))

;; get-output-file : Out-File -> String
;; Gets the value for the given Out-File
(define (get-output-filename outfile)
  (cond
    [(boolean? outfile) "No output filename found!"]
    [(string? outfile) (string-append "" outfile)]))

;; get-input-file-offset : In-File-Offset -> String
;; Gets the value for the given In-File-Offset
(define (get-input-file-offset infileoffset)
  (cond
    [(boolean? infileoffset) "No input file offset found!"]
    [(string? infileoffset) (string-append "" infileoffset)]))

;; get-input-file-size : In-File-Size -> String
;; Gets the value for the given In-File-Size
(define (get-input-file-size infilesize)
  (cond
    [(boolean? infilesize) "No input file size found!"]
    [(string? infilesize) (string-append "" infilesize)]))

;; get-output-file-offset : Out-File-Offset -> String
;; Gets the value for the given In-File-Offset
(define (get-output-file-offset outfileoffset)
  (cond
    [(boolean? outfileoffset) "No output file offset found!"]
    [(string? outfileoffset) (string-append "" outfileoffset)]))

;; prints result to the command line
(printf "~a\n" (string-append "InputFile: " (get-input-filename (in-file))))
(printf "~a\n" (string-append "OutputFile: " (get-output-filename (out-file))))
(printf "~a\n" (string-append "InputFileOffset: " (get-input-file-offset (in-file-offset))))
(printf "~a\n" (string-append "InputFileSize: " (get-input-file-size (in-file-size))))
(printf "~a\n" (string-append "OutputFileOffset: " (get-output-file-offset (out-file-offset))))

(define infilename (get-input-filename (in-file)))
;;(displayln infilename)
(define outfilename (get-output-filename (out-file)))
;;(displayln outfilename)
(define inoffset (string->number (get-input-file-offset (in-file-offset))))
;;(displayln inoffset)
(define insize (string->number (get-input-file-size (in-file-size))))
;;(displayln insize)
(define outoffset (string->number (get-output-file-offset (out-file-offset))))
;;(displayln outffset)

(define in (open-input-file infilename #:mode 'binary))
;;(define raw-data (read in))
(file-position in inoffset) 
(define raw-data (read-bytes insize in))
(close-input-port in)

(define out (open-output-file outfilename #:mode 'binary #:exists 'update))
;;(write raw-data out)
(file-position out outoffset) 
(write-bytes raw-data out)
(close-output-port out)
