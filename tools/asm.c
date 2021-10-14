/* Assembler
   Copyright (C) 2013  Joseph H. Allen

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street,
   Fifth Floor, Boston, MA  02110-1301, USA. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "util.h"
#include "asm.h"

unsigned long mem[256];
int setmem[256];

void write_mem(int addr, unsigned long val)
{
	if (addr < 0 || addr > 255) {
		error0("Invalid memory address\n");
        } else if (setmem[addr]) {
                error0("Duplicate memory assignment\n");
	} else {
		mem[addr] = val;
		setmem[addr] = 1;
	}
}

enum {
	NONE,	/* No operand */
	RIGHT,	/* Right operand only */
	DUP,	/* Put single argument into both sides */
	BOTH,	/* Left and right */
	IBOTH,	/* Left and right: left side can be immediate */
	ILEFT,	/* Left only, which can be immediate */
	EQU,
	ORG,
	SKIP,
	INSN,
	DATA
};

const struct { char *insn; unsigned long opcode; int type; } table[] =
{
	{ "nop", 0x4010ff00, NONE },
	{ "halt", 0xC810ff00, NONE },
	{ "clc", 0x00000000, NONE },
	{ "stc", 0x4020FF00, NONE },
	{ "ntoc", 0x00800000, DUP },
	{ "jmp", 0x4018ff00, RIGHT },
	{ "jsr", 0x84080000, BOTH },
	{ "jmi", 0x00610000, BOTH },
	{ "jlt", 0x00610000, BOTH },
	{ "jpl", 0x00690000, BOTH },
	{ "jge", 0x00690000, BOTH },
	{ "jeq", 0x00620000, BOTH },
	{ "jne", 0x006a0000, BOTH },
	{ "jle", 0x00630000, BOTH },
	{ "jgt", 0x006b0000, BOTH },
	{ "jcc", 0x00640000, RIGHT },
	{ "jlo", 0x00640000, RIGHT },
	{ "jcs", 0x006c0000, RIGHT },
	{ "jhs", 0x006c0000, RIGHT },
	{ "jls", 0x00660000, BOTH },
	{ "jhi", 0x006e0000, BOTH },
	{ "jo", 0x02020000, BOTH },
	{ "je", 0x020a0000, BOTH },
	{ "incjne", 0x802a0000, BOTH },
	{ "incjeq", 0x80220000, BOTH },
	{ "st", 0x08000000, IBOTH },
	{ "add", 0x80800000, BOTH },
	{ "addto", 0x08800000, IBOTH },
	{ "adcto", 0x08900000, IBOTH },
	{ "lsl", 0x08800000, DUP },
	{ "lslo", 0x08a00000, DUP },
	{ "rol", 0x08900000, DUP },
	{ "rorto", 0x0a100000, BOTH },
	{ "ror", 0x0a100000, DUP },
	{ "rsbto", 0x08e00000, IBOTH },
	{ "rsb", 0x80e00000, BOTH },
	{ "andto", 0x09800000, IBOTH },
	{ "bicto", 0x09c00000, IBOTH },
	{ "negto", 0x08600000, BOTH },
	{ "ngcto", 0x08500000, BOTH },
	{ "neg", 0x08600000, DUP },
	{ "ngc", 0x08500000, DUP },
	{ "comto", 0x08400000, BOTH },
	{ "com", 0x08400000, DUP },
	{ "clr", 0x48000000, RIGHT },
	{ "inc", 0x48800100, RIGHT },
	{ "dec", 0x48e00100, RIGHT },
	{ "out", 0x10000000, ILEFT },
	{ "outc", 0x98000000, ILEFT },
	{ "in", 0x68000000, RIGHT },
	{ "inwait", 0xE8000000, RIGHT },
	{ "lsr", 0x0a000000, DUP },
	{ "lsro", 0x0a200000, DUP },
	{ "lsrto", 0x0a000000, BOTH },
	{ "lsroto", 0x0a200000, BOTH },
	{ "rsbcto", 0x08d00000, IBOTH },
	{ "equ", 0x0, EQU },
	{ "org", 0x0, ORG },
	{ "skip", 0x0, SKIP },
	{ "insn", 0x0, INSN },
	{ "data", 0x0, DATA },
	{ 0, 0, 0 }
};

/*
 * assemble() is called once per line in the input asm file.
 *
 * addr is the current address, it is updated and returned by assemble, and then fed back in on the next line.
 * buf is a char* to the start of the line. It is null terminated and does not contain a \n newline at the end.
 * pass is the pass number. On the 0 (first) pass, no memory is written and no lines are output to console.
 * On the 1 (second) pass, memory is written and lines are output.
*/
unsigned long long assemble(unsigned long long addr, char *buf, int pass)
{
	char *org = buf;
	char str[80];
	unsigned long long label_addr = addr;
	struct symbol *label_sy = 0;
	unsigned long opcode;
	int type;
	unsigned long long left;
	unsigned long long right;
	int x;

	++line;

	if (buf[0] == ';' || !buf[0] || buf[0] == '*') {
		// Comment line, ignore
		if (pass) {
			output("%-7d                 %s\n", line, org);
		}
		return addr;
	}

	if (parse_word(&buf, str)) {
		/* Maybe it's an instruction... */
		for (x = 0; table[x].insn; ++x)
			if (!strcmp(table[x].insn, str)) {
				opcode = table[x].opcode;
				type = table[x].type;
				goto found_insn;
			}
		/* A label */
		label_sy = find_symbol(str);
		if (*buf == ':') ++buf;
		skipws(&buf);
		if (!parse_word(&buf, str)) {
			goto done;
		}
	} else {
		skipws(&buf);
		if (!parse_word(&buf, str)) {
			goto done;
		}
	}

	/* Lookup instruction */
	for (x = 0; table[x].insn; ++x)
		if (!strcmp(table[x].insn, str)) {
			opcode = table[x].opcode;
			type = table[x].type;
			break;
		}

	if (!table[x].insn) {
		error1("Unknown instruction '%s'", str);
		if (pass) {
			output("%-7d                 %s\n", line, org);
		}
		set_symbol(label_sy, label_addr);
		return addr;
	}

	found_insn:

	skipws(&buf);

	if (type == NONE) {
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == RIGHT) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, pass);
		opcode |= (right & 255);
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == DUP) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, pass);
		opcode |= (right & 255) | ((right & 255) << 8);
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == BOTH) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &left, addr, pass);
		skipws(&buf);
		if (*buf != ',') {
			error0("Missing second operand");
			right = 0;
		} else {
			++buf;
			skipws(&buf);
			rtn = expr(&buf, &right, addr, pass);
		}
		opcode |= (right & 255) | ((left & 255) << 8);
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == IBOTH) {
		int rtn;
		skipws(&buf);
		if (*buf == '#') {
			++buf;
			opcode |= 0x40000000;
		}
		rtn = expr(&buf, &left, addr, pass);
		skipws(&buf);
		if (*buf != ',') {
			error0("Missing second operand");
			right = 0;
		} else {
			++buf;
			skipws(&buf);
			rtn = expr(&buf, &right, addr, pass);
		}
		opcode |= (right & 255) | ((left & 255) << 8);
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == ILEFT) {
		int rtn;
		skipws(&buf);
		if (*buf == '#') {
			++buf;
			opcode |= 0x40000000;
		}
		rtn = expr(&buf, &left, addr, pass);
		opcode |= ((left & 255) << 8);
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == EQU) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 1);
		if (rtn == 1) {
			label_addr = right;
		}
		if (pass) {
			output("%-7d %s       %s\n", line, hex(8, addr), org);
		}
		goto done;
	} else if (type == ORG) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 1);
		if (rtn == 1) {
			addr = right;
			label_addr = right;
		}
		if (pass) {
			output("%-7d %2.2llx              %s\n", line, addr, org);
		}
		goto done;
	} else if (type == SKIP) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 1);
		if (rtn == 1) {
			addr += right;
		}
		if (pass) {
			output("%-7d %2.2llx              %s\n", line, label_addr, org);
		}
		goto done;
	} else if (type == INSN) {
		int rtn;
		skipws(&buf);

		/* Parse base opcode */
		rtn = expr(&buf, &right, addr, pass);
		opcode = right & 0xFFFFFFFF;

		skipws(&buf);

		/* Parse A argument (optional) */
		if(*buf && *buf != ',') {
			if (*buf == '#') {
				++buf;
				opcode |= 0x40000000;
			}
			rtn = expr(&buf, &left, addr, pass);
			if(!rtn) {
				left = 0;
			}

			opcode = (opcode & 0xFFFF00FF) | ((left & 255) << 8);

			skipws(&buf);
		}
		else {
			left = 0;
		}

		/* Parse B argument (optional) */
		if (*buf == ',') {
			++buf;
			skipws(&buf);
			rtn = expr(&buf, &right, addr, pass);
			if(!rtn) {
				right = 0;
			}

			opcode = (opcode & 0xFFFFFF00) | (right & 255);
		}
		else {
			right = 0;
		}

		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	} else if (type == DATA) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, pass);
		opcode = (0xC810FF00 + (0xFF & right));
		if (pass) {
			output("%-7d %2.2llx %s    %s\n", line, addr, hex(8, opcode), org);
			write_mem(addr, opcode);
		}
		++addr;
		goto done;
	}

	done:
	if (skipws(&buf) && *buf && (*buf != ';' && *buf != '*')) {
		error1("Extra junk at end of line '%s'", buf);
	} else {
		set_symbol(label_sy, label_addr);
	}

	

	return addr;
}

void dump_mem()
{
	int x;
	for (x = 0; x != 256; ++x) {
		if (setmem[x]) {
// One word per line
//			printf("%2.2x: %8.8lx\n", x, mem[x]);
// Many words per line
 			output("%2.2x:", x);
			while (setmem[x]) {
				printf(" %8.8lx", mem[x]);
				++x;
				if ((x&7) == 0) break;
			}
			printf("\n");
			--x;
		}
	}
}
