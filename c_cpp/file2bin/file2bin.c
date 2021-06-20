/*****************************************************************************
 *                              File file2bin.c
 *
 *                    Extract binary portion from file to file
 *
 *      Copyright (c) Dmitry V. Stefankov, 2006. All rights reserved.
 *
 *****************************************************************************/
/*
 *   $Source: /usr/local/src/projects/freeware/file2bin/RCS/file2bin.c,v $
 *  $RCSfile: file2bin.c,v $
 *   $Author: dstef $
 *     $Date: 2014-02-16 19:22:46+04 $
 * $Revision: 1.2 $
 *   $Locker: root $
 *
 *      $Log: file2bin.c,v $
 *      Revision 1.2  2014-02-16 19:22:46+04  dstef
 *      Changed atol to strtoul
 *      Minor changes
 *
 *      Revision 1.1  2006-12-05 17:42:38+03  dstef
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
#endif

#endif



/* Definitions */
#define  FILENAME_SIZE	    256
#define  DIRNAME_SIZE	    FILENAME_SIZE

#define  KILOBYTES          1024
#define  MEGABYTES          (KILOBYTES*1024)

#define  MAX_BUF_SIZ        (16*KILOBYTES)


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
const char rcs_id[] = "$Id: file2bin.c,v 1.2 2014-02-16 19:22:46+04 dstef Exp root $";

  
/*----------------------- Functions ---------------------------------------*/


void usage( void )
{
  fprintf( stderr, "\n" );
  fprintf( stderr, "Extract binary portion from file, version %s\n", prog_ver );
  fprintf( stderr, "Copyright (C) 2006,2014 Dmitry Stefankov. All Rights Reserved.\n" );
  fprintf( stderr, "Usage: file2bin [-vfh] [-i infile] [-o outfile]\n" );  
  fprintf( stderr, "       [-l in_offset] [-s in_size]\n" );
  fprintf( stderr, "       -h       this help\n" );   
  fprintf( stderr, "       -v       verbose output (default=no)\n" );
  fprintf( stderr, "       -f       don't suppress questions (default=yes)\n" );  
  fprintf( stderr, "       -l val   byte offset on input stream (default=0)\n" );
  fprintf( stderr, "       -s N     copy N bytes from input stream (default=0)\n" );
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
  int                   res;
  int                   force_ask = 0;
  unsigned long int     i_off = 0;
  unsigned long int     i_siz = 0;
  int                   bytes_count;  
  char                * i_fname = NULL;
  char                * o_fname = NULL;
  unsigned char       * p_buf;
  FILE                * ifp = NULL;
  FILE                * ofp = NULL;
  char                  temp_buf[128];
  
  
/* Process command line  */  
  opterr = 0;
  while( (op = getopt(argc,argv,"fi:l:o:s:vh")) != -1)
    switch(op) {
      case 'i':
               i_fname = optarg;
               break;
      case 'o':
               o_fname = optarg;
               break;
      case 'l':
               //i_off = atol(optarg);
               i_off = strtoul(optarg,NULL,0);
               break;
      case 's':
               //i_siz = atol(optarg);
               i_siz = strtoul(optarg,NULL,0);
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

  if (verbose) {
    printf( "i_fname:'%s'\n", i_fname );
    printf( "o_fname: '%s'\n", o_fname );
    printf( "i_siz: '%lu' (0x%08X)\n", i_siz, i_siz );
    printf( "i_off: '%lu' (0x%08X)\n", i_off, i_off );
  }

  if (i_siz == 0) {
    fprintf( stderr, "ERROR: Bytes count to transfer not specified!\n" ); 
    return(1);
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
    if (verbose) printf( "Create input stream.\n" );
    ifp = fopen( i_fname, "rb" );
    if (ifp == NULL) {
       fprintf( stderr, "ERROR: cannot open input file!\n" );
       return(2);
    }
  }

  /* Open output stream */
  if (o_fname != NULL) {
    if (verbose) printf( "Create output stream.\n" );
    if (force_ask && (o_fname != NULL)) {
      ofp = fopen( o_fname, "rb" );
      if (ofp == NULL) {
       //fprintf( stderr, "ERROR: cannot create output file [1]!\n" );
       //return(2);
       if (verbose) printf( "Output stream not found.\n");
       goto  create_file;
      }
      fclose(ofp);
      printf( "Overwrite existing output file? (Y/n) " );
      fgets( temp_buf, sizeof(temp_buf), stdin );
      if (tolower(temp_buf[0]) == 'n' ) {
          fprintf( stderr, "Aborted by user.\n" );
          return(3);
      }
    }
  create_file:   
    ofp = fopen( o_fname, "wb" );
    if (ofp == NULL) {
       fprintf( stderr, "ERROR: cannot create output file!\n" );
       return(4);
    }
  }

  /* Set starting position for input stream */
  if (verbose) printf( "Seek input stream.\n" );  
  res = fseek( ifp, i_off, SEEK_SET );
  if (res < 0) {
       fprintf( stderr, "ERROR: input stream seek failed !\n" );
       ret_code = 5;
       goto done;
  }

  if (verbose) printf( "Allocate memory %u bytes.\n", MAX_BUF_SIZ );
  p_buf = malloc(MAX_BUF_SIZ);
  if (p_buf == NULL) {
       fprintf( stderr, "ERROR: cannot allocate memory = %u bytes!\n", MAX_BUF_SIZ );
       ret_code = 6;
       goto done;
  }
  
  while( i_siz ) {
    if (i_siz > MAX_BUF_SIZ) bytes_count = MAX_BUF_SIZ;
    else bytes_count = i_siz;
    i_siz -= bytes_count;
    if (verbose) printf( "Bytes_count=%u\n", bytes_count );

    if (verbose) printf( "Read.\n" );
    res = fread( p_buf, 1, bytes_count, ifp );
    if (res != bytes_count) {
       fprintf( stderr, "ERROR: cannot read %u bytes!\n", bytes_count );
       ret_code = 7;
       goto done;
    }

    if (verbose) printf( "Write.\n" );
    res = fwrite( p_buf, 1, bytes_count, ofp );
    if (res != bytes_count) {
       fprintf( stderr, "ERROR: cannot write %u bytes!\n", bytes_count );
       ret_code = 8;
       goto done;
    }

  } /*while*/
  
  ret_code = 0;
  
  
done:
    if (verbose) printf( "Close streams.\n" );
  if (ifp != NULL) fclose( ifp );
  if (ofp != NULL) fclose( ofp );  
  
  return(ret_code);
}
