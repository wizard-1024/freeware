nasm -f win64 -l file2bin.lst file2bin.asm
link.exe file2bin.obj /map /subsystem:console /entry:main /nodefaultlib kernel32.lib user32.lib /largeaddressaware:no
