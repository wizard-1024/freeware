# $Id: bin2data.mak,v 1.1 2006-12-06 19:40:45+03 dstef Exp root $

target=bin2data

$(target): $(target).c
	cc -Wall -D_GNU_SOURCE=1 -D_BSD_SOURCE=1 -o $(target) $(target).c

static: $(target).c
	cc -static -Wall -D_GNU_SOURCE=1 -D_BSD_SOURCE=1 -o $(target) $(target).c
	
clean:
	rm -f $(target)
