/* Relay computer main microcontroller code
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
#include "symtab.h"

int hold_console; /* Set if Ctrl-S sent to console serial */

int last_u; /* Last unassemble address */
int trace; /* Trace mode */

char buf[80]; /* Command line input buffer */
int buf_idx; /* Input buffer index */

unsigned char bits[6]; /* Bits we send */
/* bits:
 *
 *  bits[0] is B Address
 *  bits[1] is A Address (no SN754410NE)
 *  bits[2] is B data
 *  bits[3] is A data
 *  bits[4] is { ben, com, cinv, cen, cc[3:0] }
 *  bits[5] is { halt, clk, in, out, wrb, jsr, ror, and }
 */

unsigned long current_insn; // current instruction
unsigned char current_a;
unsigned char current_b;
int pc; // current program counter

unsigned long memory[256]; // Main memory
int addr; // Current address

int mode; // editing mode: 0=no editing, 1=data entry
unsigned long edit_data; // current data being loaded
int edit_len; // number of digits we have so far

/* PORTAbits.RA0
 * TRISAbits.TRISA0
 */

/* Pin assignment:
 *
 * RA0  serial out to 595s
 * RA1  clock for 595s
 * RA2  reset_l for 595s and 597s (now it's clock_pulse)
 * RA3  xfer for 595s
 *
 * RB0  Async Tx to kbddisp
 * RB1  Async Rx from kbddisp
 * RB2  Async Rx from DB9
 * RB7  Async Tx to DB9
 * RB8  serial in from 597s
 * RB9  clk to 597s
 * RB10 load clock to 597s (now it's RB12)
 * RB11 xfer_l to 597s (now it's RB13)
 *   (now RB15 is connected to pot)
 */


void junk()
{
}

int speed;

// (1000/freq - 17)/.0052

const long speed_table[]=
{
//	1920000,// .1 Hz
//	381538,	// .5 Hz
//	189230,	// 1 Hz

	93077,	// 2 Hz
	78653,
	64230,
	35384,	// 5 Hz
	25768,
	16153,	// 10 Hz default
	12948,
	9743,	// 15 Hz
	8140,
	6538,	// 20 Hz
	5581,
	4615,	// 25 Hz
	3974,
	3333,	// 30 Hz (works)
	2875,
	2418,	// 35 Hz (works sometimes)

//	1731,	// 40 Hz
//	1197,	// 45 Hz
//	769,	// 50 Hz
//	419,	// 55 Hz
//	128	// 60 Hz
};

void delay()
{
	long x;
	long e;
	if (speed == 0) {
		e = 8500000L;
		while (e > 0) {
			int tmp;
			// Use knob
			tmp = 3069 - knob + 88;
			if (tmp > 3333)
				tmp = 3333;
			if (tmp < 1)
				tmp = 1;
			e -= tmp;
			junk();
		}
	} else {
		// Use table
		e = speed_table[speed];
		for (x = 0; x != e; ++x)
			junk();
	}
}

/* Send bits to '595 chain */

void send_bits(unsigned int old_clk, unsigned int new_clk)
{
	int idx;
	int val;

	for (idx = 0; idx != 6; ++idx) {
		unsigned char byte = bits[idx];
		int x;
		for (x = 0; x != 8; ++x) {
			if (byte & 1) {
				val = (LS595_DOUT | LS595_SHIFT_CLK | LS595_XFER | old_clk);
				// val = (LS595_DOUT | old_clk);
			} else {
				val = (LS595_SHIFT_CLK | LS595_XFER | old_clk);
				// val = (old_clk);
			}
			porta(val);
			junk();
			junk();
			// PORTAbits.RA0 = (byte & 1);
			byte >>= 1;
			porta((val & ~LS595_SHIFT_CLK)); // clk low
			// porta(val | LS595_SHIFT_CLK); // clk high
			// PORTAbits.RA1 = 0;
			junk();
			junk();
			porta(val); // clk high
			// PORTAbits.RA1 = 1;
			junk();
			junk();
		}
	}
//	porta(LS595_XFER | old_clk);	// xfer high
	porta(LS595_SHIFT_CLK | old_clk);		// xfer low
//	PORTAbits.RA3 = 0;
	junk();
	junk();
//	PORTAbits.RA3 = 1;
	porta(LS595_SHIFT_CLK | LS595_XFER | new_clk);		// xfer high
//	porta(new_clk); // xfer low
	junk();
	junk();
}

void clock_pulse()
{
	porta(LS595_SHIFT_CLK | LS595_XFER | RELAY_CLK);	// Clock high
	// porta(RELAY_CLK);
	delay();
	porta(LS595_SHIFT_CLK | LS595_XFER);			// Clock high
	// porta(0);
	delay();
}

/* Receive bits from '597 chain */

unsigned int get_bits_a()
{
	unsigned int data;
	int count;

	portb(LS597_LOAD_CLK); // Capture parallel inputs / transfer to shift register
	junk();
	junk();
	portb(LS597_XFER_L);
	junk();
	junk();

	for (count = 0; count != 16; ++count) {
		if (rd_portb() & LS597_DIN) {
			data = 0x8000 + (data >> 1);
		} else {
			data = (data >> 1);
		}
		portb(LS597_XFER_L | LS597_SHIFT_CLK);
		junk();
		junk();
		portb(LS597_XFER_L);
		junk();
		junk();
	}
	return data;
	// High bits have write data
	// Low bits have new PC value
}

unsigned int get_bits()
{
	unsigned int data, data1;
	int count;
	data = get_bits_a();
	for (count = 0; count != 3; ++count) {
		data1 = get_bits_a();
		if (data1 == data)
			break;
		else
			data = data1;
	}
	return data;
}

void update_bits()
{
	current_insn = memory[pc];
	current_b = memory[current_insn & 255];
	current_a = ((current_insn & 0x40000000) ? (current_insn >> 8) : memory[(current_insn >> 8) & 255]);

	bits[0] = current_insn;
	bits[1] = (current_insn >> 8);
	bits[2] = current_b;
	bits[3] = current_a;
	bits[4] = (current_insn >> 16);
	bits[5] = (current_insn >> 24);
}

void show()
{
	unsigned long data = memory[addr];
	if (!mode) {
		// Normal mode
		uart2_putc('@');
		if ((data & 0x88000000) == 0x88000000) {
			/* Display data */
			uart2_putc(to_hex_digit(0xF & (memory[addr+3] >> 4)));
			uart2_putc(to_hex_digit(0xF & (memory[addr+3])));
			uart2_putc('.');

			uart2_putc(to_hex_digit(0xF & (memory[addr+2] >> 4)));
			uart2_putc(to_hex_digit(0xF & (memory[addr+2])));
			uart2_putc('.');

			uart2_putc(to_hex_digit(0xF & (memory[addr+1] >> 4)));
			uart2_putc(to_hex_digit(0xF & (memory[addr+1])));
			uart2_putc('.');

			uart2_putc(to_hex_digit(0xF & (data >> 4)));
			uart2_putc(to_hex_digit(0xF & (data >> 0)));

			uart2_putc(to_hex_digit(0xF & (addr >> 4)));
			uart2_putc(to_hex_digit(0xF & (addr >> 0)));
		} else {
			/* Display an instruction */
			uart2_putc(to_hex_digit(0xF & (data >> 28)));
			uart2_putc(to_hex_digit(0xF & (data >> 24)));
			uart2_putc(to_hex_digit(0xF & (data >> 20)));
			uart2_putc(to_hex_digit(0xF & (data >> 16)));
			uart2_putc(to_hex_digit(0xF & (data >> 12)));
			uart2_putc(to_hex_digit(0xF & (data >> 8)));
			uart2_putc(to_hex_digit(0xF & (data >> 4)));
			uart2_putc(to_hex_digit(0xF & (data >> 0)));
			uart2_putc(to_hex_digit(0xF & (addr >> 4)));
			uart2_putc(to_hex_digit(0xF & (addr >> 0)));
		}
	} else {
		// Edit mode
		uart2_putc('@');
		if (edit_len >= 8) uart2_putc(to_hex_digit(0xF & (edit_data >> 28))); else uart2_putc(0x20);
		if (edit_len >= 7) uart2_putc(to_hex_digit(0xF & (edit_data >> 24))); else uart2_putc(0x20);
		if (edit_len >= 6) uart2_putc(to_hex_digit(0xF & (edit_data >> 20))); else uart2_putc(0x20);
		if (edit_len >= 5) uart2_putc(to_hex_digit(0xF & (edit_data >> 16))); else uart2_putc(0x20);
		if (edit_len >= 4) uart2_putc(to_hex_digit(0xF & (edit_data >> 12))); else uart2_putc(0x20);
		if (edit_len >= 3) uart2_putc(to_hex_digit(0xF & (edit_data >> 8))); else uart2_putc(0x20);
		if (edit_len >= 2) uart2_putc(to_hex_digit(0xF & (edit_data >> 4))); else uart2_putc(0x20);
		if (edit_len >= 1) uart2_putc(to_hex_digit(0xF & (edit_data >> 0))); else uart2_putc(0x20);
		uart2_putc(to_hex_digit(0xF & (addr >> 4)));
		uart2_putc(to_hex_digit(0xF & (addr >> 0)));
	}
	/* Update insn if it changed */
	if (current_insn != memory[pc] ||
	    current_a != (255 & ((current_insn & 0x40000000) ? (current_insn >> 8) : memory[(current_insn >> 8) & 255])) ||
	    current_b != (255 & memory[255 & current_insn])) {
//			bits[0] = 0;
//			bits[1] = 0;
//			bits[2] = 0;
//			bits[3] = 0;
//			bits[4] = 0;
//			bits[5] = 0;
//			send_bits(0, 0);
//			delay();
	    	update_bits();
		    send_bits(0, 0);
//		    delay();
//		    send_bits(0, 0);
//		    delay();
//		    send_bits(0, 0);
//		    delay();
	}
}

void save_edit()
{
	if (mode) {
		switch(edit_len) {
			case 8: memory[addr] = edit_data; break;
			case 7: memory[addr] = (memory[addr] & 0xF0000000) | edit_data; break;
			case 6: memory[addr] = (memory[addr] & 0xFF000000) | edit_data; break;
			case 5: memory[addr] = (memory[addr] & 0xFFF00000) | edit_data; break;
			case 4: memory[addr] = (memory[addr] & 0xFFFF0000) | edit_data; break;
			case 3: memory[addr] = (memory[addr] & 0xFFFFF000) | edit_data; break;
			case 2: memory[addr] = (memory[addr] & 0xFFFFFF00) | edit_data; break;
			case 1: memory[addr] = (memory[addr] & 0xFFFFFFF0) | edit_data; break;
		}
		mode = 0;
		edit_len = 0;
	}
}

void key_dep()
{
	save_edit();
	show();
}

void key_inc()
{
	save_edit();
	if (addr == 255)
		addr = 0;
	else
		addr = addr + 1;
	show();
}

void key_dec()
{
	save_edit();
	if (addr == 0)
		addr = 255;
	else
		addr = addr - 1;
	show();
}

void key_type(int k)
{
	if (!mode) {
		// Go into edit mode
		mode = 1;
		edit_data = k;
		edit_len = 1;
		show();
	} else {
		// Already editing
		if (edit_len != 8) {
			edit_data = (edit_data << 4) + k;
			edit_len++;
			show();
		}
	}
}

void key_addr()
{
	if (mode) {
		addr = edit_data;
		mode = 0;
		edit_len = 0;
		show();
	}
}

void key_bksp()
{
	if (mode) {
		if (--edit_len) {
			edit_data >>= 4;
			show();
		} else {
			mode = 0;
			show();
		}
	}
}

void get_pc()
{
	pc = (get_bits() & 0xFF);
	// Update insn to relays
	// update_bits();
	// send_bits(0, 0);
}

void jump(int addr)
{
	// Jump to new PC value
	bits[0] = addr; // New PC here
	bits[1] = 0;
	bits[2] = 0;
	bits[3] = 0xff;
	bits[4] = 0x18; // Jump
	bits[5] = 0x00; // Clock low
	send_bits(0, RELAY_CLK);
	delay();
	send_bits(RELAY_CLK, 0);
	delay();
	// Get new PC value
	get_pc();
	update_bits();
	send_bits(0, 0);
	show();
}

unsigned char unasm_line(unsigned char pc);

/*
unsigned int prev;
int prev_set = 0;
int halt = 0;
*/

void step()
{
	unsigned int data;
	unsigned char org_pc = pc;

	// Falling clock edge
	// bits[5] &= 0xBF;
	// send_bits(0, RELAY_CLK);
	// send_bits(0, 0);
	// delay();
	porta(LS595_SHIFT_CLK | LS595_XFER | RELAY_CLK);	// Clock high
	delay();
	// Rising clock edge
	// bits[5] |= 0x40;
	// First get and process write-back data..
	data = get_bits();

	if (trace) {
		unasm_line(pc);
		tab(43);
		if ((current_insn & 0x88000000) == 0x08000000) {
			/* if (prev_set) {
				if ((data >> 8) != (prev - 1)) {
					halt = 1;
					return;
				}
			}
			prev_set = 1;
			prev = (data >> 8); */
			// Write to B
			memory[current_insn & 0xFF] = ((memory[current_insn & 0xFF] & 0xFFFFFF00) | (data >> 8));
			jputs("B[");
			jputs(hex2(current_insn));
			jputs("] <- ");
			jputs(hex2(data >> 8));
		} else if ((current_insn & 0x88000000) == 0x80000000) {
			// Write to A
			memory[0xFF & (current_insn >> 8)] = ((memory[0xFF & (current_insn >> 8)] & 0xFFFFFF00 ) | (data >> 8));
			jputs("A[");
			jputs(hex2(current_insn >> 8));
			jputs("] <- ");
			jputs(hex2(data >> 8));
		} else if ((current_insn & 0xB8000000) == 0xA8000000) {
			// Wait for input to change
			unsigned int data1, data2;
			int c;
			if (hold_console) {
#ifdef JDEBUG
				cu_termios();
#else
//J1				jputc('Q' - '@');
#endif
			}
			do {
				delay();
				data1 = get_bits();
				if (data1 != data) {
					// De-bounce
					delay();
					data2 = get_bits();
					if (data2 != data1)
						data1 = data;
				}
				// Check for keypress...
				if (uart2_ne() && ((c = uart2_getc()) & 0x80) != 0x80) {
					data1 = (c << 8);
					break;
				}
				if (uart1_ne()) {
					data1 = (uart1_getc() << 8);
					break;
				}
			} while (data1 == data);
			if (hold_console) {
#ifdef JDEBUG
				restore_termios();
#else
//J1				jputc('S' - '@');
#endif
			}
			data = data1;
			// Write to B
			memory[current_insn & 0xFF] = ((memory[current_insn & 0xFF] & 0xFFFFFF00) | (data >> 8));
			jputs("B[");
			jputs(hex2(current_insn));
			jputs("] <- ");
			jputs(hex2(data >> 8));
		} else if ((current_insn & 0x98000000) == 0x98000000) {
			uart1_putc(data >> 8);
		} else if ((current_insn & 0x88000000) == 0x88000000) {
			jputs("halt");
		}
	} else {
		if ((current_insn & 0x88000000) == 0x08000000) {
			/* if (prev_set) {
				if ((data >> 8) != (prev - 1)) {
					halt = 1;
					return;
				}
			}
			prev_set = 1;
			prev = (data >> 8); */
			// Write to B
			memory[current_insn & 0xFF] = ((memory[current_insn & 0xFF] & 0xFFFFFF00) | (data >> 8));
		} else if ((current_insn & 0x88000000) == 0x80000000) {
			// Write to A
			memory[0xFF & (current_insn >> 8)] = ((memory[0xFF & (current_insn >> 8)] & 0xFFFFFF00 ) | (data >> 8));
		} else if ((current_insn & 0xB8000000) == 0xA8000000) {
			// Wait for input to change
			unsigned int data1, data2;
			int c;
			if (hold_console) {
#ifdef JDEBUG
				cu_termios();
#else
//J1				jputc('Q' - '@');
#endif
			}
			do {
				delay();
				data1 = get_bits();
				if (data1 != data) {
					// De-bounce
					delay();
					data2 = get_bits();
					if (data1 != data2)
						data1 = data;
				}
				// Check for keypress...
				if (uart2_ne() && ((c = uart2_getc()) & 0x80) != 0x80) {
					data1 = (c << 8);
					break;
				}
				if (uart1_ne()) {
					data1 = (uart1_getc() << 8);
					break;
				}
			} while (data1 == data);
			if (hold_console) {
#ifdef JDEBUG
				restore_termios();
#else
//J1				jputc('S' - '@');
#endif
			}
			data = data1;
			// Write to B
			memory[current_insn & 0xFF] = ((memory[current_insn & 0xFF] & 0xFFFFFF00) | (data >> 8));
		} else if ((current_insn & 0xB8000000) == 0x98000000) {
			// Output to serial console
			uart1_putc(data >> 8);
		}
	}

//	send_bits(RELAY_CLK, RELAY_CLK);
//	delay();
	porta(LS595_SHIFT_CLK | LS595_XFER);	// Clock low
	delay();
//	send_bits(RELAY_CLK, 0);
//	delay();

	// Get new PC value
	get_pc();
	if (trace) {
		if ((org_pc + 1) != pc) {
			tab(56);
			jputs("PC <- ");
			jputs(hex2(pc));
		}
		crlf();
	}
	show(); // Calls send_bits with new data...
}

void key_step()
{

	if (mode) {
		mode = 0;
		edit_len = 0;

		jump(edit_data);
	} else {
		step();

	}
}

void key_run()
{
	// halt = 0;
	// prev_set = 0;	
	for (;;) {
		key_step();
		// for debug noise issues: clock, but no data change
		// clock_pulse();
		// Check for halt instruction...
		if ((current_insn & 0xB8000000) == 0x88000000) {
			// Halt requested...
			
			break;
		}
		// if (halt)
		//	break;
		// Check for keypress...
		if (uart2_ne() && (uart2_getc() & 0x80) != 0x80)
			break;
	}
}

void show_prog(int n)
{
	uart2_putc('@');
	uart2_putc(' '); uart2_putc('.');
	uart2_putc(' '); if (n >= 1) uart2_putc('.');
	uart2_putc(' '); if (n >= 2) uart2_putc('.');
	uart2_putc(' '); if (n >= 3) uart2_putc('.');
	uart2_putc(' '); if (n >= 4) uart2_putc('.');
	uart2_putc(' '); if (n >= 5) uart2_putc('.');
	uart2_putc(' '); if (n >= 6) uart2_putc('.');
	uart2_putc(' '); if (n >= 7) uart2_putc('.');
	uart2_putc(' ');
	uart2_putc(' ');
}

/* Save memory to EEPROM */

void save()
{
	int c;
	/* Save */
	for (c = 0; c != 128; ++c) {
		unsigned int data;
		if ((c & 7) == 0) {
			show_prog(c >> 3);
		}
		data = memory[c];
		eeprom_write((c << 1), data);
		data = (memory[c] >> 16);
		eeprom_write((c << 1) + 1, data);
	}
	show();
}

void save_cmd(char *p)
{
	jputs("Saving...");
	save();
	jputs("done\n");
}

/* Load memory from EEPROM */

void load()
{
	int c;
	/* Restore */
	for (c = 0; c != 128; ++c) {
		if ((c & 7) == 0) {
			show_prog(c >> 3);
		}
		memory[c] = (long)eeprom_read(c << 1) + ((long)eeprom_read((c << 1) + 1) << 16);
	}
	show();
}

void load_cmd(char *p)
{
	jputs("Loading...");
	load();
	jputs("done\n");
}

void key_freq()
{
	if (mode) {
		speed = (0xF & edit_data);
		edit_len = 0;
		mode = 0;
		show();
	} else {
		int c;
		// Show current speed
		uart2_putc('@');
		uart2_putc('f');
		uart2_putc('-');
		uart2_putc(' ');
		uart2_putc(to_hex_digit(speed));
		for (c = 4; c != 10; ++c)
			uart2_putc(' ');
		// Wait for key-press...
		while (((c = uart2_getc()) & 0x80) == 0x80);
		if (c >= 0 && c <= 15) {
			speed = c;
			show();
		} else if (c == 0x13) {
			save();
		} else if (c == 0x12) {
			load();
		} else {
		}	show();
	}
}

/* Step command */

void step_cmd(char *p)
{
	key_step();
}

/* Jump command */

void jump_cmd(char *p)
{
	unsigned long val;
	if (parse_hex(&p, &val)) {
		jump(val);
	} else {
		huh();
	}
}

/* Continue command */

void cont_cmd(char *p)
{
	unsigned long val;
	if (parse_hex(&p, &val)) {
		jump(val);
	}
	key_run();
}

/* Dump command */

void dump_cmd(char *p)
{
	int addr;
	for (addr = 0; addr != 256; addr += 8) {
		int x;
		jputs(hex2(addr)); jputs(":");
		for (x = 0; x != 8; ++x) {
			jputs(" ");
			jputs(hex8(memory[addr+x]));
		}
		crlf();
	}
}

/* Show registers */

void regs_cmd(char *p)
{
	jputs("From relays:\n");
	jputs("  PC = "); jputs(hex2(pc)); crlf();
	jputs("  Write data = "); jputs(hex2(get_bits() >> 8)); crlf();
	jputs("To relays:\n");
	jputs("  Current insn = "); jputs(hex8(current_insn)); crlf();
	jputs("  A data = "); jputs(hex2(current_a)); crlf();
	jputs("  B data = "); jputs(hex2(current_b)); crlf();
	jputs("Current speed = "); jputc(to_hex_digit(speed)); crlf();
}

/* Trace enable / disable */

void t_cmd(char *p)
{       
        if (match_word(&p, "on"))
                trace = 1;
        else if (match_word(&p, "off"))
                trace = 0;
        else
                huh();
}

void b_cmd(char *p)
{
}

/* Clear memory */

struct init {
	unsigned long insn;
} init_program[]=
{
/*
	{ 0x48e00101 },
	{ 0x00620123 },
	{ 0x4018ff10 }
*/
	{ 0x48009000 },
	{ 0x4800e901 },
	{ 0x0062011a },
	{ 0x08000002 },
	{ 0x08e00102 },
	{ 0x00660218 },
	{ 0x08e00100 },
	{ 0x4018ff12 },
	{ 0x08e00001 },
	{ 0x4018ff12 },

};

void clear_mem()
{
	int x;
	// Fill memory with halt instruction
	for (x = 0; x != 256; ++x) {
		memory[x] = 0xc810ff00;
	}
	// Initial program
	for (x = 0; x != sizeof(init_program) / sizeof(struct init); ++x) {
		memory[x + 0x10] = init_program[x].insn;
	}
}

void clear_cmd(char *p)
{
	clear_mem();
	show();
}

/* Set speed */

void speed_cmd(char *p)
{
	unsigned long val;
	if (parse_hex(&p, &val) && val >= 0 && val <= 15) {
		speed = val;
	} else
		huh();
}

/* Assembler */

void write_mem(int addr, unsigned long val)
{
	if (addr < 0 || addr > 255) {
		jputs("Invalid memory address\n");
	} else {
		memory[addr] = val;
		show();
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

unsigned char assemble(unsigned char addr, char *buf)
{
	char *org = buf;
	char str[8];
	unsigned long label_addr = addr;
	int label_sy = -1;
	unsigned long opcode;
	int type;
	unsigned long left;
	unsigned long right;
	int x;

	if (buf[0] == ';' || !buf[0] || buf[0] == '*') {
		return addr;
	}

	if (parse_word(&buf, str)) {
		/* Maybe it's an instruction... */
		for (x = 0; table[x].insn; ++x)
			if (!jstrcmp(table[x].insn, str)) {
				opcode = table[x].opcode;
				type = table[x].type;
				goto found_insn;
			}
		/* nope, so it must be a label */
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
		if (!jstrcmp(table[x].insn, str)) {
			opcode = table[x].opcode;
			type = table[x].type;
			break;
		}

	if (!table[x].insn) {
		jputs("Unknown instruction\n");
		return addr;
	}

	found_insn:

	skipws(&buf);

	if (type == NONE) {
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == RIGHT) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 1);
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		}
		if (rtn & 2) {
			jputs("Undefined symbol\n");
		}
		opcode |= (right & 255);
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == DUP) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 3);
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		}
		if (rtn & 2) {
			jputs("Undefined symbol\n");
		}
		opcode |= (right & 255) | ((right & 255) << 8);
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == BOTH) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &left, addr, 2);
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		}
		if (rtn & 2) {
			jputs("Undefined symbol\n");
		}
		skipws(&buf);
		if (*buf != ',') {
			jputs("Missing second operand\n");
			right = 0;
		} else {
			++buf;
			skipws(&buf);
			rtn = expr(&buf, &right, addr, 1);
			if (rtn & 1) {
				jputs("Bad or missing operand\n");
			}
			if (rtn & 2) {
				jputs("Undefined symbol\n");
			}
		}
		opcode |= (right & 255) | ((left & 255) << 8);
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == IBOTH) {
		int rtn;
		skipws(&buf);
		if (*buf == '#') {
			++buf;
			opcode |= 0x40000000;
		}
		rtn = expr(&buf, &left, addr, 2);
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		}
		if (rtn & 2) {
			jputs("Undefined symbol\n");
		}
		skipws(&buf);
		if (*buf != ',') {
			jputs("Missing second operand\n");
			right = 0;
		} else {
			++buf;
			skipws(&buf);
			rtn = expr(&buf, &right, addr, 1);
			if (rtn & 1) {
				jputs("Bad or missing operand\n");
			}
			if (rtn & 2) {
				jputs("Undefined symbol\n");
			}
		}
		opcode |= (right & 255) | ((left & 255) << 8);
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == ILEFT) {
		int rtn;
		skipws(&buf);
		if (*buf == '#') {
			++buf;
			opcode |= 0x40000000;
		}
		rtn = expr(&buf, &left, addr, 2);
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		}
		if (rtn & 2) {
			jputs("Undefined symbol\n");
		}
		opcode |= ((left & 255) << 8);
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == EQU) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 0);
		if (rtn & 1) {
			jputs("Bad or missing expression\n");
		} else if (rtn & 2) {
			jputs("Undefined symbol\n");
		} else {
			label_addr = right;
		}
		goto done;
	} else if (type == ORG) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 0);
		if (rtn & 1) {
			jputs("Bad or missing expression\n");
		} else if (rtn & 2) {
			jputs("Undefined symbol\n");
		} else {
			addr = right;
			label_addr = right;
		}
		goto done;
	} else if (type == SKIP) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 0);
		if (rtn & 1) {
			jputs("Bad or missing expression\n");
		} else if (rtn & 2) {
			jputs("Undefined symbol\n");
		} else {
			addr += right;
		}
		goto done;
	} else if (type == INSN) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 1); // fixme.. we only fix bytes but we write word..
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		} else if (rtn & 4) {
			jputs("Undefined symobl\n");
		}
		opcode = right;
		write_mem(addr, opcode);
		++addr;
		goto done;
	} else if (type == DATA) {
		int rtn;
		skipws(&buf);
		rtn = expr(&buf, &right, addr, 1); // fixme.. we only fix bytes but we write word..
		if (rtn & 1) {
			jputs("Bad or missing operand\n");
		} else if (rtn & 4) {
			jputs("Undefined symobl\n");
		}
		opcode = (0xC810FF00 + (0xFF & right));
		write_mem(addr, opcode);
		++addr;
		goto done;
	}

	done:
	if (skipws(&buf) && *buf && *buf != ';' && *buf != '*') {
		jputs("Syntax error\n");
	} else {
		if (label_sy != -1)
			set_symbol(label_sy, label_addr);
	}
	return addr;
}

/* Clear cymbol table */

void clr_cmd(char *p)
{
        clr_symbols();
}

/* Show symbol table */

void sy_cmd(char *p)
{
        pr_symbols();
}

/* Assemble command */

void a_cmd(char *p)
{
        unsigned long addr;
        jputs("Hit Ctrl-C to exit assembler\n");
        if (parse_hex(&p, &addr)) {
                for (;;) {
			jputs(hex2(addr)); jputs(": ");
                        if (!jgetline(buf, sizeof(buf))) {
                                if (buf[0]) {
                                        addr = assemble(addr, buf);
                                } else {
                                        // break;
                                }
                        } else { 
				crlf();
                                break;
                        }
                }
        } else   
                huh();
}

/* Unassemble command */
 
unsigned char unasm_line(unsigned char pc)
{
        unsigned long opcode = memory[pc];
        int args = 0;
        char *insn = "???";
        unsigned char bb = opcode;
        unsigned char aa = (opcode >> 8);
        unsigned char cc = (0x0F & (opcode >> 16));
        int start;

        jputs(hex2(pc)); jputs("  "); jputs(hex_8(opcode)); jputs(" ");
        jputs("        "); // Label

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
        if (args)
        	tab(start + 8);

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

        return pc + 1;
}

void u_cmd(char *p)
{
        unsigned long addr = last_u;
        if (parse_hex(&p, &addr) || !*p) {
                int x;
                for (x = 0; x != 22; ++x) {
                        addr = unasm_line(addr);
                        crlf();
                }
                last_u = addr;
        } else
                huh();
}

void eval_cmd(char *p)
{
	unsigned long val;
	if (!expr(&p, &val, 0, 0)) {
		jputs(phex(1, val));
		crlf();
	} else {
		jputs("Bad expression\n");
	}
}

void x_cmd(char *p)
{
	int x;
	for (;;) {
		if (uart2_ne()) {
			x = uart2_getc();
			if (!(x & 0x80)) {
				if (x == 8) {
					jputc('Q' - '@');
				} else if (x == 9) {
					jputc('S' - '@');
				} else if (x < 0x10)
					uart1_putc('@' + x);
				else {
					jputs("Done.\n");
					break;
				}
			}
		}
		if (uart1_ne()) {
			jputc(uart1_getc());
		}
	}
}

void k_cmd(char *p)
{
	int count = 0;
	for (;;) {
		int data;
		if (uart2_ne())
			break;
		if (++count == 10) {
			int data = knob;
			count = 0;
			uart2_putc('@');
			uart2_putc(' ');
			uart2_putc(' ');
			uart2_putc(' ');
			uart2_putc(' ');
			uart2_putc(to_hex_digit(0xF & (data >> 12)));
			uart2_putc(to_hex_digit(0xF & (data >> 8)));
			uart2_putc(to_hex_digit(0xF & (data >> 4)));
			uart2_putc(to_hex_digit(0xF & (data >> 0)));
			uart2_putc(' ');
			uart2_putc(' ');
		}
	}
}

/* Command table */

void help_cmd(char *);

const struct cmd {
	char *name;
	void (*func)(char *);
	char *help;
} cmds[]=
{
	{ "help", help_cmd,	"		Show this help text" },
	{ "h", help_cmd,	"		Show this help text" },
	{ "s", step_cmd,	"		Step one instruction" },
	{ "g", cont_cmd,	" [hh]		Go (at current or address hh)" },
	{ "j", jump_cmd,	" hh		Jump to address hh" },
	{ "d", dump_cmd,	"		Hex dump" },
	{ "r", regs_cmd,	"		Show registers" },
	{ "speed", speed_cmd,	" h		Set speed 0 - F" },
	{ "clear", clear_cmd,	"		Clear memory" },
	{ "save", save_cmd,	"		Save memory to EEPROM" },
	{ "load", load_cmd,	"		Load memory from EEPROM" },
        { "t", t_cmd,           " [on|off]	Turn tracing on / off" },
        { "b", b_cmd,           " [hhhh]	Set/Clear breakpoint" }, 
        { "a", a_cmd,           " hhhh		Assemble" },
        { "clr", clr_cmd,       "		Clear symbol table" },
        { "sy", sy_cmd,         "		Show symbol table" }, 
        { "u", u_cmd,           " hhhh		Unassemble" },
        { "v", eval_cmd,	" expr		Evaluate expression" },
        { "x", x_cmd,            "		Check xon/xoff" },
        { "k", k_cmd,            "		Check knob" },
	{ 0, 0, 0 }
};

/* Help command */

void help_cmd(char *p)
{
	int x;
	for (x = 0; cmds[x].name; ++x) {
		jputs(cmds[x].name);
		jputs(cmds[x].help);
		crlf();
	}
	jputs("aa: hh hh ...	Load memory with hex data\n");
}

void do_command(char *buf)
{
	char *p = buf;
	unsigned long addr;
	unsigned long val;

	if (skipws(&p) && *p) {
		int x;
		// Check hex first so we can download at full speed
		if (parse_hex(&p, &addr) && skipws(&p) && *p == ':') {
			++p;
			for (;;) {
				skipws(&p);
				if (parse_hex(&p, &val)) {
					memory[addr & 0xFF] = val;
					++addr;
				} else {
					break;
				}
			}
			show();
		} else {
			p = buf;
			for (x = 0; cmds[x].name; ++x)
				if (match_word(&p, cmds[x].name))
					break;
			if (cmds[x].name) {
				skipws(&p);
				cmds[x].func(p);
			} else {
				huh();
			}
		}
	}

	buf_idx = 0; jputs("\n>");

}

int main()
{
	int x;

	col = 0;

	speed = 5;
	clear_mem();

	trace = 0;
	last_u = 0;

	setup_pic();
	adc_init();
	adc_start();
	timer_init();

	buf_idx = 0;

	mode = 0;
	addr = 0;
	edit_len = 0;

	pc = 0;
	update_bits();

//	uart_init(103); // 9615 baud with 16 MHz Fcy
//	uart_init(417); // 2398 baud with 16 MHz Fcy
	uart1_init(25); // 9615 baud with 4 MHz Fcy
//	uart2_init(207); // 1202 baud width 4 MHz Fcy
//	uart2_init(103); // 2404 baud width 4 MHz Fcy
	uart2_init(25); // 9615 baud with 4 MHz Fcy

	send_bits(0, 0);
	delay();
	get_pc();

//	RPINR18bits.U1RXR = 2;
//	RPOR1bits.RP3 = 3;

	jputs("\nRelay Computer firmware version 1\n\nREADY\n\n>");
	jputc('Q' - '@');

	show();

	for (;;) {
//		send_bits();
//		delay();
		if (uart1_ne()) {
			x = uart1_getc();
			if (x >= 0x20 && x <= 0x7E) {
				// Type
				if (buf_idx != sizeof(buf)-1) {
					jputc(x);
					buf[buf_idx++] = x;
				} else {
					// jputs(7);
				}
			} else if (x == 8 || x == 0x7F) {
				// Backspace
				if (buf_idx) {
					jputc(8);
					jputc(' ');
					jputc(8);
					--buf_idx;
				} else {
					// jputs(7);
				}
			} else if (x == 13) {
				hold_console = 1;
#ifdef JDEBUG
				restore_termios();
#else
//J1				jputc('S' - '@');
#endif
				crlf();
				// Carriage return
				buf[buf_idx] = 0;
				do_command(buf);
#ifdef JDEBUG
				cu_termios();
#else
//J1				jputc('Q' - '@');
#endif
				hold_console = 0;
			}

//			jputs("You typed: ");
//			jputs(hex(x));
//			crlf();
//			uart2_putc(x);
		}
		if (uart2_ne()) {
			x = uart2_getc();
//			jputs("Keypad: ");
//			jputs(hex(x));
//			crlf();
			if (x >= 0 && x <= 15)
				key_type(x);
			else switch(x) {
				case 0x10: key_dep(); break;
				case 0x11: key_addr(); break;
				case 0x12: key_dec(); break;
				case 0x13: key_inc(); break;
				case 0x14: key_step(); break;
				case 0x15: key_run(); break;
				case 0x16: key_freq(); break;
				case 0x17: key_bksp(); break;
			}
		}
	}
}
