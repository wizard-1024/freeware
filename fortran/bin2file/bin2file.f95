!
! Put binary portion from file to file
! Copyright (C) 2021 Dmitry Stefankov
!

program bin2file
 
  implicit none
  integer, parameter :: len_max = 256
  integer :: i , nargs
  integer :: in_file_ofs, in_file_siz, out_file_ofs
  character (len_max) :: arg
  character(len_max) :: infile
  character(len_max) :: outfile
  character*16 s
  integer :: err
  integer :: n, m
  character :: c
  character, dimension(:), allocatable :: buf
  character, dimension(:), allocatable :: wbuf
 
  nargs = command_argument_count()
  if( nargs < 5 ) then
    print*, "Put binary portion from file to file, version 1.0"
    print*, "Copyright (C) 2021 Dmitry Stefankov. All Rights Reserved."
    print*, "Usage: bin2file.exe infile outfile offset size newoffset"
  else
    call get_command_argument (1, infile)
    call get_command_argument (2, outfile)
    call get_command_argument (3, s)
    read(s,*) in_file_ofs
    call get_command_argument (4, s)
    read(s,*) in_file_siz
    call get_command_argument (5, s)
    read(s,*) out_file_ofs

    print*, "infile: ", trim(infile)
    print*, "outfile: ", trim(outfile)
    print*, "in_offset: ", in_file_ofs
    print*, "in_size: ", in_file_siz
    print*, "out_offset: ", out_file_ofs

    open(unit=10, file=infile, action="read", &
         form="unformatted", access="stream")
    inquire(unit=10, size=n)
    allocate(buf(n))
    read(10) buf
    close(10)

    open(unit=20, file=outfile, action="read", &
         form="unformatted", access="stream")
    inquire(unit=20, size=m)
    allocate(wbuf(m))
    read(20) wbuf
    close(20)

    do i=1,in_file_siz
       wbuf(out_file_ofs+i) = buf(in_file_ofs+i)
    end do

    open(unit=30, file=outfile, status="replace", action="write", access="stream", iostat=err)
    if (err == 0) then
      write(30) wbuf
      close(30)
    end if

  end if
 
end program bin2file
