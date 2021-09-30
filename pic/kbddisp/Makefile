# MPLAB IDE generated this makefile for use with GNU make.
# Project: kbddisp.mcp
# Date: Sun Aug 04 19:51:11 2013

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

kbddisp.cof : main.o
	$(CC) /p16F720 "main.o" /u_DEBUG /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /m"kbddisp.map" /w /o"kbddisp.cof"

main.o : main.asm ../../../../../../../../Program\ Files\ (x86)/Microchip/MPASM\ Suite/p16f720.inc macros.inc uart.inc
	$(AS) /q /p16F720 "main.asm" /l"main.lst" /e"main.err" /o"main.o" /d__DEBUG=1

clean : 
	$(CC) "main.o" "main.err" "main.lst" "kbddisp.cof" "kbddisp.hex" "kbddisp.map"

