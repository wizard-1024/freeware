# $Id: file2bin.mak,v 1.1 2006-12-05 17:42:30+03 dstef Exp root $

target=file2bin

$(target): $(target).c
	cc -Wall -D_GNU_SOURCE=1 -D_BSD_SOURCE=1 -o $(target) $(target).c

static: $(target).c
	cc -static -Wall -D_GNU_SOURCE=1 -D_BSD_SOURCE=1 -o $(target) $(target).c
	
clean:
	rm -f $(target)
