/* Main function for assembler
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
#include "asm.h"
#include "util.h"

extern int line;
extern char *file;

int main(int argc, char *argv[])
{
	char buf[1024];
	unsigned long long addr;
	int x;
	FILE *f;

	for (x = 1; argv[x]; ++x) {
		if (!strcmp(argv[x], "--help") || !strcmp(argv[x], "-h")) {
			printf("%s [options] filename\n", argv[0]);
			printf("Valid options:\n");
			printf("  --help, -h        Print this help information\n");
			return 0;
		} else if (argv[x][0] == '-') {
			printf("error: unknown option '%s'\n", argv[x]);
			return -1;
		} else {
			if (file) {
				printf("error: only one file name allowed\n");
				return -1;
			} else {
				file = argv[x];
			}
		}
	}

	if (!file) {
		printf("error: missing file name\n");
		return -1;
	}

	f = fopen(file, "r");
	if (!f) {
		fprintf(stderr, "Couldn't open file '%s'\n", file);
		return -1;
	}

	/* Text written with output(...) macro will start with a comment when comment_on = 1 */
	comment_on = 1;

	output("Pass 1...\n");
	addr = 0;
	line = 0;
	ecount = 0;
	while(fgets(buf, sizeof(buf) - 1, f)) {
		if (strlen(buf) && buf[strlen(buf)-1] == '\n')
			buf[strlen(buf)-1] = 0;
		addr = assemble(addr, buf, 0);
	}
	printf("\n");
	output("%d errors detected in pass 1\n", ecount);
	rewind(f);
	addr = 0;
	line = 0;
	ecount = 0;
	printf("\n");
	output("Pass 2...\n");
	while(fgets(buf, sizeof(buf) - 1, f)) {
		if (strlen(buf) && buf[strlen(buf)-1] == '\n')
			buf[strlen(buf)-1] = 0;
		addr = assemble(addr, buf, 1);
	}
	fclose(f);
	printf("\n");
	output("%d errors detected in pass 2\n", ecount);
	printf("\n");
	output("Symbol table:\n");
	show_syms();
	printf("\n");
	output("Memory image:\n");

	/* Print memory dump without comments */
	comment_on = 0;

	dump_mem();

	if (ecount) {
		return -1;
	}
	else {
		return 0;
	}
}
