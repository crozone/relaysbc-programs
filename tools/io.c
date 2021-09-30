/* I/O functions so that microcontroller and C are similar
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
#include "io.h"

// Output functions

int col;

int jputc(int c)
{
        int org_col = col;
	if (c == 10) {
	        putchar(10);
		col = 0;
	} else {
	        putchar(c);
		if (c == 13) {
			col = 0;
		} else if (c == 8) {
			--col;
		} else if (c >= 32 && c <= 126) {
			++col;
		}
	}
	return org_col;
}

int jputs(char *s)
{
        int org_col = col;
	while (*s)
		jputc(*s++);
	return org_col;
}

int jputsn(char *s, int len)
{
	int x;
        int org_col = col;
        for (x = 0; s[x] && x != len; ++x)
		jputc(s[x]);
	return org_col;
}

int tab(int to)
{
        int org_col = col;
	while (col < to)
		jputc(' ');
	return org_col;
}

/* Print huh? */

void huh()
{
	jputs("Huh?\n");
}

void crlf()
{
	jputc('\n');
}

int jgetline(char *buf, int limit)
{
        if (fgets(buf, limit, stdin)) {
                int len = strlen(buf);
                if (len && buf[len - 1] == '\n') {
                        buf[len - 1] = 0;
                        --len;
                }
                return len;
        } else {
                return -1;
        }
}
