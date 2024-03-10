nasm -f win64 -l findrep.lst findrep.asm
link.exe findrep.obj /map /subsystem:console /entry:main /nodefaultlib kernel32.lib user32.lib /largeaddressaware:no
