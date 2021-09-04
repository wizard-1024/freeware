!
! Extract binary portion from file
! Copyright (C) 2021 Dmitry Stefankov
!

program file2bin
 
  implicit none
  integer, parameter :: len_max = 256
  integer :: i , nargs
  integer :: file_ofs, file_siz
  character (len_max) :: arg
  character(len_max) :: infile
  character(len_max) :: outfile
  character*16 s
  integer :: err
  integer :: n
  character :: c
  character, dimension(:), allocatable :: buf
  character, dimension(:), allocatable :: wbuf
 
  nargs = command_argument_count()
  if( nargs < 4 ) then
    print*, "Extract binary portion from file, version 1.0"
    print*, "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
    print*, "Usage: file2bin.exe infile outfile offset size"
  else
    call get_command_argument (1, infile)
    call get_command_argument (2, outfile)
    call get_command_argument (3, s)
    read(s,*) file_ofs
    call get_command_argument (4, s)
    read(s,*) file_siz

    print*, "infile: ", trim(infile)
    print*, "outfile: ", trim(outfile)
    print*, "offset: ", file_ofs
    print*, "size: ", file_siz

    open(unit=10, file=infile, action="read", &
         form="unformatted", access="stream")
    inquire(unit=10, size=n)
    allocate(buf(n))
    read(10) buf
    close(10)

    !print "(A)", buf

    allocate(wbuf(file_siz))

    do i=1,file_siz
       wbuf(i) = buf(file_ofs+i)
    end do

    open(unit=20, file=outfile, status="replace", action="write", access="stream", iostat=err)
    if (err == 0) then
      write(20) wbuf
      close(20)
    end if

  end if
 
end program file2bin
