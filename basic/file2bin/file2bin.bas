' FreeBASIC 1.09
'

#include "fbgetopt.bi"

using fbgetopt


print  "Extract binary portion from file, version 1.0"
print  "Copyright (C) 2022-2024 Dmitry Stefankov. All Rights Reserved."

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


Sub PrintHelp
print  "Usage: file2bin [-vfh] [-i infile] [-o outfile]"
print  "       [-l in_offset] [-s in_size]"
print  "       -h       this help"
print  "       -v       verbose output (default=no)"
print  "       -f       don't suppress questions (default=yes)"
print  "       -l val   byte offset on input stream (default=0)"
print  "       -s N     copy N bytes from input stream (default=0)"
End Sub


'Flag set by --verbose option
static VerboseFlag as long
dim c as string
dim OptionIndex as long
static offset as long
static size as long
static infilename as string
static outfilename as string
static nosupress as long

offset = 0 : size = 0 : infilename = "": outfilename = "" : nosupress = 0

static as Options LongOptions(9) => {(Options("verbose", no_argument, @VerboseFlag, 1)),_
				     (Options("brief", no_argument, @VerboseFlag, 0)),_
				     (Options("help", no_argument, 0, asc("h"))),_
				     (Options("add", no_argument, 0, asc("a"))),_
				     (Options("append", no_argument, 0, asc("b"))),_
				     (Options("nosupress", no_argument, 0, asc("f"))),_
                                     (Options("offset", required_argument, 0, asc("l"))),_
                                     (Options("size", required_argument, 0, asc("s"))),_
                                     (Options("output", required_argument, 0, asc("o"))),_
				     (Options("input", required_argument, 0, asc("i")))}

while 1

	c = GetLongOpts("abi:l:o:f:s:hv", LongOptions(), OptionIndex)

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
			print "option -s with value " & optarg : size = val(optarg)
		case "l":
			print "option -s with value " & optarg : offset = val(optarg)
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
    print "size = " &  size
    print "offset = " & offset
end if


'Print any remaining command line arguments (not options).
if OptInd <= ParamCount then print "non-option commandline args: "
for i as long = OptInd to ParamCount
	print ParamStr(i)
next i


if (VerboseFlag) then print "Read input binary file" end if


Dim As Integer FileHandler
Dim As UByte   DataArray()
   
''FileHandler = FreeFile
''Open infilename For Binary, Access Read, As #FileHandler
    ''Dim myfileLen As LongInt = Lof(1)
    ''ReDim DataArray(Lof(FileHandler)-1)
    ''ReDim DataArray(myfilelen)
    ''Get #FileHandler, , DataArray()
''Close #FileHandler

Dim As Long fileNum
Dim As Integer numBytes
Dim As Integer result

'open in binary reading mode
fileNum = FreeFile
If Open(infilename, For Binary, Access Read, As fileNum) = 0 Then
    'build buffer space
    Dim myfileLen As LongInt = Lof(1)
    ReDim DataArray(myfilelen)
   'skip the first M items
    Seek fileNum, offset * SizeOf(DataArray(0)) + 1 'Note: +1 & seek(...) not allowed
   'try to read the next N items
    result = Get(fileNum, , DataArray(0), size, numBytes)
    if (VerboseFlag) then Print "Number of bytes read: " & Str(numBytes) end if
    Close(fileNum)
Else
    Print "Failed to open " & infilename & " for reading"
    Stop(10)
End If


if (VerboseFlag) then print "Write output binary file" end if


''FileHandler = FreeFile
''Open outfilename, For Binary, Access Write, As #FileHandler
  ''static ByteCounter AS long
  ''static Result AS long 
  ''Result = offset+size
  ''FOR ByteCounter = offset TO Result
    ''PUT #FileHandler, ByteCounter, DataArray(ByteCounter)
  ''NEXT ByteCounter
''Close #FileHandler


fileNum = FreeFile
'open in binary writing mode
If Open(outfileName, For Binary, Access Write, As fileNum) = 0 Then
    'write N bytes
    result = Put(fileNum, , DataArray(0), size) 'No @buffer(0)
    numBytes = Seek(fileNum) - 1 'FreeBASIC file position is 1-based
    if (VerboseFlag) then Print "Number of bytes written: " & Str(numBytes) end if
    Close(fileNum)
Else
    Print "Failed to open " & outfileName & " for writing"
    Stop(20)
End If


if (VerboseFlag) then print "All processing done" end if
