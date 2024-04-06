#!/bin/sh

nasm -felf64 -l file2bin.lst file2bin.asm && ld -Map file2bin.map -o file2bin file2bin.o
