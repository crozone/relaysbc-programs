/* PIC specific information
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

void uart1_init(int baud);
void uart1_putc(char c);
void uart1_puts(char *s);
int uart1_ne(); /* True if UART Rx FIFO not empty */
int uart1_getc();

void uart2_init(int baud);
void uart2_putc(char c);
void uart2_puts(char *s);
int uart2_ne(); /* True if UART Rx FIFO not empty */
int uart2_getc();

void eeprom_erase();
void eeprom_write(unsigned int addr, unsigned int data);
unsigned int eeprom_read(unsigned int addr);

void porta(unsigned int val);
void portb(unsigned int val);
unsigned int rd_portb();

void setup_pic();
void cu_termios();
void restore_termios();

#define LS595_DOUT 0x0001
#define LS595_SHIFT_CLK 0x0002
#define RELAY_CLK 0x0004
#define LS595_XFER 0x0008

#define LS597_SHIFT_CLK 0x0200
// #define LS597_LOAD_CLK 0x0400
#define LS597_LOAD_CLK 0x1000
// #define LS597_XFER_L 0x0800
#define LS597_XFER_L 0x2000
#define LS597_DIN 0x0100

void adc_init(void);
void adc_start(void);
int adc_done(void);
int adc_read(void);

void timer_init(void);

extern volatile int knob;
