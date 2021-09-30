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

int to_hex_digit(unsigned int x);
char *hex8(unsigned long x);
char *hex_8(unsigned long x);
char *hex4(unsigned int x);
char *hex2(unsigned int x);
/* Print hex nicely */
char *phex(int width, unsigned long val);

int skipws(char **at_p);
int match_word(char **at_p, char *word);
int parse_field(char **at_p, char *buf);

int parse_hex(char **at_p, unsigned long *hex);

void hd(unsigned char *mem, int start, int len);
int fields(char *buf, char *words[]);
char *jstrcpy(char *d, char *s);
char *jstrncpy(char *d, int len, char *s);
int jstrlen(char *s);
int jstrcmp(char *d, char *s);
int jstrncmp(char *d, int len, char *s);
int jstricmp(char *d, char *s);
void jmemmove(char *d, char *s, int size);

/* Parse an expression */
int expr(char **s, unsigned long *rtn_val, unsigned long addr, int flags);

/* Parse a word */
int parse_word(char **str, char *buf);
