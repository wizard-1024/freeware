#!/bin/sh

nasm -felf64 -l bin2file.lst bin2file.asm && ld -Map bin2file.map -o bin2file bin2file.o
