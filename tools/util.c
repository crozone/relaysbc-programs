/* Utility functions: expression parser, printing
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

#include "util.h"

int comment_on;

int line;
char *file;
int ecount;

/* Symbol table */

struct symbol *symbols;

struct symbol *find_symbol(char *name)
{
        struct symbol *sy;
        for (sy = symbols; sy; sy = sy->next)
                if (!strcmp(sy->name, name))
                        return sy;
        sy = (struct symbol *)malloc(sizeof(struct symbol));
        sy->next = symbols;
        symbols = sy;
        sy->name = strdup(name);
        sy->valid = 0;
        sy->val = 0;
        return sy;
}

/* Set symbol's value, process pending fixups */

void set_symbol(struct symbol *sy, unsigned long long val)
{
        if (!sy)
                return;
        sy->valid = 1;
        sy->val = val;
}

/* Print symbol table */

int sy_comp(const void *a, const void *b)
{
	struct symbol *aa = *(struct symbol **)a;
	struct symbol *bb = *(struct symbol **)b;
	return strcmp(aa->name, bb->name);
}

void show_syms()
{
	struct symbol *sy;
	int count = 0;
	struct symbol **sorted;
	for (sy = symbols; sy; sy = sy->next)
		++count;
	if (count) {
		int x;
		sorted = malloc(sizeof(struct symbol *) * count);
		x = 0;
		for (sy = symbols; sy; sy = sy->next)
			sorted[x++] = sy;
		qsort(sorted, x, sizeof(struct symbol *), sy_comp);
		for (x = 0; x != count; ++x) {
			if (sorted[x]->valid) {
				output("%s = 0x%llx\n", sorted[x]->name, sorted[x]->val);
			}
			else {
				output("%s = ???\n", sorted[x]->name);
			}
		}
	}
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

int parse_hex(char **str, unsigned long long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long long val = 0;

	if (s[0] == '0' && s[1] == 'x')
		s += 2;
	else
		return 0;

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

int parse_oct(char **str, unsigned long long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long long val = 0;

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

int parse_dec(char **str, unsigned long long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long long val = 0;

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

int parse_bin(char **str, unsigned long long *rtn_val)
{
	int status = 0;
	char *s = *str;
	unsigned long long val = 0;

	if (*s == '%')
		++s;
	else
		return 0;

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

int parse_num(char **str, unsigned long long *rtn_val)
{
	int status;
	char *s = *str;

	if (s[0] == '0' && s[1] == 'x') {
		status = parse_hex(&s, rtn_val);
		*str = s;
		return status;
	} else if (s[0] == '%') {
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
	if ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || *p == '_') {
		int x = 0;
		while ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') || (*p >= '0' && *p <= '9') || *p == '_') {
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

char word_buf[80];
int udf;
unsigned long long the_addr;

int parse_expr(char **str, unsigned long long *rtn_val, int prec, int eudf)
{
	int status;
	char *s = *str;
	unsigned long long b;
	if (*s == '(') {
		++s;
		status = parse_expr(&s, rtn_val, 0, eudf);
		if (*s != ')')
			return 0;
		++s;
	} else if (*s == '-') {
		++s;
		status = parse_expr(&s, rtn_val, 2, eudf);
		*rtn_val = -*rtn_val;
	} else if (*s == '~') {
		++s;
		status = parse_expr(&s, rtn_val, 2, eudf);
		*rtn_val = ~*rtn_val;
	} else if (*s == '*') {
		++s;
		status = 1;
		*rtn_val = the_addr;
	} else if (parse_word(&s, word_buf)) {
		struct symbol *sy = find_symbol(word_buf);
		status = 1;
		if (sy && sy->valid) {
			*rtn_val = sy->val;
		} else {
			if (eudf)
				error1("Undefined symbol '%s'", word_buf);
			*rtn_val = 0;
			udf = 1;
		}
	} else {
		status = parse_num(&s, rtn_val);
	}
	while (*s && status) {
		if (s[0] == '<' && s[1] == '<') {
				s += 2;
				status = parse_expr(&s, &b, 3, eudf);
				if (status)
					*rtn_val <<= b;
		} else if (s[0] == '>' && s[1] == '>') {
				s += 2;
				status = parse_expr(&s, &b, 3, eudf);
				if (status)
					*rtn_val >>= b;
		} else if (*s == '*' && prec < 2) {
				++s;
				status = parse_expr(&s, &b, 2, eudf);
				if (status)
					*rtn_val *= b;
		} else if (*s == '/' && prec < 2) {
				++s;
				status = parse_expr(&s, &b, 2, eudf);
				if (b == 0)
					status = 0;
				if (status)
					*rtn_val /= b;
		} else if (*s == '&' && prec < 2) {
				++s;
				status = parse_expr(&s, &b, 2, eudf);
				if (status)
					*rtn_val &= b;
		} else if (*s == '%' && prec < 2) {
				++s;
				status = parse_expr(&s, &b, 2, eudf);
				if (b == 0)
					status = 0;
				if (status)
					*rtn_val %= b;
		} else if (*s == '+' && prec < 1) {
				++s;
				status = parse_expr(&s, &b, 1, eudf);
				if (status)
					*rtn_val += b;
		} else if (*s == '-' && prec < 1) {
				++s;
				status = parse_expr(&s, &b, 1, eudf);
				if (status)
					*rtn_val -= b;
		} else if (*s == '|' && prec < 1) {
				++s;
				status = parse_expr(&s, &b, 1, eudf);
				if (status)
					*rtn_val |= b;
		} else
			break;
	}
	if (status)
		*str = s;
	return status;
}

/* Parse an expression */
/* Returns 0 for error, 1 for OK, or -1 for OK but undefined symbols */

int expr(char **str, unsigned long long *rtn_val, unsigned long long addr, int eudf)
{
	int status;
	char *s = *str;
	udf = 0;
	the_addr = addr;
	status = parse_expr(&s, rtn_val, 0, eudf);
	if (!status) {
		error0("Bad or missing expression");
		return 0;
	}
	*str = s;
	if (udf)
		return -1;
	else
		return 1;
}

/* Print number in hex with underscores */

char *hex(int width, unsigned long long val)
{
	
	static char out[8][64];
	static int nextbuf = 0;
	char buf[64];
	int wid = 0;
	int q;
	int z;
	int x;

	/* Choose next buffer */
	if (++nextbuf >= 8)
		nextbuf = 0;

	for (x = 0; x != 16; ++x) {
		int dig = (val & 0xF);
		val >>= 4;
		buf[wid++] = "0123456789abcdef"[dig];
	}

	/* Suppress zeros */
	while (wid >= 2 && buf[wid - 1] == '0')
		--wid;

	/* Force to asked-for size */
	if (width > wid)
		wid = width;

	/* Print with underscores */
	z = (wid - 1) / 4 + wid;
	out[nextbuf][z] = 0;
	q = z;
	for (x = 0; x != wid; ++x) {
		out[nextbuf][--q] = buf[x];
		if ((x & 3) == 3 && x + 1 != wid) {
			out[nextbuf][--q] = '_';
		}
	}

	return out[nextbuf];
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

