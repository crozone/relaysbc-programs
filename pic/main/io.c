/* I/O functions for main microcontroller
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

#include "pic.h"
#include "io.h"
#include "utils.h"

// Output functions

int col;

int jputc(int c)
{
        int org_col = col;
	if (c == 10) {
		uart1_putc(13);
		col = 0;
		uart1_putc(10);
	} else {
		uart1_putc(c);
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
        int x;
        int buf_idx = 0;
#ifdef JDEBUG
        cu_termios();
#else
//J1        uart1_putc('Q' - '@');
#endif
        for (;;) {
                x = uart1_getc();
                if (x >= 0x20 && x <= 0x7E) {
                        // Type
                        if (buf_idx != limit-1) {
                                uart1_putc(x);
                                buf[buf_idx++] = x;
                        } else {
                                // uart1_putc(7);
                        }
                } else if (x == 8 || x == 0x7F) {
                        // Backspace
                        if (buf_idx) {
                                uart1_putc(8);
                                uart1_putc(' ');
                                uart1_putc(8);
                                --buf_idx;
                        } else {
                                // uart1_putc(7);
                        }
                } else if (x == 13) {
                        crlf();
                        buf[buf_idx] = 0;
                        x = 0;
                        break;
                } else if (x == 3) {
                        crlf();
                        buf[0] = 0;
                        x = -1;
                        break;
                }
        }
#ifdef JDEBUG
        restore_termios();
#else
//J1        uart1_putc('S' - '@');
#endif
        return x;
}
