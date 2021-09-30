CFLAGS = -g -Wall
CC = gcc

# LIBS = -lm -lreadline -lcurses
# For Cygwin...
# LIBS = -lm -lreadline -ltermcap
LIBS =

OBJS = asm.o util.o main.o

all: asm sim

asm: $(OBJS)
	$(CC) $(CFLAGS) -o asm $(OBJS) $(LIBS)

sim: sim.o util.o io.o
	$(CC) $(CFLAGS) -o sim sim.o util.o io.o $(LIBS)

clean:
	/bin/rm -f ${OBJS} ${OBJS:.o=.d} *~

# include dependancy files if they exist
-include $(OBJS:.o=.d)

# compile and generate dependency info
%.o: %.c
	$(CC) -c $(CFLAGS) $*.c -o $*.o
	@$(CC) -MM $(CFLAGS) $*.c > $*.d
# Improve dependency file produced by gcc... allows files to be renamed and source files to exist
# in subdirectories.
	@mv -f $*.d $*.d.tmp
	@sed -e 's|.*:|$*.o:|' < $*.d.tmp > $*.d
	@sed -e 's/.*://' -e 's/\\$$//' < $*.d.tmp | fmt -1 | sed -e 's/^ *//' -e 's/$$/:/' >> $*.d
	@rm -f $*.d.tmp
