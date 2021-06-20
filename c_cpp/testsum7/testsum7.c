/*****************************************************************************
 *                             File TESTSUM7.C
 *
 *       Generate and test checksums (CRC-16,CRC-32,MD5,SHA-1,SHA2,SHA-3,GOST) for files 
 *              (multi-platform version)
 *
 *      Copyright (c) Dmitry V. Stefankov, 1998-2019. All rights reserved.
 *
 *       This software is distributed under GPL agreement
 *       (See copying file for details).
 *
 *****************************************************************************/
/*
 *   $Source$
 *  $RCSfile$
 *   $Author$
 *     $Date$
 * $Revision$
 *   $Locker$
 *
 *      $Log$
 *****************************************************************************/



/*-------------------------- Check for platforms ---------------------------*/



/*-------------------------- Check for compiler ----------------------------*/



/*-------------------------- Standard definitions --------------------------*/
#if _WIN32
#include <windows.h>                        /* WIN32 base definitions */
#endif                                      /* #if defined(_WIN32) */
#include <stdio.h>                          /* I/O standard streams */
#include <stdlib.h>                         /* Miscellaneous common functions */
#if !defined(_WIN32)
#include <dirent.h>                         /* Posix directory operations */
#endif
#include <string.h>                         /* String and memory operations */
#include <ctype.h>                          /* Character macros */
#if defined(_MSVC)
#include <dos.h>
#endif                                      /* #if defined(_MSVC) */


/*------------------------------- Description ------------------------------*/
const char  g_ProgramName[]       =   "TestSum7";
const char  g_ProgramVersion[]    =   "v1.30";
const char  g_CopyrightNotice[]   =   "Copyright (c) 1998,2019";
const char  g_Author[]            =   "Dmitry Stefankov";



/*------------------------------- Return Codes -----------------------------*/
#define   ERROR_DONE                 0     /* Running is successful        */
#define   ERROR_BAD_PARAMETER        1     /* Bad user supplied parameter  */
#define   ERROR_CANNOT_USE_THEM      2     /* Cannot used together         */
#define   ERROR_LOGFILE_NOT_FOUND    3     /* Missed logfile               */
#define   ERROR_LOGFILE_CREAT_FAIL   4     /* Failed logfile creating      */
#define   ERROR_NO_CRC_METHOD        5     /* Missed CRC method to sum     */
#define   ERROR_LOGFILE_OPEN_FAIL    6     /* Failed logfile open          */
#define   ERROR_NO_ACTION            7     /* No option to act             */
#define   ERROR_RESFILE_CREAT_FAIL   8     /* Failed results file creating */
#define   ERROR_CHECK_FAILED         9     /* Faild check action           */
#define   ERROR_USER_HELP_OUTPUT   255     /* Output user help message     */



/*----------------------------- Miscellaneous ------------------------------*/
#define   QUOTA                    0x22     /* Quatation mark */
#define   FMASKS_MAX               30       /* Available masks */
#if defined(_MSDOS)
#define   MAX_FILENAME_SIZE        80+1     /* UNIX compatibility */
#else
#define   MAX_FILENAME_SIZE        255+1    /* UNIX compatibility */
#endif                                      /* #if defined(_MSDOS) */
#define   MAX_CRC_TABLE_SIZE       256      /* 8*32 */
#define   CRC32_POLYNOMIAL      0xEDB88320L /* PKZIP compatible */
#define   CRC16_POLYNOMIAL         0x1021   /* XMODEM compatible */
#define   BITS_PER_BYTE            8        /* One byte has eight bits */
#if defined(_BCC)
#define   MAX_FILEBUF_SIZE         3072     /* Workaround for ml,mh,mc */
#else
#define   MAX_FILEBUF_SIZE         16384    /* File operations buffer */
#endif                                      /* #if defined(_BCC) */
#define   MAX_LINE_SIZE            1024     /* Working buffer */
#define   HEX_RADIX                16       /* Hexadecimal */
#define   MAX_OUT_LINE_SIZE        1024     /* Working buffer */
#define   WORK_LINE_SIZE           256      /* Working buffer */
#define   MAX_CRC_TIMES            1024     /* Calculation factor */
#define   DIGEST_BUF_SIZE          16       /* Digest buffer size */
#if (defined(_WIN32) || defined(_MSVC))
#define   DIRMAGIC                  0xDD    /* Borland C compatibilty */
#define   EBADF                     6       /* Bad file number */
#define   ENOMEM                    8       /* Not enough core */
#define   ENOENT                    2       /* No such file or directory*/
#endif                                      /* #if (defined(_WIN32) || defined(_MSVC)) */



/*--------------------------- MD5 definitions ------------------------------*/
#define _MD5STRSAVE_WORKAROUND	1

typedef struct { unsigned char  md5sig[DIGEST_BUF_SIZE]; }  md5buf;
typedef md5buf * pmd5buf;

pmd5buf GetFileMD5( char *szFileName );




/*-------------------------- SHA-1 definitions ------------------------------*/

#define	SHA1_RESULTLEN	(160/8)

unsigned char *  GetFileSHA1( char *szFileName );




/*-------------------------- SHA-2 definitions ------------------------------*/


unsigned char * GetFileSHA2_224( char *szFileName );
unsigned char * GetFileSHA2_256( char *szFileName );
unsigned char * GetFileSHA2_384( char *szFileName );
unsigned char * GetFileSHA2_512( char *szFileName );

enum hash_bits_sizes
{
  HASH_BITS_SIZE_224 = 1,
  HASH_BITS_SIZE_384 = 2,
  HASH_BITS_SIZE_256 = 3,
  HASH_BITS_SIZE_512 = 4
};


#define	SHA2_224_RESULTLEN   (224/8)
#define	SHA2_256_RESULTLEN   (256/8)
#define	SHA2_384_RESULTLEN   (384/8)
#define	SHA2_512_RESULTLEN   (512/8)


#define sha256_block_size 64
#define sha256_hash_size  32
#define sha224_hash_size  28

#define sha512_block_size 128
#define sha512_hash_size  64
#define sha384_hash_size  48




/*-------------------------- SHA-3 definitions ------------------------------*/

#define	SHA3_224_RESULTLEN   (224/8)
#define	SHA3_256_RESULTLEN   (256/8)
#define	SHA3_384_RESULTLEN   (384/8)
#define	SHA3_512_RESULTLEN   (512/8)



unsigned char * GetFileSHA3_224( char *szFileName );
unsigned char * GetFileSHA3_256( char *szFileName );
unsigned char * GetFileSHA3_384( char *szFileName );
unsigned char * GetFileSHA3_512( char *szFileName );




/*-------------------------- GOST HASH 34.11-2012 definitions ------------------------------*/

#define	GOSTHASH_1994_256_RESULTLEN   (256/8)

unsigned char * GetFileGOSTHASH_1994_256( char *szFileName );




/*-------------------------- GOST HASH 34.11-2012 definitions ------------------------------*/


#define	GOSTHASH_2012_256_RESULTLEN   (256/8)
#define	GOSTHASH_2012_512_RESULTLEN   (512/8)


unsigned char * GetFileGOSTHASH_2012_256( char *szFileName );
unsigned char * GetFileGOSTHASH_2012_512( char *szFileName );




/*----------------------------- Structures ---------------------------------*/
#if (defined(_WIN32) || defined(_MSVC))     /* Definitions for POSIX directory operations. */
struct dirent                               /* dirent structure returned by readdir() */
{
#if defined(_MSVC)
    char        d_name[13];                 /* MS-DOS FAT 8+3 name */
#else
    char        d_name[MAX_FILENAME_SIZE];  /* Full filename */
#endif                                      /* #if defined(_MSVC) */
};

typedef struct                              /* DIR type returned by opendir() */
{
/* DIR type returned by opendir().  The first two members cannot
 * be separated, because they make up the DOS DTA structure used
 * by findfirst() and findnext().
 */
#if defined(_MSVC)
    char          _d_reserved[30];          /* reserved part of DTA */
    struct dirent  d_dirent;                /* filename part of DTA */
    char         * d_dirname;               /* Directory name */
#else
    char         * d_dirname;               /* Directory name */
    struct dirent  d_dirent;                /* Copy of filename */
#endif                                      /* #if defined(_MSVC) */
    char           d_first;                 /* First file flag */
    unsigned char  d_magic;                 /* Magic cookie for verifying handle */
#if !defined(_MSVC)
    HANDLE        fileHandle;               /* Win32 classic object */
    WIN32_FIND_DATA  findData;              /* Win32 search structire */
#endif                                      /* #if !defined(_MSVC) */
} DIR;
#endif                                      /* #if defined(_WIN32) */

struct  MaskNode
{
    char *   pFilesMask;                    /* Filemask */
};

struct  FileSearchMasks
{
  struct MaskNode    sFileMasks[FMASKS_MAX];
};
typedef  struct FileSearchMasks  * pFileSearchMasks;



/*----------------------------- GOST HASH ---------------------------------*/

#ifndef SECTOR_SIZE
#define SECTOR_SIZE 512
#endif
//
#if SPEED && SIZE
#error You Must Choose SPEED or SIZE ?
#endif
//
#ifndef SPEED
#ifndef SIZE
#define SIZE
#endif
#endif
//
typedef struct _GOSTKey { unsigned long key [8]; } GOSTKey;
typedef struct _GOSTtst { unsigned long Test[2]; } GOSTtst;
//
typedef struct
{
#ifdef SPEED
  unsigned long k21[256];
  unsigned long k43[256];
  unsigned long k65[256];
  unsigned long k87[256];
#else
  unsigned char k21[256];
  unsigned char k43[256];
  unsigned char k65[256];
  unsigned char k87[256];
#endif
  unsigned long key  [  8  ];
} GOSTCTX, 
*PGOSTCTX;
//
unsigned long
__GOSTSHA       (
         register PGOSTCTX       gost,
                unsigned long *in, 
                unsigned long  len, 
                unsigned long *sha
              );
//
unsigned long
__GOSTSHA_1   (
         register PGOSTCTX       gost,
                unsigned long *in, 
                unsigned long  len, 
                unsigned long *sha
              );
//
unsigned long
__GOSTSHA_2   (
         register PGOSTCTX       gost,
                unsigned long *in, 
                unsigned long  len, 
                unsigned long *sha
              );
//
void 
__GOSTFree      (
         register PGOSTCTX       gost
              );
//
void 
__GOSTInit      (
         register PGOSTCTX       gost,
                unsigned long *key,
                unsigned char *perms
              );
//
int __GOSTCryptTest ( void );
//
unsigned long int  GOSTHash ( char *szFileName );
unsigned long int  FileGOSTHash ( char *szFileName );


#pragma pack(1)
//
// 8*16 4-bit permutation blocks
//
unsigned char k1[]=
{0x4,0x2,0xf,0x5,0x9,0x1,0x0,0x8,0xe,0x3,0xb,0xc,0xd,0x7,0xa,0x6};
unsigned char k2[]=
{0xc,0x9,0xf,0xe,0x8,0x1,0x3,0xa,0x2,0x7,0x4,0xd,0x6,0x0,0xb,0x5};
unsigned char k3[]=
{0xd,0x8,0xe,0xc,0x7,0x3,0x9,0xa,0x1,0x5,0x2,0x4,0x6,0xf,0x0,0xb};
unsigned char k4[]=
{0xe,0x9,0xb,0x2,0x5,0xf,0x7,0x1,0x0,0xd,0xc,0x6,0xa,0x4,0x3,0x8};
unsigned char k5[]=
{0x3,0xe,0x5,0x9,0x6,0x8,0x0,0xd,0xa,0xb,0x7,0xc,0x2,0x1,0xf,0x4};
unsigned char k6[]=
{0x8,0xf,0x6,0xb,0x1,0x9,0xc,0x5,0xd,0x3,0x7,0xa,0x0,0xe,0x2,0x4};
unsigned char k7[]=
{0x9,0xb,0xc,0x0,0x3,0x6,0x7,0x5,0x4,0x8,0xe,0xf,0x1,0xa,0x2,0xd};
unsigned char k8[]=
{0xc,0x6,0x5,0x2,0xb,0x0,0x9,0xd,0x3,0xe,0x7,0xa,0xf,0x4,0x1,0x8};
//
#pragma pack()


//#ifndef __uint64_t
#if  !defined(_GNU_SOURCE) || !defined(_BSD_SOURCE)
typedef unsigned long long int   __uint64_t;
#endif


/*----------------------------- RCS marker ---------------------------------*/
static char  rcsid[] = "$Id$";



/*----------------------------- Global data --------------------------------*/
unsigned long  int g_TableCRC32[MAX_CRC_TABLE_SIZE];
unsigned int       g_TableCRC16[MAX_CRC_TABLE_SIZE];

int   g_fVerbose                =   0;      /* Verbose output             */
int   g_iDebugLevel             =   0;      /* Debugging level            */
int   g_fRecursiveSearch        =   0;      /* Scan all subdirectories    */
int   g_fCreateCrcLog           =   1;      /* Add CRC sums to logfile    */
int   g_fTestCrcLog             =   0;      /* Test CRC sums from logfile */
int   g_fCRC16                  =   0;      /* Use CRC-16 algorithm       */
int   g_fCRC32                  =   0;      /* Use CRC-32 algorithm       */
int   g_fMD5                    =   0;      /* Use MD5 algorithm          */
int   g_fSHA1                   =   0;      /* Use SHA-1 algorithm        */
int   g_fSHA2                   =   0;      /* Use SHA-2 algorithm        */
int   g_fSHA3                   =   0;      /* Use SHA-3 algorithm        */
int   g_fGOSTHASH               =   0;      /* Use GOSTHASH algorithm     */
int   g_fGOSTHASH2012           =   0;      /* Use GOSTHASH algorithm  (2012) */
int   g_fPrintBadCRC            =   0;      /* Print only failed CRC files*/
int   g_iRetryCountCRC          =   1;      /* How many times count CRC   */
int   g_fIgnoreCaseInFilenames  =   0;      /* Ignore case in filenames   */
int   g_iIncFilesMask           =   0;      /* Include to search          */
int   g_iExcFilesMask           =   0;      /* Include to search          */
int   g_iHashBitsSize           =   0;
int   g_iDirectoryDepth         =   0;      /* Directory depth size      */

struct FileSearchMasks    g_sIncFileMasks;
struct FileSearchMasks    g_sExcFileMasks;

char   g_szHashSize[16] = "\0";

const  char  g_szCRC32[]        =   { "CRC32="};
const  char  g_szCRC16[]        =   { "CRC16="};
const  char  g_szMD5[]          =   { "MD5="};
const  char  g_szSHA1[]         =   { "SHA1="};
const  char  g_szGOSTHASH[]     =   { "GOSTHASH="};
const  char  g_szSHA2_224[]     =   { "SHA2(224)="};
const  char  g_szSHA2_256[]     =   { "SHA2(256)="};
const  char  g_szSHA2_384[]     =   { "SHA2(384)="};
const  char  g_szSHA2_512[]     =   { "SHA2(512)="};
const  char  g_szSHA3_224[]     =   { "SHA3(224)="};
const  char  g_szSHA3_256[]     =   { "SHA3(256)="};
const  char  g_szSHA3_384[]     =   { "SHA3(384)="};
const  char  g_szSHA3_512[]     =   { "SHA3(512)="};
const  char  g_szGOSTHASH2012_256[]     =   { "GOSTHASH2012(256)="};
const  char  g_szGOSTHASH2012_512[]     =   { "GOSTHASH2012(512)="};
const  char  g_szOK[]           =   { "OK"};
const  char  g_szBAD[]          =   { "(bad)"};
const  char  g_szNOFILE[]       =   { "(file not found)"};
const  char  g_szWrongCRC[]     =   { "(unreliable results)"};

const  char  g_szDefLogFile[]   =   { "crc.log"};



/*---------------------------- Error Messages ------------------------------*/
const char  g_szNoMemForExcFMask[]  =
                     "WARNING: insufficient memory for excluding filemask.";
const char  g_szNoMemForIncFMask[]  =
                     "WARNING: insufficient memory for including filemask.";



/*------------------------- Function Prototype -----------------------------*/
unsigned long int ulScanDir( char *dirname, int maxdirlen,
                             pFileSearchMasks pIncFMasks,
                             pFileSearchMasks pExcFMasks, int iSearchDirs,
                             const char *resfile, int iMaxDirDepth );
int   iTestDir( char *dirname );
int   iTestPattern( const char * szName, const char * szPattern );
int  iTestForFileMask( char *filename, pFileSearchMasks pFMasks,
                       int iFMasksCount );
int  AddFileMask( const char * pszAddMask, pFileSearchMasks pFMasks,
                  int * piFMasksCount, const char * pszErrMsg );
char  *StrUpper( char *pstr);
void  BuildTableCRC32( void );
void  BuildTableCRC16( void );
unsigned long int ulGetFileCRC32( char *szFileName );
unsigned int iGetFileCRC16( char *szFileName );
unsigned long int ulCalcBufCRC32( unsigned int count, unsigned long int crc,
                                  unsigned char *pbuf );
unsigned int iCalcBufCRC16( unsigned int count, unsigned int crc,
                            unsigned char *pbuf );
int   iFileExists( const char * szName );
char *  safe_strncpy ( char *dest, const char *src, size_t maxlen );
char *  safe_strncat( char *dest, const char *src, size_t n );
#if (defined(_WIN32) || defined(_MSVC))
DIR *  opendir( char *dirname );
struct dirent *  readdir( DIR  *dir );
int   closedir( DIR  *dir );
#endif                                      /* #if (defined(_WIN32) || defined(_MSVC)) */




#if !defined(strcasecmp) && !defined(strncasecmp)  && !defined(__FreeBSD__) \
    && !defined(__linux__)
static int strcasecmp( const char * s1, const char * s2 );
static int strncasecmp( const char * s1, const char * s2, size_t n );

int
strcasecmp(s1, s2)
	const char *s1, *s2;
{
	register const u_char
			*us1 = (const u_char *)s1,
			*us2 = (const u_char *)s2;

	while (tolower(*us1) == tolower(*us2++))
		if (*us1++ == '\0')
			return (0);
	return (tolower(*us1) - tolower(*--us2));
}

int
strncasecmp(s1, s2, n)
	const char *s1, *s2;
	register size_t n;
{
	if (n != 0) {
		register const u_char
				*us1 = (const u_char *)s1,
				*us2 = (const u_char *)s2;

		do {
			if (tolower(*us1) != tolower(*us2++))
				return (tolower(*us1) - tolower(*--us2));
			if (*us1++ == '\0')
				break;
		} while (--n != 0);
	}
	return (0);
}
#endif


static    md5buf      md5sig_test;                /* MD5 hash sum (from file) */
static    md5buf      md5sig_calc;                /* MD5 hash sum (calc on file) */
static    pmd5buf     psignature;                 /* MD5 hash sum pointer */
static    unsigned char  sha1_hash_test[SHA1_RESULTLEN]; /* SHA-1 hash buffer */
static    unsigned char  sha1_hash_calc[SHA1_RESULTLEN]; /* SHA-1 hash buffer */
static    unsigned char  sha_224_hash_test[SHA2_224_RESULTLEN]; /* SHA2-224 hash buffer */
static    unsigned char  sha_224_hash_calc[SHA2_224_RESULTLEN]; /* SHA2-224 hash buffer */
static    unsigned char  sha_256_hash_test[SHA2_256_RESULTLEN]; /* SHA2-256 hash buffer */
static    unsigned char  sha_256_hash_calc[SHA2_256_RESULTLEN]; /* SHA2-256 hash buffer */
static    unsigned char  sha_384_hash_test[SHA2_384_RESULTLEN]; /* SHA2-384 hash buffer */
static    unsigned char  sha_384_hash_calc[SHA2_384_RESULTLEN]; /* SHA2-384 hash buffer */
static    unsigned char  sha_512_hash_test[SHA2_512_RESULTLEN]; /* SHA2-512 hash buffer */
static    unsigned char  sha_512_hash_calc[SHA2_512_RESULTLEN]; /* SHA2-512 hash buffer */



/*****************************************************************************
 *                              --- main ---
 *
 * Purpose: Main program function
 *   Input: int   argc    - argument count
 *          char **argv   - argument list
 *  Output: int           - exit code (see above)
 * Written: by Dmitry V.Stefankov 09-29-1998
 *****************************************************************************/
int main( int argc, char **argv )
{
    int         prog_exit_code = 0;         /* Exit default code */
    int         iArgc;                      /* Arguments number  */
    char       **lpszArgv;                  /* Arguments array   */
    char  szIncSearchDir[MAX_FILENAME_SIZE+1]  = { "\0" };
    char  szIncSearchMask[MAX_FILENAME_SIZE+1] = { "\0" };
    char  szExcSearchMask[MAX_FILENAME_SIZE+1] = { "\0" };
    char  szOutResFile[MAX_FILENAME_SIZE+1]    = { "\0" };
    char  szLogFile[MAX_FILENAME_SIZE+1]       = { "\0" };
    char  szCurDir[MAX_FILENAME_SIZE+1]        = { "\0" };
    char  szChkFileName[MAX_FILENAME_SIZE+1];
    char  szTempBuf[MAX_OUT_LINE_SIZE];     /* Working buffer */
#if _MD5STRSAVE_WORKAROUND
    char  szTempBuf_save[MAX_OUT_LINE_SIZE];/* Working buffer */
    char        StrBuf_save[MAX_LINE_SIZE]; /* Working string */
#endif                                      /* #if _MD5STRSAVE_WORKAROUND */
    char  szTempStr[WORK_LINE_SIZE];        /* Working string */
    int         iTemp;                      /* Temporary */
    char        chTemp;                     /* Temporary storage */
    unsigned long int ulFoundFiles = 0;     /* Counter */
    FILE       *LogFile;                    /* Output logfile */
    FILE       *ResFile;                    /* Output resfile */
    char        StrBuf[MAX_LINE_SIZE];      /* Working string */
    unsigned long int  ulLinesCount = 0;    /* Count processing lines */
    char       *pchs;                       /* Temporary pointer */
    char       *pche;                       /* Temporary pointer */
    unsigned long int  ulTestCRC32;         /* Test CRC-32 sum */
    unsigned long int  ulCalcCRC32;         /* Computed CRC-32 sum */
    unsigned short int   iTestCRC16;        /* Test CRC-16 sum */
    unsigned short int   iCalcCRC16;        /* Computed CRC-16 sum */
    int         fBadCRC;                    /* Flag for failed CRC */
    int         iIndex;                     /* Index loop */
    int         fWrongCRC;                  /* Wrong CRC found */
    void *      pTemp;                      /* Temporary */
    unsigned char * p_sha1_hash;            /* Temporary */
    unsigned char * p_hash;                 /* Temporary */
    int         i;                          /* Temporary */
    int         iDirDepth = 0;              /* Temporary */
#if 0
    md5buf      md5sig_test;                /* MD5 hash sum (from file) */
    md5buf      md5sig_calc;                /* MD5 hash sum (calc on file) */
    pmd5buf     psignature;                 /* MD5 hash sum pointer */
    unsigned char  sha1_hash_test[SHA1_RESULTLEN]; /* SHA-1 hash buffer */
    unsigned char  sha1_hash_calc[SHA1_RESULTLEN]; /* SHA-1 hash buffer */
    unsigned char  sha_224_hash_test[SHA2_224_RESULTLEN]; /* SHA2-224 hash buffer */
    unsigned char  sha_224_hash_calc[SHA2_224_RESULTLEN]; /* SHA2-224 hash buffer */
    unsigned char  sha_256_hash_test[SHA2_256_RESULTLEN]; /* SHA2-256 hash buffer */
    unsigned char  sha_256_hash_calc[SHA2_256_RESULTLEN]; /* SHA2-256 hash buffer */
    unsigned char  sha_384_hash_test[SHA2_384_RESULTLEN]; /* SHA2-384 hash buffer */
    unsigned char  sha_384_hash_calc[SHA2_384_RESULTLEN]; /* SHA2-384 hash buffer */
    unsigned char  sha_512_hash_test[SHA2_512_RESULTLEN]; /* SHA2-512 hash buffer */
    unsigned char  sha_512_hash_calc[SHA2_512_RESULTLEN]; /* SHA2-512 hash buffer */
#endif
    

/*-------------------------- Compiler test phase ---------------------------*/
#ifdef  _TEST
#if __STDC__ == 0 && !defined(__cplusplus)
  printf("cc is not ANSI C compliant!\n");
  return 0
#else
  if (g_iDebugLevel > 0)
    printf( "%s compiled at %s %s. This statement is at line %d.\n",
            __FILE__, __DATE__, __TIME__, __LINE__);
#endif                                      /* __STDC__ == 0 && !defined(__cplusplus) */
#endif                                      /* #ifdef  _TEST */

/*-------------------------- Pre-initialization ----------------------------*/
  pTemp = (void *)rcsid;                    /* Just to avoid warning */
  for(iTemp=0; iTemp<FMASKS_MAX; iTemp++)
  {
    g_sIncFileMasks.sFileMasks[iTemp].pFilesMask = NULL;
    g_sExcFileMasks.sFileMasks[iTemp].pFilesMask = NULL;
  }

/*-------------------------- Process comand parameters ---------------------*/
    iArgc   = argc;                         /* Copy argument indices */
    lpszArgv = (char **)argv;

  if (iArgc == 1)
  {                                         /* Print on-line help */
     printf( "TESTSUM(1)                                             TESTSUM(1)\n" );
     printf( "\n" );
     printf( "NAME\n" );
     printf( "  testsum - test file(s) integrity using CRC-16/CRC-32/MD5/SHA-1/GOSTHASH/SHA-2/SHA-3 sums\n" );
     printf( "\n" );
     printf( "SYNOPSIS\n" );
     printf( "   testsum [-1][-2][-3][-4][-5][-7][-8][9] [-b] [-d] [[-e filemask]..] [-f logfile]\n" );
     printf( "           [-g] [[-i filemask]..] [-l] [-o resfile] [-r times] [-s] [-t]\n" );
     printf( "           [-v] [-h hashsize] [-n num] [dirname]\n" );
     printf( "\n" );
     printf( "DESCRIPTION\n" );
     printf( "  TESTSUM uses the standard CRC math to check the file contents integrity.\n" );
     printf( "  Defaults: generate CRC sums for file(s) in current directory, and a name of\n" );
     printf( "  a logfile to test CRC sums is the '%s' filename.\n", g_szDefLogFile );
     printf( "\n" );
     printf( "OPTIONS\n" );
     printf( "  -1   Use CRC-16 algorithm.\n" );
     printf( "  -3   Use CRC-32 algorithm (default).\n" );
     printf( "  -5   Use MD5 algorithm.\n" );
     printf( "  -7   Use SHA-1 algorithm.\n" );
     printf( "  -2   Use SHA-2 algorithm.\n" );
     printf( "  -4   Use SHA-3 algorithm.\n" );
     printf( "  -9   Use GOSTHASH algorithm (34.11-1994).\n" );
     printf( "  -8   Use GOSTHASH algorithm (34.11-2012).\n" );
     printf( "  -b   Print only filenames with failed CRC.\n" );
     printf( "  -d   Debugging level.\n" );
     printf( "  -e filemask\n" );
     printf( "       Exclude file(s) for search, wildcards are allowed (upto %d masks).\n", FMASKS_MAX );
     printf( "  -f   Input logfile.\n" );
     printf( "  -g   Ignore case in filename(s).\n" );
     printf( "  -i filemask\n" );
     printf( "       Include file(s) for search, wildcards are allowed (upto %d masks).\n", FMASKS_MAX );
     printf( "  -l   Use default logfile name to write output results.\n" );
     printf( "  -o   Output results filename.\n" );
     printf( "  -r times\n" );
     printf( "       Repeat a CRC calculations many times. Maximum is %d.\n", MAX_CRC_TIMES );
     printf( "  -h hashsize\n" );
     printf( "       hash size in bits (224,256,384,512).\n" );
     printf( "  -s   Search subdirectories.\n" );
     printf( "  -t   Test (check) CRC sum for each file(s) listed in logfile.\n" );
     printf( "  -n num\n" );
     printf( "       Directory depth limit (default=unlimited).\n" );
     printf( "  -v   Verbose output.\n" );
     printf( "  dirname\n" );
     printf( "       Directory name to start. If absent then current in use.\n" );
     printf( "\n" );
     printf( "HISTORY\n" );
     printf( "  TESTSUM command appeared in October 1998\n" );
     printf( "\n" );
     printf( "AUTHOR\n" );
     printf( "  Dmitry V. Stefankov  (dmstef@gmail.com, dstef@tpmail.ru)" );
     printf( "\n" );
     return( ERROR_USER_HELP_OUTPUT );
  }
  else
  {
     --iArgc;                               /* Remove program name */
     while (iArgc)
     {
       chTemp = **(++lpszArgv);
       iArgc--;                             /* Remove this argument */
       //if ( (chTemp == '-') || (chTemp == '/') )
       if (chTemp == '-')
       {
          chTemp = *(++*lpszArgv);          /* Look options */
          switch( chTemp )
          {
                case '9':
                    g_fGOSTHASH  = 1;       /* GOSTHASH */
                    break;
                case '8':
                    g_fGOSTHASH2012 = 1;       /* GOSTHASH 2012 */
                    break;
                case '7':
                    g_fSHA1  = 1;           /* SHA1 */
                    break;
                case '2':
                    g_fSHA2  = 1;           /* SHA2 */
                    break;
                case '4':
                    g_fSHA3  = 1;           /* SHA3 */
                    break;
                case '5':
                    g_fMD5   = 1;           /* MD5 */     
                    break;
                case '1':
                    g_fCRC16 = 1;           /* CRC-16 */
                    break;
                case '3':
                    g_fCRC32 = 1;           /* CRC-32 */
                    break;
                case 'b':
                    g_fPrintBadCRC = 1;     /* Print only bad CRC */
                    break;
                case 'd':
                    g_iDebugLevel = 1;      /* Some debugging */
                    break;
                case 'e':
                    if (iArgc)              /* Exclude files mask */
                    {
                        --iArgc;
                        safe_strncpy( szExcSearchMask, *(++lpszArgv), sizeof(szExcSearchMask) );
#if defined(_MSDOS)
                        StrUpper( szExcSearchMask );
#endif                                      /* #if defined(_MSDOS) */
                        iTemp = AddFileMask( szExcSearchMask,
                                             &g_sExcFileMasks,
                                             &g_iExcFilesMask,
                                             g_szNoMemForExcFMask );
                    }
                    break;
                case 'f':
                    if (iArgc)              /* Logfile */
                    {
                        --iArgc;
                        safe_strncpy( szLogFile, *(++lpszArgv), sizeof(szLogFile) );
                    }
                    break;
                case 'g':                   /* Case-insensitive search for filenames */
                    g_fIgnoreCaseInFilenames = 1;
                    break;
                case 'h':
                    if (iArgc)              /* hash size */
                    {
                        --iArgc;
                        /*iTemp = strlen(*(++lpszArgv) );*/
                        safe_strncpy( g_szHashSize, *(++lpszArgv), sizeof(g_szHashSize) );
                        if (strcasecmp(g_szHashSize,"224") == 0) g_iHashBitsSize = HASH_BITS_SIZE_224;
                        if (strcasecmp(g_szHashSize,"256") == 0) g_iHashBitsSize = HASH_BITS_SIZE_256;
                        if (strcasecmp(g_szHashSize,"384") == 0) g_iHashBitsSize = HASH_BITS_SIZE_384;
                        if (strcasecmp(g_szHashSize,"512") == 0) g_iHashBitsSize = HASH_BITS_SIZE_512;
                    }
                    break;
                case 'i':
                    if (iArgc)              /* Include files mask */
                    {
                        --iArgc;
                        /*iTemp = strlen(*(++lpszArgv) );*/
                        safe_strncpy( szIncSearchMask, *(++lpszArgv), sizeof(szIncSearchMask) );
#if defined(_MSDOS)
                        StrUpper( szIncSearchMask );
#endif                                      /* #if defined(_MSDOS) */
                        iTemp = AddFileMask( szIncSearchMask,
                                             &g_sIncFileMasks,
                                             &g_iIncFilesMask,
                                             g_szNoMemForIncFMask );
                    }
                    break;
                case 'l':                   /* Default output logfile name */
                    if ( g_fCreateCrcLog && (!g_fTestCrcLog) )
                    {
                      safe_strncpy( szOutResFile, g_szDefLogFile, sizeof(szOutResFile) );
                    }
                    break;
                case 'o':
                    if (iArgc)              /* Output results file */
                    {
                        --iArgc;
                        safe_strncpy( szOutResFile, *(++lpszArgv), sizeof(szOutResFile) );
                    }
                    break;
                case 'r':                   /* How many times */
                    if (iArgc)
                    {
                      --iArgc;
                      iTemp = atoi( *(++lpszArgv) );
                      if ( (iTemp >= 0 ) && (iTemp <= MAX_CRC_TIMES) )
                      {
                         g_iRetryCountCRC = iTemp;
                      }
                    }
                    break;
                case 's':                   /* Search subdirectories */
                    g_fRecursiveSearch = 1;
                    break;
                case 't':                   /* Test CRC logfile */
                    g_fCreateCrcLog = 0;
                    g_fTestCrcLog = 1;
                    break;
                case 'v':
                    g_fVerbose = 1;         /* Verbose output */
                    break;
                case 'n':
                    if (iArgc)              /* Exclude files mask */
                    {
                        --iArgc;
                        g_iDirectoryDepth = atoi(*(++lpszArgv));
                    }
                    break;
                default:
                    printf( "ERROR: unknown option: -%s\n", *lpszArgv );
                    return( ERROR_BAD_PARAMETER );
                    /* break; */
          } /*switch*/
       }
       else
       {
          safe_strncpy( szIncSearchDir, *lpszArgv, sizeof(szIncSearchDir) );
       } /*if-else*/
     } /*while*/
  } /*if-else*/

/*--------------------------- Banner message -------------------------------*/
  if (g_fVerbose)
    printf( "%s %s, %s %s\n", g_ProgramName, g_ProgramVersion,
             g_CopyrightNotice,  g_Author );

/*--------------------------- Initial checks -------------------------------*/
#if defined(_WIN32)
    if( !GetCurrentDirectory( MAX_FILENAME_SIZE, szCurDir) )
    {
        printf( "ERROR: Unable to get current directory.\n" );
        return 0;                           /* Emergency exit */
    }
#endif                                      /* #if defined(_WIN32) */
  if ( !( g_fCreateCrcLog || g_fTestCrcLog ) )
  {
      printf( "ERROR: create or test option must be used.\n" );
      return( ERROR_NO_ACTION );
  }

  if ( g_fCreateCrcLog && g_fTestCrcLog )
  {
      printf( "ERROR: create and test options cannot be used together.\n" );
      return( ERROR_CANNOT_USE_THEM );
  }

  if ( g_fTestCrcLog && (szLogFile[0] == '\0') )
  {
    safe_strncpy( szLogFile, g_szDefLogFile, sizeof(szLogFile) );
  }

  if ( szIncSearchDir[0] == '\0' )
    safe_strncpy( szIncSearchDir, ".", sizeof(szIncSearchDir) );
  if ( szIncSearchMask[0] == '\0' )
  {
     safe_strncpy( szIncSearchMask, "*", sizeof(szIncSearchMask) );
     iTemp = AddFileMask( szIncSearchMask, &g_sIncFileMasks,
                          &g_iIncFilesMask, g_szNoMemForIncFMask );
  }

#if defined(_MSDOS)
  StrUpper( szIncSearchDir );               /* Convert all to uppercase */
  StrUpper( szLogFile );
  StrUpper( szOutResFile );
  StrUpper( szCurDir );
#endif                                      /* #if defined(_MSDOS) */

  if (g_iDebugLevel > 0)
  {
    printf( "Hash size: %s\n", g_szHashSize );
    printf( "Search catalog:  %s\n", &szIncSearchDir[0] );
    printf( "Include masks:  " );
    for(iTemp=0; iTemp < g_iIncFilesMask; iTemp++)
    {
      pTemp = g_sIncFileMasks.sFileMasks[iTemp].pFilesMask;
      if (pTemp != NULL)
        printf( "%s ", (char *)pTemp );
    }/*for*/
    printf( "\nExclude masks:  " );
    for(iTemp=0; iTemp < g_iExcFilesMask; iTemp++)
    {
      pTemp = g_sExcFileMasks.sFileMasks[iTemp].pFilesMask;
      if (pTemp != NULL)
        printf( "%s ", (char *)pTemp );
    }/*for*/
    printf( "\n" );
    printf( "Input file:      %s\n", &szLogFile[0] );
    printf( "Output file:     %s\n", &szOutResFile[0] );
    printf( "Current catalog: %s\n", &szCurDir[0] );
  }

  BuildTableCRC16();                        /* Initialize tables */
  BuildTableCRC32();

/*--------------------------- Searches directory ---------------------------*/

  if ( g_fCreateCrcLog )
  {
    if (!g_fCRC16 && !g_fCRC32 && !g_fMD5 && !g_fSHA1 && !g_fGOSTHASH && !g_fSHA2 && !g_fSHA3 && !g_fGOSTHASH2012)
    {
      printf( "ERROR: you must specify CRC method(s).\n" );
      return( ERROR_NO_CRC_METHOD );
    }

    if (szOutResFile[0] != '\0' )
    {
      LogFile = fopen( szOutResFile, "wt" );
      if (LogFile == NULL )
      {
        printf( "ERROR: cannot create logfile.\n" );
        return( ERROR_LOGFILE_CREAT_FAIL );
      }
      fclose( LogFile );
    }

    ulFoundFiles = ulScanDir( szIncSearchDir, MAX_FILENAME_SIZE+1,
                              &g_sIncFileMasks, &g_sExcFileMasks,
                              g_fRecursiveSearch, szOutResFile, iDirDepth+1 );

    if (g_iDebugLevel > 0)
    {
      printf( "Total found %lu item", ulFoundFiles );
      if (ulFoundFiles != 1)
        printf("s");
      printf("\n");
    }
  }/*if*/

/*--------------------------- Process logfile ------------------------------*/
  if ( g_fTestCrcLog )
  {
    if ( szLogFile[0] == '\0' )
    {
      printf( "ERROR: user logfile name missed.\n" );
      return( ERROR_LOGFILE_NOT_FOUND );
    }

    LogFile = fopen( szLogFile, "rt" );
    if ( LogFile == NULL )
    {
      printf( "ERROR: cannot open logfile.\n" );
      return( ERROR_LOGFILE_OPEN_FAIL );
    }

    if ( szOutResFile[0] != '\0' )
    {
      ResFile = fopen( szOutResFile, "wt" );
      if (ResFile == NULL )
      {
        printf( "ERROR: cannot create output results file.\n" );
        return( ERROR_RESFILE_CREAT_FAIL );
      }
    }
    else
    {
      ResFile = stdout;
    }

    while ( fgets(StrBuf,sizeof(StrBuf), LogFile ) != NULL )
    {
       ulLinesCount++;
       pchs = strchr(StrBuf,QUOTA);
       if (pchs == NULL)
       {
         continue;                          /* Skip this line */
       }
       else
       {
         pchs++;                            /* Skip first delimiter */
         pche = strchr(pchs,QUOTA);         /* Now search second delimiter */
         if (pche == NULL)
         {
           printf( "WARNING: line %ld has wrong format\n", ulLinesCount );
           continue;
         }
         iTemp = (int)(pche-pchs);          /* We got a filename */
         if (iTemp > (int)sizeof(szChkFileName) )
            iTemp = sizeof(szChkFileName) - 1;
         safe_strncpy( szChkFileName, pchs, iTemp+1 );
         szChkFileName[iTemp] = '\0';

         fBadCRC = 0;                       /* Save a filename */
         memset( szTempBuf, 0, sizeof(szTempBuf) );
         safe_strncat( szTempBuf, "\"", sizeof(szTempBuf)-strlen(szTempBuf) );
         safe_strncat( szTempBuf, szChkFileName, sizeof(szTempBuf)-strlen(szTempBuf) );
         safe_strncat( szTempBuf, "\"", sizeof(szTempBuf)-strlen(szTempBuf) );

         if ( iFileExists(szChkFileName) != 0 )
         {
           sprintf( szTempStr, "  %s", g_szNOFILE );
           safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
           fBadCRC = 1;
         }
         else
         {
           pchs = strstr( StrBuf, g_szCRC16 );/* Extract CRC-16 value */
           if (pchs != NULL)
           {
             pchs += strlen( g_szCRC16 );
             iTestCRC16 = (unsigned int)strtoul( pchs, &pche, HEX_RADIX);
             iCalcCRC16 = iGetFileCRC16( szChkFileName );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                    if ( iCalcCRC16 !=  iGetFileCRC16(szChkFileName) )
                        fWrongCRC++;
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if (iCalcCRC16 == iTestCRC16)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szCRC16, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x%04X %s", g_szCRC16, iCalcCRC16, g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }

           pchs = strstr( StrBuf, g_szCRC32 );/* Extract CRC-32 value */
           if (pchs != NULL)
           {
             pchs += strlen( g_szCRC32 );
             ulTestCRC32 = strtoul( pchs, &pche, HEX_RADIX);
             ulCalcCRC32 = ulGetFileCRC32( szChkFileName );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                    if ( ulCalcCRC32 !=  ulGetFileCRC32(szChkFileName) )
                        fWrongCRC++;
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( ulCalcCRC32 == ulTestCRC32 )
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szCRC32, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x%08lX %s", g_szCRC32, ulCalcCRC32,
                          g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }/*if-else*/
             goto done;
           }

           pchs = strstr( StrBuf, g_szMD5 );/* Extract MD5 value */
           if (pchs != NULL)
           {
             memset( &md5sig_test, 0, sizeof(md5sig_test) );
             pchs += strlen( g_szMD5 );
             pchs += strlen( "0x" );
#if _MD5STRSAVE_WORKAROUND
             strncpy( szTempBuf_save, szTempBuf, sizeof(szTempBuf_save) );
	     strncpy( StrBuf_save, StrBuf, sizeof(StrBuf_save) );
#endif                                      /* #if _MD5STRSAVE_WORKAROUND */
             for( i=0; i<DIGEST_BUF_SIZE; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&md5sig_test.md5sig[i] );
               pchs += 2;                   /* Next 2 chars */
             }
#if _MD5STRSAVE_WORKAROUND
             strncpy( szTempBuf, szTempBuf_save, sizeof(szTempBuf) );
	     strncpy( StrBuf, StrBuf_save, sizeof(StrBuf) );
#endif                                      /* #if _MD5STRSAVE_WORKAROUND */
             psignature = GetFileMD5( szChkFileName );
             if (psignature != NULL)
               memcpy( &md5sig_calc, psignature, sizeof(md5sig_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  psignature = GetFileMD5( szChkFileName );
                  if (memcmp(psignature, &md5sig_calc, DIGEST_BUF_SIZE) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&md5sig_test, &md5sig_calc, DIGEST_BUF_SIZE) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szMD5, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szMD5 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<DIGEST_BUF_SIZE; i++ ) {
                   sprintf( szTempStr, "%02X", md5sig_calc.md5sig[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szSHA1 );/* Extract SHA1 value */
           if (pchs != NULL)
           {
             memset( &sha1_hash_test, 0, sizeof(sha1_hash_test) );
             pchs += strlen( g_szSHA1 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA1_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha1_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_sha1_hash = GetFileSHA1( szChkFileName );
             if (p_sha1_hash != NULL)
               memcpy( &sha1_hash_calc, p_sha1_hash, sizeof(sha1_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_sha1_hash = GetFileSHA1( szChkFileName );
                  if (memcmp(p_sha1_hash, &sha1_hash_calc, DIGEST_BUF_SIZE) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha1_hash_test, &sha1_hash_calc, SHA1_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA1, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA1 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA1_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha1_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/


           pchs = strstr( StrBuf, g_szGOSTHASH );/* Extract GOST-HASH value */
           if (pchs != NULL)
           {
             memset( &sha_256_hash_test, 0, sizeof(sha_256_hash_test) );
             pchs += strlen( g_szGOSTHASH );
             pchs += strlen( "0x" );
             for( i=0; i<SHA2_256_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_256_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileGOSTHASH_1994_256( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_256_hash_calc, p_hash, sizeof(sha_256_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileGOSTHASH_1994_256( szChkFileName );
                  if (memcmp(p_hash, &sha_256_hash_calc, SHA2_256_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_256_hash_test, &sha_256_hash_calc, SHA2_256_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA2_256, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szGOSTHASH );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA2_256_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_256_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/


           pchs = strstr( StrBuf, g_szSHA2_224 );/* Extract SHA2-224 value */
           if (pchs != NULL)
           {
             memset( &sha_224_hash_test, 0, sizeof(sha_224_hash_test) );
             pchs += strlen( g_szSHA2_224 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA2_224_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_224_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA2_224( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_224_hash_calc, p_hash, sizeof(sha_224_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA2_224( szChkFileName );
                  if (memcmp(p_hash, &sha_224_hash_calc, SHA2_224_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_224_hash_test, &sha_224_hash_calc, SHA2_224_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA2_224, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA2_224 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA2_224_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_224_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szSHA2_256 );/* Extract SHA2-256 value */
           if (pchs != NULL)
           {
             memset( &sha_256_hash_test, 0, sizeof(sha_256_hash_test) );
             pchs += strlen( g_szSHA2_256 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA2_256_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_256_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA2_256( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_256_hash_calc, p_hash, sizeof(sha_256_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA2_256( szChkFileName );
                  if (memcmp(p_hash, &sha_256_hash_calc, SHA2_256_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_256_hash_test, &sha_256_hash_calc, SHA2_256_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA2_256, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA2_256 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA2_256_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_256_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szSHA2_384 );/* Extract SHA2-384 value */
           if (pchs != NULL)
           {
             memset( &sha_384_hash_test, 0, sizeof(sha_384_hash_test) );
             pchs += strlen( g_szSHA2_384 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA2_384_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_384_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA2_384( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_384_hash_calc, p_hash, sizeof(sha_384_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA2_384( szChkFileName );
                  if (memcmp(p_hash, &sha_384_hash_calc, SHA2_384_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_384_hash_test, &sha_384_hash_calc, SHA2_384_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA2_384, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA2_384 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA2_384_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_384_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szSHA2_512 );/* Extract SHA2-512 value */
           if (pchs != NULL)
           {
             memset( &sha_512_hash_test, 0, sizeof(sha_512_hash_test) );
             pchs += strlen( g_szSHA2_512 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA2_512_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_512_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA2_512( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_512_hash_calc, p_hash, sizeof(sha_512_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA2_512( szChkFileName );
                  if (memcmp(p_hash, &sha_512_hash_calc, SHA2_512_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_512_hash_test, &sha_512_hash_calc, SHA2_512_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA2_512, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA2_512 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA2_512_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_512_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/
                                                   
           pchs = strstr( StrBuf, g_szSHA3_224 );/* Extract SHA3-224 value */
           if (pchs != NULL)
           {
             memset( &sha_224_hash_test, 0, sizeof(sha_224_hash_test) );
             pchs += strlen( g_szSHA3_224 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA3_224_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_224_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA3_224( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_224_hash_calc, p_hash, sizeof(sha_224_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA3_224( szChkFileName );
                  if (memcmp(p_hash, &sha_224_hash_calc, SHA3_224_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_224_hash_test, &sha_224_hash_calc, SHA3_224_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA3_224, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA3_224 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA3_224_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_224_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szSHA3_256 );/* Extract SHA3-256 value */
           if (pchs != NULL)
           {
             memset( &sha_256_hash_test, 0, sizeof(sha_256_hash_test) );
             pchs += strlen( g_szSHA3_256 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA3_256_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_256_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA3_256( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_256_hash_calc, p_hash, sizeof(sha_256_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA3_256( szChkFileName );
                  if (memcmp(p_hash, &sha_256_hash_calc, SHA3_256_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_256_hash_test, &sha_256_hash_calc, SHA3_256_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA3_256, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA3_256 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA3_256_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_256_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szSHA3_384 );/* Extract SHA3-384 value */
           if (pchs != NULL)
           {
             memset( &sha_384_hash_test, 0, sizeof(sha_384_hash_test) );
             pchs += strlen( g_szSHA3_384 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA3_384_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_384_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA3_384( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_384_hash_calc, p_hash, sizeof(sha_384_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA3_384( szChkFileName );
                  if (memcmp(p_hash, &sha_384_hash_calc, SHA3_384_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_384_hash_test, &sha_384_hash_calc, SHA3_384_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA3_384, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA3_384 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA3_384_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_384_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/


           pchs = strstr( StrBuf, g_szSHA3_512 );/* Extract SHA3-512 value */
           if (pchs != NULL)
           {
             memset( &sha_512_hash_test, 0, sizeof(sha_512_hash_test) );
             pchs += strlen( g_szSHA3_512 );
             pchs += strlen( "0x" );
             for( i=0; i<SHA3_512_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_512_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileSHA3_512( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_512_hash_calc, p_hash, sizeof(sha_512_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileSHA3_512( szChkFileName );
                  if (memcmp(p_hash, &sha_512_hash_calc, SHA3_512_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_512_hash_test, &sha_512_hash_calc, SHA3_512_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szSHA3_512, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szSHA3_512 );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<SHA3_512_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_512_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szGOSTHASH2012_256);/* Extract GOSTHASH2012-256 value */
           if (pchs != NULL)
           {
             memset( &sha_256_hash_test, 0, sizeof(sha_256_hash_test) );
             pchs += strlen( g_szGOSTHASH2012_256);
             pchs += strlen( "0x" );
             for( i=0; i<GOSTHASH_2012_256_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_256_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileGOSTHASH_2012_256( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_256_hash_calc, p_hash, sizeof(sha_256_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileGOSTHASH_2012_256( szChkFileName );
                  if (memcmp(p_hash, &sha_256_hash_calc, GOSTHASH_2012_256_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_256_hash_test, &sha_256_hash_calc, GOSTHASH_2012_256_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szGOSTHASH2012_256, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szGOSTHASH2012_256);
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<GOSTHASH_2012_256_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_256_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           pchs = strstr( StrBuf, g_szGOSTHASH2012_512);/* Extract GOSTHASH2012-512 value */
           if (pchs != NULL)
           {
             memset( &sha_512_hash_test, 0, sizeof(sha_512_hash_test) );
             pchs += strlen( g_szGOSTHASH2012_512);
             pchs += strlen( "0x" );
             for( i=0; i<GOSTHASH_2012_512_RESULTLEN; i++ ) {
               sscanf( pchs, "%02X", (unsigned int *)&sha_512_hash_test[i] );
               pchs += 2;                   /* Next 2 chars */
             }
             p_hash = GetFileGOSTHASH_2012_512( szChkFileName );
             if (p_hash != NULL)
               memcpy( &sha_512_hash_calc, p_hash, sizeof(sha_512_hash_calc) );
             fWrongCRC = 0;
             if ( g_iRetryCountCRC > 1 )
             {
                for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++) {
                  p_hash = GetFileGOSTHASH_2012_512( szChkFileName );
                  if (memcmp(p_hash, &sha_512_hash_calc, GOSTHASH_2012_512_RESULTLEN) != 0)
                        fWrongCRC++;
                }
             }
             if (fWrongCRC)
             {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szWrongCRC, sizeof(szTempBuf)-strlen(szTempBuf) );
             }
             else
             {
               if ( memcmp(&sha_512_hash_test, &sha_512_hash_calc, GOSTHASH_2012_512_RESULTLEN) == 0)
               {
                 safe_strncat( szTempBuf, "  ", sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szGOSTHASH2012_512, sizeof(szTempBuf)-strlen(szTempBuf) );
                 safe_strncat( szTempBuf, g_szOK, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
               else
               {
                 fBadCRC = 1;
                 sprintf( szTempStr, "  %s0x", g_szGOSTHASH2012_512);
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 for( i=0; i<GOSTHASH_2012_512_RESULTLEN; i++ ) {
                   sprintf( szTempStr, "%02X", sha_512_hash_calc[i] );
                   safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
                 }
                 sprintf( szTempStr, " %s", g_szBAD );
                 safe_strncat( szTempBuf, szTempStr, sizeof(szTempBuf)-strlen(szTempBuf) );
               }
             }
             goto done;
           }/*if-else*/

           done: {};
         }/*if-else*/

         if ( (szOutResFile[0] != '\0') && (g_fVerbose) )
         {
           printf( "%s\n", szChkFileName );
         }
         if ( !( (g_fPrintBadCRC == 1) && (fBadCRC == 0) ) )
         {
           fprintf( ResFile, "%s\n", szTempBuf );
         }
         if (fBadCRC == 1) 
           prog_exit_code = ERROR_CHECK_FAILED;

       }/*if-else*/
    }/*while*/
    fclose( LogFile );
    if ( szOutResFile[0] != '\0' )
      fclose( ResFile );

    if (g_iDebugLevel > 0)
    {
      printf( "Total found %lu line", ulLinesCount );
      if (ulLinesCount != 1)
        printf("s");
      printf("\n");
    }
  }/*if*/

/*--------------------------- Terminate program  ---------------------------*/

  return prog_exit_code;
}



/*****************************************************************************
 *                             --- ulScanDir ---
 *
 * Purpose: Scan files in directory
 *   Input: char       *dirname    - directory name
 *          int        maxdirlen   - directory name buffer size (max.)
 *          pFileSearchMasks pIncFMasks - include filemasks array
 *          pFileSearchMasks pExcFMasks - exclude filemasks array
 *          int        iSearchDirs - search subdirectories
 *          const char *resfile    - output results file
 *  Output: unsigned long int      - number of matching found files
 * Written: by Dmitry V.Stefankov 10-03-1998
 *****************************************************************************/
unsigned long int  ulScanDir( char *dirname, int maxdirlen,
                              pFileSearchMasks pIncFMasks,
                              pFileSearchMasks pExcFMasks, int iSearchDirs,
                              const char *resfile, int iMaxDirDepth )
{
  unsigned long int  ulFilesCount = 0;      /* Counter */
  char  szTestFName[MAX_FILENAME_SIZE+1];   /* Filename */
  DIR  *dir;                                /* Directory structure */
  struct dirent  *ent;                      /* Directory entry */
  int   fExcThisFile;                       /* Boolean flag */
  int   fIncThisFile;                       /* Boolean flag */
  FILE   *OutputStream;                     /* Output stream */
  unsigned long  int   ulTempCRC32;         /* Temporary value */
  unsigned short int   iTempCRC16;          /* Temporary value */
  int   iIndex;                             /* Index loop */
  int   fWrongCRC;                          /* Wrong CRC found */
  int   maxlen;                             /* Space size */
  md5buf  md5sig;
  pmd5buf  psignature;
  unsigned char * pch;
  unsigned char * p_sha1_hash;
  unsigned char * p_sha2_hash;
  unsigned char * p_sha3_hash;
  unsigned char * p_gost2012_hash;
  unsigned char  sha1_hash[SHA1_RESULTLEN]; /* SHA-1 hash buffer */
  unsigned char  sha2_224_hash[SHA2_224_RESULTLEN]; /* SHA2-224 hash buffer */
  unsigned char  sha2_256_hash[SHA2_256_RESULTLEN]; /* SHA2-256 hash buffer */
  unsigned char  sha2_384_hash[SHA2_384_RESULTLEN]; /* SHA2-384 hash buffer */
  unsigned char  sha2_512_hash[SHA2_512_RESULTLEN]; /* SHA2-512 hash buffer */
  unsigned char  sha3_224_hash[SHA2_224_RESULTLEN]; /* SHA3-224 hash buffer */
  unsigned char  sha3_256_hash[SHA3_256_RESULTLEN]; /* SHA3-256 hash buffer */
  unsigned char  sha3_384_hash[SHA3_384_RESULTLEN]; /* SHA3-384 hash buffer */
  unsigned char  sha3_512_hash[SHA3_512_RESULTLEN]; /* SHA3-512 hash buffer */
  unsigned char  gost2012_256_hash[GOSTHASH_2012_256_RESULTLEN]; /* GOST 34.11-2012 hash buffer */
  unsigned char  gost2012_512_hash[GOSTHASH_2012_512_RESULTLEN]; /* GOST 34.11-2012 hash buffer */


/*------------------------ Process directory name --------------------------*/
  iMaxDirDepth++;
  if (g_iDebugLevel) {
     printf( "iMaxDirDepth=%d, g_iDirectoryDepth=%d\n", iMaxDirDepth, g_iDirectoryDepth );
  }
  if (g_iDirectoryDepth > 0) {
     if (iMaxDirDepth > g_iDirectoryDepth) {
       printf( "%s\n", dirname );
       return ulFilesCount;
     }
  }
  maxlen = strlen(dirname);
#if _WIN32
  if ( dirname[maxlen-1] != '\\' )
    safe_strncat( dirname, "\\", maxdirlen );
#else
  if ( dirname[maxlen-1] != '/' )
    safe_strncat( dirname, "/", maxdirlen );
#endif                                      /* #if defined(_WIN32) */

/*---------------------------- Open directory  -----------------------------*/
  if ((dir = opendir(dirname)) == NULL)
  {
    printf( "ERROR: Unable to open directory.\n" );
    return 0;                               /* Emergency exit */
  }

/*---------------------- Process directory entries -------------------------*/
  while ((ent = readdir(dir)) != NULL)
  {
    if ( strcmp(ent->d_name,".") && strcmp(ent->d_name,"..") )
    {
      safe_strncpy( szTestFName, dirname, sizeof(szTestFName)-strlen(szTestFName) );
      safe_strncat( szTestFName, ent->d_name, sizeof(szTestFName)-strlen(szTestFName) );
      if (g_iDebugLevel > 0)
      {
        printf( "Test Item: %s\n", szTestFName );
      }
      if ( iTestDir(szTestFName) == 1 )     /* Catalog or file? */
      {
        fExcThisFile = iTestForFileMask( ent->d_name, pExcFMasks,
                                         g_iExcFilesMask );
        if ( !fExcThisFile )
        {
          fIncThisFile = iTestForFileMask( ent->d_name, pIncFMasks,
                                           g_iIncFilesMask );
          if ( fIncThisFile )
          {
            if ( iFileExists(szTestFName) != 0 )
            {
              continue;                     /* File not found */
            }
            if (strcmp(resfile, ent->d_name) != 0)
            {                               /* Write to logfile */
              if ( *resfile == '\0' )
                OutputStream = stdout;
              else
                OutputStream = fopen( resfile, "at" );
              if (OutputStream != NULL )
              {
                fprintf( OutputStream, "%c%s%c", '"', szTestFName, '"' );
                
                if (g_fCRC16)
                {
                  fWrongCRC = 0;
                  iTempCRC16 = iGetFileCRC16( szTestFName );
                  if ( g_iRetryCountCRC > 1 )
                  {
                     for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                       if ( iTempCRC16 != iGetFileCRC16(szTestFName) )
                         fWrongCRC++;
                  }
                  if (fWrongCRC)
                    fprintf( OutputStream, "  %s", g_szWrongCRC );
                  else
                    fprintf( OutputStream, "  %s0x%04X", g_szCRC16, iTempCRC16 );
                }

                if (g_fCRC32)
                {
                  fWrongCRC = 0; 
                  ulTempCRC32 = ulGetFileCRC32( szTestFName );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( ulTempCRC32 != ulGetFileCRC32(szTestFName) )
                        fWrongCRC++;
                  }
                  if (fWrongCRC)
                    fprintf(OutputStream, " %s", g_szWrongCRC );
                  else
                    fprintf( OutputStream, "  %s0x%08lX", g_szCRC32, ulTempCRC32 );
                }

                if (g_fMD5)  {
                  fWrongCRC = 0; 
                  psignature = GetFileMD5( szTestFName );
                  if (psignature != NULL)
                    memcpy( &md5sig, psignature, sizeof(md5sig) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( psignature, GetFileMD5(szTestFName),
                           sizeof(md5sig)) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szMD5 );
                     pch = (unsigned char *)psignature;     
                     for(iIndex = 0; iIndex < DIGEST_BUF_SIZE; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA1)  {
                  fWrongCRC = 0; 
                  p_sha1_hash = GetFileSHA1( szTestFName );
                  if (p_sha1_hash != NULL)
                    memcpy( &sha1_hash, p_sha1_hash, sizeof(sha1_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha1_hash, GetFileSHA1(szTestFName),
                           SHA1_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA1 );
                     pch = (unsigned char *)sha1_hash;
                     for(iIndex = 0; iIndex < SHA1_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA2 && (g_iHashBitsSize == HASH_BITS_SIZE_224))  {
                  fWrongCRC = 0; 
                  p_sha2_hash = GetFileSHA2_224( szTestFName );
                  if (p_sha2_hash != NULL)
                    memcpy( &sha2_224_hash, p_sha2_hash, sizeof(sha2_224_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha2_hash, GetFileSHA2_224(szTestFName),
                           SHA2_224_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA2_224 );
                     pch = (unsigned char *)sha2_224_hash;
                     for(iIndex = 0; iIndex < SHA2_224_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA2 && (g_iHashBitsSize == HASH_BITS_SIZE_256))  {
                  fWrongCRC = 0; 
                  p_sha2_hash = GetFileSHA2_256( szTestFName );
                  if (p_sha2_hash != NULL)
                    memcpy( &sha2_256_hash, p_sha2_hash, sizeof(sha2_256_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha2_hash, GetFileSHA2_256(szTestFName),
                           SHA2_256_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA2_256 );
                     pch = (unsigned char *)sha2_256_hash;
                     for(iIndex = 0; iIndex < SHA2_256_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA2 && (g_iHashBitsSize == HASH_BITS_SIZE_384))  {
                  fWrongCRC = 0; 
                  p_sha2_hash = GetFileSHA2_384( szTestFName );
                  if (p_sha2_hash != NULL)
                    memcpy( &sha2_384_hash, p_sha2_hash, sizeof(sha2_384_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha2_hash, GetFileSHA2_384(szTestFName),
                           SHA2_384_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA2_384 );
                     pch = (unsigned char *)sha2_384_hash;
                     for(iIndex = 0; iIndex < SHA2_384_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA2 && (g_iHashBitsSize == HASH_BITS_SIZE_512))  {
                  fWrongCRC = 0; 
                  p_sha2_hash = GetFileSHA2_512( szTestFName );
                  if (p_sha2_hash != NULL)
                    memcpy( &sha2_512_hash, p_sha2_hash, sizeof(sha2_512_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha2_hash, GetFileSHA2_512(szTestFName),
                           SHA2_512_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA2_512 );
                     pch = (unsigned char *)sha2_512_hash;
                     for(iIndex = 0; iIndex < SHA2_512_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA3 && (g_iHashBitsSize == HASH_BITS_SIZE_224))  {
                  fWrongCRC = 0; 
                  p_sha3_hash = GetFileSHA3_224( szTestFName );
                  if (p_sha3_hash != NULL)
                    memcpy( &sha3_224_hash, p_sha3_hash, sizeof(sha3_224_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha3_hash, GetFileSHA3_224(szTestFName),
                           SHA3_224_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA3_224 );
                     pch = (unsigned char *)sha3_224_hash;
                     for(iIndex = 0; iIndex < SHA3_224_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA3 && (g_iHashBitsSize == HASH_BITS_SIZE_256))  {
                  fWrongCRC = 0; 
                  p_sha3_hash = GetFileSHA3_256( szTestFName );
                  if (p_sha3_hash != NULL)
                    memcpy( &sha3_256_hash, p_sha3_hash, sizeof(sha3_256_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha3_hash, GetFileSHA3_256(szTestFName),
                           SHA3_256_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA3_256 );
                     pch = (unsigned char *)sha3_256_hash;
                     for(iIndex = 0; iIndex < SHA3_256_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA3 && (g_iHashBitsSize == HASH_BITS_SIZE_384))  {
                  fWrongCRC = 0; 
                  p_sha3_hash = GetFileSHA3_384( szTestFName );
                  if (p_sha3_hash != NULL)
                    memcpy( &sha3_384_hash, p_sha3_hash, sizeof(sha3_384_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha3_hash, GetFileSHA3_384(szTestFName),
                           SHA3_384_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA3_384 );
                     pch = (unsigned char *)sha3_384_hash;
                     for(iIndex = 0; iIndex < SHA3_384_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fSHA3 && (g_iHashBitsSize == HASH_BITS_SIZE_512))  {
                  fWrongCRC = 0; 
                  p_sha3_hash = GetFileSHA3_512( szTestFName );
                  if (p_sha3_hash != NULL)
                    memcpy( &sha3_512_hash, p_sha3_hash, sizeof(sha3_512_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_sha3_hash, GetFileSHA3_512(szTestFName),
                           SHA3_512_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szSHA3_512 );
                     pch = (unsigned char *)sha3_512_hash;
                     for(iIndex = 0; iIndex < SHA3_512_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fGOSTHASH)  {
                  fWrongCRC = 0; 
                  p_gost2012_hash = GetFileGOSTHASH_1994_256( szTestFName );
                  if (p_gost2012_hash != NULL)
                    memcpy( &gost2012_256_hash, p_gost2012_hash, sizeof(gost2012_256_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_gost2012_hash, GetFileGOSTHASH_1994_256(szTestFName),
                           GOSTHASH_1994_256_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szGOSTHASH );
                     pch = (unsigned char *)gost2012_256_hash;
                     for(iIndex = 0; iIndex < GOSTHASH_1994_256_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fGOSTHASH2012 && (g_iHashBitsSize == HASH_BITS_SIZE_256))  {
                  fWrongCRC = 0; 
                  p_gost2012_hash = GetFileGOSTHASH_2012_256( szTestFName );
                  if (p_gost2012_hash != NULL)
                    memcpy( &gost2012_256_hash, p_gost2012_hash, sizeof(gost2012_256_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_gost2012_hash, GetFileGOSTHASH_2012_256(szTestFName),
                           GOSTHASH_2012_256_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szGOSTHASH2012_256 );
                     pch = (unsigned char *)gost2012_256_hash;
                     for(iIndex = 0; iIndex < GOSTHASH_2012_256_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }

                if (g_fGOSTHASH2012 && (g_iHashBitsSize == HASH_BITS_SIZE_512))  {
                  fWrongCRC = 0; 
                  p_gost2012_hash = GetFileGOSTHASH_2012_512( szTestFName );
                  if (p_gost2012_hash != NULL)
                    memcpy( &gost2012_512_hash, p_gost2012_hash, sizeof(gost2012_512_hash) );
                  if ( g_iRetryCountCRC > 1 )
                  {
                    for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                      if ( memcmp( p_gost2012_hash, GetFileGOSTHASH_2012_512(szTestFName),
                           GOSTHASH_2012_512_RESULTLEN) != 0 )
                        fWrongCRC++;
                  }                   
                  if (fWrongCRC) {
                     fprintf(OutputStream, " %s", g_szWrongCRC );
                  }
                  else {
                     fprintf( OutputStream, "  %s0x", g_szGOSTHASH2012_512 );
                     pch = (unsigned char *)gost2012_512_hash;
                     for(iIndex = 0; iIndex < GOSTHASH_2012_512_RESULTLEN; iIndex++) {
                       fprintf( OutputStream, "%02X", *pch++ );
                     }
                  }
                }
                
                fprintf( OutputStream, "\n" );
                   if ( *resfile != '\0' )
                      fclose( OutputStream );
                if ( (g_fVerbose) && (*resfile != '\0') )
                    printf( "%s\n", szTestFName );
              }/*if*/
            }/*if*/
            ++ulFilesCount;
          }
        }
      }
      else {
        if (iSearchDirs) { /* Have we look more? */
                 if (g_iDebugLevel) {
                    //iMaxDirDepth++;
                    printf( "iMaxDirDepth=%d, g_iDirectoryDepth=%d\n", iMaxDirDepth, g_iDirectoryDepth );
                    //printf( "iMaxDirDepth=%d\n", iMaxDirDepth );
                 }
                 if (g_iDirectoryDepth > 0) {
                    //if (iMaxDirDepth+1 > g_iDirectoryDepth) goto dir_done;
                 }
                 ulFilesCount += ulScanDir( szTestFName, maxdirlen,
                            pIncFMasks, pExcFMasks, iSearchDirs, resfile, iMaxDirDepth );
        }
      }/*if-else*/
    }/*if*/
  }/*while*/

/*------------------------ Close a directory--------------------------------*/
  if ( closedir(dir) != 0 )
      printf( "ERROR: Unable to close directory.\n" );

  return( ulFilesCount );
}



/*****************************************************************************
 *                            --- iTestDir ---
 *
 * Purpose: Tests for the valid directory name
 *   Input: char *dirname - directory name to test
 *  Output: int           - 0 this is directory
 *                          1 thie is not directory
 * Written: by Dmitry V.Stefankov 10-03-1998
 *****************************************************************************/
int  iTestDir( char *dirname )
{
  DIR   *dir;                               /* Directory structure */

  if ( (dir = opendir(dirname)) == NULL )
  {
      return(1);                            /* This is not directory */
  }
  if ( closedir(dir) != 0 )
      printf( "ERROR: Unable to close directory during testing.\n" );
  return(0);                                /* Yes, directory found. */
}



/*****************************************************************************
 *                          --- iTestPattern ---
 *
 * Purpose: Tests a string for matching pattern
 *   Input: const char * szName    - testing string
 *          const char * szPattern - testing pattern (wildcards allowed)
 *  Output: int                    - 0 mismatched string
 *                                   any other matching string
 * Written: by Dmitry V.Stefankov 10-03-1998
 *****************************************************************************/
int  iTestPattern( const char * szName, const char * szPattern )
{
    int iRetcode = 0;                       /* Default = string mismatch */
    int iMatch;                             /* Matching character */
    char chLeft;                            /* Test character from left */
    char chRight;                           /* Test character from right */

    if ( (szName == NULL) || (szPattern == NULL) )
      return iRetcode;                      /* Empty strings not allowed! */

    switch ( *szPattern )                   /* Current pattern symbol */
    {
      case '*':                             /* Any string */
        szPattern++;
        do {
            iRetcode = iTestPattern( szName, szPattern );
        } while (!iRetcode && *szName++);
        break;
      case '?':                             /* Any character */
        if ( *szName )
          iRetcode = iTestPattern( ++szName, ++szPattern );
        break;
      case '\0':                            /* End of pattern */
        iRetcode = !strlen(szName);
        break;
      default:                              /* Any other character */
        chLeft  = *szName;
        chRight = *szPattern;
        if ( (g_fIgnoreCaseInFilenames) && isalpha(chLeft)
               && isalpha(chRight) )
          iMatch = ( tolower(chLeft) == tolower(chRight) );
        else
          iMatch = (chLeft == chRight);
          if ( iMatch )
            iRetcode = iTestPattern( ++szName, ++szPattern );
        break;
    }
    return( iRetcode );
}



/*****************************************************************************
 *                         --- iTestForFileMask ---
 *
 * Purpose: Test filename for match filemasks
 *   Input: char           *filename - file name
 *          pFileSearchMasks pFMasks - filemasks array
 *          int         iFMasksCount - filemasks array dimension
 *  Output: int                      - 0 matching not found
 *                                     1 matching found
 * Written: by Dmitry V.Stefankov 03-28-1999
 *****************************************************************************/
int  iTestForFileMask( char *filename, pFileSearchMasks pFMasks,
                       int iFMasksCount )
{
  int           iRetCode = 0;               /* Default = matching not found */
  int           iTemp;                      /* Temporary index */
  char         *pTemp;                      /* Temporary string */

  if ( (iFMasksCount) && (pFMasks != NULL) && (filename != NULL) )
  {
    for(iTemp=0; iTemp<iFMasksCount; iTemp++)
    {
      pTemp = pFMasks->sFileMasks[iTemp].pFilesMask;
      if (pTemp != NULL)
      {
        iRetCode = iTestPattern( filename, pTemp );
        if (iRetCode)
          break;                            /* Stop looking */
      }
    }/*for*/
  }/*if*/

  return( iRetCode );
}



/*****************************************************************************
 *                         --- AddFileMask ---
 *
 * Purpose: Add filemask to filemasks array
 *   Input: const char *  pszAddMask - filemask to add to array
 *          pFileSearchMasks pFMasks - filemasks array
 *          int         iFMasksCount - filemasks array dimension
 *          const char *   pszErrMsg - error message
 *  Output: int                      - 0 success
 *                                     1 failure
 * Written: by Dmitry V.Stefankov 03-28-1999
 *****************************************************************************/
int  AddFileMask( const char * pszAddMask, pFileSearchMasks pFMasks,
                  int * piFMasksCount, const char * pszErrMsg )
{
  int           iRetCode = 1;               /* Default = fail */
  char          * pTemp;                    /* Temporary string */

  if ( (*piFMasksCount < FMASKS_MAX) && (pFMasks != NULL) &&
       (pszAddMask != NULL) )
  {
     pTemp = (char *)malloc( strlen(pszAddMask)+1 );
     if (pTemp != NULL)
     {
       safe_strncpy( pTemp, pszAddMask, strlen(pszAddMask)+1 );
       pFMasks->sFileMasks[*piFMasksCount].pFilesMask = pTemp;
       (*piFMasksCount)++;
       iRetCode = 0;
     }
     else
     {
       if (pszErrMsg)
         printf( "%s\n", pszErrMsg );
     }/*if-else*/
  }/*if*/

  return( iRetCode );
}



#if defined(_MSDOS)
/*****************************************************************************
 *                            --- StrUpper ---
 *
 * Purpose: Converts string to uppercase
 *   Input: char  *pstr - input string (pointer)
 *  Output: char *      - output string (pointer)
 * Written: by Dmitry V.Stefankov 10-03-1998
 *****************************************************************************/
char *StrUpper( char *pstr )
{
   char  *pTemp = pstr;                     /* Temporary */

   if ( pTemp != NULL )
   {
       do {
           *pTemp = toupper( (int)*pTemp );
           pTemp++;
       } while ( *pTemp != '\0' );
   }
   return( pstr );
}
#endif                                      /* #if defined(_MSDOS) */



/*****************************************************************************
 *                         --- BuildTableCRC32 ---
 *
 * Purpose: Builds a global CRC-32 table
 *   Input: none
 *  Output: none
 * Written: by Dmitry V.Stefankov 10-05-1998
 *   Note:  CRC-32 computation is used a polynomial
 *(forward) X^31+X^30+X^29+X^27+X^26+X^24+X^23+X^21+X^20+X^19+X^15+X^9+X^8+X^5+X^0
 *(backward)X^32+X^26+X^23+X^22+X^16+X^12+X^11+X^10+X^8+X^7+X^5+X^4+X^2+X^1+X^0
 *****************************************************************************/
void  BuildTableCRC32( void )
{
   int  i;                                  /* Byte index */
   int  j;                                  /* Bit index */
   unsigned long int crc;                   /* Temporary */

   for(i = 0; i < MAX_CRC_TABLE_SIZE; i++)
   {
      crc = i;
      for(j = BITS_PER_BYTE; j > 0; j--)
      {
          if ( crc & 1 )
             crc = (crc >> 1)^CRC32_POLYNOMIAL;
           else
             crc >>=1;
       }
     g_TableCRC32[i]  = crc;
   }
}



/*****************************************************************************
 *                         --- ulGetFileCRC32 ---
 *
 * Purpose: Calculate the CRC-32 value for specified file
 *   Input: char    *szFileName - filename
 *  Output: unsigned long int   - calculated CRC-32 value for file
 * Written: by Dmitry V.Stefankov 10-05-1998
 *****************************************************************************/
unsigned long int ulGetFileCRC32( char *szFileName )
{
   FILE                *crcfile;            /* File stream */
   unsigned long int   crc = 0xFFFFFFFFL;   /* CRC sum */
#if _WIN32 && !defined(_MINGW32)
   unsigned __int64    filelen;             /* File size */
   unsigned __int64    readbytes = 0;       /* Read bytes count */
#else   
   __uint64_t          filelen;             /* File size */
   __uint64_t          readbytes = 0;       /* Read bytes count */
#endif   
   int                 count = 0;           /* Byte count */
   unsigned char       buffer[MAX_FILEBUF_SIZE]; /* Working buffer */

   if ( (crcfile = fopen(szFileName,"rb") ) == NULL )
   {
     return 0;
   }
   else
   {
#if _WIN32 && !defined(_MINGW32)
     _fseeki64( crcfile, 0, SEEK_END );
     filelen = _ftelli64( crcfile );
     _fseeki64( crcfile, 0, SEEK_SET );
#else   
     fseek( crcfile, 0L, SEEK_END );
     filelen = ftell( crcfile );
     fseek( crcfile, 0L, SEEK_SET );
#endif   
     //printf( "\nfilelen=%lu\n",filelen );
     while ( (count = fread(buffer, 1, MAX_FILEBUF_SIZE, crcfile)) != 0)
     {
         crc = ulCalcBufCRC32( count, crc, buffer );
         readbytes += count;
     }
     //printf( "readbytes=%lu\n",readbytes );
     if (readbytes != filelen)
     {
        printf("ERROR: cannot read file %s\n", szFileName );
        crc = 0;
     }
     fclose( crcfile );
   }/*if-else*/
   return( crc ^= 0xFFFFFFFFL );
}



/*****************************************************************************
 *                         --- ulCalcBufCRC32 ---
 *
 * Purpose: Calculate CRC-32 value for memory buffer
 *   Input: unsigned int    count  -  size of buffer
 *          unsigned long int crc  -  initial CRC-32 value
 *          unsigned char *pbuf    -  pointer to buffer
 *  Output: unsigned long int      -  calculated CRC-32 value
 * Written: by Dmitry V.Stefankov 10-05-1998
 *****************************************************************************/
unsigned long int  ulCalcBufCRC32( unsigned int count,
                                   unsigned long int crc,
                                   unsigned char *pbuf )
{
   if ( (pbuf == NULL) || (count == 0) )  /* Check for empty buffer */
     return 0;

   while( count-- )
     crc = ( (crc >> 8) & 0x00FFFFFFL) ^
           g_TableCRC32[ ( (int) crc ^ *pbuf++) & 0xFF];

   return crc;
}



/*****************************************************************************
 *                         --- BuildTableCRC16 ---
 *
 * Purpose: Builds a global CRC-16 table
 *   Input: none
 *  Output: none
 * Written: by Dmitry V.Stefankov 10-05-1998
 *   Note:  CRC-16 computation is used a polynomial X**16+X**15+X**2+1
 *****************************************************************************/
void  BuildTableCRC16( void )
{
   int  i;                                  /* Byte index */
   int  j;                                  /* Bit index */
   unsigned int crc;                        /* Temporary */
   unsigned int val;                        /* Temporary */

   for(i = 0; i < MAX_CRC_TABLE_SIZE; i++)
   {
     crc = 0;
     val = (i << 8);
     for(j=BITS_PER_BYTE; j > 0; j--)
     {
        if ( (val ^ crc) & 0x8000)
           crc = (crc << 1) ^ CRC16_POLYNOMIAL;
        else
           crc <<= 1;
        val <<= 1;
     }
     g_TableCRC16[i]  = crc;
   }
}



/*****************************************************************************
 *                         --- iGetFileCRC16 ---
 *
 * Purpose: Calculate the CRC-16 value for specified file
 *   Input: char    *szFileName - filename
 *  Output: unsigned long int   - calculated CRC-16 value for file
 * Written: by Dmitry V.Stefankov 10-05-1998
 *****************************************************************************/
unsigned int iGetFileCRC16( char *szFileName )
{
   FILE                *crcfile;            /* File stream */
   unsigned int        crc = 0;             /* CRC sum */
   //unsigned long int   filelen;             /* File size */
   //unsigned long int   readbytes = 0;       /* Read bytes count */
#if _WIN32 && !defined(_MINGW32)
   unsigned __int64    filelen;             /* File size */
   unsigned __int64    readbytes = 0;       /* Read bytes count */
#else   
   __uint64_t          filelen;             /* File size */
   __uint64_t          readbytes = 0;       /* Read bytes count */
#endif   
   int                 count = 0;           /* Byte count for one reading */
   unsigned char       buffer[MAX_FILEBUF_SIZE]; /* Working buffer */

   if ( (crcfile = fopen(szFileName,"rb") ) == NULL )
   {
     return 0;
   }
   else
   {
     //fseek( crcfile, 0L, SEEK_END );
     //filelen = ftell( crcfile );
     //fseek( crcfile, 0L, SEEK_SET );
#if _WIN32 && !defined(_MINGW32)
     _fseeki64( crcfile, 0, SEEK_END );
     filelen = _ftelli64( crcfile );
     _fseeki64( crcfile, 0, SEEK_SET );
#else   
     fseek( crcfile, 0L, SEEK_END );
     filelen = ftell( crcfile );
     fseek( crcfile, 0L, SEEK_SET );
#endif   
     while ( (count = fread(buffer, 1, MAX_FILEBUF_SIZE, crcfile)) != 0)
     {
         crc = iCalcBufCRC16( count, crc, buffer );
         readbytes += count;
     }
     if (readbytes != filelen)
     {
        printf("ERROR: cannot read file %s\n", szFileName );
        crc = 0;
     }
     fclose( crcfile );
   }/*if-else*/
   return( crc );
}



/*****************************************************************************
 *                         --- iCalcBufCRC16 ---
 *
 * Purpose: Calculate CRC-16 value for memory buffer
 *   Input: unsigned int    count  -  size of buffer
 *          unsigned int      crc  -  initial CRC-16 value
 *          unsigned char *buffer  -  pointer to buffer
 *  Output: unsigned int           -  calculated CRC-16 value
 * Written: by Dmitry V.Stefankov 10-05-1998
 *****************************************************************************/
unsigned int iCalcBufCRC16( unsigned int count, unsigned int crc,
                            unsigned char *pbuf )
{
   if ( (pbuf == NULL) || (count == 0) )  /* Check for empty buffer */
     return 0;

   while( count-- != 0)
      crc = (crc << 8) ^ g_TableCRC16[ ( (crc >> 8)^ *pbuf++) & 0xFF ];

   return crc;
}



/*****************************************************************************
 *                         --- iFileExists ---
 *
 * Purpose: Check that file exists
 *   Input: char  * szName    - filename
 *  Output: int               - 0 file found
 *                              any other indicates error
 * Written: by Dmitry V.Stefankov 10-11-1998
 *****************************************************************************/
int   iFileExists( const char * szName )
{
  FILE  *filestream;                        /* File stream */

  if ( (filestream = fopen(szName,"rb") ) == NULL )
    return 1;
  else
    fclose( filestream );
  return 0;
}



/*****************************************************************************
 *                          --- safe_strncpy ---
 *
 * Purpose: Make a safe copy of one string to another
 *   Input: char       *dest - destination buffer (string)
 *          const char *src  - source string
 *          size_t     n     - maximum size of destination buffer (string)
 *  Output: char *           - destination string
 * Written: by Dmitry V.Stefankov 06-Jan-2000
 ****************************************************************************/
char *  safe_strncpy ( char *dest, const char *src, size_t n )
{
    char          * s;                      /* Temporary  */

    for( s = dest; 0 < (n-1) && *src!= '\0'; --n )
         *s++ = *src++;                     /* Copy at most n-1 chars */

    for( ; 0 < n; --n )
         *s++ = '\0';                       /* Padding */

    return( dest );
}



/*****************************************************************************
 *                          --- safe_strncat ---
 *
 * Purpose: Make a safe concatenation of two strings
 *   Input: char       *dest - destination buffer (string)
 *          const char *src  - source string
 *          size_t     n     - maximum size of destination buffer (string)
 *  Output: char *           - destination string
 * Written: by Dmitry V.Stefankov 06-Jan-2000
 ****************************************************************************/
char *  safe_strncat( char *dest, const char *src, size_t n )
{
    char          * s;                      /* Temporary  */

    for( s = dest; *s != '\0'; ++s)         /* Find end of dest */
        ;

    for( ; 0 < (n-1) && *src != '\0'; --n )
        *s++ = *src++;                      /* Copy at most n-1 chars */

    *s = '\0';

    return( dest );
}



#if (defined(_WIN32) || defined(_MSVC))
/*****************************************************************************
 *                         --- opendir ---
 *
 * Purpose: open a directory stream
 *   Input: char  * dirname     - directory name
 *  Output: DIR *               - directory structure (POSIX.1)
 * Written: by Dmitry V.Stefankov 10-07-1998
 *****************************************************************************/
DIR *  opendir( char  * dirname )
{
   char    *name;                           /* Copy of directory name */
   DIR     *dir;                            /* Directory structure */
   int     len;                             /* Temporary */
   int     maxlen;                          /* Space size */

   /*
    * Allocate space for a copy of the directory name, plus
    * room for the "*.*" we will concatenate to the end.
    */

   len = strlen(dirname);
   maxlen = len+5-1;
   if ((name = (char *)malloc(maxlen+1)) == NULL)
   {
      errno = ENOMEM;
      return (NULL);
   }

   safe_strncpy( name, dirname, maxlen+1 );
   if (len-- && name[len] != ':' && name[len] != '\\' && name[len] != '/')
#if defined(_MSVC)
      safe_strncat( name, "\\*.*", maxlen+1 );
   else
      safe_strncat( name, "*.*", maxlen+1 );
#else
      safe_strncat( name, "\\*", maxlen+1 );
   else
      safe_strncat( name, "*", maxlen+1 ) ;
#endif                                      /* #if defined(_MSVC) */
											/* Allocate space for a DIR structure */
   if ((dir = (DIR *)malloc(sizeof(DIR))) == NULL) 
   {
       errno = ENOMEM;
       free(name);
       return (NULL);
   }

#if defined(_MSVC)
    /* Search for the first file to see if the directory exists,
     * and to set up the DTA for future _dos_findnext() calls.
     */
    if (_dos_findfirst(name, _A_HIDDEN|_A_SYSTEM|_A_RDONLY|_A_SUBDIR,
                (struct find_t *)&dir->_d_reserved) != 0)
#else                                       /* Search for first entry */
   dir->fileHandle = FindFirstFile( name, &dir->findData );
   if ( dir->fileHandle == INVALID_HANDLE_VALUE )
#endif                                      /* #if defined(_MSVC) */
   {
#if !defined(_MSVC)
      errno = ENOENT;                       /* I no hope that FindFirstFile */
#endif                                      /* #if !defined(_MSVC) */
      free(name);                           /* sets errno for us */
      free(dir);
      return (NULL);
   }
   /*
    * Everything is OK.  Save information in the DIR structure, return it.
    */
   dir->d_dirname = name;
   dir->d_first = 1;
   dir->d_magic = DIRMAGIC;
#if !defined(_MSVC)
   safe_strncpy( dir->d_dirent.d_name, dir->findData.cFileName, sizeof(dir->d_dirent.d_name) );
                                            /* Make a copy */
#endif                                      /* #if !defined(_MSVC) */
   return dir;
}



/*****************************************************************************
 *                         --- readdir ---
 *
 * Purpose: read directory entry from a directory stream
 *   Input: DIR *            - directory structure (POSIX.1)
 *  Output: struct dirent *  - pointer to directory entry (POSIX.1)
 * Written: by Dmitry V.Stefankov 10-07-1998
 *****************************************************************************/
struct dirent *  readdir( DIR  *dir )
{

   if (dir->d_magic != DIRMAGIC)            /* Verify the handle.*/
   {
      errno = EBADF;                        /* Bad handle */
      return (NULL);
   }

   /*
    * If this isn't the first file, call findnextfile(...) to get the next
    * directory entry.  Opendir() fetches the first one.
    */
   if (!dir->d_first)
   {
#if defined(_MSVC)
      if (_dos_findnext((struct find_t *)&dir->_d_reserved) != 0)
#else
      if ( !FindNextFile(dir->fileHandle, &dir->findData) )
#endif                                      /* #if defined(_MSVC) */
         return NULL;
#if !defined(_MSVC)
      safe_strncpy( dir->d_dirent.d_name, dir->findData.cFileName, sizeof(dir->d_dirent.d_name) );
#endif                                      /* #if !defined(_MSVC) */
   }

   dir->d_first = 0;                        /* Clear first call flag */
   return( &dir->d_dirent );                /* Just return a first element copy */
}



/*****************************************************************************
 *                         --- closedir ---
 *
 * Purpose: close directory stream
 *   Input: DIR *   - directory structure (POSIX.1)
 *  Output: int     - 0   successful
 *                    -1  bad directory structure
 * Written: by Dmitry V.Stefankov 10-07-1998
 *****************************************************************************/
int  closedir (DIR  *dir)
{
    if (dir == NULL || dir->d_magic != DIRMAGIC)
    {                                       /* Wrong structure on entry */
       errno = EBADF;
       return(-1);
    }

    dir->d_magic = 0;                       /* Prevent use after closing */
#if !defined(_MSVC)
    FindClose( dir->fileHandle );           /* Clean up Win32 space */
#endif                                      /* #if !defined(_MSVC) */
    free(dir->d_dirname);
    free(dir);
    return 0;
}
#endif                                      /* #if defined(_WIN32) */



