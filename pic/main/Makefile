# MPLAB IDE generated this makefile for use with GNU make.
# Project: main.mcp
# Date: Sat Aug 03 22:07:33 2013

AS = pic30-as.exe
CC = pic30-gcc.exe
LD = pic30-ld.exe
AR = pic30-ar.exe
HX = pic30-bin2hex.exe
RM = rm

main.hex : main.cof
	$(HX) "main.cof"

main.cof : main.o utils.o io.o pic.o symtab.o
	$(CC) -mcpu=24FV32KA301 "main.o" "utils.o" "io.o" "pic.o" "symtab.o" -o"main.cof" -Wl,-Tp24FV32KA301.gld,--defsym=__MPLAB_BUILD=1,--defsym=__MPLAB_DEBUG=1,-Map="main.map",--report-mem

main.o : main.c
	$(CC) -mcpu=24FV32KA301 -x c -c "main.c" -o"main.o" -D__DEBUG -Wall

utils.o : utils.c
	$(CC) -mcpu=24FV32KA301 -x c -c "utils.c" -o"utils.o" -D__DEBUG -Wall

io.o : io.c
	$(CC) -mcpu=24FV32KA301 -x c -c "io.c" -o"io.o" -D__DEBUG -Wall

pic.o : pic.c
	$(CC) -mcpu=24FV32KA301 -x c -c "pic.c" -o"pic.o" -D__DEBUG -Wall

symtab.o : symtab.c
	$(CC) -mcpu=24FV32KA301 -x c -c "symtab.c" -o"symtab.o" -D__DEBUG -Wall

clean : 
	$(RM) "main.o" "utils.o" "io.o" "pic.o" "symtab.o" "main.cof" "main.hex"

