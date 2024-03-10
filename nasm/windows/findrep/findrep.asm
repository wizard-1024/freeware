; Microsoft Windows sample code
; with known limitations
; Dmitry Stefankov Feb-2024

global main
extern GetStdHandle
extern WriteFile
extern GetCommandLineA
extern CreateFileA
extern WriteFile
extern SetFilePointer
extern ReadFile
extern CloseHandle
extern GetFileSize



FILE_BEGIN equ 0
FILE_CURRENT equ 1
FILE_END equ 2

CREATE_NEW equ 1
CREATE_ALWAYS equ 2
OPEN_EXISTING equ 3
OPEN_ALWAYS equ 4
TRUNCATE_EXISTING equ 5

INVALID_SET_FILE_POINTER equ -1
INVALID_HANDLE_VALUE equ -1
INVALID_FILE_SIZE equ -1

DELETE equ 10000h
READ_CONTROL equ 20000h
WRITE_DAC equ 40000h
WRITE_OWNER equ 80000h
SYNCHRONIZE equ 100000h
STANDARD_RIGHTS_READ equ READ_CONTROL
STANDARD_RIGHTS_WRITE equ READ_CONTROL
STANDARD_RIGHTS_EXECUTE equ READ_CONTROL
STANDARD_RIGHTS_REQUIRED equ 0F0000h
STANDARD_RIGHTS_ALL equ 1F0000h
SPECIFIC_RIGHTS_ALL equ 0FFFFh

FILE_READ_DATA equ 1h
FILE_LIST_DIRECTORY equ 1h
FILE_WRITE_DATA equ 2h
FILE_ADD_FILE equ 2h
FILE_APPEND_DATA equ 4h
FILE_ADD_SUBDIRECTORY equ 4h
FILE_CREATE_PIPE_INSTANCE equ 4h
FILE_READ_EA equ 8h
FILE_READ_PROPERTIES equ FILE_READ_EA
FILE_WRITE_EA equ 10h
FILE_WRITE_PROPERTIES equ FILE_WRITE_EA
FILE_EXECUTE equ 20h
FILE_TRAVERSE equ 20h
FILE_DELETE_CHILD equ 40h
FILE_READ_ATTRIBUTES equ 80h
FILE_WRITE_ATTRIBUTES equ 100h
FILE_ALL_ACCESS equ STANDARD_RIGHTS_REQUIRED|SYNCHRONIZE|1FFh
FILE_GENERIC_READ equ STANDARD_RIGHTS_READ|FILE_READ_DATA|FILE_READ_ATTRIBUTES|FILE_READ_EA|SYNCHRONIZE
FILE_GENERIC_WRITE equ STANDARD_RIGHTS_WRITE|FILE_WRITE_DATA|FILE_WRITE_ATTRIBUTES|FILE_WRITE_EA|FILE_APPEND_DATA|SYNCHRONIZE
FILE_GENERIC_EXECUTE equ STANDARD_RIGHTS_EXECUTE|FILE_READ_ATTRIBUTES|FILE_EXECUTE|SYNCHRONIZE
FILE_SHARE_READ equ 1h
FILE_SHARE_WRITE equ 2h
FILE_ATTRIBUTE_READONLY equ 1h
FILE_ATTRIBUTE_HIDDEN equ 2h
FILE_ATTRIBUTE_SYSTEM equ 4h
FILE_ATTRIBUTE_DIRECTORY equ 10h
FILE_ATTRIBUTE_ARCHIVE equ 20h
FILE_ATTRIBUTE_NORMAL equ 80h
FILE_ATTRIBUTE_TEMPORARY equ 100h
FILE_ATTRIBUTE_COMPRESSED equ 800h
FILE_NOTIFY_CHANGE_FILE_NAME equ 1h
FILE_NOTIFY_CHANGE_DIR_NAME equ 2h
FILE_NOTIFY_CHANGE_ATTRIBUTES equ 4h
FILE_NOTIFY_CHANGE_SIZE equ 8h
FILE_NOTIFY_CHANGE_LAST_WRITE equ 10h
FILE_NOTIFY_CHANGE_SECURITY equ 100h

GENERIC_READ equ 80000000h
GENERIC_WRITE equ 40000000h
GENERIC_EXECUTE equ 20000000h
GENERIC_ALL equ 10000000h


section .text
main:
;    int     3
    sub     rsp, 40          ; reserve shadow spaceand align the stack by 16
    mov     ecx, -11         ; GetStdHandle takes a DWORD arg, write it as 32-bit.  This is STD_OUTPUT_HANDLE
    call    GetStdHandle

    mov     rcx, rax
    mov     [NtOutConsoleHandle], rax
    mov     rdx, NtlpBuffer         ; or better, lea rdx, [rel NtlpBuffer]
    mov     r8, [NtnNBytesToWrite]  ; or better, make it an EQU constant for mov r8d, bytes_to_write
    mov     r9, NtlpNBytesWritten   ; first 4 args in regs
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

    call    GetCommandLineA
    mov     [NtnArgsBuffer], rax

    mov     rbx, rax
    xor     rcx, rcx
    xor     rax, rax
NextSym:
    mov     al, byte [rbx]
    or      al, al
;    jnz     ArgsDone
    jz      ArgsDone
    inc     rbx
    inc     rcx
    jmp     NextSym 

ArgsDone:
    mov     [NtArgsBufCount], rcx

    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, [NtnArgsBuffer]
;    mov     r8, 50
    mov     r8, [NtArgsBufCount]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

; scan command arguments
    mov     rbx, [NtnArgsBuffer]
NextSym1:
    mov     al, byte [rbx]
    or      al, al
    jz      Finished
    cmp     al,' '
    je      TestDelim1
    inc     rbx
    jmp     NextSym1

TestDelim1:
    inc     rbx
    mov     al, byte [rbx]
    or      al, al
    jz      Finished
    cmp     al,' '
    je      TestDelim1

; extract input filename
    xor     rcx,rcx
    mov     rdi, InFileName
NextSym2:
    mov     al, byte [rbx]
    or      al, al
    jz      Finished 
    cmp     al,' '
    je      StoreInFile
    mov     byte [rdi], al
    inc     rbx
    inc     rdi
    inc     rcx
    jmp     NextSym2

StoreInFile:
    mov     [InFileNameLen], rcx
    mov     [temp_rbx], rbx
; print cmd arg
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, crlf_buf 
    mov     r8, [crlf_len]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile
; test print arg 1
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, InFileName
    mov     r8, [InFileNameLen]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

    mov     rbx, [temp_rbx]
TestDelim2:
    inc     rbx
    mov     al, byte [rbx]
    or      al, al
    jz      Finished
    cmp     al,' '
    je      TestDelim2

; extract output filename
    xor     rcx,rcx
    mov     rdi, OutFileName
NextSym3:
    mov     al, byte [rbx]
    or      al, al
    jz      Finished 
    cmp     al,' '
    je      StoreOutFile
    mov     byte [rdi], al
    inc     rbx
    inc     rdi
    inc     rcx
    jmp     NextSym3

StoreOutFile:
    mov     [OutFileNameLen], rcx
    mov     [temp_rbx], rbx
; print cmd arg
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, crlf_buf 
    mov     r8, [crlf_len]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile
; test print arg 2
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, OutFileName
    mov     r8, [OutFileNameLen]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

    mov     rbx, [temp_rbx]
TestDelim3:
    inc     rbx
    mov     al, byte [rbx]
    or      al, al
    jz      Finished
    cmp     al,' '
    je      TestDelim3

; extract input pattern
    xor     rcx,rcx
    mov     rdi, InPatternBuf
NextSym4:
    mov     al, byte [rbx]
    or      al, al
    jz      Finished 
    cmp     al,' '
    je      StoreInPattern
    mov     byte [rdi], al
    inc     rbx
    inc     rdi
    inc     rcx
    jmp     NextSym4

StoreInPattern:
    mov     [InPatternLen], rcx
    mov     [temp_rbx], rbx
; print cmd arg
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, crlf_buf 
    mov     r8, [crlf_len]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile
; test print arg 3
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, InPatternBuf
    mov     r8, [InPatternLen]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

    mov     rbx, [temp_rbx]
TestDelim4:
    inc     rbx
    mov     al, byte [rbx]
    or      al, al
    jz      Finished
    cmp     al,' '
    je      TestDelim4

; extract output pattern
    xor     rcx,rcx
    mov     rdi, OutPatternBuf
NextSym5:
    mov     al, byte [rbx]
    or      al, al
;   jz      Finished
    jz      StoreOutPattern
    cmp     al,' '
    je      StoreOutPattern
    mov     byte [rdi], al
    inc     rbx
    inc     rdi
    inc     rcx
    jmp     NextSym5

StoreOutPattern:
    mov     [OutPatternLen], rcx
    mov     [temp_rbx], rbx
; print cmd arg
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, crlf_buf 
    mov     r8, [crlf_len]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile
; test print arg 4
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, OutPatternBuf
    mov     r8, [OutPatternLen]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

; print cmd arg
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, crlf_buf 
    mov     r8, [crlf_len]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile

;    jmp     Finished

;HANDLE CreateFileA(
;  LPCSTR                lpFileName,
;  DWORD                 dwDesiredAccess,
;  DWORD                 dwShareMode,
;  LPSECURITY_ATTRIBUTES lpSecurityAttributes,
;  DWORD                 dwCreationDisposition,
;  DWORD                 dwFlagsAndAttributes,
;  HANDLE                hTemplateFile
;);   

    sub     rsp, 38h
    and     qword [rsp + 30h], 0          ; arg7: 0
    mov     qword [rsp + 28h], 80         ; arg6: FILE_ATTRIBUTE_NORMAL
    mov     qword [rsp + 20h],  3         ; arg5: OPEN_EXISTING
    xor     r9d, r9d                      ; arg4: 0
    mov     r8d, 1                        ; arg3: FILE_SHARE_READ
    mov     rdx, 80000000h                ; arg2: GENERIC_READ
    lea	    rcx, [InFileName]             ; arg1: like "CreateFile.asm"
    call    CreateFileA
    add     rsp, 38h
    mov     [fHandle], rax
    cmp     rax, INVALID_HANDLE_VALUE
    jne     GetFileSizeHere
; display error message and terminate
    mov     rcx, [NtOutConsoleHandle]
    mov     rdx, Msg_01_CannotOpenFile
    mov     r8, [Msg_01_Len]
    mov     r9, NtlpNBytesWritten
    mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
    call    WriteFile
    jmp     Finished

GetFileSizeHere:
;DWORD GetFileSize(
;  [in]            HANDLE  hFile,
;  [out, optional] LPDWORD lpFileSizeHigh
;);
        sub     rsp, 40
	mov 	rcx, [fHandle]			;handle
	mov 	rdx, 0		                ;low bits of position
	call	GetFileSize
        add     rsp, 40
        mov     [InFileSize], rax
        mov     [OutFileSize], rax
        cmp     rax, INVALID_FILE_SIZE
        jne     ReadFileBuf
; display error message and terminate
        mov     rcx, [NtOutConsoleHandle]
        mov     rdx, Msg_02_CannotGetFileSize
        mov     r8, [Msg_02_Len]
        mov     r9, NtlpNBytesWritten
        mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
        call    WriteFile
        jmp     Finished

ReadFileBuf:
;BOOL ReadFile(
;  HANDLE       hFile,
;  LPCVOID      lpBuffer,
;  DWORD        nNumberOfBytesToRead,
;  LPDWORD      lpNumberOfBytesRead,
;  LPOVERLAPPED lpOverlapped
;);           
;bytesRead equ [rsp+40]
        sub     rsp, 56
        mov     r8, [InFileSize]              ; 3rd arg - buffer size
        mov     rcx, [fHandle]                ; 1st arg - file descriptor
        lea     rdx, [readbuffer]             ; 2nd arg - buffer address
        mov     r9, lpNumberOfBytesRead        ; 4th arg - bytes read during call
        mov     qword [rsp + 32], 0           ; 5th arg - 0 (no overlapped)
        call    ReadFile       
        mov    rcx, [lpNumberOfBytesRead]
        or     rax, rax
        add    rsp, 56
        jz     DisplayReadError
        cmp    rcx, [InFileSize]
        je     DoneCloseFile
DisplayReadError:    
; display error message and terminate
        mov     rcx, [NtOutConsoleHandle]
        mov     rdx, Msg_03_CannotReadFile
        mov     r8, [Msg_03_Len]
        mov     r9, NtlpNBytesWritten
        mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
        call    WriteFile
        jmp     Finished

DoneCloseFile:
;BOOL WINAPI CloseHandle(
;  _In_ HANDLE hObject
;);
        sub     rsp, 40
        mov     rcx, [fHandle]      
        call    CloseHandle
        add     rsp, 40

; change input pattern to output pattern into output text buffer
        lea     rsi, [readbuffer]
        lea     rdi, [writebuffer]
        mov     rcx, [InFileSize]
        xor     r8,  r8               ; output chars counter
GetNextCharPerBuffer:
        or      rcx, rcx
        jz      WriteOutFile
        mov     al, byte [rsi]        ; compare first byte of input pattern with current char of buffer
        mov     byte [rdi], al
        lea     rbx, [InPatternBuf]
        cmp     al, byte [rbx]
        jne     MoveNextChar
;       jmp     MoveNextChar
        mov     r9, [InPatternLen]
        cmp     rcx, r9
        jb      MoveNextChar
;       jmp     MoveNextChar
        mov     rdx, rsi
TestNextCharPattern:
        mov     al, byte [rdx]        ; compare pattern and buffer contents
        cmp     al, byte [rbx]
        jne     MoveNextChar
        inc     rbx
        inc     rdx
        dec     r9
        jnz     TestNextCharPattern
        mov     r9, [InPatternLen]    ; replace string per buffer
        add     rsi, r9
        dec     rsi
        sub     rcx, r9
        lea     rbx, [OutPatternBuf]
        mov     r10, [OutPatternLen]
CopyReplacePattern:
        mov     al, byte [rbx]
        mov     byte [rdi], al
        inc     rbx
        inc     rdi
        inc     r8
        dec     r10
        jnz     CopyReplacePattern
        jmp     GetNextCharPerBuffer
MoveNextChar:
;        mov     byte [rdi], al
MoveNextChar2:
        dec     rcx
        inc     rsi
        inc     rdi
        inc     r8
        jmp     GetNextCharPerBuffer

WriteOutFile:
        mov     [OutFileSize], r8
; write output file
; create output file
        sub     rsp, 56
        lea     rcx, [OutFileName]    ; filename
        mov     rdx, 0C0000000h       ; read/write
        xor     r8, r8                ; exclusive access
        xor     r9, r9                ; no security
        mov     r10, 4                ; create always
        mov     [rsp + 32], r10
        mov     r10, 128              ; normal attributes
        mov     [rsp + 40], r10 
        mov     [rsp + 48], r9        ; NULL - no template
        call    CreateFileA
        add     rsp, 56
        mov     [fOutHandle], rax
        cmp     rax, INVALID_HANDLE_VALUE
        jne     DoWriteFile
; display error message and terminate
        mov     rcx, [NtOutConsoleHandle]
        mov     rdx, Msg_04_CannotCreateFile
        mov     r8, [Msg_04_Len]
        mov     r9, NtlpNBytesWritten
        mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
        call    WriteFile
        jmp     Finished

; write output file
DoWriteFile:
        sub     rsp, 56
        mov     rcx, [fOutHandle]        ; 1st arg = file handle
        lea     rdx, [writebuffer]        ; 2nd arg = buffer address
        mov     r8, [OutFileSize]         ; 3rd arg = buffer size
        lea     r9, [NtlpNBytesWritten]  ; 4th arg = address of variable to bytes written counter
        mov     qword [rsp + 32], 0      ; 5th arg = non overlapped
        call    WriteFile
        mov     rcx, [NtlpNBytesWritten]
        or      rax, rax
        add     rsp, 56
        jz     DisplayWriteError
        cmp    rcx, [OutFileSize]
        je     DoCloseOutputFile
DisplayWriteError:    
; display error message and terminate
        mov     rcx, [NtOutConsoleHandle]
        mov     rdx, Msg_05_CannotWriteFile
        mov     r8, [Msg_05_Len]
        mov     r9, NtlpNBytesWritten
        mov     qword [rsp + 32], 00h   ; fifth arg on the stack above the shadow space.  Also, this is a pointer so it needs to be a qword store.
        call    WriteFile
        ;jmp     Finished

; truncate and close output file
DoCloseOutputFile:
;        sub     rsp, 56                  ; truncate file (?)
;        mov     rcx, [fOutHandle]        ; 1st arg = file handle
;        lea     rdx, [readbuffer]        ; 2nd arg = buffer address
;        mov     r8, 0                    ; 3rd arg = buffer size
;        lea     r9, [NtlpNBytesWritten]  ; 4th arg = address of variable to bytes written counter
;        mov     qword [rsp + 32], 0      ; 5th arg = non overlapped
;        call    WriteFile
;        add     rsp, 56

        sub     rsp, 40
        mov     rcx, [fOutHandle]      
        call    CloseHandle
        add     rsp, 40

Finished:
    add     rsp, 40
ExitProgram:
    xor     eax, eax
    ret


section .data
temp_rbx           dq    0
crlf_buf           db    13,10,0
crlf_len           dq    2
NtlpBuffer         db    'Search and replace text pattern per file, version 1.0', 13,10, 
                   db    'Copyright (C) 2024 Dmitry Stefankov. All Rights Reserved.', 13,10,
                   db    'Usage: findrep <InFileName> <OutFileName> <SrchPat> <RplPat>', 13,10,
                   db    00h
NtnNBytesToWrite   dq    $ - NtlpBuffer - 1
Msg_01_CannotOpenFile    db    'ERROR: canoot open input filename!', 13,10, 00h
Msg_01_Len               dq  $ - Msg_01_CannotOpenFile - 1
Msg_02_CannotGetFileSize db    'ERROR: canoot get filesize of input filename!', 13,10, 00h
Msg_02_Len               dq  $ - Msg_02_CannotGetFileSize - 1
Msg_03_CannotReadFile    db    'ERROR: canoot read input filename!', 13,10, 00h
Msg_03_Len               dq  $ - Msg_03_CannotReadFile - 1
Msg_04_CannotCreateFile  db    'ERROR: canoot create input filename!', 13,10, 00h
Msg_04_Len               dq  $ - Msg_04_CannotCreateFile - 1
Msg_05_CannotWriteFile   db    'ERROR: canoot write input filename!', 13,10, 00h
Msg_05_Len               dq  $ - Msg_05_CannotWriteFile - 1
InFileNameLen      dq    0
OutFileNameLen     dq    0
InPatternLen       dq    0
OutPatternLen      dq    0
InFileName         db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
OutFileName        db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
InPatternBuf       db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
OutPatternBuf      db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

NtOutConsoleHandle: dq	 0
NtnArgsBuffer:	    dq   0
NtArgsBufCount:     dq   0

InFileSize           dq   0
OutFileSize          dq   0

fHandle                 dq  0
lpNumberOfBytesWritten 	dq  0 
lpNumberOfBytesRead 	dq  0
fOutHandle              dq  0


section .bss
NtlpNBytesWritten: resq  01h
readbuffer         resb  16384
writebuffer        resb  (32768+16384)
