' FreeBASIC 1.09
'

#include "crt.bi"

#include "file.bi"
#include "fbgetopt.bi"

#Include Once "windows.bi"
#Include Once "vbcompat.bi" 'file.bi wird mitgeladen

using fbgetopt


print  "Search and replace hexdec. pattern per file, version 1.0"
print  "Copyright (C) 2024 Dmitry Stefankov. All Rights Reserved."

	if( __FB_ARGC__ = 1 ) then
		print "(no arguments)"
                System 255
	end if

Function HasOption (Byref opt As String) As Integer
  Dim As Integer i = 1
  Do
    Dim As String arg = Command(i)
    If arg = "" Then
      Exit Do
    Elseif arg = opt Then
      Return -1
    End If
    i += 1
  Loop
End Function

Function GetOptionValue (Byref opt As String) As String
  Dim As Integer i = 1
  Do
    Dim As String arg = Command(i)
    If arg = "" Then
      Exit Do
    Elseif arg = opt Then
      Return Command(i+1)
    End If
    i += 1
  Loop
End Function


sub InsertStr overload (byref s1 as string, byref s2 as const string, _
byval start as uinteger)
	' in <s1> insert <s2> at <start>
	s1 = left(s1, start - 1) + s2 + mid(s1, start)
end sub

sub InsertStr overload (byref s1 as string, byref s2 as const string, _
byval start as uinteger, byval count as uinteger)
	' in <s1> insert <s2> at <start> and replace <count> characters
	s1 = left(s1, start - 1) + s2 + mid(s1, start + count)
end sub

sub Replace(byref s1 as string, byref s2 as const string, _
byref s3 as const string)
	' in <s1> replace <s2> by <s3>
	dim p as uinteger
	
	if s3 <> s2 then
		p = instr(s1, s2)
		if p then
			InsertStr(s1, s3, p, len(s2))
		end if
	end if
end sub

sub ReplaceAll(byref s1 as string, byref s2 as const string, _
byref s3 as const string)
	' in <s1> replace all occurrences of <s2> by <s3>
	dim p as uinteger
	dim q as uinteger
	
	if s3 <> s2 then
		p = instr(s1, s2)
		if p then
			q = len(s3)
			if q = 0 then q = 1
			do
				InsertStr(s1, s3, p, len(s2))
				p = instr(p + q, s1, s2)
			loop until p = 0
		end if
	end if
end sub


Function  FileContent(byref fileName as String) as String

    function = ""
    
    Var  fileNum = FreeFile
    If  Open(fileName, for input, as fileNum) = 0 Then
        function = Input(Lof(fileNum), fileNum)
        Close fileNum
    End  if

End  function


Sub PrintHelp
print  "Usage: findrep [-vfh] [-i infile] [-o outfile]"
print  "       [-s srch_pat] [-r repl_str]"
print  "       -h       this help"
print  "       -v       verbose output (default=no)"
print  "       -f       don't suppress questions (default=yes)"
print  "       -s str   search pattern (default=empty)"
print  "       -r str   replace pattern (default=empty)"

End Sub


'Flag set by --verbose option
static VerboseFlag as long
dim c as string
dim OptionIndex as long
static in_offset as long
static out_offset as long
static in_size as long
static infilename as string
static outfilename as string
static nosupress as long
static search_str as string
static replace_str as string

in_offset = 0 : in_size = 0 : infilename = "": outfilename = "" : nosupress = 0 : out_offset = 0 
search_str = "" : replace_str = ""

static as Options LongOptions(10) => {(Options("verbose", no_argument, @VerboseFlag, 1)),_
				     (Options("brief", no_argument, @VerboseFlag, 0)),_
				     (Options("help", no_argument, 0, asc("h"))),_
				     (Options("add", no_argument, 0, asc("a"))),_
				     (Options("append", no_argument, 0, asc("b"))),_
				     (Options("nosupress", no_argument, 0, asc("f"))),_
                                     (Options("search", required_argument, 0, asc("s"))),_
                                     (Options("replace", required_argument, 0, asc("r"))),_
                                     (Options("output", required_argument, 0, asc("o"))),_
				     (Options("input", required_argument, 0, asc("i")))}

while 1

	c = GetLongOpts("abi:o:f:r:s:hv", LongOptions(), OptionIndex)

	if c = EndOfOptions then exit while
	
	select case c
		case FlagSet:
			if LongOptions(OptionIndex).flag <> 0 then exit select
			print "option " & LongOptions(OptionIndex).OptName
			if optarg <> "" then print " with arg " & LongOptions(OptionIndex).OptName
			print ""
		case "a":
			print "option -a"
		case "b":
			print "option -b"
		case "v":
			print "option -v" : VerboseFlag = 1
		case "f":
			print "option -v" : nosupress = 1
		case "s":
			print "option -s with value " & optarg : search_str = optarg
		case "r":
			print "option -r with value " & optarg : replace_str = optarg
		case "i":
			print "option -i with value " & optarg : infilename = optarg
		case "o":
			print "option -o with value " & optarg : outfilename = optarg
		case "?":
		case "h":
			'opterr not set, default behavior is to let
			'getopt handle the error
                        PrintHelp
                        System 254
		case else
			end 1
	end select
wend

'Instead of reporting '--verbose' and '--brief' as they are encountered,
'we report the final status resulting from them.
if (VerboseFlag) then 
    print "verbose flag is set"
    print "infilename = " & infilename
    print "outfilename = " & outfilename
    print "search_pat = " & search_str
    print "replace_pat = " & replace_str
end if


'Print any remaining command line arguments (not options).
if OptInd <= ParamCount then print "non-option commandline args: "
for i as long = OptInd to ParamCount
	print ParamStr(i)
next i


if (VerboseFlag) then print "Read input binary file" end if


Dim As Integer FileHandler
Dim As UByte   DataArray()
   
Dim As Long fileNum
Dim As Integer numBytes
Dim As Integer result
Dim d1 As Double

'open in binary reading mode
fileNum = FreeFile
If Open(infilename, For Binary, Access Read, As fileNum) = 0 Then
    d1 = FileDateTime( infilename )
    'build buffer space
    Dim myfileLen As LongInt = Lof(fileNum)
    if (VerboseFlag) then Print "filesize: " & Str(myfileLen) end if
    ReDim DataArray(myfilelen+1)
    for i as long = 0 to myfilelen 
        DataArray(i) = 0 
    next i
   'try to read the next N items
    result = Get(fileNum, , DataArray(0), myfileLen, numBytes)
    if (VerboseFlag) then Print "Number of bytes read: " & Str(numBytes) end if
    Close(fileNum)
Else
    Print "Failed to open " & infilename & " for reading"
    Stop(10)
End If


Var  InfileNum = FreeFile

Open infilename for input as InfileNum
'Var  fileContentIn = Input(Lof(InfileNum), InfileNum)
DIM AS string fileContentIn = Input(Lof(InfileNum), InfileNum)
Close InfileNum
'print fileContentIn

'dim as string mybuffer
'open infilename for binary as 1
'mybuffer = space(lof(1))
'get #1,,mybuffer
'print mybuffer


Dim As Integer OutFileHandler
Dim As UByte   OutDataArray()
DIM As long out_size
Dim As Long OutfileNum
Dim d2 As Double

out_size = 0

'update output buffer 
if (VerboseFlag) then print "Update output buffer" end if

Dim s1 As string
Dim As Byte Ptr p = @DataArray(0)
'Dim As String Ptr s2 = @DataArray(0)
's1 = *Cast(Zstring Ptr, p)
s1 = *Cast(Zstring Ptr, @DataArray(0))
print s1

'ReplaceAll(DataArray, search_str, replace_str )
ReplaceAll(s1, search_str, replace_str )
out_size = len(s1)
if (VerboseFlag) then print "out_size = ", out_size end if
print s1 

ReplaceAll(fileContentIn, search_str, replace_str )
out_size = len(fileContentIn)
if (VerboseFlag) then print "out_size = ", out_size end if
if (VerboseFlag) then print "fileContentIn: ", fileContentIn end if

if (VerboseFlag) then print "Write output binary file" end if

'OutfileNum = FreeFile
'd2 = FileDateTime( outfilename )
'open in binary writing mode
'If Open(outfileName, For Binary, Access Write, As OutfileNum) = 0 Then
    'write all bytes
    'Dim As UByte ptr up1
    'up1 = @Cast(UByte ptr, s1) 
    'result = Put(OutfileNum, , @s1[0], out_size) 'No @buffer(0)
    'result = Put(OutfileNum, , DataArray(0), out_size) 'No @buffer(0)
    'result = Put(OutfileNum, , @fileContentIn(0), out_size) 'No @buffer(0)
    'result = Put(OutfileNum, , @fileContentIn(0), out_size) 'No @buffer(0)
    'result = Put(OutfileNum, , fileContentIn As string, out_size) 
    'DIM as UBYTE ptr up2
    'up2 = Allocate(out_size)
    'for i as integer = 0 to out_size-1
    '    up2[i] = fileContentIn(i) & &HFF
    'next i
    'result = Put(OutfileNum, , fileContentIn(0), out_size) 
    'if (VerboseFlag) then Print "Number of bytes written: " & Str(numBytes) end if
    'Put OutfileNum, 1, @fileContentIn(0)
    'PUT OutfileNum, 1, s1
    'WRITE OutfileNum, s1
    'Close(OutfileNum)
'Else
    'Print "Failed to open " & outfileName & " for writing"
    'Stop(30)
'End If

'OPEN "myfile.txt" FOR OUTPUT AS #1
'WRITE #1, 1,fileContentIn
'CLOSE #1

OPEN outfileName FOR OUTPUT AS #1
'WRITE #1, s1
PUT #1, 1, s1
CLOSE #1


if (VerboseFlag) then print "All processing done" end if
