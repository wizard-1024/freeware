/*****************************************************************************
 *                             File LISTDIR7.C
 *
 *            List files in directory  (multi-platform version)
 *
 *   Copyright (c) Dmitry V. Stefankov, 1998-2019. All rights reserved.
 *
 *       This software is distributed under GPL agreement
 *       (See copying file for details).
 *
 *****************************************************************************/
/*
 *   $Source: /usr/local/src/projects/freeware/listdir2/RCS/listdir2.c,v $
 *  $RCSfile: listdir2.c,v $
 *   $Author: dstef $
 *     $Date: 2008-09-14 00:46:28+04 $
 * $Revision: 1.1 $
 *   $Locker: root $
 *
 *      $Log: listdir2.c,v $
 *      Revision 1.1  2008-09-14 00:46:28+04  dstef
 *      Initial revision
 *
 *      Revision 1.24  2000/01/22 03:06:18  dstef
 *      Removed _BEOS target
 *
 *      Revision 1.23  2000/01/21 22:53:09  dstef
 *      Added support for new targets
 *
 *      Revision 1.22  2000/01/06 22:48:30  dstef
 *      Added new safe functions strncpy and strncat
 *      Updated version and copyright notice
 *
 *      Revision 1.21  1999/12/31 20:17:40  dstef
 *      Increased buffer size for string operations
 *
 *      Revision 1.20  1999/12/31 18:04:25  dstef
 *      Switched to safe coding style (strncat,strncpy)
 *
 *      Revision 1.19  1999/12/30 22:38:57  dstef
 *      Minor changes
 *
 *      Revision 1.18  1999/12/30 22:37:33  dstef
 *      Added DJGPP compiler support
 *      Added target platform checking
 *
 *      Revision 1.17  1999/03/28 17:43:23  dstef
 *      Changed MASKS_MAX to FMASKS_MAX
 *
 *      Revision 1.16  1999/03/28 15:27:23  dstef
 *      Fixed Y2K problem
 *      Improve filemasks array additions
 *
 *      Revision 1.15  1999/03/28 14:48:00  dstef
 *      More simple code for filemasks
 *
 *      Revision 1.14  1999/03/28 04:31:12  dstef
 *      Added filemasks array instead single filemask
 *
 *      Revision 1.13  1999/03/09 12:44:53  dstef
 *      Added ignorecase in filenames switch
 *
 *      Revision 1.11  1998/11/17 12:36:37  dstef
 *      Minor changes of program header and help
 *
 *      Revision 1.10  1998/11/17 12:05:00  dstef
 *      Updated program description
 *
 *      Revision 1.9  1998/11/17 11:59:26  dstef
 *      Changed order of arguments processing
 *      Updated compile instructions for MS-DOS
 *
 *      Revision 1.8  1998/11/17 11:38:16  dstef
 *      Put under GPL agreement
 *      Updated program help
 *      Changed program version
 *      Updated compile instructions
 *
 *      Revision 1.7  1998/11/04 12:48:28  dstef
 *      Fixed UNIX command line parsing
 *
 *      Revision 1.6  1998/11/02 00:23:47  dstef
 *      Fixed MSVC 1.5 compile bug
 *
 *      Revision 1.5  1998/11/01 01:04:00  dstef
 *      Added RCS marker
 *
 *      Revision 1.4  1998/10/25 02:17:53  dstef
 *      Added support for Microsoft Visual C 1.5
 *      Added compile instructions
 *
 *      Revision 1.3  1998/10/09 22:04:56  dstef
 *      Added POSIX support for Win32 platform
 *      Removed straightforward Win32 implementation
 *
 *      Revision 1.2  1998/10/03 11:33:09  dstef
 *      Added exclude files mask for search
 *
 *      Revision 1.1  1998/10/03 02:19:06  dstef
 *      Initial revision
 *
 *****************************************************************************/




/*------------------------------- Conditions ------------------------------*/
//#if defined(_WIN32)
//#define  _USE_32BIT_TIME_T  1
//#endif




/*-------------------------- Standard definitions --------------------------*/
#if defined(_WIN32)
#include <windows.h>                        /* WIN32 base definitions */
#endif                                      /* #if defined(_WIN32) */
#include <stdio.h>                          /* I/O standard streams */
#include <stdlib.h>                         /* Miscellaneous common functions */
#if !defined(_WIN32)
#include <dirent.h>                         /* Posix directory operations */
#endif
#include <string.h>                         /* String and memory operations */
#include <ctype.h>                          /* Character macros */
#if defined(_WIN32)
#include <dos.h>
#endif
#include <sys/stat.h>
#include <time.h>



/*------------------------------- Description ------------------------------*/
const char  g_ProgramName[]       =   "ListDir7";
const char  g_ProgramVersion[]    =   "v1.40";
const char  g_CopyrightNotice[]   =   "Copyright (c) 1998,2019";
const char  g_Author[]            =   "Dmitry Stefankov";



/*------------------------------- Return Codes -----------------------------*/
#define   ERROR_DONE                 0     /* Running is successful        */
#define   ERROR_BAD_PARAMETER        1     /* Bad user supplied parameter  */
#define   ERROR_USER_HELP_OUTPUT   255     /* Output user help message     */



/*----------------------------- Miscellaneous ------------------------------*/
#define   QUOTA                    0x22     /* Quatation mark */
#define   FMASKS_MAX                30       /* Available masks */
//#define   MAX_FILENAME_SIZE        255+1    /* UNIX compatibility */
#define   MAX_FILENAME_SIZE        2048+1    /* UNIX compatibility */
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
#define   DIGEST_BUF_SIZE          16       /* Digest buffer size */
#if defined(_WIN32)
#define   DIRMAGIC                  0xDD    /* Borland C compatibilty */
#define   EBADF                     6       /* Bad file number */
#define   ENOMEM                    8       /* Not enough core */
#define   ENOENT                    2       /* No such file or directory*/
#endif                                      /* #if (defined(_WIN32) || defined(_MSVC)) */

#define   WCMFMS_ALGO_NUM_MIN        0
#define   WCMFMS_ALGO_NUM_DEF        0
#define   WCMFMS_ALGO_NUM_MAX        8



/*----------------------------- Structures ---------------------------------*/
#if defined(_WIN32)                         /* Definitions for POSIX directory operations. */
struct dirent                               /* dirent structure returned by readdir() */
{
    char        d_name[MAX_FILENAME_SIZE];  /* Full filename */
};

typedef struct                              /* DIR type returned by opendir() */
{
/* DIR type returned by opendir().  The first two members cannot
 * be separated, because they make up the DOS DTA structure used
 * by findfirst() and findnext().
 */
    char         * d_dirname;               /* Directory name */
    struct dirent  d_dirent;                /* Copy of filename */
    char           d_first;                 /* First file flag */
    unsigned char  d_magic;                 /* Magic cookie for verifying handle */
    HANDLE        fileHandle;               /* Win32 classic object */
    WIN32_FIND_DATA  findData;              /* Win32 search structire */
} DIR;
#endif                                      /* #if defined(_WIN32) || defined(_MSVC)) */

struct  MaskNode
{
    char *   pFilesMask;                    /* Filemask */
};

struct  FileSearchMasks
{
  struct MaskNode    sFileMasks[FMASKS_MAX];
};
typedef  struct FileSearchMasks  * pFileSearchMasks;




/*--------------------------- MD5 definitions ------------------------------*/
#define _MD5STRSAVE_WORKAROUND	1

typedef unsigned long int   uint32;
typedef struct { unsigned char  md5sig[DIGEST_BUF_SIZE]; }  md5buf;
typedef md5buf * pmd5buf;

struct MD5Context {
        uint32 buf[4];
        uint32 bits[2];
        unsigned char in[64];
};

typedef struct MD5Context MD5_CTX;

/* The four core functions - F1 is optimized somewhat */

/* #define F1(x, y, z) (x & y | ~x & z) */
#define F1(x, y, z) (z ^ (x & (y ^ z)))
#define F2(x, y, z) F1(z, x, y)
#define F3(x, y, z) (x ^ y ^ z)
#define F4(x, y, z) (y ^ (x | ~z))

/* This is the central step in the MD5 algorithm. */
#define MD5STEP(f, w, x, y, z, data, s) \
	( w += f(x, y, z) + data,  w = w<<s | w>>(32-s),  w += x )




/*----------------------------- RCS marker ---------------------------------*/
static char  rcsid[] = "$Id$";



/*----------------------------- Global data --------------------------------*/
int   g_fVerbose                =   0;      /* Verbose output            */
int   g_iDebugLevel             =   0;      /* Debugging level           */
int   g_iRecursiveSearch        =   0;      /* Scan all subdirectories   */
int   g_iPrintFullName          =   0;      /* Print full filename       */
int   g_fIgnoreCaseInFilenames  =   0;      /* Ignore case in filenames  */
int   g_fPrintFileStatInfo      =   0;      /* Print file status info    */
int   g_iIncFilesMask           =   0;      /* Include to search         */
int   g_iExcFilesMask           =   0;      /* Include to search         */
int   g_fMD5                    =   0;      /* Use MD5 algorithm         */
int   g_iRetryCountCRC          =   1;      /* How many times count CRC  */
int   g_fPrintOnlyDirectory     =   0;      /* Print directory name only */
int   g_iDirectoryDepth         =   0;      /* Directory depth size      */

int   g_iWCMFMS_AlgoNum         =   WCMFMS_ALGO_NUM_DEF;      
                                            /* Wildcard file masks search algorithm number */

struct FileSearchMasks    g_sIncFileMasks;
struct FileSearchMasks    g_sExcFileMasks;

const  char  g_szMD5[]          =   { "md5sum="};
const  char  g_szWrongCRC[]     =   { "(unreliable results)"};


/*---------------------------- Error Messages ------------------------------*/
const char  g_szNoMemForExcFMask[]  =
                     "WARNING: insufficient memory for excluding filemask.";
const char  g_szNoMemForIncFMask[]  =
                     "WARNING: insufficient memory for including filemask.";


/*------------------------- Function Prototype -----------------------------*/
unsigned long int ulListDir( char *dirname, int maxdirlen,
                             pFileSearchMasks pIncFMasks,
                             pFileSearchMasks pExcFMasks, 
                             int iSearchDirs, int iMaxDirDepth );
int  iTestDir( char *dirname );
int  iTestPattern( const char * szName, const char * szPattern );
int  iTestForFileMask( char *filename, pFileSearchMasks pFMasks,
                       int iFMasksCount );
int  AddFileMask( const char * pszAddMask, pFileSearchMasks pFMasks,
                  int * piFMasksCount, const char * pszErrMsg );
char *  safe_strncpy ( char *dest, const char *src, size_t maxlen );
char *  safe_strncat( char *dest, const char *src, size_t n );
#if defined(_WIN32)
DIR *  opendir( char *dirname );
struct dirent *  readdir( DIR  *dir );
int   closedir( DIR  *dir );
#endif                                      /* #if (defined(_WIN32) || defined(_MSVC)) */
int  dbl2dec( double d, char * buf, int bufsize );

pmd5buf GetFileMD5( char *szFileName );
void MD5Init(struct MD5Context *ctx);
void MD5Update(struct MD5Context *ctx, unsigned char *buf, unsigned len);
void MD5Final( pmd5buf digest, struct MD5Context *ctx);
#if 0
void MD5Final( unsigned char digest[DIGEST_BUF_SIZE], 
               struct MD5Context *ctx);
#endif               
void MD5Transform(uint32 buf[4], uint32 in[16]);



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
    int         iArgc;                      /* Arguments number  */
    char       **lpszArgv;                  /* Arguments array   */
    char  szIncSearchDir[MAX_FILENAME_SIZE+1]  = { "\0" };
    char  szIncSearchMask[MAX_FILENAME_SIZE+1] = { "\0" };
    char  szExcSearchMask[MAX_FILENAME_SIZE+1] = { "\0" };
    int         iTemp;                      /* Temporary */
    char        chTemp;                     /* Temporary storage */
    unsigned long int ulFoundFiles = 0;     /* Counter */
    void *      pTemp;                      /* Temporary */
    int         iDirDepth = 0;              /* Temporary */


/*-------------------------- Compiler test phase ---------------------------*/
#ifdef  _TEST
#if __STDC__ == 0 && !defined(__cplusplus)
  printf("cc is not ANSI C compliant\n");
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
     printf( "NAME\n" );
     printf( "  listdir7 - list directory contents\n" );
     printf( "\n" );
     printf( "SYNOPSIS\n" );
     printf( "   listdir7 [-d][-s][-v][-f][-g][-m][-t][-r] [-n num] [-a num] [[-e mask]..] [[-i mask]..] [dirname]\n" );
     printf( "\n" );
     printf( "DESCRIPTION\n" );
     printf( "  LISTDIR7 is used the standard POSIX functions to list the directory contents.\n" );
     printf( "  The options are as follows:\n" );
     printf( "  -d   Debugging level.\n" );
     printf( "  -e mask\n" );
     printf( "       Exclude file(s) for search, wildcards are allowed (upto %d masks).\n", FMASKS_MAX );
     printf( "  -t   Print file date,time,size.\n" );
     printf( "  -f   Print full filename.\n" );
     printf( "  -g   Ignore case in filename(s).\n" );
     printf( "  -a num\n" );
     printf( "       wildcard match algoirthm for file masks search (default=%d,min=%d,max=%d).\n", 
                     g_iWCMFMS_AlgoNum,WCMFMS_ALGO_NUM_MIN,WCMFMS_ALGO_NUM_MAX );
     printf( "  -i mask\n" );
     printf( "       Include file(s) for search, wildcards are allowed (upto %d masks).\n", FMASKS_MAX );
     printf( "  -s   Search also subdirectories.\n" );
     printf( "  -m   Use MD5 algorithm.\n" );
     printf( "  -r   Print only directory name.\n" );
     printf( "  -v   Verbose output.\n" );
     printf( "  -n num\n" );
     printf( "       Directory depth limit (default=unlimited).\n" );
     printf( "  dirname\n" );
     printf( "       Directory name to list.\n" );
     printf( "\n" );
     printf( "HISTORY\n" );
     printf( "  LISTDIR7 command appeared in October 2019\n" );
     printf( "\n" );
     printf( "AUTHOR\n" );
     printf( "  Dmitry V. Stefankov  (dstef@mail.ru, dmstef@google.com)" );
     return( ERROR_USER_HELP_OUTPUT );
  }
  else
  {
     --iArgc;                               /* Remove program name */
     while (iArgc)
     {
       chTemp = **(++lpszArgv);
       iArgc--;                             /* Remove this argument */
       /*if ( (chTemp == '-') || (chTemp == '/') )*/
       if ( chTemp == '-' )
       {
          chTemp = *(++*lpszArgv);          /* Look options */
          switch( chTemp )
          {
                case 'a':
                    {
                        --iArgc;
                        g_iWCMFMS_AlgoNum = atol(*(++lpszArgv));
                        if ((g_iWCMFMS_AlgoNum < WCMFMS_ALGO_NUM_MIN) || (g_iWCMFMS_AlgoNum > WCMFMS_ALGO_NUM_MAX)) {
                          printf( "ERROR: bad algorithm number!\n" );
                          return( ERROR_BAD_PARAMETER );
                        }
                    }
                    break;
                case 'd':
                    g_iDebugLevel = 1;      /* Some debugging */
                    break;
                case 'e':
                    if (iArgc)              /* Exclude files mask */
                    {
                        --iArgc;
                        safe_strncpy( szExcSearchMask, *(++lpszArgv),
                                      sizeof(szExcSearchMask) );
                        /*strupr( szExcSearchMask );*/
                        iTemp = AddFileMask( szExcSearchMask,
                                             &g_sExcFileMasks,
                                             &g_iExcFilesMask,
                                             g_szNoMemForExcFMask );
                    }
                    break;
                case 'f':
                    g_iPrintFullName = 1;   /* Full filename */
                    break;
                case 'g':                   /* Case-insensitive search for filenames */
                    g_fIgnoreCaseInFilenames = 1;
                    break;
                case 'i':
                    if (iArgc)              /* Include files mask */
                    {
                        --iArgc;
                        safe_strncpy( szIncSearchMask, *(++lpszArgv),
                                      sizeof(szIncSearchMask) );
                           /*strupr( szIncSearchMask );*/
                           iTemp = AddFileMask( szIncSearchMask,
                                                &g_sIncFileMasks,
                                                &g_iIncFilesMask,
                                                g_szNoMemForIncFMask );
                    }
                    break;
                case 's':                   /* Search subdirectories */
                    g_iRecursiveSearch = 1;
                    break;
                case 't':                   /* Print file status info */
                    g_fPrintFileStatInfo = 1;
                    break;
                case 'm':
                    g_fMD5   = 1;           /* MD5 */     
                    break;
                case 'v':
                    g_fVerbose = 1;         /* Verbose output */
                    break;
                case 'r':
                    g_fPrintOnlyDirectory = 1; /* Directory name only */
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
  if (g_fVerbose) {
    printf( "%s %s, %s %s\n", g_ProgramName, g_ProgramVersion,
             g_CopyrightNotice,  g_Author );
    printf( "WCMFMS algorithm: %d\n", g_iWCMFMS_AlgoNum );
  }

/*--------------------------- Searches directory ---------------------------*/
   if ( szIncSearchDir[0] == '\0' )
     safe_strncpy( szIncSearchDir, ".", sizeof(szIncSearchDir) );
   if ( szIncSearchMask[0] == '\0' )
   {
     safe_strncpy( szIncSearchMask, "*", sizeof(szIncSearchMask) );
     iTemp = AddFileMask( szIncSearchMask, &g_sIncFileMasks,
                          &g_iIncFilesMask, g_szNoMemForIncFMask );
   }
   //strupr( szIncSearchDir );                /* Convert all to uppercase */

   if (g_iDebugLevel > 0)
   {
     printf( "Search catalog: %s\n", &szIncSearchDir[0] );
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
   }

   ulFoundFiles = ulListDir( szIncSearchDir, MAX_FILENAME_SIZE+1,
                             &g_sIncFileMasks, &g_sExcFileMasks,
                             g_iRecursiveSearch, iDirDepth+1 );

   printf( "Total found %lu item", ulFoundFiles );
   if (ulFoundFiles != 1)
     printf("s");
   printf("\n");

/*--------------------------- Terminate program  ---------------------------*/
  return 0;
}



/*****************************************************************************
 *                             --- ulListDir ---
 *
 * Purpose: List files in directory
 *   Input: char       *dirname    - directory name
 *          int        maxdirlen   - directory name buffer size (max.)
 *          pFileSearchMasks pIncFMasks - include filemasks array
 *          pFileSearchMasks pExcFMasks - exclude filemasks array
 *          int        iSearchDirs - search subdirectories
 *  Output: unsigned long int      - number of matching found files
 * Written: by Dmitry V.Stefankov 10-03-1998
 *****************************************************************************/
unsigned long int  ulListDir( char *dirname, int maxdirlen,
                              pFileSearchMasks pIncFMasks,
                              pFileSearchMasks pExcFMasks, 
                              int iSearchDirs, int iMaxDirDepth )
{
  unsigned long int  ulFilesCount = 0;      /* Counter */
  char  szTestFName[MAX_FILENAME_SIZE+1];   /* Filename */
  struct _stat  file_stat;		    /* File status */
  DIR  *dir;                                /* Directory structure */
  struct dirent  *ent;                      /* Directory entry */
  int   fExcThisFile;                       /* Boolean flag */
  int   fIncThisFile;                       /* Boolean flag */
  int   maxlen;                             /* Space size */
  int   result;                             /* Temporary */
  time_t  mtime;                            /* Mod.time */
  struct tm *   tmptr;                      /* Time structure */
  char  szTempStr[64];                      /* Temporary */
  int   iIndex;                             /* Index loop */
  int   fWrongCRC;                          /* Wrong CRC found */
  md5buf  md5sig;
  pmd5buf  psignature;
  unsigned char * pch;


/*------------------------ Process directory name --------------------------*/
  //printf( "iMaxDirDepth=%d\n", iMaxDirDepth );
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
  if ( g_iPrintFullName == 0 )
     printf( "%s\n", dirname );
  maxlen = (int)strlen(dirname);
#if defined(_WIN32)
  if ( dirname[maxlen-1] != '\\' )
    safe_strncat( dirname, "\\", maxdirlen );
#else
  if ( dirname[maxlen-1] != '/' )
    safe_strncat( dirname, "/", maxdirlen );
#endif                                      /* #if defined(_UNIX) */

/*---------------------------- Open directory  -----------------------------*/
  if ((dir = opendir(dirname)) == NULL)
  {
    printf( "ERROR: Unable to open directory!\n" );
    return 0;                               /* Emergency exit */
  }

/*---------------------- Process directory entries -------------------------*/
  while ((ent = readdir(dir)) != NULL)
  {
    if ( strcmp(ent->d_name,".") && strcmp(ent->d_name,"..") )
    {
      safe_strncpy( szTestFName, dirname, sizeof(szTestFName) );
      safe_strncat( szTestFName, ent->d_name, sizeof(szTestFName) );
      if (g_iDebugLevel > 0)
      {
        printf( "Test Item: %s\n", szTestFName );
      }
      if ( iTestDir(szTestFName) == 1 )
      {
        if (g_fPrintOnlyDirectory) goto done;
        //printf( "test mask 1\n" );
        fExcThisFile = iTestForFileMask( ent->d_name, pExcFMasks,
                                         g_iExcFilesMask );
        if (!fExcThisFile)
        {
          //printf( "test mask 2\n" );
          fIncThisFile = iTestForFileMask( ent->d_name, pIncFMasks,
                                           g_iIncFilesMask );
          //printf( "test mask 2 done\n" );
          if ( fIncThisFile )
          {
            //printf( "file mask match OK\n" );
            if (g_fPrintFileStatInfo) {     /* print file status information */
              memset( &file_stat, 0, sizeof(file_stat) );
              //printf( "_stat()\n" );
              result = _stat(szTestFName,&file_stat);
              //printf( "result=%d\n",result);
              if (result == 0) {
                memset( szTempStr, 0, sizeof(szTempStr) );
                mtime = file_stat.st_mtime;
                tmptr = localtime(&mtime);
                //printf( "convert\n" );
                if (tmptr != NULL) {
                  strftime( szTempStr, sizeof(szTempStr)-1, "%d.%m.%Y %H:%M", tmptr );
                }
                printf( "datetime=\"%s\"", szTempStr );
                memset( szTempStr, 0, sizeof(szTempStr) );
                result = dbl2dec( (double)file_stat.st_size,szTempStr,sizeof(szTempStr)-1 );
                printf( "  size=\"%s\"", szTempStr );
                //printf( "  %s  (%ld)  ", szTempStr, file_stat.st_size );
                //printf( "  %ld   ", file_stat.st_size );
              }
            }
            if (g_fMD5)  {
              fWrongCRC = 0; 
              psignature = GetFileMD5( szTestFName );
              if (psignature != NULL)
                memcpy( &md5sig, psignature, sizeof(md5sig) );
               if ( g_iRetryCountCRC > 1 )
               {
                 for(iIndex=1; iIndex < g_iRetryCountCRC; iIndex++)
                    if ( memcmp( psignature, GetFileMD5(szTestFName), sizeof(md5sig)) != 0 )
                      fWrongCRC++;
               }                   
               if (fWrongCRC) {
                 printf( " %s", g_szWrongCRC );
               }
               else {
                 printf( " %s=\"0x", g_szMD5 );
                 pch = (unsigned char *)psignature;     
                 for(iIndex = 0; iIndex < DIGEST_BUF_SIZE; iIndex++) {
                    printf( "%02X", *pch++ );
                 }
                 printf( "\"" );
               }
            }
            if ( g_iPrintFullName )           /* Now print name */
               printf( "  filename=\"%s\"\n", szTestFName );
            else
               printf( "  filename=\"%s\"\n", ent->d_name );
            ++ulFilesCount;
          }
          done: {};
        }/*if*/
      }
      else
      {
         if (g_fPrintOnlyDirectory) {
           //printf( "  catalog=\"%s\"\n", szTestFName );
         }
         if (iSearchDirs) {                 /* Have we look more? */
            if (g_iDebugLevel) {
              //iMaxDirDepth++;
              printf( "iMaxDirDepth=%d, g_iDirectoryDepth=%d\n", iMaxDirDepth, g_iDirectoryDepth );
              //printf( "iMaxDirDepth=%d\n", iMaxDirDepth );
            }
            if (g_iDirectoryDepth > 0) {
               //if (iMaxDirDepth+1 > g_iDirectoryDepth) goto dir_done;
            }
            ulFilesCount += ulListDir( szTestFName, maxdirlen, pIncFMasks,
                                       pExcFMasks, iSearchDirs, iMaxDirDepth );
            //dir_done: {};
         }
      }/*if-else*/
    }/*if*/
  }/*while*/

/*------------------------ Close a directory --------------------------------*/
  if ( closedir(dir) != 0 )
      printf( "ERROR: Unable to close directory!\n" );

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
      printf( "ERROR: Unable to close directory during testing!\n" );
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



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 1st routine.
 I designed it a few years ago, but the original was buggy and slower than
 this.
 The logic is quite obvious. This is quite slow as it uses recursion.
--------------------------------------------------------------------------- */
BOOL szWildMatch1(PSZ pat, PSZ str) {
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   while (*str) {
      switch (*pat) {
         case '?':
            if (*str == '.') return FALSE;
            break;
         case '*':
            do { ++pat; } while (*pat == '*'); /* enddo */
            if (!*pat) return TRUE;
            while (*str) if (szWildMatch1(pat, str++)) return TRUE;
            return FALSE;
         default:
             chLeft = *str; 
             chRight = *pat;
             if (g_fIgnoreCaseInFilenames)
               if (tolower(chLeft) != tolower(chRight)) return FALSE;
             else 
               if (chLeft != chRight) return FALSE;
           break;
      } /* endswitch */
      ++pat, ++str;
   } /* endwhile */
   while (*pat == '*') ++pat;
   return !*pat;
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 2nd routine.
 It is basically as the previous routine. It uses a different flow just
 to check if that would perform faster (it doesn't).
--------------------------------------------------------------------------- */
BOOL szWildMatch2(PSZ pat, PSZ str) {
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */
   while (*str) {
      chLeft = *str; 
      chRight = *pat;
      if (g_fIgnoreCaseInFilenames) 
        iMatch = ( tolower(chLeft) == tolower(chRight) );
      else 
        iMatch = (chLeft == chRight);
      //if (*str == *pat) {
      if (iMatch) {
         ++pat, ++str;
      } else if (*pat == '?') {
         if (*str == '.') return FALSE;
         ++pat, ++str;
      } else if (*pat == '*') {
         do { ++pat; } while (*pat == '*'); /* enddo */
         if (!*pat) return TRUE;
         while (*str) if (szWildMatch2(pat, str++)) return TRUE;
         return FALSE;
      } else {
         return FALSE;
      } /* endif */
   } /* endwhile */
   while (*pat == '*') ++pat;
   return !*pat;
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 3rd routine.
 This was suggested by an anonymous on a comp.os.os2.programmer.misc post.
 It is published by http://www.snippets.org (xstrcmp.c).
 The original file was :
 "Derived from code by Arjan Kentner (submitted by Steve Summit),
  modified by Bob Stout."
 No use restriction is mentioned in the source file.
 I modified it to prevent matching between '?' and '.' and to use
 the mapCaseTable[] array rather than toupper().
 This performs around twice slower than the previous routines I designed
 as it uses more extensively recursion.
--------------------------------------------------------------------------- */
BOOL szWildMatch3(PSZ pat, PSZ str) {
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */
   switch (*pat) {
      case '\0':
         return !*str;
         break;
      case '*':
         return szWildMatch3(pat+1, str) || *str && szWildMatch3(pat, str+1);
         break;
      case '?':
         return *str && (*str != '.') && szWildMatch3(pat+1, str+1);
         break;
      default: 
      chLeft = *str; 
      chRight = *pat;
      if (g_fIgnoreCaseInFilenames) 
         iMatch = ( tolower(chLeft) == tolower(chRight) );
      else 
         iMatch = (chLeft == chRight);
         //return (*str == *pat) &&
         return (iMatch) && szWildMatch3(pat+1, str+1);
         break;
   } /* endswitch */
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 4th routine.
 This was inspired by the previous routine.
 I modified it trying to reduce recursion as much as possible.
 While this is faster than the snippets.org routine it is not as fast as
 the first two ones.
--------------------------------------------------------------------------- */
BOOL szWildMatch4(PSZ pat, PSZ str) {
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */
   while (*str) {
      switch (*pat) {
         case '?':
            if (*str == '.') return FALSE;
            break;
         case '*':
            return !*(pat + 1) ||
                   szWildMatch4(pat + 1, str) ||
                   szWildMatch4(pat, str + 1);
         default:
            chLeft = *str; 
            chRight = *pat;
            if (g_fIgnoreCaseInFilenames) 
               iMatch = ( tolower(chLeft) == tolower(chRight) );
            else 
               iMatch = (chLeft == chRight);
            //if (*str != *pat) return FALSE;
            if (!iMatch) return FALSE;
            break;
      } /* endswitch */
      ++str, ++pat;
   } /* endwhile */
   while (*pat == '*') ++pat;
   return !*pat;
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 5th routine.
 This is the first NON RECURSIVE routine.
 I got it from a Walnut Creek CD (C/C++ user group library).
 The original code is from "C/C++ Users Journal".
 The author is Mike Cornelison.
 No use restriction is mentioned in the source file or other documentation
 I found in the CD.
 I modified it to prevent matching between '?' and '.' and to use
 the mapCaseTable[] array (the original routine didn't perform case
 insensitive matching) .
 On my PC this performs almost 100 times faster than the routine from
 snippets.org .
 But I was sure it would have been possible to do better...
--------------------------------------------------------------------------- */
BOOL szWildMatch5(PSZ pat, PSZ str) {
   int i, star;
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */

new_segment:

   star = 0;
   if (*pat == '*') {
      star = 1;
      do { pat++; } while (*pat == '*'); /* enddo */
   } /* endif */

test_match:

   for (i = 0; pat[i] && (pat[i] != '*'); i++) {
      chLeft  = str[i]; 
      chRight = pat[i];
      if (g_fIgnoreCaseInFilenames) 
        iMatch = ( tolower(chLeft) == tolower(chRight) );
      else 
        iMatch = (chLeft == chRight);
      //if (str[i] != pat[i]) {
      if (!iMatch) {
         if (!str[i]) return 0;
         if ((pat[i] == '?') && (str[i] != '.')) continue;
         if (!star) return 0;
         str++;
         goto test_match;
      }
   }
   if (pat[i] == '*') {
      str += i;
      pat += i;
      goto new_segment;
   }
   if (!str[i]) return 1;
   if (i && pat[i - 1] == '*') return 1;
   if (!star) return 0;
   str++;
   goto test_match;
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 6th routine.
 This is based on the logic of the first routine, which is the faster
 among the recursive ones.
 I used array indexes as in the previous routine, but the flow is
 completely different and much simpler and straighter. Do not be
 scared by the goto (you also find in the previous routine) they are
 the only way to convert slow recursive procedures to fast non-recursive
 ones.
 This routine is in up to 65 % faster than the previous one.
--------------------------------------------------------------------------- */
BOOL szWildMatch6(PSZ pat, PSZ str) {
   int i;
   BOOL star = FALSE;
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */

loopStart:
   for (i = 0; str[i]; i++) {
      switch (pat[i]) {
         case '?':
            if (str[i] == '.') goto starCheck;
            break;
         case '*':
            star = TRUE;
            str += i, pat += i;
            do { ++pat; } while (*pat == '*');
            if (!*pat) return TRUE;
            goto loopStart;
         default:
            chLeft  = str[i]; 
            chRight = pat[i];
            if (g_fIgnoreCaseInFilenames) 
              iMatch = ( tolower(chLeft) == tolower(chRight) );
            else 
              iMatch = (chLeft == chRight);
            //if (str[i] != pat[i])
            if (!iMatch)
              goto starCheck;
         break;
      } /* endswitch */
   } /* endfor */
   while (pat[i] == '*') ++i;
   return (!pat[i]);

starCheck:
   if (!star) return FALSE;
   str++;
   goto loopStart;
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 7th routine.
 This is not different from the previous one... I thought it would have been
 possible to squeeze some more power by using pointers rather than array
 indexes and it looks like I was right although the speed gain is really
 minimum.
--------------------------------------------------------------------------- */
BOOL szWildMatch7(PSZ pat, PSZ str) {
   PSZ s, p;
   BOOL star = FALSE;
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */

loopStart:
   for (s = str, p = pat; *s; ++s, ++p) {
      switch (*p) {
         case '?':
            if (*s == '.') goto starCheck;
            break;
         case '*':
            star = TRUE;
            str = s, pat = p;
            do { ++pat; } while (*pat == '*');
            if (!*pat) return TRUE;
            goto loopStart;
         default:
            chLeft  = *s; 
            chRight = *p;
            if (g_fIgnoreCaseInFilenames) 
              iMatch = ( tolower(chLeft) == tolower(chRight) );
            else 
              iMatch = (chLeft == chRight);
            //if (*s != *p)
            if (!iMatch)
               goto starCheck;
            break;
      } /* endswitch */
   } /* endfor */
   while (*p == '*') ++p;
   return (!*p);

starCheck:
   if (!star) return FALSE;
   str++;
   goto loopStart;
}



/* --------------------------------------------------------------------------
 Alessandro Felice Cantatore - 2003/25/04
 8th routine.
 This is the same as the 7th routine, but it assumes that pattern has been
 preprocessed to remove consecutive asterisks.
--------------------------------------------------------------------------- */
BOOL szWildMatch8(PSZ pat, PSZ str) {
   PSZ s, p;
   BOOL star = FALSE;
   char chLeft;                            /* Test character from left */
   char chRight;                           /* Test character from right */
   int iMatch;                             /* Matching character */

loopStart:
   for (s = str, p = pat; *s; ++s, ++p) {
      switch (*p) {
         case '?':
            if (*s == '.') goto starCheck;
            break;
         case '*':
            star = TRUE;
            str = s, pat = p;
            if (!*++pat) return TRUE;
            goto loopStart;
         default:
            chLeft  = *s; 
            chRight = *p;
            if (g_fIgnoreCaseInFilenames) 
              iMatch = ( tolower(chLeft) == tolower(chRight) );
            else 
              iMatch = (chLeft == chRight);
            //if (*s != *p)
            if (!iMatch)
               goto starCheck;
            break;
      } /* endswitch */
   } /* endfor */
   if (*p == '*') ++p;
   return (!*p);

starCheck:
   if (!star) return FALSE;
   str++;
   goto loopStart;
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
        iRetCode = 0;
        switch( g_iWCMFMS_AlgoNum) {
           case 0:
               iRetCode = iTestPattern( filename, pTemp );
               break;
           case 1:
               iRetCode = szWildMatch1( pTemp, filename );
               break;
           case 2:
               iRetCode = szWildMatch2( pTemp, filename );
               break;
           case 3:
               iRetCode = szWildMatch3( pTemp, filename );
               break;
           case 4:
               iRetCode = szWildMatch4( pTemp, filename );
               break;
           case 5:
               iRetCode = szWildMatch5( pTemp, filename );
               break;
           case 6:
               iRetCode = szWildMatch6( pTemp, filename );
               break;
           case 7:
               iRetCode = szWildMatch7( pTemp, filename );
               break;
           case 8:
               iRetCode = szWildMatch8( pTemp, filename );
               break;
           default:
               break;
        }
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
       safe_strncpy( (char *)pTemp, pszAddMask, strlen(pszAddMask)+1 );
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



#if defined(_WIN32)
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

   len = (int)strlen( dirname );
   maxlen = len+5-1;
   if ((name = (char *)malloc(maxlen+1)) == NULL)
   {
      errno = ENOMEM;
      return (NULL);
   }

   safe_strncpy( name, dirname, maxlen );
   if (len-- && name[len] != ':' && name[len] != '\\' && name[len] != '/')
      safe_strncat( name, "\\*", maxlen+1 );
   else
      safe_strncat( name, "*", maxlen+1 );
                                             
   if ((dir = (DIR *)malloc(sizeof(DIR))) == NULL) /* Allocate space for a DIR structure */
   {
       errno = ENOMEM;
       free(name);
       return (NULL);
   }
   dir->fileHandle = FindFirstFile( name, &dir->findData );
   if ( dir->fileHandle == INVALID_HANDLE_VALUE )
   {
      errno = ENOENT;                       /* I no hope that FindFirstFile */
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
   safe_strncpy( dir->d_dirent.d_name, dir->findData.cFileName, 
                 sizeof(dir->d_dirent.d_name) ); 

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
      if ( !FindNextFile(dir->fileHandle, &dir->findData) )
         return NULL;
      safe_strncpy( dir->d_dirent.d_name, dir->findData.cFileName, 
                    sizeof(dir->d_dirent.d_name) );
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
    FindClose( dir->fileHandle );           /* Clean up Win32 space */
    free(dir->d_dirname);
    free(dir);
    
    return 0;
}
#endif                                      /* #if defined(_WIN32) */




//****************************************************************************
//                            --- dbl2dec ---
//
// Purpose: Convert positive double value to pretty decimal representation
//   Input: double d       - value to translate
//          char * buf     - buffer to store translation results
//          int    bufsize - buffer size
//  Output: int            - 0  if successful
//                           -1 insufficient buffer
// Written: by Dmitry V.Stefankov 11-Aug-2000
//****************************************************************************
int
  dbl2dec( double d, char * buf, int bufsize )
{
    double              f;                  // Fraction
    double              u;                  // Divisor
    char        * p = buf;                  // Buffer offset
    char              * n;                  // Buffer offset
    char                c;                  // Temporary
    char            t[32];                  // Conversion buffer
    int                 i;                  // Index

    if ( (bufsize == 0) || (buf == NULL) )
        return(-1);

    do {
      u = (d / 1000);                       // Divide num by 1000
      f = d - (floor(u) * 1000);            // And store result
      d = (d - f) / 1000;                   // in reverse form
      if (d > 0) {
        sprintf( t, "%03d", (int)f );
        i = (int)strlen(t);
        while( i > 0) {
           *p = t[i-1];
           p++; i--;
        }
        *p++ = ',';
      }
      else {
        sprintf( t, "%d", (int)f );
        i = (int)strlen(t);
        while( i > 0) {
           *p = t[i-1];
           p++; i--;
        }

      }

    } while( d >= 1000 );

    if (d > 0) {
        sprintf( t, "%d", (int)d );
        i = (int)strlen(t);
        while( i > 0) {
           *p = t[i-1];
           p++; i--;
        }
    }
    *p = '\0';                              // End of string

    i=((int)strlen(buf))/2;                        // Reverse string
    p = buf;
    n = buf+strlen(buf)-1;
    while( p < n ) {
        c = *p;
        *p = *n;
        *n = c;
        p++;
        n--;
    }


    return(0);
}




/*
 * This code implements the MD5 message-digest algorithm.
 * The algorithm is due to Ron Rivest.	This code was
 * written by Colin Plumb in 1993, no copyright is claimed.
 * This code is in the public domain; do with it what you wish.
 *
 * Equivalent code is available from RSA Data Security, Inc.
 * This code has been tested against that, and is equivalent,
 * except that you don't need to include two pages of legalese
 * with every copy.
 *
 * To compute the message digest of a chunk of bytes, declare an
 * MD5Context structure, pass it to MD5Init, call MD5Update as
 * needed on buffers full of bytes, and then call MD5Final, which
 * will fill a supplied 16-byte array with the digest.
 */

#ifndef HIGHFIRST
#define byteReverse(buf, len)	/* Nothing */
#else
/*
 * Note: this code is harmless on little-endian machines.
 */
void byteReverse(unsigned char *buf; unsigned longs)
{
    uint32 t;
    do {
	t = (uint32) ((unsigned) buf[3] << 8 | buf[2]) << 16 |
	    ((unsigned) buf[1] << 8 | buf[0]);
	*(uint32 *) buf = t;
	buf += 4;
    } while (--longs);
}
#endif

/*
 * Debugging print
 */
void print_md5c(MD5_CTX * md5c)
{
#if 0
  int i;
  printf( "\nbuf[4] = 0x%08X,0x%08X,0x%08X,0x%08X\n", 
           md5c->buf[0], md5c->buf[1], md5c->buf[2], md5c->buf[3] );
  printf( "bits[2] = 0x%08X, 0x%08X\n", md5c->bits[0], md5c->bits[1] );
  printf( "in[64]=0x" );
  for (i = 0; i < 64; i++)
    printf( "%02X", md5c->in[i] );
  printf( "\n\n" );  
#endif  
}

/*
 * Start MD5 accumulation.  Set bit count to 0 and buffer to mysterious
 * initialization constants.
 */
void MD5Init( struct MD5Context *ctx )
{
    ctx->buf[0] = 0x67452301;
    ctx->buf[1] = 0xefcdab89;
    ctx->buf[2] = 0x98badcfe;
    ctx->buf[3] = 0x10325476;

    ctx->bits[0] = 0;
    ctx->bits[1] = 0;
}

/*
 * Update context to reflect the concatenation of another buffer full
 * of bytes.
 */
 
void MD5Update( struct MD5Context *ctx, unsigned char *buf, unsigned len )
{
    uint32 t;

    /* Update bitcount */

    t = ctx->bits[0];
    if ((ctx->bits[0] = t + ((uint32) len << 3)) < t)
	ctx->bits[1]++; 	/* Carry from low to high */
    ctx->bits[1] += len >> 29;

    t = (t >> 3) & 0x3f;	/* Bytes already in shsInfo->data */

    /* Handle any leading odd-sized chunks */

    if (t) {
	unsigned char *p = (unsigned char *) ctx->in + t;

	t = 64 - t;
	if (len < t) {
	    memcpy(p, buf, len);
	    return;
	}
	memcpy(p, buf, t);
	byteReverse(ctx->in, 16);
	MD5Transform(ctx->buf, (uint32 *) ctx->in);
	buf += t;
	len -= t;
    }
    /* Process data in 64-byte chunks */

    while (len >= 64) {
	memcpy(ctx->in, buf, 64);
	byteReverse(ctx->in, 16);
	MD5Transform(ctx->buf, (uint32 *) ctx->in);
	buf += 64;
	len -= 64;
    }

    /* Handle any remaining bytes of data. */

    memcpy(ctx->in, buf, len);
}

/*
 * Final wrapup - pad to 64-byte boundary with the bit pattern 
 * 1 0* (64-bit count of bits processed, MSB-first)
 */
void MD5Final( pmd5buf digest,
#if 0
 unsigned char digest[DIGEST_BUF_SIZE], 
#endif 
 struct MD5Context *ctx )
{
    unsigned count;
    unsigned char *p;

    /* Compute number of bytes mod 64 */
    count = (ctx->bits[0] >> 3) & 0x3F;

    /* Set the first char of padding to 0x80.  This is safe since there is
       always at least one byte free */
    p = ctx->in + count;
    *p++ = 0x80;

    /* Bytes of padding needed to make 64 bytes */
    count = 64 - 1 - count;

    /* Pad out to 56 mod 64 */
    if (count < 8) {
	/* Two lots of padding:  Pad the first block to 64 bytes */
	memset(p, 0, count);
	byteReverse(ctx->in, 16);
	MD5Transform(ctx->buf, (uint32 *) ctx->in);

	/* Now fill the next block with 56 bytes */
	memset(ctx->in, 0, 56);
    } else {
	/* Pad block to 56 bytes */
	memset(p, 0, count - 8);
    }
    byteReverse(ctx->in, 14);

    /* Append length in bits and transform */
    ((uint32 *) ctx->in)[14] = ctx->bits[0];
    ((uint32 *) ctx->in)[15] = ctx->bits[1];

    MD5Transform(ctx->buf, (uint32 *) ctx->in);
    byteReverse((unsigned char *) ctx->buf, 4);
    memcpy( digest, ctx->buf, 16);
#if 0
    printf( "digest=0x" );
    p = (unsigned char *)digest;
    for (count = 0; count < 16; count++)
      printf( "%02X", *p++ );
    printf( "\n" );
#endif
    memset(ctx, 0, sizeof(ctx));        /* In case it's sensitive */
}


/*
 * The core of the MD5 algorithm, this alters an existing MD5 hash to
 * reflect the addition of 16 longwords of new data.  MD5Update blocks
 * the data and converts bytes into longwords for this routine.
 */
void MD5Transform( uint32 buf[4], uint32 in[DIGEST_BUF_SIZE] )
{
    register uint32 a, b, c, d;

    a = buf[0];
    b = buf[1];
    c = buf[2];
    d = buf[3];

    MD5STEP(F1, a, b, c, d, in[0] + 0xd76aa478, 7);
    MD5STEP(F1, d, a, b, c, in[1] + 0xe8c7b756, 12);
    MD5STEP(F1, c, d, a, b, in[2] + 0x242070db, 17);
    MD5STEP(F1, b, c, d, a, in[3] + 0xc1bdceee, 22);
    MD5STEP(F1, a, b, c, d, in[4] + 0xf57c0faf, 7);
    MD5STEP(F1, d, a, b, c, in[5] + 0x4787c62a, 12);
    MD5STEP(F1, c, d, a, b, in[6] + 0xa8304613, 17);
    MD5STEP(F1, b, c, d, a, in[7] + 0xfd469501, 22);
    MD5STEP(F1, a, b, c, d, in[8] + 0x698098d8, 7);
    MD5STEP(F1, d, a, b, c, in[9] + 0x8b44f7af, 12);
    MD5STEP(F1, c, d, a, b, in[10] + 0xffff5bb1, 17);
    MD5STEP(F1, b, c, d, a, in[11] + 0x895cd7be, 22);
    MD5STEP(F1, a, b, c, d, in[12] + 0x6b901122, 7);
    MD5STEP(F1, d, a, b, c, in[13] + 0xfd987193, 12);
    MD5STEP(F1, c, d, a, b, in[14] + 0xa679438e, 17);
    MD5STEP(F1, b, c, d, a, in[15] + 0x49b40821, 22);

    MD5STEP(F2, a, b, c, d, in[1] + 0xf61e2562, 5);
    MD5STEP(F2, d, a, b, c, in[6] + 0xc040b340, 9);
    MD5STEP(F2, c, d, a, b, in[11] + 0x265e5a51, 14);
    MD5STEP(F2, b, c, d, a, in[0] + 0xe9b6c7aa, 20);
    MD5STEP(F2, a, b, c, d, in[5] + 0xd62f105d, 5);
    MD5STEP(F2, d, a, b, c, in[10] + 0x02441453, 9);
    MD5STEP(F2, c, d, a, b, in[15] + 0xd8a1e681, 14);
    MD5STEP(F2, b, c, d, a, in[4] + 0xe7d3fbc8, 20);
    MD5STEP(F2, a, b, c, d, in[9] + 0x21e1cde6, 5);
    MD5STEP(F2, d, a, b, c, in[14] + 0xc33707d6, 9);
    MD5STEP(F2, c, d, a, b, in[3] + 0xf4d50d87, 14);
    MD5STEP(F2, b, c, d, a, in[8] + 0x455a14ed, 20);
    MD5STEP(F2, a, b, c, d, in[13] + 0xa9e3e905, 5);
    MD5STEP(F2, d, a, b, c, in[2] + 0xfcefa3f8, 9);
    MD5STEP(F2, c, d, a, b, in[7] + 0x676f02d9, 14);
    MD5STEP(F2, b, c, d, a, in[12] + 0x8d2a4c8a, 20);

    MD5STEP(F3, a, b, c, d, in[5] + 0xfffa3942, 4);
    MD5STEP(F3, d, a, b, c, in[8] + 0x8771f681, 11);
    MD5STEP(F3, c, d, a, b, in[11] + 0x6d9d6122, 16);
    MD5STEP(F3, b, c, d, a, in[14] + 0xfde5380c, 23);
    MD5STEP(F3, a, b, c, d, in[1] + 0xa4beea44, 4);
    MD5STEP(F3, d, a, b, c, in[4] + 0x4bdecfa9, 11);
    MD5STEP(F3, c, d, a, b, in[7] + 0xf6bb4b60, 16);
    MD5STEP(F3, b, c, d, a, in[10] + 0xbebfbc70, 23);
    MD5STEP(F3, a, b, c, d, in[13] + 0x289b7ec6, 4);
    MD5STEP(F3, d, a, b, c, in[0] + 0xeaa127fa, 11);
    MD5STEP(F3, c, d, a, b, in[3] + 0xd4ef3085, 16);
    MD5STEP(F3, b, c, d, a, in[6] + 0x04881d05, 23);
    MD5STEP(F3, a, b, c, d, in[9] + 0xd9d4d039, 4);
    MD5STEP(F3, d, a, b, c, in[12] + 0xe6db99e5, 11);
    MD5STEP(F3, c, d, a, b, in[15] + 0x1fa27cf8, 16);
    MD5STEP(F3, b, c, d, a, in[2] + 0xc4ac5665, 23);

    MD5STEP(F4, a, b, c, d, in[0] + 0xf4292244, 6);
    MD5STEP(F4, d, a, b, c, in[7] + 0x432aff97, 10);
    MD5STEP(F4, c, d, a, b, in[14] + 0xab9423a7, 15);
    MD5STEP(F4, b, c, d, a, in[5] + 0xfc93a039, 21);
    MD5STEP(F4, a, b, c, d, in[12] + 0x655b59c3, 6);
    MD5STEP(F4, d, a, b, c, in[3] + 0x8f0ccc92, 10);
    MD5STEP(F4, c, d, a, b, in[10] + 0xffeff47d, 15);
    MD5STEP(F4, b, c, d, a, in[1] + 0x85845dd1, 21);
    MD5STEP(F4, a, b, c, d, in[8] + 0x6fa87e4f, 6);
    MD5STEP(F4, d, a, b, c, in[15] + 0xfe2ce6e0, 10);
    MD5STEP(F4, c, d, a, b, in[6] + 0xa3014314, 15);
    MD5STEP(F4, b, c, d, a, in[13] + 0x4e0811a1, 21);
    MD5STEP(F4, a, b, c, d, in[4] + 0xf7537e82, 6);
    MD5STEP(F4, d, a, b, c, in[11] + 0xbd3af235, 10);
    MD5STEP(F4, c, d, a, b, in[2] + 0x2ad7d2bb, 15);
    MD5STEP(F4, b, c, d, a, in[9] + 0xeb86d391, 21);

    buf[0] += a;
    buf[1] += b;
    buf[2] += c;
    buf[3] += d;
}

/*
 * Build MD5 hash sum for file
 */
pmd5buf GetFileMD5( char *szFileName )
{
   FILE                *crcfile;            /* File stream */
   //unsigned long int   filelen;             /* File size */
   //unsigned long int   readbytes = 0;       /* Read bytes count */
#if _WIN32 && !defined(_MINGW32)  
   unsigned __int64    filelen;             /* File size */
   unsigned __int64    readbytes = 0;       /* Read bytes count */
#else   
   __uint64_t          filelen;             /* File size */
   __uint64_t          readbytes = 0;       /* Read bytes count */
#endif   
   int                 count = 0;           /* Byte count */
   unsigned char       buffer[MAX_FILEBUF_SIZE]; /* Working buffer */
   struct MD5Context md5c;
   static md5buf  signature;
   pmd5buf psig = NULL;

   if ( (crcfile = fopen(szFileName,"rb") ) == NULL )
   {
     return( psig );
   }
   else
   {
     memset( &signature, 0, sizeof(signature) );
     memset( &md5c, 0, sizeof(md5c) );
     MD5Init(&md5c);
     print_md5c(&md5c);
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
     while ( (count = (int)fread(buffer, 1, MAX_FILEBUF_SIZE, crcfile)) != 0)
     {
         MD5Update(&md5c, buffer, count);
         print_md5c(&md5c);
         readbytes += count;
     }
     if (readbytes != filelen)  {
        printf("ERROR: cannot read file %s\n", szFileName );
     }
     else {
#if 0
        unsigned char *p;
#endif
         MD5Final( &signature, &md5c);
         print_md5c(&md5c);
#if 0
    printf( "digest_md5final=0x" );
    p = (unsigned char *)&signature;
    for (count = 0; count < 16; count++)
      printf( "%02X", *p++ );
    printf( "\n" );
#endif         
         psig = &signature;
     }
     fclose( crcfile );
   }/*if-else*/
   
   return( psig );
}

