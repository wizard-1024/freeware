#!/bin/sh

nasm -felf64 -l findrep.lst findrep.asm && ld -Map findrep.map -o findrep findrep.o
