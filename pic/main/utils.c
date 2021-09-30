/* Utility functions, expression parsing / printing
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

#include "utils.h"
#include "symtab.h"
#include "io.h"

void jmemmove(char *dest, char *src, int size)
{
        if (dest < src) {
                while (size--)
                        *dest++ = *src++;
        } else {
                dest += size;
                src += size;
                while (size--)
                        *--dest = *--src;
        }
}

/* Return length of string */

int jstrlen(char *s)
{
        char *o = s;
        while (*s) ++s;
        return s-o;
}

/* Copy a string */

char *jstrcpy(char *d, char *s)
{
        char *org_d = d;
        while (*d++ = *s++);
        return org_d;
}

char *jstrncpy(char *d, int len, char *s)
{
	int x;
	for (x = 0; x != len && *s; ++x)
		d[x] = *s++;
	if (x != len)
		d[x] = 0;
	return d;
}

/* Compare strings */

int jstrcmp(char *d, char *s)
{
	while (*d && *s && *d == *s) {
		++d;
		++s;
	}
	if (*d == *s)
		return 0;
	else if (*d > *s)
		return 1;
	else
		return -1;
}

int jstrncmp(char *d, int len, char *s)
{
	int x;
	for (x = 0; x != len; ++x)
		if (!d[x] || !s[x] || d[x] != s[x])
			break;
	if (x == len)
		return 0;
	if (d[x] == s[x])
		return 0;
	else if (d[x] > s[x])
		return 1;
	else
		return -1;
}

/* Convert to upper case */

int to_upper(int c)
{
        if (c >= 'a' && c <= 'z')
                c += 'A' - 'a';
        return c;
}

/* stricmp not univeral.. */

int jstricmp(char *d, char *s)
{
        while (*d && *s && to_upper(*d) == to_upper(*s)) {
                ++d;
                ++s;
        }
        if (!*d && !*s)
                return 0;
        else
                return 1;
}

static char hbuf[12];

int to_hex_digit(unsigned int x)
{
	return "0123456789abcdef"[x & 0xF];
}

char *hex8(unsigned long x)
{
	hbuf[0] = to_hex_digit(x >> 28);
	hbuf[1] = to_hex_digit(x >> 24);
	hbuf[2] = to_hex_digit(x >> 20);
	hbuf[3] = to_hex_digit(x >> 16);
	hbuf[4] = to_hex_digit(x >> 12);
	hbuf[5] = to_hex_digit(x >> 8);
	hbuf[6] = to_hex_digit(x >> 4);
	hbuf[7] = to_hex_digit(x);
	hbuf[8] = 0;
	return hbuf;
}

char *hex_8(unsigned long x)
{
	hbuf[0] = to_hex_digit(x >> 28);
	hbuf[1] = to_hex_digit(x >> 24);
	hbuf[2] = to_hex_digit(x >> 20);
	hbuf[3] = to_hex_digit(x >> 16);
	hbuf[4] = '_';
	hbuf[5] = to_hex_digit(x >> 12);
	hbuf[6] = to_hex_digit(x >> 8);
	hbuf[7] = to_hex_digit(x >> 4);
	hbuf[8] = to_hex_digit(x);
	hbuf[9] = 0;
	return hbuf;
}

char *hex4(unsigned int x)
{
	hbuf[0] = to_hex_digit(x >> 12);
	hbuf[1] = to_hex_digit(x >> 8);
	hbuf[2] = to_hex_digit(x >> 4);
	hbuf[3] = to_hex_digit(x);
	hbuf[4] = 0;
	return hbuf;
}

char *hex2(unsigned int x)
{
	hbuf[0] = to_hex_digit(x >> 4);
	hbuf[1] = to_hex_digit(x);
	hbuf[2] = 0;
	return hbuf;
}

/* Print number in hex with underscores */

char *phex(int width, unsigned long val)
{
	
	char buf[8];
	int wid = 0;
	int q;
	int z;
	int x;

	for (x = 0; x != 8; ++x) {
		buf[wid++] = to_hex_digit(val);
		val >>= 4;
	}

	/* Suppress zeros */
	while (wid >= 2 && buf[wid - 1] == '0')
		--wid;

	/* Force to asked-for size */
	if (width > wid)
		wid = width;

	/* Print with underscores */
	z = (wid - 1) / 4 + wid;
	hbuf[z] = 0;
	q = z;
	for (x = 0; x != wid; ++x) {
		hbuf[--q] = buf[x];
		if ((x & 3) == 3 && x + 1 != wid) {
			hbuf[--q] = '_';
		}
	}

	return hbuf;
}

/* Skip to whitespace */

int skiptows(char **at_p)
{
	char *p = *at_p;
	while (*p && *p != ' ' && *p != '\t')
		++p;
	*at_p = p;
	if (*p == ' ' || *p == '\t')
        	return 1;
        else
                return 0;
}

/* Skip over matching word */

int match_word(char **at_p, char *word)
{
        char *p = *at_p;
        int len = jstrlen(word);
        if (!strncmp(p, word, len) && (!p[len] || p[len] == ' ' || p[len] == '\t')) {
                p += len;
                skipws(&p);
                *at_p = p;
                return 1;
        } else
                return 0;
}

/* Extract field */

int parse_field(char **at_p, char *buf)
{
	char *p = *at_p;
	if (*p && *p != ' ' && *p != '\t' && *p != ',' && *p != '+' && *p != '-') {
		int x = 0;
		while (*p && *p != ' ' && *p != '\t' && *p != ',' && *p != '+' && *p != '-') {
			buf[x++] = *p++;
		}
		buf[x] = 0;
		*at_p = p;
		return 1;
	} else {
		return 0;
	}
}

/* Hex dump */
#if 0
void hd(unsigned char *mem, int start, int len)
{
        int y;
        int skip = (start & 0x0F);
        int skip1 = skip;
        start &= ~0x0F;

        len += skip;

        y = 0;
        while (len > 0) {
                int x;
                int len1 = len;
                fprintf(out, "%4.4X:", start + y);
                for (x = 0; x != 16; ++x) {
                        if (skip || len <= 0) {
                                --skip;
                                fprintf(out, "   ");
                        } else {
                                fprintf(out, " %2.2X", mem[start +y + x]);
                        }
                        if (x == 7)
                                fprintf(out, " ");
                        --len;
                }
                fprintf(out, " ");
                for (x = 0; x != 16; ++x) {
                        unsigned char c = mem[start + y + x];
                        if (c < 32 || c > 126) c = '.';
                        if (skip1 || len1 <= 0) {
                                --skip1;
                                fprintf(out, " ");
                        } else {
                                fprintf(out, "%c", c);
                        }
                        --len1;
                }
                fprintf(out, "\n");
                y += 16;
        }
}
#endif
/* Break up whitespace separated words into an array of string pointers */

int fields(char *buf, char *words[])
{
        int n = 0;
        while (skipws(&buf) && *buf) {
                words[n++] = buf;
                skiptows(&buf);
                if (*buf)
                        *buf++ = 0;
        }
        return n;
}

/* Expressions */

int hex_digit(int c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	else if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;
	else
		return -1;
}

int dec_digit(int c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else
		return -1;
}

int oct_digit(int c)
{
	if (c >= '0' && c <= '7')
		return c - '0';
	else
		return -1;
}

int bin_digit(int c)
{
	if (c >= '0' && c <= '1')
		return c - '0';
	else
		return -1;
}

/* Parse hex */

int parse_hex(char **str, unsigned long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long val = 0;

//	if (s[0] == '0' && s[1] == 'x')
//		s += 2;
//	else
//		return 0;

	while (*s == '_' || hex_digit(*s) >= 0) {
		if (*s != '_') {
			val = (val << 4) + hex_digit(*s);
			status = 1;
		}
		++s;
	}

	if (status) {
			*rtn_val = val;
			*str = s;
	}

	return status;
}

/* Parse octal */

int parse_oct(char **str, unsigned long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long val = 0;

	while (*s == '_' || oct_digit(*s) >= 0) {
		if (*s != '_') {
			val = (val << 3) + oct_digit(*s);
			status = 1;
		}
		++s;
	}

	if (status) {
			*rtn_val = val;
			*str = s;
	}

	return status;
}

/* Parse decimal */

int parse_dec(char **str, unsigned long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long val = 0;

	while (*s == '_' || dec_digit(*s) >= 0) {
		if (*s != '_') {
			val = (val * 10) + dec_digit(*s);
			status = 1;
		}
		++s;
	}

	if (status) {
			*rtn_val = val;
			*str = s;
	}

	return status;
}

/* Parse binary */

int parse_bin(char **str, unsigned long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long val = 0;

//	if (*s == '%')
//		++s;
//	else
//		return 0;

	while (*s == '_' || bin_digit(*s) >= 0) {
		if (*s != '_') {
			val = (val << 1) + bin_digit(*s);
			status = 1;
		}
		++s;
	}

	if (status) {
			*rtn_val = val;
			*str = s;
	}

	return status;
}

/* Parse a number: 10, 0xa and 012 all have the same value.  Underscores
      allowed. */

int parse_num(char **str, unsigned long *rtn_val)
{
	int status;
	char *s = *str;

	if (s[0] == '0' && s[1] == 'x') {
		s += 2;
		status = parse_hex(&s, rtn_val);
		*str = s;
		return status;
	} else if (s[0] == '%') {
		s += 1;
		status = parse_bin(&s, rtn_val);
		*str = s;
		return status;
	} else if (s[0] == '0') {
		status = parse_oct(&s, rtn_val);
		*str = s;
		return status;
	} else {
		status = parse_dec(&s, rtn_val);
		*str = s;
		return status;
	}
}

/* Parse a word */

int parse_word(char **str, char *buf)
{
	char *p = *str;
	if (*p >= 'a' && *p <= 'z' || *p >= 'A' && *p <= 'Z' || *p == '_') {
		int x = 0;
		while (*p >= 'a' && *p <= 'z' || *p >= 'A' && *p <= 'Z' || *p >= '0' && *p <= '9' || *p == '_') {
			buf[x++] = *p++;
		}
		buf[x] = 0;
		*str = p;
		return 1;
	} else {
		return 0;
	}
}

/* Skip whitespace */

int skipws(char **at_p)
{
	char *p = *at_p;
	while (*p == ' ' || *p == '\t')
		++p;
	*at_p = p;
	return 1;
}

/* Parse an expression:
      0 = OK
      1 = syntax error
      2 = has undefined symbol
      4 = too complex to fixup later
      8 = tried to divide by 0
*/

char word_buf[80];
unsigned long the_addr;

int parse_expr(char **str, unsigned long *rtn_val, int prec, int flags)
{
	int status;
	int rstatus;
	char *s = *str;
	unsigned long b;
	if (*s == '(') {
		++s;
		status = parse_expr(&s, rtn_val, 0, flags);
		if (*s != ')')
			return 0;
		++s;
	} else if (*s == '-') {
		++s;
		status = parse_expr(&s, rtn_val, 2, flags);
		*rtn_val = -*rtn_val;
		if (status & 2)
			status |= 4;
	} else if (*s == '~') {
		++s;
		status = parse_expr(&s, rtn_val, 2, flags);
		*rtn_val = ~*rtn_val;
		if (status & 2)
			status |= 4;
	} else if (*s == '*') {
		++s;
		status = 0;
		*rtn_val = the_addr;
	} else if (parse_word(&s, word_buf)) {
		int sy = find_symbol(word_buf);
		if (sy != -1) {
		        int flag = get_flag(sy);
		        if (flag & 0x80) {
		                *rtn_val = 0;
		                status = 2;
		                if (flags)
        		                add_fixup(sy, the_addr, flags);
                        } else {
                                *rtn_val = get_value(sy);
        			status = 0;
                        }
		} else {
			*rtn_val = 0;
			status = 6;
		}
	} else {
		status = !parse_num(&s, rtn_val);
	}
	while (*s && !(status & 1)) {
		if (s[0] == '<' && s[1] == '<') {
				s += 2;
				status |= parse_expr(&s, &b, 3, flags);
				if (!status)
					*rtn_val <<= b;
				else if (status & 2)
					status |= 4;
		} else if (s[0] == '>' && s[1] == '>') {
				s += 2;
				status |= parse_expr(&s, &b, 3, flags);
				if (!status)
					*rtn_val >>= b;
				else if (status & 2)
					status |= 4;
		} else if (*s == '*' && prec < 2) {
				++s;
				status |= parse_expr(&s, &b, 2, flags);
				if (!status)
					*rtn_val *= b;
				else if (status & 2)
					status |= 4;
		} else if (*s == '/' && prec < 2) {
				++s;
				status |= parse_expr(&s, &b, 2, flags);
				if (b == 0)
					status |= 8;
				if (!status)
					*rtn_val /= b;
				else if (status & 2)
					status |= 4;
		} else if (*s == '&' && prec < 2) {
				++s;
				status |= parse_expr(&s, &b, 2, flags);
				if (!status)
					*rtn_val &= b;
				else if (status & 2)
					status |= 4;
		} else if (*s == '%' && prec < 2) {
				++s;
				status |= parse_expr(&s, &b, 2, flags);
				if (b == 0)
					status |= 8;
				if (!status)
					*rtn_val %= b;
				else if (status & 2)
					status |= 4;
		} else if (*s == '+' && prec < 1) {
				++s;
				status |= parse_expr(&s, &b, 1, flags);
				if (!status || status == 2)
					*rtn_val += b;
		} else if (*s == '-' && prec < 1) {
				++s;
				rstatus = parse_expr(&s, &b, 1, flags);
				if (rstatus & 2)
					rstatus |= 4;
				status |= rstatus;
				if (status == 0 || status == 2)
					*rtn_val -= b;
		} else if (*s == '|' && prec < 1) {
				++s;
				status |= parse_expr(&s, &b, 1, flags);
				if (!status)
					*rtn_val |= b;
				else if (status & 2)
					status |= 4;
		} else
			break;
	}
	if (!(status & 1))
		*str = s;
	return status;
}

/* Parse an expression */
/* Parse an expression:
      0 = OK
      1 = syntax error
      2 = has undefined symbol
      4 = too complex to fixup later
      8 = tried to divide by 0
*/

int expr(char **str, unsigned long *rtn_val, unsigned long addr, int flags)
{
	int status;
	char *s = *str;
	the_addr = addr;
	status = parse_expr(&s, rtn_val, 0, flags);
	if (status & 1) {
		jputs("Expression syntax error\n");
	}
	if (status & 4) {
		jputs("Expression too complex to fixup later\n");
	}
	if (status & 8) {
		jputs("Tried to divide by zero\n");
	}
	if (!(status & 1))
		*str = s;
	return status;
}
