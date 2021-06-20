/*****************************************************************************
 *                              File bin2data.c
 *
 *                    Convert binary data file to data format file
 *
 *      Copyright (c) Dmitry V. Stefankov, 2006. All rights reserved.
 *
 *****************************************************************************/
/*
 *   $Source: /root/projects/freeware/bin2data/RCS/bin2data.c,v $
 *  $RCSfile: bin2data.c,v $
 *   $Author: dstef $
 *     $Date: 2006-12-06 19:41:16+03 $
 * $Revision: 1.1 $
 *   $Locker: root $
 *
 *      $Log: bin2data.c,v $
 *      Revision 1.1  2006-12-06 19:41:16+03  dstef
 *      Initial revision
 *
 ****************************************************************************/



#if _WIN32
#include <windows.h>
#endif
#ifndef _MSVC
#include  <unistd.h>
#endif
#include  <sys/types.h>
#include  <limits.h>
#include  <stdlib.h>
#include  <stdio.h>
#include  <string.h>
#include  <ctype.h>
#include  <errno.h>
#include  <sys/stat.h>
#if _WIN32
#include  <sys/utime.h>
#endif

#if _WIN32
#include "getopt.h"
#endif


/* Definitions (OS-dependent) */

#if _WIN32

#ifndef snprintf
#define snprintf _snprintf
#endif

#if     _MSC_VER > 1000
#define  open      _open
#define  read      _read
#define  write     _write
#define  close     _close
#define  fileno    _fileno
#define  unlink    _unlink
#define  lseek     _lseek
#define  utime     _utime
#endif

#endif



/* Definitions */
#define  FILENAME_SIZE	    256
#define  DIRNAME_SIZE	    FILENAME_SIZE

#define  KILOBYTES          1024
#define  MEGABYTES          (KILOBYTES*1024)

#define  MAX_BUF_SIZ        (16*KILOBYTES)

#define  DEF_BYTES_PER_LINE  8
#define  MAX_BYTES_PER_LINE  16

#define  LANG_UNKNOWN       0
#define  LANG_C             1
#define  LANG_PAS           2
#define  LANG_ASM           3

#define  ASCII_NONE         0
#define  ASCII_7BIT         7
#define  ASCII_8BIT         8

/* Data structures */


/*------------------------------- GNU C library -----------------------------*/
#if _WIN32
extern int       opterr;
extern int       optind;
extern char     *optarg;
#endif


/* Local data */

extern  int        optind;
extern  int        opterr;
extern  char     * optarg;

const char prog_ver[] = "1.0";
const char rcs_id[] = "$Id: bin2data.c,v 1.1 2006-12-06 19:41:16+03 dstef Exp root $";

  
/*----------------------- Functions ---------------------------------------*/


void usage( void )
{
  fprintf( stderr, "\n" );
  fprintf( stderr, "Convert binary data to data format, version %s\n", prog_ver );
  fprintf( stderr, "Copyright (C) 2006 Dmitry Stefankov. All Rights Reserved.\n" );
  fprintf( stderr, "Usage: file2bin [-vfh] [-i infile] [-o outfile]\n" );  
  fprintf( stderr, "       [-l bytes_per_line] [-a ascii_format]\n" );
  fprintf( stderr, "       -h       this help\n" );   
  fprintf( stderr, "       -v       verbose output (default=no)\n" );
  fprintf( stderr, "       -f       don't suppress questions (default=yes)\n" );  
  fprintf( stderr, "       -l val   number of bytes per line (default=%d)\n", DEF_BYTES_PER_LINE );
  fprintf( stderr, "       -a val   ASCII format for text (7,8,0=default)\n" );
  fprintf( stderr, "\n" );
}

 
/*
 *  Main program stream
 */
int main( int argc, char ** argv )
{
  int                   ret_code = 0;
  int                   verbose = 0;
  char                  op;
  int                   c;
  int                   i;
  int                   count;
  int                   ascii = ASCII_NONE;
  int                   lang = LANG_C;
  int                   bytes_per_line = DEF_BYTES_PER_LINE;
  int                   res;
  unsigned long int     i_fsize = 0;
  int                   force_ask = 0;
  int                   bytes_count;  
  char                * i_fname = NULL;
  char                * o_fname = NULL;
  FILE                * ifp = NULL;
  FILE                * ofp = NULL;
  char                  ascii_buf[64];
  char                  temp_buf[128];
  char                  work_buf[256];
  char                  out_buf[2048];
  
/* Process command line  */  
  opterr = 0;
  while( (op = getopt(argc,argv,"a:fg:i:l:o:vh")) != -1)
    switch(op) {
      case 'a':
               ascii = atoi(optarg);
               break;   
      case 'i':
               i_fname = optarg;
               break;
      case 'o':
               o_fname = optarg;
               break;
      case 'l':
               bytes_per_line = atol(optarg);
               break;
      case 'g':
               lang = atoi(optarg);
               break;         
      case 'f':
               force_ask = 1;
               break;
      case 'v':
               verbose = 1;
      	       break;       
      case 'h':
               usage();
               return(255);
               break;   
      default:
               break;
    }

  
  /* If none filename then use standard streams */
  if (i_fname == NULL) {
     if (verbose) printf( "Open standard input stream.\n" );
     ifp = stdin;
  }
  if (o_fname == NULL) {
     if (verbose) printf( "Open standard output stream.\n" );
     ofp = stdout;
  }

  /* Open input stream */
  if (i_fname != NULL) {
    if (verbose) printf( "Open input stream.\n" );
    ifp = fopen( i_fname, "rb" );
    if (ifp == NULL) {
       fprintf( stderr, "ERROR: cannot open input file!\n" );
       return(2);
    }
  }

  /* Open output stream */
  if (o_fname != NULL) {
    if (verbose) printf( "Create output stream.\n" );
    if (force_ask && (i_fname != NULL)) {
      ofp = fopen( o_fname, "rt" );
      if (ofp == NULL) {
       fprintf( stderr, "ERROR: cannot open output file!\n" );
       return(2);
      }
      fclose( ofp );
      printf( "Overwrite existing output file? (Y/n) " );
      fgets( temp_buf, sizeof(temp_buf), stdin );
      if (tolower(temp_buf[0]) == 'n' ) {
          fprintf( stderr, "Aborted by user.\n" );
          return(3);
      }
    }
    
    ofp = fopen( o_fname, "wt" );
    if (ofp == NULL) {
       fprintf( stderr, "ERROR: cannot create output file!\n" );
       return(4);
    }
  }

  /* Get data count on input stream */
  if (i_fname != NULL) {
    fseek( ifp, 0L, SEEK_END );
    i_fsize = ftell(ifp);
    rewind(ifp);
  }
  
  /* Write first lines to output stream */
  fprintf( ofp, "\n" );
  switch (lang) {
     case LANG_C:
        fprintf( ofp, "/*\n" );
        break;
     case LANG_PAS:
        fprintf( ofp, "{\n" );
        break;
     case LANG_ASM:
        fprintf( ofp, "COMMENT  !\n" );
        break;
     default:
        break;
  };
  if (i_fname != NULL) 
      fprintf( ofp, "  SOURCE FILE:  '%s'\n", i_fname );
  fprintf( ofp, "  Created by bin2data utility, Copyright (C) 2006 Dmitry Stefankov\n" );
  switch (lang) {
     case LANG_C:
        fprintf( ofp, "*/\n" );
        break;
     case LANG_PAS:
        fprintf( ofp, "}\n" );
        break;
     case LANG_ASM:
        fprintf( ofp, "!\n" );
        break;
     default:
        break;
  };
  fprintf( ofp, "\n" );
  fprintf( ofp, "\n" );
  switch (lang) {
     case LANG_C:
        fprintf( ofp, "  unsigned char gdbdataArray[%lu] = {\n", i_fsize );
        break;
     case LANG_PAS:
        fprintf( ofp, "CONST\n" );
        fprintf( ofp, "  gdbdataArray[1..%lu] OF Byte = (\n", i_fsize );
        break;
     case LANG_ASM:
        fprintf( ofp, ".XLIST\n" );
        break;
     default:
        break;
  };
 

  
  while( i_fsize ) {
    if (i_fsize > (unsigned)bytes_per_line) bytes_count = bytes_per_line;
    else bytes_count = i_fsize;

    res = fread( &work_buf, 1, bytes_count, ifp );
    if (res != bytes_count) {
        fprintf( stderr, "ERROR: cannot read %d bytes from input stream!\n", 
                 bytes_count );
        ret_code = 5;
        goto done;
    }

    memset( &out_buf, 0, sizeof(out_buf) );
    memset( &ascii_buf, 0, sizeof(ascii_buf) );
    
    switch( ascii ) {
       case ASCII_7BIT:
          for(i=0; i<bytes_count; i++ ) {
              c = (unsigned char)work_buf[i];
              snprintf( temp_buf, sizeof(temp_buf), "%c", c );
              if (isascii(c) && !iscntrl(c)) strcat( ascii_buf, temp_buf );
              else strcat( ascii_buf, "." );
          }
          if (bytes_count < bytes_per_line) {
              count = (bytes_per_line - bytes_count);
              for( i=0; i<count; i++ ) strcat( ascii_buf, " " );
          }
          break;
       case ASCII_8BIT:
          for(i=0; i<bytes_count; i++ ) {
              c = (unsigned char)work_buf[i];
              snprintf( temp_buf, sizeof(temp_buf), "%c", c );
              if (!iscntrl(c)) strcat( ascii_buf, temp_buf );
              else strcat( ascii_buf, "." );
          }
          if (bytes_count < bytes_per_line) {
              count = (bytes_per_line - bytes_count);
              for( i=0; i<count; i++ ) strcat( ascii_buf, " " );
          }
          break;
       default:
          break;
    }
    
    switch( lang ) {
       case LANG_C:
          fprintf( ofp, "\t" );
          for( i=0; i<bytes_count; i++ ) {
              fprintf( ofp, "0x%02X", (unsigned char)work_buf[i] );
              if (i < (bytes_count-1)) fprintf( ofp, ", " );
          }
          if (bytes_count < bytes_per_line) {
             count = (bytes_per_line - bytes_count);
             count *= 6;
             memset( temp_buf, 0, sizeof(temp_buf) );
             memset( temp_buf, ' ', count );
             fprintf( ofp, temp_buf );
          }
          if (ascii != ASCII_NONE) {
             fprintf( ofp, "     /* %s */", ascii_buf );
          }
          fprintf( ofp, "\n" );
          break;
       case LANG_PAS:
          fprintf( ofp, "\t" );
          for( i=0; i<bytes_count; i++ ) {
              fprintf( ofp, "$%02X", (unsigned char)work_buf[i] );
              if (i < (bytes_count-1)) fprintf( ofp, ", " );
          }
          if (bytes_count < bytes_per_line) {
             count = (bytes_per_line - bytes_count);
             count *= 5;
             memset( temp_buf, 0, sizeof(temp_buf) );
             memset( temp_buf, ' ', count );
             fprintf( ofp, temp_buf );
          }
          if (ascii != ASCII_NONE) {
             fprintf( ofp, "     { %s }", ascii_buf );
          }
          fprintf( ofp, "\n" );
          break;
       case LANG_ASM:          
          fprintf( ofp, "\tDB " );
          for( i=0; i<bytes_count; i++ ) {
              fprintf( ofp, "0%02Xh", (unsigned char)work_buf[i] );
              if (i < (bytes_count-1)) fprintf( ofp, ", " );
          }
          if (bytes_count < bytes_per_line) {
             count = (bytes_per_line - bytes_count);
             count *= 6;
             memset( temp_buf, 0, sizeof(temp_buf) );
             memset( temp_buf, ' ', count );
             fprintf( ofp, temp_buf );
          }
          if (ascii != ASCII_NONE) {
             fprintf( ofp, "     ; %s", ascii_buf );
          }
          fprintf( ofp, "\n" );
          break;
       default:
          break;
    }
    
    i_fsize -= bytes_count;
  } /*while*/
  
  ret_code = 0;
  

  /* Write last lines to output stream */
  //fprintf( ofp, "\n" );
  switch (lang) {
     case LANG_C:
        fprintf( ofp, "\t  };\n" );
        break;
     case LANG_PAS:
        fprintf( ofp, "\t  );\n" );
        break;
     case LANG_ASM:
        fprintf( ofp, ".LIST\n" );
        break;
     default:
        break;
  };
    
done:
  if (verbose) printf( "Close streams.\n" );
  if (ifp != NULL) fclose( ifp );
  if (ofp != NULL) fclose( ofp );  

  return(ret_code);
}
