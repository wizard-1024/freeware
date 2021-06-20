/*
 * Copyright (c) 2013, Alexey Degtyarev <alexey@renatasystems.org>. 
 * All rights reserved.
 *
 * GOST R 34.11-2012 core and API functions.
 *
 * $Id$
 */

#include "gost3411-2012-core.h"

#include <stdio.h>


#if defined(_BCC)
#define   MAX_FILEBUF_SIZE         3072     /* Workaround for ml,mh,mc */
#else
#define   MAX_FILEBUF_SIZE         16384    /* File operations buffer */
#endif                                      /* #if defined(_BCC) */

#define sha256_hash_size  32
#define sha512_hash_size  64


#define BSWAP64(x) \
    (((x & 0xFF00000000000000ULL) >> 56) | \
     ((x & 0x00FF000000000000ULL) >> 40) | \
     ((x & 0x0000FF0000000000ULL) >> 24) | \
     ((x & 0x000000FF00000000ULL) >>  8) | \
     ((x & 0x00000000FF000000ULL) <<  8) | \
     ((x & 0x0000000000FF0000ULL) << 24) | \
     ((x & 0x000000000000FF00ULL) << 40) | \
     ((x & 0x00000000000000FFULL) << 56))

void
GOST34112012Cleanup(GOST34112012Context *CTX)
{
    memset(CTX, 0x00, sizeof (GOST34112012Context));
}

void
GOST34112012Init(GOST34112012Context *CTX, const unsigned int digest_size)
{
    unsigned int i;

    memset(CTX, 0x00, sizeof(GOST34112012Context));
    CTX->digest_size = digest_size;

    for (i = 0; i < 8; i++)
    {
        if (digest_size == 256)
            CTX->h.QWORD[i] = 0x0101010101010101ULL;
        else
            CTX->h.QWORD[i] = 0x00ULL;
    }
}

static inline void
pad(GOST34112012Context *CTX)
{
    if (CTX->bufsize > 63)
        return;

    memset(CTX->buffer + CTX->bufsize,
        0x00, sizeof(CTX->buffer) - CTX->bufsize);

    CTX->buffer[CTX->bufsize] = 0x01;
}

static inline void
add512(const union uint512_u *x, const union uint512_u *y, union uint512_u *r)
{
#ifndef __GOST3411_BIG_ENDIAN__
    unsigned int CF, OF;
    unsigned int i;

    CF = 0;
    for (i = 0; i < 8; i++)
    {
        r->QWORD[i] = x->QWORD[i] + y->QWORD[i];
        if ( (r->QWORD[i] < y->QWORD[i]) || 
             (r->QWORD[i] < x->QWORD[i]) )
            OF = 1;
        else
            OF = 0;

        r->QWORD[i] += CF;
        CF = OF;
    }
#else
    const unsigned char *xp, *yp;
    unsigned char *rp;
    unsigned int i;
    int buf;

    xp = (const unsigned char *) &x[0];
    yp = (const unsigned char *) &y[0];
    rp = (unsigned char *) &r[0];

    buf = 0;
    for (i = 0; i < 64; i++)
    {
        buf = xp[i] + yp[i] + (buf >> 8);
        rp[i] = (unsigned char) buf & 0xFF;
    }
#endif
}

static void
g(union uint512_u *h, const union uint512_u *N, const unsigned char *m)
{
    union uint512_u Ki, data;
    unsigned int i;

    XLPS(h, N, (&data));

    /* Starting E() */
    Ki = data;
    XLPS((&Ki), ((const union uint512_u *) &m[0]), (&data));

    for (i = 0; i < 11; i++)
        ROUND(i, (&Ki), (&data));

    XLPS((&Ki), (&C[11]), (&Ki));
    X((&Ki), (&data), (&data));
    /* E() done */

    X((&data), h, (&data));
    X((&data), ((const union uint512_u *) &m[0]), h);
}

static inline void
stage2(GOST34112012Context *CTX, const unsigned char *data)
{
    g(&(CTX->h), &(CTX->N), data);

    add512(&(CTX->N), &buffer512, &(CTX->N));
    add512(&(CTX->Sigma), (const union uint512_u *) data, &(CTX->Sigma));
}

static inline void
stage3(GOST34112012Context *CTX)
{
    ALIGN(16) union uint512_u buf = {{ 0 }};

#ifndef __GOST3411_BIG_ENDIAN__
    buf.QWORD[0] = CTX->bufsize << 3;
#else
    buf.QWORD[0] = BSWAP64(CTX->bufsize << 3);
#endif

    pad(CTX);

    g(&(CTX->h), &(CTX->N), (const unsigned char *) &(CTX->buffer));

    add512(&(CTX->N), &buf, &(CTX->N));
    add512(&(CTX->Sigma), (const union uint512_u *) &CTX->buffer[0],
           &(CTX->Sigma));

    g(&(CTX->h), &buffer0, (const unsigned char *) &(CTX->N));

    g(&(CTX->h), &buffer0, (const unsigned char *) &(CTX->Sigma));
#ifdef _WIN32
    memcpy(&(CTX->hash), &(CTX->h), sizeof(union uint512_u) );
#else
    memcpy(&(CTX->hash), &(CTX->h), sizeof uint512_u);
#endif
}

void
GOST34112012Update(GOST34112012Context *CTX, const unsigned char *data, size_t len)
{
    size_t chunksize;

    if (CTX->bufsize) {
        chunksize = 64 - CTX->bufsize;
        if (chunksize > len)
            chunksize = len;

        memcpy(&CTX->buffer[CTX->bufsize], data, chunksize);

        CTX->bufsize += chunksize;
        len -= chunksize;
        data += chunksize;
        
        if (CTX->bufsize == 64)
        {
            stage2(CTX, CTX->buffer);

            CTX->bufsize = 0;
        }
    }

    while (len > 63)
    {
        stage2(CTX, data);

        data += 64;
        len  -= 64;
    }

    if (len) {
        memcpy(&CTX->buffer, data, len);
        CTX->bufsize = len;
    }
}

void
GOST34112012Final(GOST34112012Context *CTX, unsigned char *digest)
{
    stage3(CTX);

    CTX->bufsize = 0;

    if (CTX->digest_size == 256)
        memcpy(digest, &(CTX->hash.QWORD[4]), 32);
    else
        memcpy(digest, &(CTX->hash.QWORD[0]), 64);
}




#if 0
/*
 * Build GOST 34.11-2012 256-bit hash sum for file
 */
unsigned char * GetFileGOSTHASH_2012_256( char *szFileName )
{
   static unsigned char psig[sha256_hash_size];
   unsigned char *     p;

   memset( psig, 0, sizeof(psig) );
   p = psig;

   return( p );
}




/*
 * Build GOST 34.11-2012 512-bit hash sum for file
 */
unsigned char * GetFileGOSTHASH_2012_512( char *szFileName )
{
   static unsigned char psig[sha512_hash_size];
   unsigned char *     p;

   memset( psig, 0, sizeof(psig) );
   p = psig;

   return( p );
}
#endif




/*
 * Build GOST 34.11-2012 256-bit hash sum for file
 */
unsigned char * GetFileGOSTHASH_2012_256( char *szFileName )
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
   GOST34112012Context ctxt;
   static unsigned char psig[sha256_hash_size];
   unsigned char *     p;

   memset( psig, 0, sizeof(psig) );
   p = psig;
   if ( (crcfile = fopen(szFileName,"rb") ) == NULL )
   {
     return( p );
   }
   else
   {
     memset( &ctxt, 0, sizeof(ctxt) );
     GOST34112012Init(&ctxt, 256);
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
         GOST34112012Update(&ctxt, buffer, count);
         readbytes += count;
     }
     if (readbytes != filelen)  {
        printf("ERROR: cannot read file %s\n", szFileName );
     }
     else {
         GOST34112012Final(&ctxt, psig);
     }
     fclose( crcfile );
   }/*if-else*/


   return( p );
}



/*
 * Build GOST 34.11-2012 512-bit hash sum for file
 */
unsigned char * GetFileGOSTHASH_2012_512( char *szFileName )
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
   GOST34112012Context ctxt;
   static unsigned char psig[sha512_hash_size];
   unsigned char *     p;

   memset( psig, 0, sizeof(psig) );
   p = psig;
   if ( (crcfile = fopen(szFileName,"rb") ) == NULL )
   {
     return( p );
   }
   else
   {
     memset( &ctxt, 0, sizeof(ctxt) );
     GOST34112012Init(&ctxt, 512);
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
         GOST34112012Update(&ctxt, buffer, count);
         readbytes += count;
     }
     if (readbytes != filelen)  {
        printf("ERROR: cannot read file %s\n", szFileName );
     }
     else {
         GOST34112012Final(&ctxt, psig);
     }
     fclose( crcfile );
   }/*if-else*/


   return( p );
}
