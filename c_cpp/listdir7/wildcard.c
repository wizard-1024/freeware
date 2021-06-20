/* --------------------------------------------------------------------------

                                 WILDCARD.C

 by Alessandro Felice Cantatore - 2003/25/04

 Notes:

    * The code mentioned below is the copyright property of
      Alessandro Felice Cantatore, with the exception of those
      algorithms which are, as specified in source comments,
      property of the respective owners.
    * You are not allowed to patent or copyright this code as your!
    * If you work for Microsoft you are NOT allowed to use this code!
    * If you work for IBM you can use this code only if the target OS
      is OS/2 or linux.
    * You are not allowed to use this code for projects or programs
      owned or used by the army, the department of defense or the
      government of any country violating human rights and international
      laws (including those western countries pretending to "export"
      democracy).
      If you are unsure just check what Amnesty International reports
      about your country.
    * You are not allowed to use this code in programs used in
      activities causing harm to living beeings or to the environment.
    * You are free to use the algorithms described below in your
      programs, or modify them to suit your needs, provided that you
      include their source, including these notes and my name, (you are
      not required to include the whole source of your program) in
      your program package.
    * You are not allowed to sell this code, but you can include it
      into a commercial program.
    * If you have any doubt ask the author.
    * The previous notes only apply to the algorithms written by
      Alessandro Felice Cantatore: they do not apply to the other
      public domain algorithms mentioned in this file (szWildMatch3
      and szWildMatch5 ).

  ---------------------------------------------------------------------------

 This program shows various methods of matching a string against a pattern
 using '*' and '?' wildcards.
 The matching is done accordingly to what specified in the OS/2
 "Control Program Programming Guide and Reference":

     Metacharacters are characters that can be used to represent placeholders
     in a file name. The asterisk (*) and the question mark (?) are the two
     metacharacters.

     The asterisk matches one or more characters, including blanks.

     The question mark matches exactly one character, unless that character
     is a period. To match a period, the original name must contain a period.
     Metacharacters are illegal in all but the last component of a path.

 The only relevant difference is that the asterisk cam also match no
 character as in '*.zip' matching ".zip" or "A*.bbb" matching "a.bbb".

Note :
 The program has been compiled with IBM V.Age C++ 3.08, with the following
 options:
 icc /B"/EXEPACK:2 /NOLOGO" /Q /Fa /Ss /O+ /G5 /Ol /Oc+ /Rn /Gu /Oi+

-------------------------------------------------------------------------- */

#define INCL_DOS
#define INCL_DOSPROFILE
#define INCL_DOSERRORS
#include <os2.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


// definitions --------------------------------------------------------------
#define ITERATIONS    1000       // iterations for the speed test

#define COUNTPROC      8         // count of tested routines

typedef BOOL (*PPATMATCH)(PSZ, PSZ);

// globals ------------------------------------------------------------------

// char table initialized via DosMapCase() as this routine is for a
// subsystem library and toupper() is not available in that context

CHAR mapCaseTable[256];


// array of test patterns and string (these are just for speed tests)
PSZ apszPatt[] = { "?.zip", "*zip", "*.zip", "*?.zip", "?*?.zip", "*?*?.zip",
                   "*sa?a*a?a*a.zip", "a*a?a*a?a*a.zip", "*zi?", "*.zi?", "*zi*", "*.zi*",
                   "a*?*?", "a*b*c*l*m*n*?*.?*"};

PSZ apszStr[] = { "ZIP",
                 "accbddcrrfddhuulggnffphhqggyyyrnnvhgflllmmnnnnkpi.iuuuiyt",
                 "A.bkdfadfasfa.faskfa.sfaf•kl.A.ZIP",
                 "Asdhgerlthwegjsdklgjsdgjsdkgjsdgjsdg.ZIP",
                 "AAgsdjtweoruterjtertweiutwejtwejtwetwoejtwejtrwleAA.ZIP",
                 "Agjsdgjdsjgsdkjgsdjgsjd•gjsd•gjsd•gj•sdgj.A.ZIdgjsdkjglsdjgPPO"};

PSZ apszPatt2[] = { "?.zip", "*zip", "*.zip", "*?.zip", "?*?.zip", "*?*?.zip",
                   "*?*?*.zip", "a*?*?*.zip", "*zi?", "*.zi?", "*zi*", "*.zi*",
                   "a*?*?", "?*.?*"};

PSZ apszStr2[] = { "ZIP", ".ZIP", "A.A.ZIP", "A.ZIP", "AAAA.ZIP", "A.A.ZIPPO"};


/* --------------------------------------------------------------------------
 Print usage notes.
--------------------------------------------------------------------------- */

VOID printHelp(VOID) {
   printf(
" WILDCARD.EXE\n"
" comparison of wildcard matching algorithms\n"
" by Alessandro Felice Cantatore 2003/04/25\n"
" Usage:\n"
" WILDCARD (without parameters)\n"
"          to get a speed test of all the available algorithms\n"
" WILDCARD <algoID> <pattern> <string>\n"
"          to test the algorithm <algoID>\n"
"          where:\n"
"          <algoID>   is a number ranging from 1 to 8 for verbose output\n"
"                     or algoritm number + 10 (11-18) for minimal output;\n"
"          <pattern>  is the pattern to test (e.g. \"*A*B*C*.ZIP\");\n"
"          <string>   is the string to test (e.g. \"zAxBwCy.zip\").\n"
   );
}


/* --------------------------------------------------------------------------
 Get the high resolution timer count.
--------------------------------------------------------------------------- */

long double timeQryTime(VOID) {
   QWORD qw;
   long double ldTime;
   DosTmrQueryTime(&qw);
   ldTime = qw.ulHi;
   ldTime *= 1.09951e+12;
   ldTime += qw.ulLo;
   return ldTime;
}


/* --------------------------------------------------------------------------
 Print the elapsed time.
--------------------------------------------------------------------------- */

VOID printElapsed(long double ldEnd, long double ldStart) {
   printf(" Elapsed time : %Lf milliSeconds\n",
          (ldEnd - ldStart) * 0.838105647e-3);
}


/* --------------------------------------------------------------------------
 Init the case mapping table.
--------------------------------------------------------------------------- */

BOOL initTable(VOID) {
   INT i;
   COUNTRYCODE cc = {0, 0};
   for (i = 0; i < 256; ++i) mapCaseTable[i] = i;
   return !DosMapCase(256, &cc, mapCaseTable);
}


/* --------------------------------------------------------------------------
 START OF PATTERN MATCHING ROUTINES. ALL THE ROUTINES ARE NAMED.
 szWildMatchX where X is a progressive number starting from 0.
--------------------------------------------------------------------------- */


/* --------------------------------------------------------------------------
 1st routine.
 I designed it a few years ago, but the original was buggy and slower than
 this.
 The logic is quite obvious. This is quite slow as it uses recursion.
--------------------------------------------------------------------------- */

BOOL szWildMatch1(PSZ pat, PSZ str) {
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
            if (mapCaseTable[*str] != mapCaseTable[*pat]) return FALSE;
            break;
      } /* endswitch */
      ++pat, ++str;
   } /* endwhile */
   while (*pat == '*') ++pat;
   return !*pat;
}


/* --------------------------------------------------------------------------
 2nd routine.
 It is basically as the previous routine. It uses a different flow just
 to check if that would perform faster (it doesn't).
--------------------------------------------------------------------------- */

BOOL szWildMatch2(PSZ pat, PSZ str) {
   while (*str) {
      if (mapCaseTable[*str] == mapCaseTable[*pat]) {
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
   switch (*pat) {
      case '\0':
         return !*str;
      case '*' :
         return szWildMatch3(pat+1, str) || *str && szWildMatch3(pat, str+1);
      case '?' :
         return *str && (*str != '.') && szWildMatch3(pat+1, str+1);
      default  :
         return (mapCaseTable[*str] == mapCaseTable[*pat]) &&
                 szWildMatch3(pat+1, str+1);
   } /* endswitch */
}


/* --------------------------------------------------------------------------
 4th routine.
 This was inspired by the previous routine.
 I modified it trying to reduce recursion as much as possible.
 While this is faster than the snippets.org routine it is not as fast as
 the first two ones.
--------------------------------------------------------------------------- */

BOOL szWildMatch4(PSZ pat, PSZ str) {
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
            if (mapCaseTable[*str] != mapCaseTable[*pat]) return FALSE;
            break;
      } /* endswitch */
      ++str, ++pat;
   } /* endwhile */
   while (*pat == '*') ++pat;
   return !*pat;
}


/* --------------------------------------------------------------------------
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

new_segment:

   star = 0;
   if (*pat == '*') {
      star = 1;
      do { pat++; } while (*pat == '*'); /* enddo */
   } /* endif */

test_match:

   for (i = 0; pat[i] && (pat[i] != '*'); i++) {
      if (mapCaseTable[str[i]] != mapCaseTable[pat[i]]) {
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
            if (mapCaseTable[str[i]] != mapCaseTable[pat[i]])
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
 7th routine.
 This is not different from the previous one... I thought it would have been
 possible to squeeze some more power by using pointers rather than array
 indexes and it looks like I was right although the speed gain is really
 minimum.
--------------------------------------------------------------------------- */

BOOL szWildMatch7(PSZ pat, PSZ str) {
   PSZ s, p;
   BOOL star = FALSE;

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
            if (mapCaseTable[*s] != mapCaseTable[*p])
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
 8th routine.
 This is the same as the 7th routine, but it assumes that pattern has been
 preprocessed to remove consecutive asterisks.
--------------------------------------------------------------------------- */

BOOL szWildMatch8(PSZ pat, PSZ str) {
   PSZ s, p;
   BOOL star = FALSE;

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
            if (mapCaseTable[*s] != mapCaseTable[*p])
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


/* --------------------------------------------------------------------------
 Speed test.
 Run in a loop tests against various patterns and matching strings.
 PPATMATCH pFunc : is a function pointer.
 PSZ funcName    : is the function name.
--------------------------------------------------------------------------- */

VOID makeSpeedTest(PPATMATCH pFunc, PSZ funcName) {
   long double startTime, endTime;
   int i, j, k, l;

   printf("\ntesting %s:\n", funcName);

   startTime = timeQryTime();
   for (i = 0, l = 0; i < ITERATIONS; ++i) {
      for (j = 0; j < 14; ++j) {
         for (k = 0; k < 6; ++k) {
            pFunc(apszPatt[j], apszStr[k]);
            ++l;
         } /* endfor */
      } /* endfor */
   } /* endfor */
   endTime = timeQryTime();
   printElapsed(endTime, startTime);

   startTime = timeQryTime();
   for (i = 0, l = 0; i < ITERATIONS; ++i) {
      for (j = 0; j < 14; ++j) {
         for (k = 0; k < 6; ++k) {
            pFunc(apszPatt[j], apszStr2[k]);
            ++l;
         } /* endfor */
      } /* endfor */
   } /* endfor */
   endTime = timeQryTime();
   printElapsed(endTime, startTime);

   startTime = timeQryTime();
   for (i = 0, l = 0; i < ITERATIONS; ++i) {
      for (j = 0; j < 14; ++j) {
         for (k = 0; k < 6; ++k) {
            pFunc(apszPatt2[j], apszStr2[k]);
            ++l;
         } /* endfor */
      } /* endfor */
   } /* endfor */
   endTime = timeQryTime();
   printElapsed(endTime, startTime);

   startTime = timeQryTime();
   for (i = 0, l = 0; i < ITERATIONS; ++i) {
      for (j = 0; j < 14; ++j) {
         for (k = 0; k < 6; ++k) {
            pFunc(apszPatt2[j], apszStr[k]);
            ++l;
         } /* endfor */
      } /* endfor */
   } /* endfor */
   endTime = timeQryTime();
   printElapsed(endTime, startTime);
}


/* --------------------------------------------------------------------------
 Speed test.
 Test all the available matching routines.
--------------------------------------------------------------------------- */

VOID testSpeed(VOID) {
   makeSpeedTest(szWildMatch1, "szWildMatch1");
   makeSpeedTest(szWildMatch2, "szWildMatch2");
   makeSpeedTest(szWildMatch3, "szWildMatch3");
   makeSpeedTest(szWildMatch4, "szWildMatch4");
   makeSpeedTest(szWildMatch5, "szWildMatch5");
   makeSpeedTest(szWildMatch6, "szWildMatch6");
   makeSpeedTest(szWildMatch7, "szWildMatch7");
   makeSpeedTest(szWildMatch8, "szWildMatch8");
}


/* --------------------------------------------------------------------------
 Test the correctness of the pattern matching of the various algorithms.
 PPATMATCH pFunc : is a procedure address
 PSZ funcName    : is the procedure name
 PSZ pat         : is the tested pattern
 PSZ str         : is the tested string
 BOOL verbose    : display verbose or minimal output.
 Note minimal output is comfortable for comparing the output of the various
 routines (running tests via a batch file).
--------------------------------------------------------------------------- */

VOID makeTest(PPATMATCH pFunc, PSZ funcName, PSZ pat, PSZ str, BOOL verbose) {
   if (verbose) {
      printf("testing function  : %s\n"
             "pattern is        : %s\n"
             "tested string is  : %s\n"
             "result            : the string %s the pattern\n",
             funcName, pat, str,
             (pFunc(pat, str) ?
             "matches" : "does not match"));
   } else {
      printf("%s  %20s %20s\n", (pFunc(pat, str)? "==" : "! "), pat, str);
   } /* endif */
}


/* --------------------------------------------------------------------------
 According to the input parameters test a pattern matching algorithm.
 PSZ pat         : is the tested pattern
 PSZ str         : is the tested string
 ULONG ifn       : function index
 BOOL verbose    : display verbose or minimal output.
--------------------------------------------------------------------------- */

VOID testMatch(PSZ pat, PSZ str, ULONG ifn, BOOL verbose) {
   PPATMATCH apFunc[] = {szWildMatch1, szWildMatch2, szWildMatch3,
                         szWildMatch4, szWildMatch5, szWildMatch6,
                         szWildMatch7, szWildMatch8};
   CHAR buf[32];
   sprintf(buf, "szWildMatch%u", ifn + 1);
   makeTest(apFunc[ifn], buf, pat, str, verbose);
}


/* --------------------------------------------------------------------------
 MAIN.
 Usage:
 -1) no parameters
     The program runs the speed tests on all routines.
 -2) <pattern> <string>
     The program compares pattern to string through the first routine
     in verbose mode.
 -3) <index> <pattern> <string>
     Where index is an integer ranging from 1 to 7.
     The program compares pattern to string using the routine indexTH
     routine in verbose mode.
 -4) <index> <pattern> <string>
     Where index is an integer ranging from 11 to 17.
     The program compares pattern to string using the routine indexTH - 10
     routine displaying minimal output.

--------------------------------------------------------------------------- */

int main(int argc, char** argv) {
   ULONG ul = 0;
   // set time critical priority to get sure that speed tests are not
   // affected by other processes running on the system.
   DosSetPriority(PRTYS_THREAD, PRTYC_TIMECRITICAL, + 31, 0);
   initTable();
   if (argc == 1) {
      testSpeed();
   } else if (argc == 4) {
      ul = strtoul(argv[1], NULL, 10);
      if ((ul >= 11) && (ul <= (10 + COUNTPROC))) {
         testMatch(argv[argc - 2], argv[argc - 1], ul - 11, FALSE);
      } else if ((ul >= 1) && (ul <= COUNTPROC)) {
         testMatch(argv[argc - 2], argv[argc - 1], ul - 1, TRUE);
      } else {
         printHelp();
      } /* endif */
   } else {
      printHelp();
   } /* endif */
   return 0;
}
