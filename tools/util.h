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

/* Parse an expression */
int expr(char **s, unsigned long long *rtn_val, unsigned long long addr, int udf);

/* Print hex nicely */
char *hex(int width, unsigned long long val);

/* Parse a word */
int parse_word(char **str, char *buf);

/* Skip whitespace */
int skipws(char **str);

/* Lookup a symbol */

/* Symbol table */

struct symbol {
	struct symbol *next;
	char *name;
	int valid;
	unsigned long long val;
};

struct symbol *find_symbol(char *name);
void set_symbol(struct symbol *sy, unsigned long long val);
void show_syms();

int to_hex_digit(unsigned int x);
char *hex8(unsigned long x);
char *hex_8(unsigned long x);
char *hex4(unsigned int x);
char *hex2(unsigned int x);
/* Print hex nicely */
char *phex(int width, unsigned long val);

/* Enable commented line during output */
extern int comment_on;
#define output(...) (void)(comment_on && printf("; ")), printf(__VA_ARGS__)

/* Error printer */
extern int line;
extern char *file;
extern int ecount;
#define error0(s) ++ecount, output("%s:%d: error: " s "\n", file, line)
#define error1(s, a) ++ecount, output("%s:%d: error: " s "\n", file, line, (a))
#define error2(s, a, b) ++ecount, output("%s:%d: error: " s "\n", file, line, (a), (b))
