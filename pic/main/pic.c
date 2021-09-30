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

// PIC 24f facts:
//   int is 16 bits, char is 8 bits, short is 16 bits, long is 32 bits, long long is 64 bits
//   'void *' is 16 bits.  Unaligned accesses are not allowed.  It's little endian.

#ifndef JDEBUG

#include <p24FV32KA301.h>

#define __builtin_disi(cycles) asm ("DISI #" #cycles)

_FWDT(FWDTEN_OFF); // Disable watchdog timer
_FOSC(OSCIOFNC_OFF); // Disable oscillator output pin

#else

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/poll.h>
#include <termios.h>
#include <sys/fcntl.h>
#include <signal.h>
#include <errno.h>
#include <pwd.h>
#include <sys/ioctl.h>
#include <unistd.h>


#endif

#include "pic.h"

#ifdef JDEBUG

char have_c;
int have;


struct termios saved; // Original attributes of local system
int termios_good; // Set if 'saved' is valid.


/* Record current attributes */
void save_termios()
{
	if (!tcgetattr(fileno(stdin), &saved))
		termios_good = 1;
	else
		termios_good = 0;
}

/* Set local tty attributes for connected */
void cu_termios()
{
	struct termios attr;
	if (!tcgetattr(fileno(stdin), &attr)) {
		attr.c_oflag &= ~ONLCR;
		attr.c_iflag &= ~ICRNL;
		attr.c_iflag &= ~(IXON|IXOFF);
		attr.c_lflag &= ~ICANON;
		attr.c_lflag &= ~ECHO;
		attr.c_lflag &= ~ISIG;
		attr.c_iflag &= ~IGNBRK;
		attr.c_iflag |= BRKINT;
		tcsetattr(fileno(stdin), TCSADRAIN, &attr);
		// signal(SIGINT, got_break);
	}
}

/* Restore original local tty attributes */
void restore_termios()
{
	if (termios_good)
		tcsetattr(fileno(stdin), TCSADRAIN, &saved);
}
#endif

/* UART1 input FIFO
 * Purpose of this is to handle spill after sending Ctrl-S
 * to host.
 */

#define UART1_BUF_SIZE 80
#define UART1_ALMOST_FULL 40
#define UART1_ALMOST_EMPTY 10

volatile unsigned char uart1_buf[UART1_BUF_SIZE];
volatile int uart1_wr_ptr;
volatile int uart1_rd_ptr;
volatile int uart1_count;
volatile int uart1_paused;

/* Remember to turn off analog mode on the serial input pins: turning UART
 * on does not do this.  */

void uart1_init(int baud)
{
	uart1_wr_ptr = 0;
	uart1_rd_ptr = 0;
	uart1_count = 0;
	uart1_paused = 0;

#ifdef JDEBUG

	// fcntl(fileno(stdin), F_SETFL, O_NONBLOCK);
	save_termios();
	cu_termios();


#else
	/* Baud rate is:
		Fcy / (16*(UxBRG + 1))
		Fcy is Fosc / 2 (Doze mode and PLL disabled).

	   Or, when BRGH is high:
	   	Fcy / (4*(UxBRG + 1))
		Fcy is Fosc / 2 (Doze mode and PLL disabled). */
		
	U1BRG = baud;

	/* UxMODE bits:
		0	STSEL: 1 = 2 stop bits, 0 = 1 stop bit
		
		2:1	PDSEL: 3=9-bits/no parity, 2=8 bits/odd parity, 1=8 bits, even parity,
			0=8-bits/no parity

		3	BRGH: 1=4 clocks/bit, 0=8 clocks/bit
		4	RXINV: 1=idle state is 0, 0=idle state is 1
		5	ABAUD: 1=auto-baud enable
		6	LPBACK: 1=enable loop-back
		7	WAKE: 1=wakeup on start-bit
		9:8	UEN: 0=UxTX and UxRX pins enabled/UxCTS and UxRTS controlled by port latch
			     1=UxTX/UxRX and UxRTS pins enable/ UxCTS controlled by port latch
			     2=UxTX/UxRX/UxCTS/UxRTS enabled and used
			     3 UxTX/UxRX/UxBCLK enabled/ UxCTS controlled by port latch
		10	always set to 0
		11	RTSMD: 1=UxRTS in simplex mode, 0=flow control mode
		12	IREN: 1=IrDA encoder/decoder enabled
		13	USIDL: 1=stop in idle mode
		14	always set to 0
		15	UARTEN: 1=enable UART */
	U1MODE = 0x8000; /* U_ENABLE 0x8008 (for BRGH) */
	/* Do not enable Tx until after UARTEN has been set */

	/* UxSTA bits:
	        0	URRDA: 1 = rx buffer has data, 0 = rx buffer empty
	        1	OERR: 1 = rx buffer overflowed
	        2	FERR: 1 = framing error detected
	        3	PERR: 1 = parity error detected
	        4	RIDLE: 1 = rx idle, 0 = rx active
	        5	ADDEN: 1 = address detect mode is enabled
	        7-6	URXISEL: 0 = rx int if char avail, 10 = int on 3/4 full, 11 = int on full
	        8	TRMT: 1 = tx shift reg empty
	        9	UTXBF: 1 = tx buffer full
	        10	UTXEN: 1 = tx enabled
	        11	UTXBRK: 1 = sends sync char
	        14	UTXINV: IrDA encoder invert
	        15,13	UTXISEL: 10 = int on tx buf empty, 01 int when tx shift reg empty, 00
	                         = int when space available.
	*/
	U1STA = 0x0400; /* U_TX 0x8400 */

	IEC0bits.U1RXIE = 1; /* Enable Rx interrupts */

//	IFS0bits.U1RXIF = 0;
#endif
}

void uart2_init(int baud)
{
#ifdef JDEBUG
#else
	/* Baud rate is:
		Fcy / (16*(UxBRG + 1))
		Fcy is Fosc / 2 (Doze mode and PLL disabled).

	   Or, when BRGH is high:
	   	Fcy / (4*(UxBRG + 1))
		Fcy is Fosc / 2 (Doze mode and PLL disabled). */
		
	U2BRG = baud;

	/* UxMODE bits:
		0	STSEL: 1 = 2 stop bits, 0 = 1 stop bit
		
		2:1	PDSEL: 3=9-bits/no parity, 2=8 bits/odd parity, 1=8 bits, even parity,
			0=8-bits/no parity

		3	BRGH: 1=4 clocks/bit, 0=8 clocks/bit
		4	RXINV: 1=idle state is 0, 0=idle state is 1
		5	ABAUD: 1=auto-baud enable
		6	LPBACK: 1=enable loop-back
		7	WAKE: 1=wakeup on start-bit
		9:8	UEN: 0=UxTX and UxRX pins enabled/UxCTS and UxRTS controlled by port latch
			     1=UxTX/UxRX and UxRTS pins enable/ UxCTS controlled by port latch
			     2=UxTX/UxRX/UxCTS/UxRTS enabled and used
			     3 UxTX/UxRX/UxBCLK enabled/ UxCTS controlled by port latch
		10	always set to 0
		11	RTSMD: 1=UxRTS in simplex mode, 0=flow control mode
		12	IREN: 1=IrDA encoder/decoder enabled
		13	USIDL: 1=stop in idle mode
		14	always set to 0
		15	UARTEN: 1=enable UART */
	U2MODE = 0x8000; /* U_ENABLE 0x8008 (for BRGH) */
	/* Do not enable Tx until after UARTEN has been set */

	/* UxSTA bits:
	        0	URRDA: 1 = rx buffer has data, 0 = rx buffer empty
	        1	OERR: 1 = rx buffer overflowed
	        2	FERR: 1 = framing error detected
	        3	PERR: 1 = parity error detected
	        4	RIDLE: 1 = rx idle, 0 = rx active
	        5	ADDEN: 1 = address detect mode is enabled
	        7-6	URXISEL: 0 = rx int if char avail, 10 = int on 3/4 full, 11 = int on full
	        8	TRMT: 1 = tx shift reg empty
	        9	UTXBF: 1 = tx buffer full
	        10	UTXEN: 1 = tx enabled
	        11	UTXBRK: 1 = sends sync char
	        14	UTXINV: IrDA encoder invert
	        15,13	UTXISEL: 10 = int on tx buf empty, 01 int when tx shift reg empty, 00
	                         = int when space available.
	*/

	U2STA = 0x0400; /* U_TX 0x8400 */

//	IFS0bits.U1RXIF = 0;
#endif
}

void uart1_putc(char c)
{
#ifdef JDEBUG
	write(fileno(stdout), &c, 1);
#else
//	while (U1STAbits.UTXBF); /* This bit is broken in this chip */
	try_again:
	while (!U1STAbits.TRMT);
	__builtin_disi(0x3FFF);
	if (!U1STAbits.TRMT) {
		__builtin_disi(0x0000);
		goto try_again;
	}
	U1TXREG = c;
	__builtin_disi(0x0000);
#endif
}

void uart2_putc(char c)
{
#ifdef JDEBUG
#else
//	while (U2STAbits.UTXBF); /* This bit is broken in this chip */
	while (!U2STAbits.TRMT);
	U2TXREG = c;
#endif
}

int uart1_ne_raw()
{
//	while (IFS0bits.U1RXIF == 0);
	if (U1STAbits.URXDA)
		return 1;
	else {
		U1STA = 0x0400; // Clear overflow error bit in case it's set
		return 0;
	}
}

int uart1_ne()
{
#ifdef JDEBUG
	if (have)
		return 1;
	read(fileno(stdin), &have_c, 1);
	have = 1;
	if (have_c == 'Q') {
		restore_termios();
		printf("\r\n");
		exit(-1);
	}
	return 1;

#else
	__builtin_disi(0x3FFF);
	if (uart1_count) {
		__builtin_disi(0x0000);
		return 1;
	} else {
		__builtin_disi(0x0000);
		return 0;
	}
//	if (uart1_wr_ptr != uart1_rd_ptr)
//		return 1;
//	else
//		return 0;
#endif
}

int uart2_ne()
{
#ifdef JDEBUG
	return 0;
#else
//	while (IFS0bits.U2RXIF == 0);
	if (U2STAbits.URXDA)
		return 1;
	else {
		U2STA = 0x0400; // Clear overflow error bit in case it's set
		return 0;
	}
#endif
}

int uart1_getc_raw()
{
	unsigned char c;

	while (!uart1_ne()) {
		U1STA = 0x0400; // Clear overflow error bit in case it's set
	}
	c = U1RXREG;
	// IFS0bits.U1RXIF = 0;
	return c;
}

void __attribute__((__interrupt__)) _U1RXInterrupt(void)
{
	IFS0bits.U1RXIF = 0; // Acknowledge interrupt

	// Receive all available characters
	while (U1STAbits.URXDA) {
		if (uart1_count == UART1_BUF_SIZE - 1) {
			uart1_buf[uart1_wr_ptr] = U1RXREG;
			while (!U1STAbits.TRMT);
			U1TXREG = 'V'; // Indicates overflow
		} else {
			uart1_buf[uart1_wr_ptr++] = U1RXREG;
			if (uart1_wr_ptr == UART1_BUF_SIZE)
				uart1_wr_ptr = 0;
			++uart1_count;
			if (uart1_count == UART1_ALMOST_FULL) {
				while (!U1STAbits.TRMT);
				U1TXREG = 'S' - '@';
				// while (!U1STAbits.TRMT);
				// U1TXREG = 'S';
				uart1_paused = 1;
			}
		}
	}
	U1STA = 0x0400; // Clear overflow error bit in case it's set
}

int uart1_getc()
{
#ifdef JDEBUG
	while (!uart1_ne());
	have = 0;
	return have_c;
#else
	unsigned char c;
	while (!uart1_ne());
	c = uart1_buf[uart1_rd_ptr++];
	if (uart1_rd_ptr == UART1_BUF_SIZE)
		uart1_rd_ptr = 0;
	// Lock access to uart2_count
	__builtin_disi(0x3FFF);
	--uart1_count;
	if (uart1_count == UART1_ALMOST_EMPTY && uart1_paused) {
		// We are almost out of characters, but we're paused...
		__builtin_disi(0x0000);
		try_again:
		while (!U1STAbits.TRMT);
		// Lock access to TRMT and U1TXREG
		__builtin_disi(0x3FFF);
		if (!U1STAbits.TRMT) {
			__builtin_disi(0x0000);
			goto try_again;
		}
		// Send Ctrl-Q
		U1TXREG = 'Q' - '@';
		// while (!U1STAbits.TRMT);
		// U1TXREG = 'Q';
		uart1_paused = 0;
		__builtin_disi(0x0000);
	} else {
		__builtin_disi(0x0000);
	}
	return c;
#endif
}

int uart2_getc()
{
#ifdef JDEBUG
	return 0;
#else
	unsigned char c;

	while (!uart2_ne()) {
		U2STA = 0x0400; // Clear overflow error bit in case it's set
	}
	c = U2RXREG;
	// IFS0bits.U2RXIF = 0;
	return c;
#endif
}

/* Bulk erase EEPROM */

void eeprom_erase()
{
#ifndef JDEBUG
	NVMCON = 0x4050;
	asm volatile ("disi #5");
	__builtin_write_NVM();
#endif
}

/* Write to EEPROM: this erases each word before write,
 * so bulk erase not needed. */

void eeprom_write(unsigned int addr, unsigned int data)
{
#ifndef JDEBUG
	addr = 0xFE00 + (addr << 1);
	NVMCON = 0x4004;
	TBLPAG = 0x7F;
	__builtin_tblwtl(addr, data);
	asm volatile ("disi #5");
	__builtin_write_NVM();
	while (NVMCONbits.WR == 1);
#endif
}

/* Read from EEPROM */

unsigned int eeprom_read(unsigned int addr)
{
#ifdef JDEBUG
	return 0xFFFF;
#else
	addr = 0xFE00 + (addr << 1);
	TBLPAG = 0x7F;
	return __builtin_tblrdl(addr);
#endif
}

void uart1_puts(char *s)
{
	while (*s)
		uart1_putc(*s++);
}

void uart2_puts(char *s)
{
	while (*s)
		uart2_putc(*s++);
}

void setup_pic()
{
#ifndef JDEBUG
	CLKDIV = 0x3000; /* Set FRC postscaler to divide-by-1 */
			/* Otherwise we get 4 MHz Fosc / 2 MHz Fcy */
//	OSCCON = 0x0100; /* Enable PLL? */

	/* Set up ports */
	PORTA = 0xA;
	// PORTA = 0x0;

	TRISA = 0xFFF0;

	PORTB = 0x2000;
	TRISB = 0xCD7E;

	ANSB = 0xFeF9;
#endif
}

void porta(unsigned int val)
{
#ifdef JDEBUG
#else
	PORTA = val;
#endif
}

void portb(unsigned int val)
{
#ifdef JDEBUG
#else
	PORTB = val;
#endif
}

unsigned int rd_portb()
{
#ifdef JDEBUG
	return 0;
#else
	return PORTB;
#endif
}

void adc_init(void)
{
	AD1CON1 = 0x0070;
	AD1CHS = 0x0009;
	AD1CSSL = 0;
	AD1CON3 = 0x1F04;
	AD1CON2 = 0;
	AD1CON1bits.ADON = 1;
}

void adc_start(void)
{
	AD1CON1bits.SAMP = 1;
}

int adc_done(void)
{
	if (AD1CON1bits.DONE)
		return 1;
	else
		return 0;
}

int adc_read(void)
{
	return ADC1BUF0;
}

/* Run adc on timer */

void timer_init(void)
{
	T1CON = 0x00;
	TMR1 = 0x00;
	PR1 = 40000; // For ~100 Hz
	IFS0bits.T1IF = 0;
	IEC0bits.T1IE = 1;
	T1CONbits.TON = 1;
}

int knob_accu = 0;
int samp = 0;
volatile int knob;

#define KNOB_SAMP 4

void __attribute__((__interrupt__)) _T1Interrupt(void)
{
	IFS0bits.T1IF = 0;
	knob_accu += ADC1BUF0;
	if (++samp == KNOB_SAMP) {
		knob_accu -= knob_accu / KNOB_SAMP;
		--samp;
	}
	knob = knob_accu;
	AD1CON1bits.SAMP = 1;
}
