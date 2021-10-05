/* Relay computer simulator
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
#include <string.h>
#include <stdlib.h>
#include "io.h"
#include "util.h"

/* Relay computer simulator */

unsigned int mem[256];
unsigned char pc;
int carry_flag;

int outc_count;
unsigned char outc_buf[1024];

#define CC_N 0x00010000
#define CC_Z 0x00020000
#define CC_C 0x00040000
#define CC_INV 0x00080000
#define CEN 0x00100000
#define CINV 0x00200000
#define COM 0x00400000
#define BEN 0x00800000
#define AND 0x01000000
#define ROR 0x02000000
#define JSR 0x04000000
#define WRB 0x08000000
#define OUT 0x10000000
#define IN 0x20000000
#define IMM 0x40000000
#define WRA 0x80000000

void unasm(unsigned int opcode)
{
        int args = 0;
        char *insn = "???";
        unsigned char bb = opcode;
        unsigned char aa = (opcode >> 8);
        int start;

        switch (opcode >> 16) {
                case 0x0000: insn = "clc"; break;
                case 0x0061: insn = "jlt"; args = 2; break;
                case 0x0062: insn = "jeq"; args = 2; break;
                case 0x0063: insn = "jle"; args = 2; break;
                case 0x0064: insn = "jcc"; args = 1; break;
                case 0x0066: insn = "jls"; args = 2; break;
                case 0x0069: insn = "jpl"; args = 2; break;
                case 0x006a: insn = "jne"; args = 2; break;
                case 0x006b: insn = "jgt"; args = 2; break;
                case 0x006c: insn = "jcs"; args = 1; break;
                case 0x006e: insn = "jhi"; args = 2; break;
                case 0x0202: insn = "jo"; args = 2; break;
                case 0x020a: insn = "je"; args = 2; break;
                case 0x0080: insn = "ntoc"; args = 1; break;
                case 0x0800: insn = "st"; args = 2; break;
                case 0x0840: if (aa == bb) { insn = "com"; args = 1; } else { insn = "comto"; args = 2; } break;
                case 0x0850: if (aa == bb) { insn = "ngc"; args = 1; } else { insn = "ngcto"; args = 2; } break;
                case 0x0860: if (aa == bb) { insn = "neg"; args = 1; } else { insn = "negto"; args = 2; } break;
                case 0x0880: if (aa == bb) { insn = "lsl"; args = 1; } else { insn = "addto"; args = 2; } break;
                case 0x0890: if (aa == bb) { insn = "rol"; args = 1; } else { insn = "adcto"; args = 2; } break;
                case 0x08a0: insn = "lslo"; args = 1; break;
                case 0x08d0: insn = "rsbcto"; args = 2; break;
                case 0x08e0: insn = "rsbto"; args = 2; break;
                case 0x0980: insn = "andto"; args = 2; break;
                case 0x09c0: insn = "bicto"; args = 2; break;
                case 0x0a00: if (aa == bb) { insn = "lsr"; args = 1; } else { insn = "lsrto"; args = 2; } break;
                case 0x0a20: if (aa == bb) { insn = "lsro"; args = 1; } else { insn = "lsroto"; args = 2; } break;
                case 0x0a10: if (aa == bb) { insn = "ror"; args = 1; } else {insn = "rorto"; args = 2; } break;
                case 0x1000: insn = "out"; args = 4; break;
                case 0x4010: insn = "nop"; break;
                case 0x4018: insn = "jmp"; args = 1; break;
                case 0x4020: insn = "stc"; break;
                case 0x4800: if (aa == 0) { insn = "clr"; args = 1; } else { insn = "st"; args = 3; } break;
                case 0x4880: if (aa == 1) { insn = "inc"; args = 1; } else { insn = "addto"; args = 3; } break;
                case 0x4890: insn = "adcto"; args = 3; break;
                case 0x48d0: insn = "rsbcto"; args = 3; break;
                case 0x48e0: if (aa == 1) { insn = "dec"; args = 1; } else { insn = "rsbto"; args = 3; } break;
                case 0x4980: insn = "andto"; args = 3; break;
                case 0x49c0: insn = "bicto"; args = 3; break;
                case 0x5000: insn = "out"; args = 5; break;
                case 0x6800: insn = "in"; args = 1; break;
                case 0xE800: insn = "inwait"; args = 1; break;
                case 0x9800: insn = "outc"; args = 4; break;
                case 0xD800: insn = "outc"; args = 5; break;
                case 0x8022: insn = "incjeq"; args = 2; break;
                case 0x802a: insn = "incjne"; args = 2; break;
                case 0x8080: insn = "add"; args = 2; break;
                case 0x80e0: insn = "rsb"; args = 2; break;
                case 0x8408: insn = "jsr"; args = 2; break;
                case 0xc810: insn = "halt"; break;
                default: insn = hex_8(opcode); break;
        }

        start = jputs(insn);

        tab(start + 8);
        start = col;

        if (args == 1) {
                jputs("0x"); jputs(hex2(opcode));
        } else if (args == 2) {
                jputs("0x"); jputs(hex2(opcode >> 8));
                jputs(", ");
                jputs("0x"); jputs(hex2(opcode));
        } else if (args == 3) {
                jputs("#");
                jputs("0x"); jputs(hex2(opcode >> 8));
                jputs(", ");
                jputs("0x"); jputs(hex2(opcode));
        } else if (args == 4) {
                jputs("0x"); jputs(hex2(opcode >> 8));
        } else if (args == 5) {
                jputs("#");
                jputs("0x"); jputs(hex2(opcode >> 8));
        }

        tab(start + 16);
}

int step()
{
	unsigned int insn;
	unsigned char arga, arga_raw;
	unsigned char argb;
	unsigned char addra;
	unsigned char addrb;

	unsigned int alu_and;
	unsigned int alu_add;
	unsigned int carry_in;
	unsigned int carry_out;

	unsigned char alu_result;

	unsigned char ror_result;

	unsigned char write_data;

	// Fetch
	insn = mem[pc];

	jputs(hex2(pc)); jputs(": "); jputs(hex_8(insn)); jputs(" (C="); jputc('0' + carry_flag); jputs(")    ");
	unasm(insn);

	// B argument
	addrb = insn;
	argb = mem[addrb];

	// A argument
	addra = (insn >> 8);
	if (insn & IMM)
		arga_raw = addra;
	else
		arga_raw = mem[addra];

	arga = arga_raw;

	// Check for input
	if ((WRA & insn) && (WRB & insn) && (IN & insn)) {
		char buf[256];
		long val;
		printf("Input: ");
		fgets(buf, 255, stdin);
		val = strtol(buf, NULL, 0);
		arga = (arga & 0xF0) | (val & 0x0F);
	}

	// Argument B enable
	if (!(BEN & insn))
		argb = 0;

	// Complement
	if (COM & insn)
		arga = ~arga;

	// Carry enable
	if (CEN & insn)
		if (CINV & insn)
			carry_in = !carry_flag;
		else
			carry_in = carry_flag;
	else
		if (CINV & insn)
			carry_in = 1;
		else
			carry_in = 0;

	// printf(" arga=%2.2x", arga);
	// printf(" argb=%2.2x", argb);
	// printf(" carry_in=%d", carry_in);

	alu_and = (arga & argb);
	alu_add = (arga + argb + carry_in);

	// AND or ADD
	if (AND & insn)
		alu_result = alu_and;
	else
		alu_result = alu_add;

	// printf(" alu_result=%x", alu_result);

	// Rotate right
	if (ROR & insn) {
		ror_result = (arga >> 1) + (carry_in << 7);
		carry_out = (arga & 0x01);
	} else {
		ror_result = alu_result;
		carry_out = !!(alu_add & 0x100);
	}

	// printf(" ror_result=%x", ror_result);

	// Jump to subroutine
	if (JSR & insn)
		write_data = pc + 1;
	else
		write_data = ror_result;

	// printf(" write_data=%x", write_data);

	// Update PC
	if ( (!!(insn & CC_INV) ^ ((!!(insn & CC_N) && (arga_raw >> 7)) ||
	                          (!!(insn & CC_C) && !carry_flag) ||
	                          (!!(insn & CC_Z) && carry_out))) == 1) {
		pc = addrb;
		printf(" PC=%2.2X", pc);
	} else {
		pc = pc + 1;
	}

	// Output
	if (insn & OUT) {
		unsigned char out_val = (ror_result & 0xFF);
		if((insn & WRA) && (insn & WRB)) {
			printf(" OUTC=%X", out_val);
			outc_buf[outc_count] = out_val;
			outc_count++;
		} else {
			printf(" OUT=%X", out_val);
		}
	}

	// Write back
	if ((WRA & insn) && !(WRB & insn)) {
		mem[addra] = (mem[addra] & 0xFFFFFF00) + write_data;
		printf(" [%2.2X]=%2.2X", addra, write_data);
	} else if (((WRB & insn) && !(WRA & insn)) ||
	           ((WRB & insn) && (WRA & insn) && (IN & insn))) {
		mem[addrb] = (mem[addrb] & 0xFFFFFF00) + write_data;
		printf(" [%2.2X]=%2.2X", addrb, write_data);
	}

	printf(" C=%d", carry_out);
	carry_flag = carry_out;

	// Check for halt
	if ((WRA & insn) && (WRB & insn) && !(IN & insn) && !(OUT & insn)) {
		printf(" halt\n");
		return 1;
	}
	printf("\n");
	col = 0;

	return 0;
}

int main(int argc, char *argv[])
{
	FILE *f;
	int x;
	char *file_name = 0;
	char buf[1024];
	int total_insn = 0;

	pc = 0;
	carry_flag = 0;
	for (x = 0; x != 256; ++x) {
		mem[x] = 0xC810FF00;
	}

	outc_count=0;

	for (x = 1; argv[x]; ++x) {
		if (!strcmp(argv[x], "-pc")) {
			pc = strtol(argv[x + 1], NULL, 16);
			++x;
		} else if (!strcmp(argv[x], "-h") || !strcmp(argv[x], "--help")) {
			printf("%s [options] filename\n", argv[0]);
			printf("  -pc xx      Initial PC value if not zero\n");
			printf("  -h, --help  Print this help text\n");
			return -1;
		} else if (argv[x][0] == '-') {
			printf("Unknown option '%s'\n", argv[x]);
			return -1;
		} else {
			file_name = argv[x];
		}
	}

	if (!file_name) {
		fprintf(stderr, "file name missing\n");
		return -1;
	}

	f = fopen(file_name, "r");
	if (!f) {
		fprintf(stderr, "couldn't open %s\n", file_name);
		return -1;
	}
	while (fgets(buf, sizeof(buf) - 1, f)) {
		unsigned int base_addr;
		unsigned int insn_list[8];
		int rtn = sscanf(buf,
				"%x: %x %x %x %x %x %x %x %x",
				&base_addr,
				&insn_list[0], &insn_list[1], &insn_list[2], &insn_list[3],
				&insn_list[4], &insn_list[5], &insn_list[6], &insn_list[7]
				);
		if (rtn >= 2) {
			for(x = 0; x < rtn - 1; x++) {
				unsigned int addr = base_addr + x;
				unsigned int insn = insn_list[x];
				mem[addr] = insn;
				printf("%2.2x: %8.8x\n", addr, insn);
			}
		}
	}
	fclose(f);

	printf("Starting at %2.2x\n", pc);
	while (!step()) total_insn++;

	printf("Total instructions: %d\n", total_insn);

	// Dump memory
	printf("Final memory state:\n");
	for (x = 0; x != 256; x += 16) {
		int y;
		printf("%2.2x:", x);
		for (y = 0; y != 16; ++y) {
			printf(" %2.2x", 0xFF & mem[x+y]);
			if (y == 7)
				printf(" ");
		}
		printf("\n");
	}

	// Write console output (outc)
	if(outc_count > 0) {
		printf("Console output (len %d):\n", outc_count);
		for(x = 0; x < outc_count; x++) {
			unsigned char outc_val = outc_buf[x];
			putchar(outc_val);
		}
		printf("\n");
	}

	return 0;
}
