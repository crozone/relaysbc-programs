/* Symbol table for assembler
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

extern unsigned long memory[256];

/* Symbol table */

#define SYMSIZE 256
unsigned char symtab[SYMSIZE];
int nsyms;

int get_flag(int symidx)
{
        if (symidx == -1)
                return 0x80;
        else
                return symtab[symidx];
}

unsigned long get_value(int symidx)
{
        if (symidx == -1)
                return 0;
        else {
                int flag = symtab[symidx];
                unsigned long val;
                val = symtab[symidx + 4];
                val = (val << 8) + symtab[symidx + 3];
                val = (val << 8) + symtab[symidx + 2];
                val = (val << 8) + symtab[symidx + 1];
                // return *(unsigned long *)(symtab + symidx + 1);
                return val;
        }
}

int after_num(int symidx)
{
        return symidx + 5;
}

int after_str(int symidx)
{
        symidx = after_num(symidx);
        symidx += jstrlen(symtab + symidx) + 1;
        return symidx;
}

char *get_name(int symidx)
{
	if (symidx == -1)
		return "???";
	else
		return symtab + after_num(symidx);
}

int get_size(int symidx)
{
	if (symidx == -1)
		return 0;
	else {
	        int org_idx = symidx;
	        symidx = after_str(symidx);
	        while (symtab[symidx] != 0xff)
	                symidx += 2;
                ++symidx;
                return symidx - org_idx;
        }
}

void tiny_delay()
{
}

void short_delay()
{
        int x;
        for (x = 0; x != 10; ++x)
                tiny_delay();
}

void long_delay()
{
        int x;
        for (x = 0; x != 30000; ++x)
                short_delay();
}

/* Set symbol's value, process pending fixups */

void set_symbol(int symidx, unsigned long val)
{
        int f;
        if (symidx == -1)
                return;
        // jputs("Set symbol\n\n");
        // jputs(phex(2, symidx)); crlf();
        // long_delay();
        // Set value
        // *(unsigned long *)(symtab + symidx + 1) = val;
        symtab[symidx+1] = val;
        symtab[symidx+2] = (val >> 8);
        symtab[symidx+3] = (val >> 16);
        symtab[symidx+4] = (val >> 24);
        // Clear "not-set" flag
        // jputs("Set symbol1\n\n"); // long_delay();
        symtab[symidx] &= 0x7F;
        // Skip over value and name
        // jputs("Set symbol2\n\n"); // long_delay();
        symidx = after_str(symidx);
        // jputs("Fixups\n"); // long_delay();
        // Apply fixups
	while ((f = symtab[symidx]) != 0xff) {
	        int ofst = symtab[symidx + 1];
                jputs("Fixup at "); jputs(phex(1, ofst)); crlf(); // long_delay();
                if (f & 1)
                        *(char *)(memory + ofst) += val;
                if (f & 2)
                        *(1 + (char *)(memory + ofst)) += val;
                // jputs("delete fixup\n"); // long_delay();
                // Delete fixup
                jmemmove(symtab + symidx, symtab + symidx + 2, nsyms - (symidx + 2));
                nsyms -= 2;
	}
}

/* Add fixup to symbol */

void add_fixup(int symidx, int ofst, int flags)
{
        crlf();
        // jputs(phex(2, ofst)); crlf();
        // jputs(phex(2, flags)); crlf();
        if (nsyms + 2 <= SYMSIZE) {
                jputs("Adding fixup\n");
                symidx = after_num(symidx);
                symidx += jstrlen(symtab + symidx) + 1;
                jmemmove(symtab +symidx + 2,symtab + symidx, nsyms - symidx);
                nsyms += 2;
                symtab[symidx++] = flags;
                symtab[symidx++] = ofst;
        } else {
                jputs("Can't fit fixup\n");
        }
}

/* Symbol looks like this:
      <value><string>
*/

int find_symbol(char *name)
{
	int x;
	// jputs(name); crlf();
	for (x = 0; x != nsyms; x += get_size(x)) {
		if (!jstrcmp(get_name(x), name))
			return x;
	}
	// jputs("Couldn't find\n");
	if (jstrlen(name) + 7 + nsyms <= SYMSIZE) {
		// it will fit
		// jputs("flag\n");
		symtab[nsyms++] = 0x80;
		// jputs("num\n");
		// *(long *)(symtab + nsyms) = 0;
		nsyms += 4;
		// jputs("str\n");
		jstrcpy(symtab + nsyms, name);
		nsyms += jstrlen(name) + 1;
		// jputs("term\n");
		symtab[nsyms++] = 0xff;
		// jputs("Added\n");
		return x;
	} else {
		// it will not fit
		jputs("Symbol ");
		jputs(name);
		jputs(" couldn't fit\n");
		return -1;
	}
}

void clr_symbols()
{
	nsyms = 0;
}

void dump()
{
        int x;
        for (x = 0; x != nsyms; ++x) {
                jputs(phex(2, symtab[x]));
                crlf();
        }
}

void pr_symbols()
{
	int x;
	int z;
	// dump();
	for (x = 0; x != nsyms; x = z) {
		jputs(get_name(x));
		jputs(" = ");
		if (get_flag(x) & 0x80)
			jputs("???");
                else {
        		unsigned long v = get_value(x);
			jputs(phex(1, v));
                }
		crlf();
                z = after_str(x);
                // jputs(phex(2, z)); crlf();
                while (symtab[z] != 0xff) {
                        jputs("  pending fixup at ");
                        // jputs(phex(2, symtab[z]));
                        jputs(phex(2, symtab[z + 1]));
                        // jputs(phex(2, symtab[z + 2]));
                        crlf();
                        z += 2;
                }
                ++z;
	}
	jputs("Symbol table size ");
	jputs(phex(1, x));
	crlf();
}
