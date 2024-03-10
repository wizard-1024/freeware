nasm -f win64 -l bin2file.lst bin2file.asm
link.exe bin2file.obj /map /subsystem:console /entry:main /nodefaultlib kernel32.lib user32.lib /largeaddressaware:no
