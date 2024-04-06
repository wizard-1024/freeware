; ----------------------------------------------------------------------------------------
; Runs on 64-bit Linux only.
; Search and replace text pattern and write to new file and exit
; for 64-bit systems, Linux syscalls
; 2024 (C) Dmitry Stefankov
;
; To assemble and run:
;     nasm -felf64 file2bin.asm && ld -o file2bin file2bin.o && ./file2bin
; ----------------------------------------------------------------------------------------

;;;sys_write	equ	1		; the linux WRITE syscall
;;;sys_exit	equ	60		; the linux EXIT syscall
;;;sys_stdout	equ	1		; the file descriptor for standard output (to print/write to)

; Exit Codes
EXIT_SUCCESS equ 0
EXIT_ERROR equ 1

; STD Codes
STD_IN equ 0
STD_OUT equ 1
STD_ERR equ 2

; System Calls
SYS_READ equ 0
SYS_WRITE equ 1
SYS_OPEN equ 2
SYS_CLOSE equ 3
SYS_LSEEK equ 8
SYS_EXIT equ 60
SYS_UNLINK equ 87
SYS_CREATE equ 85

; File Codes
O_RD_ONLY equ 0
O_WR_ONLY equ 1
O_RD_WR equ 2

; File Command Codes
O_CREAT equ 64
O_EXCL equ 128
O_NOCTTY equ 256
O_TRUNC equ 512
O_APPEND equ 1024
O_NONBLOCK equ 2048
O_NDELAY equ 2048
O_DSYNC equ 4096
O_ASYNC equ 8192
O_DIRECT equ 16384
O_DIRECTORY equ 65536
O_NOFOLLOW equ 131072
O_NOATIME equ 262144
O_CLOEXEC equ 524288
O_SYNC equ 1052672
O_PATH equ 2097152
O_TMPFILE equ 4259840

; LSEEK methods
LSEEK_SET equ 0
LSEEK_CUR equ 1
LSEEK_END equ 2


          global    _start

          section   .text
_start:
	  pop	r8			; pop the number of arguments from the stack
	  pop	rsi			; discard the program name, since we only want the commandline arguments
	  mov	   [temp_r8], r8
	  mov	   [temp_rsi], rsi

	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, HelpBuffer         ; address of string to output
          mov       rdx, [HelpBytesToWrite] ; number of bytes
          syscall                           ; invoke operating system to do the write

; get next argument
	  mov	    rsi, [temp_rsi]
	  mov	    r8, [temp_r8]
	  cmp	    r8,	0		    ; check if we have to print more arguments
	  jz	   exit_to_world	    ; if not, jump to the 'end' label

; copy input filename
	  pop	    rsi
	  dec	    r8
	  mov	   [temp_r8], r8
	  mov	   [temp_rsi], rsi

	  call      get_strlen
	  mov	    [InFileNameLen], rdx
	  mov	    rcx, rdx
	  lea	    rdi, [InFileName]
          rep	    movsb
	  lea	    rsi, [InFileName]

	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          syscall                           ; invoke operating system to do the write

	  call      print_lf

; get next argument
	  mov	    rsi, [temp_rsi]
	  mov	    r8, [temp_r8]
	  cmp	    r8,	0		    ; check if we have to print more arguments
	  jz	   exit_to_world	    ; if not, jump to the 'end' label

; copy output filename
	  pop	    rsi
	  dec	    r8
	  mov	   [temp_r8], r8
	  mov	   [temp_rsi], rsi

	  call      get_strlen
	  mov	    [OutFileNameLen], rdx
	  mov	    rcx, rdx
	  lea	    rdi, [OutFileName]
          rep	    movsb

	  lea	    rsi, [OutFileName]
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          syscall                           ; invoke operating system to do the write

	  call      print_lf

; get next argument
	  mov	    rsi, [temp_rsi]
	  mov	    r8, [temp_r8]
	  cmp	    r8,	0		    ; check if we have to print more arguments
	  jz	   exit_to_world	    ; if not, jump to the 'end' label

; copy input pattern
	  pop	    rsi
	  dec	    r8
	  mov	   [temp_r8], r8
	  mov	   [temp_rsi], rsi

	  call      get_strlen
	  mov	    [InPatternLen], rdx
	  mov	    rcx, rdx
	  lea	    rdi, [InPatternBuf]
          rep	    movsb

	  lea	    rsi, [InPatternBuf]
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          syscall                           ; invoke operating system to do the write

	  call      print_lf

; get next argument
	  mov	    rsi, [temp_rsi]
	  mov	    r8, [temp_r8]
	  cmp	    r8,	0		    ; check if we have to print more arguments
	  jz	   exit_to_world	    ; if not, jump to the 'end' label

; copy output pattern
	  pop	    rsi
	  dec	    r8
	  mov	   [temp_r8], r8
	  mov	   [temp_rsi], rsi

	  call      get_strlen
	  mov	    [OutPatternLen], rdx
	  mov	    rcx, rdx
	  lea	    rdi, [OutPatternBuf]
          rep	    movsb
	  lea	    rsi, [OutPatternBuf]

	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          syscall                           ; invoke operating system to do the write

	  call      print_lf


; process numeric values

; nothing

; open input file
	  mov rax, SYS_OPEN
	  mov rdi, InFileName
	  mov rsi, O_RD_ONLY
	  mov rdx, 0644q
	  syscall
;	  js  exit_with_error
	  cmp rax, 0
	  jl   open_error
	  jmp  seek_file
open_error:
	  push	    rax
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, Msg_01_CannotOpenFile ; address of string to output
          mov       rdx, [Msg_01_Len] ; number of bytes
	  syscall
	  pop       rax
	  jmp       exit_with_error

seek_file:
	  mov [fHandle], rax
; seek input file
	  mov rdi, [fHandle]
	  mov rax, SYS_LSEEK
	  mov rdx, LSEEK_END
	  mov rsi, 0
	  syscall
	  cmp rax, 0
	  jl   seek_error
	  jmp  read_file_1
seek_error:
	  push	    rax
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, Msg_02_CannotSeekFile ; address of string to output
          mov       rdx, [Msg_02_Len] ; number of bytes
	  syscall
	  pop       rax
	  jmp       exit_with_error

; read input file
read_file_1:
	  ;;mov rax, 434
	  mov [InFileSize], rax
	  mov [OutFileSize], rax
	  mov rdi, [fHandle]   ; back to file beginning
	  mov rax, SYS_LSEEK
	  mov rdx, LSEEK_SET
	  mov rsi, 0
	  syscall
	  cmp rax, 0
	  jl   seek_2_error
	  jmp  real_read_file
seek_2_error:
	  push	    rax
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, Msg_02_CannotSeekFile ; address of string to output
          mov       rdx, [Msg_02_Len] ; number of bytes
	  syscall
	  pop       rax
	  jmp       exit_with_error
real_read_file:
	  mov rdi, [fHandle]     ; read a file contents
	  mov rax, SYS_READ
	  lea rsi, readbuffer
	  mov rdx, [InFileSize]
	  syscall
	  js  exit_with_error
	  cmp rax, [InFileSize]
	  je  close_file
	  push	    rax
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, Msg_03_CannotReadFile ; address of string to output
          mov       rdx, [Msg_03_Len] ; number of bytes
	  syscall
	  pop       rax
	  jmp       exit_with_error

; close input file
close_file:
	  mov rax, SYS_CLOSE
	  mov rdi, [fHandle]
	  syscall


; change input pattern to output pattern into output text buffer
        lea     rsi, readbuffer
        lea     rdi, writebuffer
        mov     rcx, [InFileSize]
        xor     r8,  r8               ; output chars counter
GetNextCharPerBuffer:
        or      rcx, rcx
        jz      write_new_file
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
        lea     rbx, OutPatternBuf
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


; create output file
write_new_file:
          mov [OutFileSize], r8
	  mov rax, SYS_OPEN
	  lea rdi, OutFileName
	  mov rsi, O_CREAT+O_WR_ONLY
	  mov rdx, 0644q
	  syscall
	  cmp rax, 0
	  jl   create_error
	  jmp  write_outfile
create_error:
	  push	    rax
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, Msg_04_CannotCreateFile ; address of string to output
          mov       rdx, [Msg_04_Len] ; number of bytes
	  syscall
	  pop       rax
	  jmp       exit_with_error

; write to file
write_outfile:
	  mov [fOutHandle], rax
	  mov rdi, rax
	  mov rax, SYS_WRITE
	  lea rsi, [writebuffer]
	  mov rdx, [OutFileSize]
	  ;mov rdx, 434
	  syscall
	  js  exit_with_error
	  cmp rax, [OutFileSize]
	  je  close_out_file
	  push	    rax
	  mov       rax, SYS_WRITE          ; system call for write
          mov       rdi, STD_OUT            ; file handle 1 is stdout
          mov       rsi, Msg_05_CannotWriteFile ; address of string to output
          mov       rdx, [Msg_05_Len] ; number of bytes
	  syscall
	  pop       rax
	  jmp       exit_with_error

; close output file
close_out_file:
	  mov rax, SYS_CLOSE
	  mov rdi, [fOutHandle]
	  syscall

; return control to OS
exit_to_world:
          mov       rax, SYS_EXIT           ; system call for exit
          xor       rdi, rdi                ; exit code 0
          syscall                           ; invoke operating system to exit

exit_with_error:
	  mov	    rdi, rax
          mov       rax, SYS_EXIT           ; system call for exit
          syscall                           ; invoke operating system to exit

get_strlen:
          xor      rdx, rdx
	  mov	   r9,	rsi
	  or	   r9,	r9
	  jz	  do_ret
next_sym:
	  mov	   bl,	[r9]
	  or	   bl,	bl
	  jz	  do_ret
	  inc	   rdx
	  inc	   r9
	  jmp	  next_sym
do_ret:
        ret

print_lf:
	mov	rax,	SYS_WRITE	; rax is overwritten by the kernel with the syscall return code, so we set it again
	mov	rdi,	STD_OUT
	mov	rsi,	linebreak	; this time we want to print a line break
	mov	rdx,	1		; which is one byte long
	syscall
        ret

copy_block:
do_ret_2:
        ret

fn_atoi:
        ;mov rdx, num3entered 		; our string
atoi:
	xor	rax,	rax 		; zero a "result so far"
.top:
	movzx	rcx, 	byte [rdx] 	; get a character
	inc	rdx 			; ready for next one
	cmp	rcx,	'0' 		; valid?
	jb     .done
	cmp 	rcx, 	'9'
	ja     .done
	sub	rcx,	'0' 		; "convert" character to number
	imul	rax,	10 		; multiply "result so far" by ten
	add	rax,	rcx 		; add in current digit
	jmp 	.top			; until done
.done:
        ret



          section   .data
temp_r8		   dq	0
temp_rsi	   dq	0

linebreak	   db	0x0A		; ASCII character 10, a line break

HelpBuffer         db    'Search and replace text pattern per file, version 1.0', 13,10,
                   db    'Copyright (C) 2024 Dmitry Stefankov. All Rights Reserved.', 13,10,
                   db    'Usage: findrep <InFileName> <OutFileName> <SrchPat> <RplPat>', 13,10,
                   db    00h
HelpBytesToWrite   dq    $ - HelpBuffer - 1

Msg_01_CannotOpenFile    db    'ERROR: canoot open input filename!', 13,10, 00h
Msg_01_Len               dq  $ - Msg_01_CannotOpenFile - 1
Msg_02_CannotSeekFile    db    'ERROR: canoot seek input filename!', 13,10, 00h
Msg_02_Len               dq  $ - Msg_02_CannotSeekFile - 1
Msg_03_CannotReadFile    db    'ERROR: canoot read input filename!', 13,10, 00h
Msg_03_Len               dq  $ - Msg_03_CannotReadFile - 1
Msg_04_CannotCreateFile  db    'ERROR: canoot create output filename!', 13,10, 00h
Msg_04_Len               dq  $ - Msg_04_CannotCreateFile - 1
Msg_05_CannotWriteFile   db    'ERROR: canoot write output filename!', 13,10, 00h
Msg_05_Len               dq  $ - Msg_05_CannotWriteFile - 1


InFileNameLen      dq    0
OutFileNameLen     dq    0
InOffsetLen        dq    0
InSizeLen          dq    0
InPatternLen       dq    0
OutPatternLen      dq    0
InFileName         db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
OutFileName        db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
InPatternBuf       db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
OutPatternBuf      db    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

NtOutConsoleHandle: dq	 0
NtnArgsBuffer:	    dq   0
NtArgsBufCount:     dq   0

InFileSize          dq   0
OutFileSize         dq   0

fHandle                 dq  0
lpNumberOfBytesWritten 	dq  0
lpNumberOfBytesRead 	dq  0
fOutHandle              dq  0

section .bss
NtlpNBytesWritten: resq  01h
readbuffer         resb  16384
writebuffer        resb  (32768+16384)
