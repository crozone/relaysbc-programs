;   Keyboard / display microcontroller
;   Copyright (C) 2013  Joseph H. Allen

;   This program is free software; you can redistribute it and/or
;   modify it under the terms of the GNU General Public License
;   as published by the Free Software Foundation; either version 2
;   of the License, or (at your option) any later version.

;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU General Public License for more details.

;   You should have received a copy of the GNU General Public License
;   along with this program; if not, write to the Free Software
;   Foundation, Inc., 51 Franklin Street,
;   Fifth Floor, Boston, MA  02110-1301, USA.


	processor	pic16f720

; PIC16F720 has only a single page: 2048 words of code space.  The entire
; memory range is reachable with 11-bit argument to goto.

	include	p16f720.inc
	include	macros.inc

	__config	_CONFIG1, _FOSC_INTOSCIO & _WDTEN_OFF
; 8 MHz is the default Fosc

; 96 bytes in range 0x20 - 0x7F are free to use.
; 32 bytes in range 0xA0 - 0xBF are free to use.
;
; 0x70 - 0x7F is aliased in 0xF0 - 0xFF,
; 0x170 - 0x17F and 0x1F0 - 0x1FF.
;
; There is 8K words of instruction space: 0x00 - 0x1FFF
; Range for call and goto is 2K 0x0 - 0x7FF

	cblock	0x20
digit	:	1	; Current digit which is illuminated
vidram	:	0xA	; Video RAM (indexed by digit)
tmp	:	1
tmp1	:	1
tmp2	:	1
tmp3	:	1
tmp4	:	1
cursor	:	1	; Cursor


; In the following arrays:
; Key pressed is a 1
; Key released is a 0
; Least significant four bits in each byte are valid.  Upper four bits are
; unused.
bounce	:	6	; Most recently read key value
bounce1	:	6	; Second most recently read key value
keydown	:	6	; Current key state
bdelay  :       1       ; Debounce delay
	endc

; Pinout
;   RC0 - RC7 is seg0 - seg7 output.  Pull low to drive.

;   RA0 is input col0
;   RA1 is input col1
;   RA2 is input col2
;   RA3/MCLR has 10K pullup
;   RA4 is input col3
;   RA5 is input Serial Rx
;   RB4 is unconnected. [use this for master reset instead]
;   RB5 is output master reset on 74HC4017 [should be serial Rx]
;   RB6 is output clk to 74HC4017
;   RB7 is output Serial Tx

; 7-segment bits
;     0
;  +-----+
;  |5 6  |1
;  +-----+
;  |4 3  |2
;  +-----+  +7

; Row bits
;
; 4 top row
; 2
; 0
; 1 bottom row

; Column numbers
;
; 1 right column
; 5
; 2
; 0
; 3
; 4 left column

; All segments off
rstvec	org	0x0
	jmp	run

	org	0x4
; Interrupt!
; Save context
	movwf	saved_w	; Saved_w must be visible in all banks (0x70 - 0x7F)
	swapf	STATUS, W
	banksel	0		; The rest can be anywhere
	movwf	saved_status	; Note status has nibbles swapped in saved_status
	movf	PCLATH, W
	movwf	saved_pclath
	movf	FSR, W
	movwf	saved_fsr
; ISR goes here

irqloop
	jsr	irq_uart_ne
	jeq	irqdone
	jsr	irq_uart_rx
	jsr	keyevent2
	jmp	irqloop
irqdone

; Restore context
	movf	saved_fsr, W
	movwf	FSR
	movf	saved_pclath, W
	movwf	pclath
	swapf	saved_status, W ; Swap status nibbles back to correct order
	movwf	status
	swapf	saved_w, F ; Swap nibbles in saved_w
	swapf	saved_w, W ; Swap back to normal when transferring to W
; Return...
	retfie

; Begin here after reset...

run	ldi	PORTC, 0xff

	clr	TRISC
;	ldi	fsr, TRISC
;	clr	ind

; Column scan and serial Rx inputs
	ldi	TRISA, 0xff
;	ldi	fsr, TRISA
;	ldi	ind, 0xff

;	banksel	ANSELA
;	clr	ANSELA
;	banksel	0

	clr	ANSELA

; 74HC4017 control and Tx outputs
	clr	PORTB
	ldi	TRISB, 0x2f
;	ldi	fsr, TRISB
;	ldi	ind, 0x0f

;	banksel	ANSELB
;	clr	ANSELB
;	banksel	0

	clr	ANSELB

; init UART
	jsr	uart_init

; Clear bounce ram
	ldi	fsr, bounce
	ldi	tmp, 6
	jsr	memclr
	ldi	fsr, bounce1
	ldi	tmp, 6
	jsr	memclr
	ldi	fsr, keydown
	ldi	tmp, 6
	jsr	memclr
	clr	bdelay

; Clear cursor
	clr	cursor

; Serial port interrupts
	bis	PIE1, RCIE
	bis	INTCON, PEIE
	bis	INTCON, GIE

; Clear video ram
	ldi	vidram, 0x10
	ldi	(vidram+1), 0x10
	ldi	(vidram+2), 0x10
	ldi	(vidram+3), 0x10
	ldi	(vidram+4), 0x10
	ldi	(vidram+5), 0x10
	ldi	(vidram+6), 0x10
	ldi	(vidram+7), 0x10
	ldi	(vidram+8), 0x10
	ldi	(vidram+9), 0x10

; Reset 74HC4017

	ldi	PORTB, 0x10
	jsr	short
	ldi	PORTB, 0x00
	nop
	clr	digit
	jmp	entry	; Jump right into delay so that keyboard scan is working

; Main loop

mainloop
	cmpi	bdelay, 0
	jne	noscan

; Keyboard scan...
	cmpi	digit, 6
	jhs	noscan

; Read keypad
	ld	tmp, PORTA
; Twiddle bits
	ld	tmp1, tmp
	andi	tmp, 0x7
	andi	tmp1, 0x10
	lsr	tmp1
	or	tmp, tmp1

; Show it on screen
;	ldi	fsr, vidram
;	add	fsr, digit
;	addi	fsr, 2
;	ld	ind, tmp

; Save result in debounce array
	ldi	fsr, bounce
	add	fsr, digit
	ld	ind, tmp

; One whole scan complete?
	cmpi	digit, 5
	jne	noscan

; Loop over bounce arrays
	clr	tmp2

; If a bit in bounce and bounce1 are the same, but different from
; keydown, then we have a debounced keypress or keyrelease.
bloop	
	ldi	fsr, bounce1
	add	fsr, tmp2
	ld	tmp, ind
;	ld	tmp, bounce1

	ldi	fsr, bounce
	add	fsr, tmp2
	xor	tmp, ind
;	xor	tmp, bounce

	com	tmp
; We now have bits which are the same in tmp: this is our mask

	ld	tmp1, ind
;	ld	tmp1, bounce

	ldi	fsr, keydown
	add	fsr, tmp2
	xor	tmp1, ind
;	xor	tmp1, keydown

	and	tmp1, tmp
; We now have the bits which have changed in tmp1

; Clear bits which have changed from keydown
	com	tmp1

	and	ind, tmp1
;	and	keydown, tmp1
	com	tmp1
; Get bits which have changed
	ldi	fsr, bounce
	add	fsr, tmp2
	ld	tmp, ind
;	ld	tmp, bounce
	and	tmp, tmp1
; Stick them into keydown
	ldi	fsr, keydown
	add	fsr, tmp2
	or	ind, tmp
;	or	keydown, tmp

; So now we have bits which have changed in tmp1
; And the new value of them in tmp
; Send keycodes here...
	ld	tmp3, tmp2
	lsl	tmp3
	lsl	tmp3
	lsl	tmp3

	jbc	tmp1, 0, trybit1
; Bit zero set
	ldb	tmp3, 0, tmp, 0
	jsr	keyevent

trybit1	addi	tmp3, 2
	lsr	tmp1
	lsr	tmp
	jbc	tmp1, 0, trybit2
; Bit one set
	ldb	tmp3, 0, tmp, 0
	jsr	keyevent

trybit2	addi	tmp3, 2
	lsr	tmp1
	lsr	tmp
	jbc	tmp1, 0, trybit3
; Bit two set
	ldb	tmp3, 0, tmp, 0
	jsr	keyevent

trybit3	addi	tmp3, 2
	lsr	tmp1
	lsr	tmp
	jbc	tmp1, 0, nomore
	ldb	tmp3, 0, tmp, 0
	jsr	keyevent

nomore

	inc	tmp2
	cmpi	tmp2, 6
	jne	bloop

; Transfer bounce to bounce1 for next round
	ld	bounce1+0, bounce+0
	ld	bounce1+1, bounce+1
	ld	bounce1+2, bounce+2
	ld	bounce1+3, bounce+3
	ld	bounce1+4, bounce+4
	ld	bounce1+5, bounce+5

noscan

; Segments off
	ldi	PORTC, 0xff

; Clock 74HC4017
	nop
	ldi	PORTB, 0x40
	jsr	short
	ldi	PORTB, 0x00
	nop

	inc	digit
	cmpi	digit, 0xA
	jne	skip
	clr	digit
	inc	bdelay
	cmpi	bdelay, 0x3
	jne	skip
	clr	bdelay
skip

; access video ram
	ldi	fsr, vidram
	add	fsr, digit
	ld	tmp, ind

; Lookup character, turn segments on
	lookup	font, PORTC, tmp

; Delay
entry	jsr	dly

; read characters normal level...
;	jsr	uart_ne
;	jeq	mainloop
;	jsr	uart_rx
;	ld	tmp3, rtn
;	jsr	keyevent1

	jmp	mainloop

; Send key event to serial port
keyevent
	lookup	keytab, tmp3, tmp3
	ld	arg1, tmp3
	jsr	uart_tx
	rts

keyevent1
; Display keyevent on LED display

	ld	vidram+9, vidram+7
	ld	vidram+8, vidram+6
	ld	vidram+7, vidram+5
	ld	vidram+6, vidram+4
	ld	vidram+5, vidram+3
	ld	vidram+4, vidram+2
	ld	vidram+3, vidram+1
	ld	vidram+2, vidram+0
	
	ld	vidram+0, tmp3
	andi	vidram+0, 0xF
	swap	tmp3
	ld	vidram+1, tmp3
	andi	vidram+1, 0xF
	rts

keyevent2
; Same as above, but for interrupt handler

	cmpi	irq_rtn, 0x0d
	jne	key_1

	clr	cursor
	rts

key_1	cmpi	irq_rtn, 0x08
	jne	key_2

	dec	cursor
	cmpi	cursor, 0xff
	jne	key_1_skip
	ldi	cursor, 0x9
key_1_skip
	rts

key_2	cmpi	irq_rtn, 0x20
	jne	key_3
	ldi	irq_rtn, 0x10
	jmp	key_type


key_3	cmpi	irq_rtn, 0x30
	jlo	key_4

	cmpi	irq_rtn, 0x39
	jhi	key_4

	subi	irq_rtn, 0x30
	jmp	key_type

key_4	cmpi	irq_rtn, 0x61
	jlo	key_5

	cmpi	irq_rtn, 0x66
	jhi	key_5
	addi	irq_rtn, 0x0A - 0x61
	jmp	key_type

key_5	cmpi	irq_rtn, 0x40
	jlo	key_6
	cmpi	irq_rtn, 0x49
	jhi	key_6
	subi	irq_rtn, 0x40
	ld	cursor, irq_rtn
	rts

key_6	cmpi	irq_rtn, 0x2d
	jne	key_7
	ldi	irq_rtn, 0x11

key_type
	ldi	fsr, vidram + 9
	sub	fsr, cursor
	ld	ind, irq_rtn

bumpup
	inc	cursor
	cmpi	cursor, 0xA
	jlo	cursor_ok
	clr	cursor
cursor_ok
	rts

key_7	cmpi	irq_rtn, 0x2e
	jne	key_8
	dec	cursor
	cmpi	cursor, 0xff
	jne	cursor_over
	ldi	cursor, 0x9
cursor_over

	ldi	fsr, vidram+9
	sub	fsr, cursor
	xori	ind, 0x20

	jmp	bumpup

key_8	cmpi	irq_rtn, 0x7f
	jne	cursor_ok
	dec	cursor
	cmpi	cursor, 0xff
	jne	cursor_over1
	ldi	cursor, 0x9
cursor_over1

	ldi	fsr, vidram+9
	sub	fsr, cursor
	ldi	ind, 0x10
	rts

try_pos
	cmpi	irq_rtn, 0x2A
	jhs	cursor_ok
	ld	cursor, irq_rtn
	subi	cursor, 0x20
	rts

;	ld	vidram+9, vidram+8
;	ld	vidram+8, vidram+7
;	ld	vidram+7, vidram+6
;	ld	vidram+6, vidram+5
;	ld	vidram+5, vidram+4
;	ld	vidram+4, vidram+3
;	ld	vidram+3, vidram+2
;	ld	vidram+2, vidram+1
;	ld	vidram+1, vidram+0
;	ld	vidram+0, irq_rtn
;	andi	vidram+0, 0x1F
;	rts

; Clear memory
memclr
	clr	ind
	inc	ind
	decjne	tmp, memclr
	rts

; Delay subroutine

dly
	ldi	r2,0x01
outer
	ldi	r1,0x00
inner
	nop
	nop
	decjne	r1, inner
	decjne	r2, outer
	rts

short
	nop
	nop
	nop
	rts

	include	"uart.inc"

; The font
	org	0x700
font	table
	val	0xC0	; 0
	val	0xF9	; 1
	val	0xA4	; 2
	val	0xB0	; 3
	val	0x99	; 4
	val	0x92	; 5
	val	0x82	; 6
	val	0xF8	; 7
	val	0x80	; 8
	val	0x98	; 9
	val	0x88	; A
	val	0x83	; B
	val	0xC6	; C
	val	0xA1	; D
	val	0x86	; E
	val	0x8E	; F

	val	0xFF	; space
	val	0xBF	; -
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF
	val	0xFF

	val	0x40	; 0
	val	0x79	; 1
	val	0x24	; 2
	val	0x30	; 3
	val	0x19	; 4
	val	0x12	; 5
	val	0x02	; 6
	val	0x78	; 7
	val	0x00	; 8
	val	0x18	; 9
	val	0x08	; A
	val	0x03	; B
	val	0x46	; C
	val	0x21	; D
	val	0x06	; E
	val	0x0E	; F

	val	0x7F	; space
	val	0x3F	; -
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F
	val	0x7F

keytab	table
	val	0x83
	val	0x03
	val	0x8E
	val	0x0E
	val	0x86
	val	0x06
	val	0x89
	val	0x09
	val	0x95
	val	0x15
	val	0x94
	val	0x14
	val	0x96
	val	0x16
	val	0x97
	val	0x17
	val	0x8c
	val	0x0c
	val	0x8d
	val	0x0d
	val	0x8b
	val	0x0b
	val	0x8a
	val	0x0a
	val	0x82
	val	0x02
	val	0x8f
	val	0x0f
	val	0x85
	val	0x05
	val	0x88
	val	0x08
	val	0x81
	val	0x01
	val	0x80
	val	0x00
	val	0x84
	val	0x04
	val	0x87
	val	0x07
	val	0x91
	val	0x11
	val	0x90
	val	0x10
	val	0x92
	val	0x12
	val	0x93
	val	0x13

	end
