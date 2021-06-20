{-----------------------------------------------------------------------}
{ PROJECT		NON-PROFIT HIGH QUALITY PROFESSIONAL SOFTWARE,  }
{			AVAILABLE FOR ALL WORLD				}
{ LIBRARY		SYSTEM UTILITIES                                }
{ MODULE		CONVERT_UNIX_TO_DOS_TEXT                        }
{ FILE NAME		UNIX2DOS.PAS					}
{ PURPOSE               CONVERT UNIX-FORMATTED STYLE DOCUMENTATION TO   }
{                       DOS-FORMATTED STYLE DOCUMENTATION               }
{ VERSION		1.10						}
{ DATE			20-Sep-93					}
{ DESIGN		Dmitry Stefankov				}
{ IMPLEMENTATION	Dmitry Stefankov 				}
{ COMPANY		Freelance Software Engineer			}
{ ADDRESS		Isakowskogo str, 4-2-30				}
{			Moscow, 123181					}
{			USSR						}
{			Tel. 007 (095) 944-6304				}
{ COPYRIGHT NOTICE	Copyright (C) 1987-1993, Dmitry Stefankov	}
{ RESTRICTED RIGHTS	AVAILABLE ONLY FOR FREE DISTRIBUTION,           }
{			NOT FOR COMMERCIAL PURPOSE			}
{ COMPUTER		IBM PC or compatible				}
{ OPERATING SYSTEM	MS/PC-DOS Version 3.30 or higher		}
{ COMPILER		Turbo Pascal Version 6.0			}
{                       (Borland International Inc.)  or compatible     }
{ ASSEMBLY LANGUAGE	Microsoft MASM 5.10 or compatible               }
{ LINKER		Turbo Pascal internal                           }
{ ARGUMENTS             <infile>   -   input filename                   }
{			<outfile>  -   output filename			}
{ RETURN		See error return codes definitions		}
{ REQUIRES		Source Code Files                               }
{                       NONE                                            }
{                       External Object Files                           }
{                       NONE                                            }
{ NATURAL LANGUAGE      English Language                                }
{ SPECIAL		None						}
{ DESCRIPTION		1.Read   input  stream                          }
{                       2.Format output stream                          }
{                       3.Write  output stream                          }
{ REVISION HISTORY	Dima Stefankov (DS)				}
{   			1.00  08-Jul-93  DS  initilal release		}
{			1.01  13-Jul-93  DS  updated help screen	}
{                       1.02  16-Jul-93  DS  fixed problem with string  }
{                                            size                       }
{			1.10  20-Sep-93  DS  some style updates		}
{-----------------------------------------------------------------------}


{*======================= PROGRAM HEADER PART ==========================*}

PROGRAM  UnixToDosTextReFormat;


{*** other modules ***}
{*USES;*}

{** switches for compilation **}
{$S-}		  {*  stack checking               *}
{$R-}             {*  range checking               *}
{$X-}             {*  extended syntax              *}


{** debugging version **}
{***$DEFINE DebugVersion}


{*========================== CONSTANTS PART ============================*}

CONST
   { program descriptions }
     asPurpose                  =       'UNIX to DOS reformat ';
     asMsgVersion               =       'Version ';
     asVersion                  =       '1.10';
     asAuthor                   =       'Dmitry Stefankov';
     asCopyright                =       'Copyright (c) 1987, 1993';
     asProgram                  =       'Unix2Dos';
     asProgramPrompt            =       asProgram+': ';
     asProgramU                 =       'UNIX2DOS';


   { program exit codes }
     errTerminateOK             =     0;
     errBadParamStr             =     1;
     errSourceNotFound          =     2;
     errDestDontWrite           =     3;

   { Dos miscellaneous }
     achDosSwitch               =     '/';
     achUnixSwitch              =     '-';
     achCommentMark             =     '#';
     achDosEndFile              =     #$1A;
     aDosFileNameLength         =     13;

   { TP error codes }
     errOK                      =     0;


   { base numeric system }
     aHexRadix                  =     16;
     aMaxByteVal                =     255;
     achHexPrefix               =     '$';
     achHexSuffix               =     'h';

   { character constants }
     achNULL                    =     #0;
     achHTAB                    =     #9;
     achLF                      =     #10;
     achFF                      =     #12;
     achCR                      =     #13;
     achESC                     =     #27;
     achSPC                     =     #32;
     achBlank                   =     ' ';
     achColon                   =     ':';
     achComma                   =     ',';
     achSemiColon               =     ';';
     achPoint                   =     '.';
     achZERO                    =     '0';
     achNine                    =     '9';
     achUpperA                  =     'A';
     achUpperF                  =     'F';
     achLowerA                  =     'a';
     achLowerF                  =     'f';
     achDEL                     =     #127;

   { string constants }
     asBlankStr                 =       '';
     asSpaces2                  =       achBlank+achBlank;
     asSpaces4                  =       asSpaces2+asSpaces2;
     asSpaces6                  =       asSpaces4+asSpaces2;


   { user confirm }
     achUserWant                =     'Y';
     achUserDontWant            =     'N';

   { strings definitions }
     aMaxLinesPerPage           =      66;
     aSkipLines                 =      3;
     aLinesOnFirstPage          =      aMaxLinesPerPage - aSkipLines;

   { buffers size }
     aMaxTextBufSize            =       4096;          { 4K  }


{*==================== TYPE DECLARATIONS PART ==========================*}

TYPE
    STR2        =       STRING[2];
    STR4        =       STRING[4];
    STR6        =       STRING[6];
    STR8        =       STRING[8];
    STR9        =       STRING[9];
    STR10       =       STRING[10];
    STR80       =       STRING[80];


{*====================== TYPED CONSTANTS PART ==========================*}

CONST
   gsInputFileName              :       STR80            =   asBlankStr;
   gsOutputFileName             :       STR80            =   asBlankStr;

   gliLineCount                 :       System.Longint   =   0;
   gdwLinesOnPage               :       System.Word      =   0;


{*=========================== VARIABLES PART ===========================*}

VAR
   gfInputStream                :       FILE  OF  System.Byte;
   gfInputStreamRec             :       FILE ABSOLUTE gfInputStream;
   gfOutputStream               :       FILE  OF  System.Byte;
   gfOutputStreamRec            :       FILE ABSOLUTE gfOutputStream;

   gdwBytesInLine               :       System.Word;
   gsTempInput                  :       STRING;
   giErrorCode                  :       System.Integer;
   gdbIndex                     :       System.Byte;
   gdbTextBuf                   :       ARRAY[1..aMaxTextBufSize] OF System.Byte;


{*=========================== FUNCTIONAL PART ==========================*}

FUNCTION  _fnbFileExist(VAR fStruc : FILE; sFileName : STRING) : System.Boolean;
{* Check that file exits. *}
VAR
  bResult  :  System.Boolean;

BEGIN
  {** try to open the file **}
  System.Assign(fStruc,sFileName);
  {$I-}
  System.Reset(fStruc);
  {$I+}

  {** copy the result of last I/O operation **}
  bResult := (System.IOResult = 0);

  IF (bResult)
    THEN  System.Close(fStruc);
  {if-then}

  _fnbFileExist := bResult;
END; { _fnbFileExist }


FUNCTION   _fnchGetFirstChar(sInput : STRING) : System.Char;
{* Returns a first char from string. *}
VAR
  chTemp  :  System.Char;

BEGIN
   IF (System.Length(sInput) <> 0)
     THEN  chTemp := sInput[1]
     ELSE  chTemp := achNULL;
   {if-then-else}
  _fnchGetFirstChar := chTemp;
END;
{ _fnchGetFirstChar }


{*=========================== PROCEDURAL PART ==========================*}

PROCEDURE  _ReadUnixLine;
{* Reads an UNIX-file line. *}
VAR
  dbTemp        :       Byte;
  bEndOfLine    :       System.Boolean;

BEGIN
   gdwBytesInLine := 0;
   dbTemp := $0;
   bEndOfLine := System.False;

   WHILE NOT(bEndOfLine)
         AND NOT(EOF(gfInputStream)) DO
   BEGIN
      System.Read(gfInputStream,dbTemp);
      IF  (dbTemp <> System.Byte(achLF))
       THEN  BEGIN
          If (gdwBytesInLine <= (aMaxTextBufSize-1))
            THEN BEGIN
                System.Inc(gdwBytesInLine);
                gdbTextBuf[gdwBytesInLine] := dbTemp;
                END;
          {if-then}
             END
       ELSE  BEGIN
          bEndOfLine := System.True;
             END;
      {if-then-else}
   END;
   {while-do}
END;
{ _ReadUnixLine }


PROCEDURE  _WriteDosLine;
{* Writes a DOS-file line. *}
VAR
  dwIndex        :       System.Word;
  dbTemp         :       System.Byte;

BEGIN
   IF (gdwBytesInLine <> 0)
     THEN  BEGIN
        FOR  dwIndex := 1  TO  gdwBytesInLine  DO
        BEGIN
           System.Write(gfOutputStream,gdbTextBuf[dwIndex]);
        END;
        {for-to-do}
          END;
   {if-then}
   dbTemp := System.Byte(achCR);
   System.Write(gfOutputStream,dbTemp);
   dbTemp := System.Byte(achLF);
   System.Write(gfOutputStream,dbTemp);
END;
{ _WriteDosLine }



PROCEDURE    _CopyrightDisplay;
{* Outputs the copyright notice. *}
BEGIN
     System.WriteLn(asPurpose+
                    asMsgVersion+
                    asVersion+
                    achComma+achBlank +
                    asCopyright+
                    asSpaces2+
                    asAuthor);
END;  { _CopyrightDisplay }


{*============================== MAIN PART =============================*}

BEGIN
    _CopyrightDisplay;

    IF (System.ParamCount < 2)
      THEN  BEGIN
         System.WriteLn(asProgramPrompt+'short help for you.');
         System.WriteLn('Usage: '+ asProgram + ' infile outfile');
         System.WriteLn('  infile   -  source file (UNIX-style  text)');
         System.WriteLn('  outfile  -  target file (MSDOS-style text)'); 
         System.Halt(errBadParamStr);
            END;
    {if-then}

    gsInputFileName  := System.ParamStr(1);
    gsOutputFileName := System.ParamStr(2);


    {** source file exists? **}
    IF  NOT(_fnbFileExist(gfInputStreamRec,gsInputFileName)) THEN
    BEGIN
      System.WriteLn(asProgramPrompt+'Unable to open file '+gsInputFileName);
      System.Halt(errSourceNotFound);
    END;
    {if-then}

    {** destination file present? **}
    IF (_fnbFileExist(gfOutputStreamRec,gsOutputFileName)) THEN
    BEGIN
      System.Write(asProgramPrompt+'Output file '+gsOutputFileName+
                   ' already exists. Overwrite? (n/y): ');
      System.ReadLn(gsTempInput);
      IF (System.UpCase(_fnchGetFirstChar(gsTempInput)) <> achUserWant)
        THEN  System.Halt(errDestDontWrite);
      {if-then}
    END;
    {if-then}

  {* open input stream *}
    System.Assign(gfInputStream,gsInputFileName);
    System.Reset(gfInputStream);

  {* open output stream *}
    System.Assign(gfOutputStream,gsOutputFileName);
    System.ReWrite(gfOutputStream);


  {* first page length = 63 lines: just copy *}
    FOR  gdbIndex := 1  TO  aLinesOnFirstPage  DO
    BEGIN
       System.Inc(gliLineCount);
       System.Write(achCR+asProgramPrompt+'Line ',gliLineCount);
       _ReadUnixLine;
       _WriteDosLine;
    END;


  {* all other pages = 66 lines *}
    WHILE  NOT(System.EOF(gfInputStream))  DO
    BEGIN
       System.Inc(gliLineCount);
       IF  (gdwLinesOnPage > aMaxLinesPerPage)
         THEN  gdwLinesOnPage := 0;
       {if-then}
       System.Inc(gdwLinesOnPage);
       System.Write(achCR+asProgramPrompt+'Line ',gliLineCount);
       _ReadUnixLine;
       IF (gdwLinesOnPage > aSkipLines)
         THEN  _WriteDosLine;
       {if-then}
    END;
    {while-do}


 {* close all streams *}
    System.Close(gfInputStream);
    System.Close(gfOutputStream);


  {* last report *}
    System.WriteLn;
    System.WriteLn(asProgramPrompt+'Done.');

END.