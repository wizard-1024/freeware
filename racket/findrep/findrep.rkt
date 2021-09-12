#lang racket

;;
;; Search and replace pattern per file
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

;; parameter Search-Pattern is one of:
;; - #false
;; - String
(define search-pattern (make-parameter #false))

;; parameter Replace-Pattern is one of:
;; - #false
;; - String
(define replace-pattern (make-parameter #false))

;; command line parser
(define parser
  (command-line
   #:usage-help
   "Search and replace pattern per file, version 1.0"
   "Copyright (c) 2021, Dmitry Stefankov"
   "Usage: findrep -i infile -o outfile -l offset -s size"

   #:once-each
   [("-i" "--infile") INFILE
                     "Set input file"
                     (in-file INFILE)]
   [("-o" "--outfile") OUTFILE
                     "Set output file"
                     (out-file OUTFILE)]
   [("-s" "--spat") SEARCHPATTERN
                     "Set search pattern"
                     (search-pattern SEARCHPATTERN)]
   [("-r" "--rpat") REPLACEPATTERN
                     "Set replace pattern"
                     (replace-pattern REPLACEPATTERN)]

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

;; get-search-pattern : Search-Pattern -> String
;; Gets the value for the given Search-Pattern
(define (get-search-pattern srchpat)
  (cond
    [(boolean? srchpat) "No search pattern found!"]
    [(string? srchpat) (string-append "" srchpat)]))

;; get-replace-pattern : Replace-Pattern -> String
;; Gets the value for the given Replace-Pattern
(define (get-replace-pattern replpat)
  (cond
    [(boolean? replpat) "No replace pattern found!"]
    [(string? replpat) (string-append "" replpat)]))


;; prints result to the command line
(printf "~a\n" (string-append "InputFile: " (get-input-filename (in-file))))
(printf "~a\n" (string-append "OutputFile: " (get-output-filename (out-file))))
(printf "~a\n" (string-append "SearchPattern: " (get-search-pattern (search-pattern))))
(printf "~a\n" (string-append "ReplacePattern: " (get-replace-pattern (replace-pattern))))

(define infilename (get-input-filename (in-file)))
;;(displayln infilename)
(define outfilename (get-output-filename (out-file)))
;;(displayln outfilename)
(define inpattern (get-search-pattern (search-pattern)))
;;(displayln inpattern)
(define outpattern (get-replace-pattern (replace-pattern)))
;;(displayln outpattern)

;;(define in (open-input-file infilename #:mode 'binary))
;;(file-position in inoffset) 
;;(define raw-data (read-bytes insize in))
;;(close-input-port in)

;;(define out (open-output-file outfilename #:mode 'binary #:exists 'replace))
;;(write raw-data out)
;;(write-bytes raw-data out)
;;(close-output-port out)

(define in_str (file->string infilename))
;;(displayln in_str)
(define out_str (string-replace in_str inpattern outpattern))
;;(displayln out_str)

(with-output-to-file outfilename #:exists 'replace
  (lambda () (display out_str)))
;;  (lambda () (display "characters")))
