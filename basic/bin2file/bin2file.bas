' FreeBASIC 1.09
'

#include "crt.bi"

#include "file.bi"
#include "fbgetopt.bi"

#Include Once "windows.bi"
#Include Once "vbcompat.bi" 'file.bi wird mitgeladen

using fbgetopt


print  "Put binary portion to file, version 1.0"
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



Sub PrintHelp
print  "Usage: bin2file [-vfh] [-i infile] [-o outfile]"
print  "       [-l in_offset] [-s in_size] [-p out_offset]"
print  "       -h       this help"
print  "       -v       verbose output (default=no)"
print  "       -f       don't suppress questions (default=yes)"
print  "       -l val   byte offset on input stream (default=0)"
print  "       -s N     copy N bytes from input stream (default=0)"
print  "       -p val   byte offset on output stream (default=0)"
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

in_offset = 0 : in_size = 0 : infilename = "": outfilename = "" : nosupress = 0 : out_offset = 0 

static as Options LongOptions(10) => {(Options("verbose", no_argument, @VerboseFlag, 1)),_
				     (Options("brief", no_argument, @VerboseFlag, 0)),_
				     (Options("help", no_argument, 0, asc("h"))),_
				     (Options("add", no_argument, 0, asc("a"))),_
				     (Options("append", no_argument, 0, asc("b"))),_
				     (Options("nosupress", no_argument, 0, asc("f"))),_
                                     (Options("inofs", required_argument, 0, asc("l"))),_
                                     (Options("outofs", required_argument, 0, asc("p"))),_
                                     (Options("insize", required_argument, 0, asc("s"))),_
                                     (Options("output", required_argument, 0, asc("o"))),_
				     (Options("input", required_argument, 0, asc("i")))}

while 1

	c = GetLongOpts("abi:l:o:f:p:s:hv", LongOptions(), OptionIndex)

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
			print "option -s with value " & optarg : in_size = val(optarg)
		case "l":
			print "option -s with value " & optarg : in_offset = val(optarg)
		case "p":
			print "option -s with value " & optarg : out_offset = val(optarg)
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
    print "in_size = " &  in_size
    print "in_offset = " & in_offset
    print "out_offset = " & out_offset
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
    ReDim DataArray(myfilelen)
   'skip the first M items
    Seek fileNum, in_offset * SizeOf(DataArray(0)) + 1 'Note: +1 & seek(...) not allowed
   'try to read the next N items
    result = Get(fileNum, , DataArray(0), in_size, numBytes)
    if (VerboseFlag) then Print "Number of bytes read: " & Str(numBytes) end if
    Close(fileNum)
Else
    Print "Failed to open " & infilename & " for reading"
    Stop(10)
End If


if (VerboseFlag) then print "Read output binary file" end if

Dim As Integer OutFileHandler
Dim As UByte   OutDataArray()
DIM As long out_size
Dim As Long OutfileNum
Dim d2 As Double

out_size = 0

'open in binary reading mode
OutfileNum = FreeFile
If Open(outfilename, For Binary, Access Read, As OutfileNum) = 0 Then
    'build buffer space
    Dim myfileLen2 As LongInt = Lof(OutfileNum)
    if (VerboseFlag) then Print "filesize: " & Str(myfileLen2) end if
    ReDim OutDataArray(myfilelen2)
   'skip the first M items
   'Seek OutfileNum, out_offset * SizeOf(OutDataArray(0)) + 1 'Note: +1 & seek(...) not allowed
   'try to read the all remaining N items
    out_size = myfileLen2
    'if (myfileLen2 > in_size) then out_size = myfileLen2 - in_size end if
    result = Get(OutfileNum, , OutDataArray(0), out_size, numBytes)
    if (VerboseFlag) then Print "Number of bytes read: " & Str(numBytes) end if
    Close(OutfileNum)
Else
    Print "Failed to open " & outfilename & " for reading"
    Stop(10)
End If


'update output buffer 
if (VerboseFlag) then print "Update output buffer" end if

for i as long = 0 to in_size-1
    OutDataArray(0+i+out_offset) = DataArray(i)
next i


if (VerboseFlag) then print "Write output binary file" end if

OutfileNum = FreeFile
d2 = FileDateTime( outfilename )
'open in binary writing mode
If Open(outfileName, For Binary, Access Write, As OutfileNum) = 0 Then
    'write all bytes
    result = Put(OutfileNum, , OutDataArray(0), out_size) 'No @buffer(0)
    if (VerboseFlag) then Print "Number of bytes written: " & Str(numBytes) end if
    Close(OutfileNum)
Else
    Print "Failed to open " & outfileName & " for writing"
    Stop(30)
End If


if (VerboseFlag) then print "All processing done" end if
