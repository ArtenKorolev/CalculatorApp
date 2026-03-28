#!/bin/sh
nasm -felf64 -g main.asm
ld main.o  -o main
