;   Joe's PIC macros: hide the W register and make PIC look like a
;   two-address machine with mnemonics somewhat like 6800/6502
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

		nolist

; Registers

ind		equ	0	; [index]
rtcc		equ	1	; timer
pcl		equ	2	; Low half of PC
status		equ	3	; flags
fsr		equ	4	; index register
ra		equ	5	; I/O
rb		equ	6	; I/O
rc		equ	7	; I/O
pclath		equ	0xA	; Upper half of PC

; Flag bits
;   7   6   5   4   3 2  1 0
; IRP RP1 RP0 ~TO ~PD Z DC C

c_flag		equ	0
dc_flag		equ	1
z_flag		equ	2
pd_flag		equ	3
to_flag		equ	4
pa0_flag	equ	5
pa1_flag	equ	6
pa2_flag	equ	7

; GP registers

r0		equ	0x70
r1		equ	0x71
r2		equ	0x72
r3		equ	0x73
r4		equ	0x74
r5		equ	0x75

;r6		equ	0x76
;r7		equ	0x77

irq_arg1	equ	0x76
irq_rtn		equ	0x77

; For subroutine calls

;r8		equ	0x78
;r9		equ	0x79
;r10		equ	0x7a
;r11		equ	0x7b

arg3		equ	0x78
arg2		equ	0x79
arg1		equ	0x7a
rtn		equ	0x7b

; Reserved for interrupt context saving

;r12		equ	0x7c
;r13		equ	0x7d
;r14		equ	0x7e
;r15		equ	0x7f

saved_fsr	equ	0x7c
saved_pclath	equ	0x7d
saved_status	equ	0x7e
saved_w		equ	0x7f

; Use directly:
;  nop
;  sleep
;  clrwdt

; PIC facts to remember:
;
;  Borrow is inverted (0 - 1 give a clear carry).
;
;  Two page sizes to worry about: 256 bytes for adding to PC for table
;  lookup.  2K bytes for jmp (goto).  Can use farjmp for jumps out of current
;  page.
;
;  mpasm has pagesel to help deal with this.  I provide farjmp and farjsr.
;
;  Code assumes pclath is correct, so if you set it for a farjsr and then
;  return, it needs to be restored to its original value.  farjsr does this for you. 
;  Rts (return) does not- it just restores the PC, not pclath.

;
;  With mpasm, correct sequence is:
;     pagesel dest
;     call dest
;     pagesel here
;  here
;
;     pagesel is stupid: it always sets the page bits (as long as code is larger than 2K).  It does
;  not know to not set them if the target is in the same page.
;
;  Interrupt handlers must save context in registers 0x70 - 0x7F.. problem is there is no way to
;  know which is the current register bank, so only these registers (which are aliased in each bank)
;  can be used for this.
;
;  PIC16F720 has only a single page, so no need to worry about farjsr..
;
;  You can not reach all registers with fsr / ind (there are more than 256 of them).
;  You must use bank switching, for example:
;
;    banksel ANSELA
;    clr ANSELA
;    banksel PORTA
;
; If you do a bit operation on a PORT, the other bits could be affected
; since it's a RMW operation (for example if input give different value
; than output, you will end up changing the output).
;
; Don't forget to write to ANSEL bits.. pins selected for analog input
; (which is the default) always read 0.

; Add bit to dest
; OK farok
addb	macro	dest, src, bit
		local	?done1, ?done2
		if ((src) & ~0x7F) != 0
			if ((dest) & ~0x7F) == ((src) & ~0x7F)
				banksel	src
				btfsc	src, bit
				incf	dest, 1
				banksel	0
			else
				banksel	src
				btfss	src, bit
				goto	?done2
				banksel	dest
				incf	dest, 1
?done2
				banksel	0
			endif
		else
			if ((dest) & ~0x7F) != 0
				btfss	src, bit
				goto	?done1
				banksel	dest
				incf	dest, 1
				banksel	0
?done1
			else
				btfsc	src, bit
				incf	dest, 1
			endif
		endif
	endm

; Subtract bit from dest
; OK farok
subb	macro	dest, src, bit
		local	?done1, ?done2
		if ((src) & ~0x7F) != 0
			if ((dest) & ~0x7F) == ((src) & ~0x7F)
				banksel	src
				btfsc	src, bit
				decf	dest, 1
				banksel	0
			else
				banksel	src
				btfss	src, bit
				goto	?done2
				banksel	dest
				decf	dest, 1
?done2
				banksel	0
			endif
		else
			if ((dest) & ~0x7F) != 0
				btfss	src, bit
				goto	?done1
				banksel	dest
				decf	dest, 1
				banksel	0
?done1
			else
				btfsc	src, bit
				decf	dest, 1
			endif
		endif
		endm

; Subtract inverse of bit from dest
; OK farok
subnb	macro	dest, src, bit
		local	?done1, ?done2
		if ((src) & ~0x7F) != 0
			if ((dest) & ~0x7F) == ((src) & ~0x7F)
				banksel	src
				btfss	src, bit
				decf	dest, 1
				banksel	0
			else
				banksel	src
				btfsc	src, bit
				goto	?done2
				banksel	dest
				decf	dest, 1
?done2
				banksel	0
			endif
		else
			if ((dest) & ~0x7F) != 0
				btfsc	src, bit
				goto	?done1
				banksel	dest
				decf	dest, 1
				banksel	0
?done1
			else
				btfss	src, bit
				decf	dest, 1
			endif
		endif
		endm

;;; clear a bit
; OK farok
bic		macro	dest, bit

		if	(((dest) & ~0x7F) != 0)

; If dest is not in zero bank
		banksel	dest
		bcf	dest, bit
		banksel	0

		else

; Dest is in zero bank
		bcf	dest, bit

		endif

		endm

;;; set a bit
; OK farok
bis		macro	dest, bit

		if	(((dest) & ~0x7F) != 0)

; If dest is not in zero bank
		banksel	dest
		bsf	dest, bit
		banksel	0

		else

; Dest is in zero bank
		bsf	dest, bit

		endif

		endm

;;; Branch bit clear
; OK farok
jbc		macro	addr, bit, br
		local	?over

		if	(((addr) & ~0x7F) != 0)

; If addr is not in zero bank
		banksel	addr
		btfsc	addr, bit
		goto	?over
		banksel	0
		goto	br
?over
		banksel	0

		else

; If addr is in zero bank
		btfss	addr, bit
		goto	br

		endif
		endm

; Branch bit set
; OK farok
jbs		macro	addr, bit, br
		local	?over

		if	(((addr) & ~0x7F) != 0)

; If addr is not in zero bank
		banksel	addr
		btfss	addr, bit
		goto	?over
		banksel	0
		goto	br
?over
		banksel	0

		else

; If addr is in zero bank
		btfsc	addr, bit
		goto	br

		endif
		endm

; Move bit
; OK farok
ldb	macro	dest, dest_bt, src, src_bt
		local	?over1, ?over2
		if ((src) & ~0x7F) != 0
				banksel	src
				btfsc	src, src_bt
				goto	?over1
				banksel	dest
				bcf	dest, dest_bt
				banksel	src
?over1
				btfss	src, src_bt
				goto	?over2
				banksel	dest
				bsf	dest, dest_bt
?over2
				banksel	0
		else
			if ((dest) & ~0x7F) != 0
				btfsc	src, src_bt
				goto	?over1
				banksel	dest
				bcf	dest, dest_bt
				banksel	0
?over1
				btfss	src, src_bt
				goto	?over2
				banksel	dest
				bsf	dest, dest_bt
				banksel	0
?over2
			else

				btfss	src, src_bt
				bcf	dest, dest_bt
				btfsc	src, src_bt
				bsf	dest, dest_bt
			endif
		endif
	endm

; Move inverse of bit
; OK farok
ldnb	macro	dest, dest_bt, src, src_bt
		local	?over1, ?over2
		if ((src) & ~0x7F) != 0
				banksel	src
				btfsc	src, src_bt
				goto	?over1
				banksel	dest
				bsf	dest, dest_bt
				banksel	src
?over1
				btfss	src, src_bt
				goto	?over2
				banksel	dest
				bcf	dest, dest_bt
?over2
				banksel	0
		else
			if ((dest) & ~0x7F) != 0
				btfsc	src, src_bt
				goto	?over1
				banksel	dest
				bsf	dest, dest_bt
				banksel	0
?over1
				btfss	src, src_bt
				goto	?over2
				banksel	dest
				bcf	dest, dest_bt
				banksel	0
?over2
			else

				btfss	src, src_bt
				bsf	dest, dest_bt
				btfsc	src, src_bt
				bcf	dest, dest_bt
			endif
		endif
		endm

; Clear carry (or set borrow)
; OK
clc		macro
		bic	status, c_flag
		endm

; Set carry (or clear borrow)
; OK
stc		macro
		bis	status, c_flag
		endm

; Clear zero
; OK
clz		macro
		bic	status, z_flag
		endm

; Set zero
; OK
stz		macro
		bis	status, z_flag
		endm

;; RR group
; *dest = *src, Z
; OK farok
ld	macro	dest, src

		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				movwf	dest
				banksel	0

			else

				banksel	0
				movwf	dest

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				movwf	dest
				banksel	0

			else

				movwf	dest

			endif

		endif
	endm

; *dest = *dest + *src, Z DC C
; OK farok
add	macro	dest, src

		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				addwf	dest, 1
				banksel	0

			else

				banksel	0
				addwf	dest, 1

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				addwf	dest, 1
				banksel	0

			else

				addwf	dest, 1

			endif

		endif
	endm

; OK farok
; *dest = *dest + *src + c
adc		macro	dest, src
		addb	dest, status, c_flag
		add	dest, src
		endm

; *dest = *dest - *src, Z DC C
; OK farok
sub	macro	dest, src
		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				subwf	dest, 1
				banksel	0

			else

				banksel	0
				subwf	dest, 1

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				subwf	dest, 1
				banksel	0

			else

				subwf	dest, 1

			endif

		endif
	endm

; *dest = *dest - *src - ~c
; OK farok
sbc		macro	dest, src
		subnb	dest, status, c_flag
		sub	dest, src
		endm

; *dest - *src, Z DC C
; OK farok
cmp	macro	dest, src
		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				subwf	dest, 0
				banksel	0

			else

				banksel	0
				subwf	dest, 0

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				subwf	dest, 0
				banksel	0

			else

				subwf	dest, 0

			endif

		endif
	endm

; *dest = *dest & *src, Z
; OK farok
and	macro	dest, src
		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				andwf	dest, 1
				banksel	0

			else

				banksel	0
				andwf	dest, 1

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				andwf	dest, 1
				banksel	0

			else

				andwf	dest, 1

			endif

		endif
	endm

; *dest = *dest | *src, Z
; OK farok
or	macro	dest, src
		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				iorwf	dest, 1
				banksel	0

			else

				banksel	0
				iorwf	dest, 1

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				iorwf	dest, 1
				banksel	0

			else

				iorwf	dest, 1

			endif

		endif
	endm

; *dest = *dest ^ *src, Z
; OK farok
xor		macro	dest, src
		if	((src) & ~0x7F) != 0

			banksel	src
			movf	src, 0

			if	((dest) & ~0x7F) != 0

				if	((dest) & ~0x7F) != ((src) & ~0x7F)
					banksel	dest
				endif

				xorwf	dest, 1
				banksel	0

			else

				banksel	0
				xorwf	dest, 1

			endif


		else

			movf	src, 0

			if	((dest) & ~0x7F) != 0
				banksel	dest
				xorwf	dest, 1
				banksel	0

			else

				xorwf	dest, 1

			endif

		endif
	endm

; *dest = imm
; OK farOK
ldi		macro	dest, imm

		movlw	imm

		if	((dest) & ~0x7F) != 0
			banksel	dest
			movwf	dest
			banksel	0
		else
			movwf	dest
		endif

		endm

; *dest = *dest + imm, Z DC C
; OK farOK
addi	macro	dest, imm
		movlw	imm
		if	((dest) & ~0x7F) != 0
			banksel	dest
			addwf	dest, 1
			banksel	0
		else
			addwf	dest, 1
		endif
		endm

; *dest = *dest + imm + c
; OK farOK
adci	macro	dest, imm
		addb	dest, status, c_flag
		addi	dest, imm
		endm

; *dest = *dest - imm, Z DC C
; OK farOK
subi	macro	dest, imm
		movlw	imm
		if	((dest) & ~0x7F) != 0
			banksel	dest
			subwf	dest, 1
			banksel	0
		else
			subwf	dest, 1
		endif
		endm

; OK farok
; *dest = *dest - imm - ~c
sbci	macro	dest, imm
		subnb	dest, status, c_flag
		subi	dest, imm
		endm

; *dest - imm, Z DC C
; OK farok
cmpi	macro	dest, imm
		movlw	imm
		if	((dest) & ~0x7F) != 0
			banksel	dest
			subwf	dest, 0
			banksel	0
		else
			subwf	dest, 0
		endif
		endm

; *dest = *dest & imm, Z
; OK farok
andi	macro	dest, imm
		movlw	imm
		if	((dest) & ~0x7F) != 0
			banksel	dest
			andwf	dest, 1
			banksel	0
		else
			andwf	dest, 1
		endif
		endm

; *dest = *dest | imm, Z
; OK farok
ori		macro	dest, imm
		movlw	imm
		if	((dest) & ~0x7F) != 0
			banksel	dest
			iorwf	dest, 1
			banksel	0
		else
			iorwf	dest, 1
		endif
		endm

; *dest = *dest ^ imm, Z
; OK farok
xori	macro	dest, imm
		movlw	imm
		if	((dest) & ~0x7F) != 0
			banksel	dest
			xorwf	dest, 1
			banksel	0
		else
			xorwf	dest, 1
		endif
		endm

; *dest = 0, Z=1
; OK farok
clr		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			clrf	dest
			banksel	0
		else
			clrf	dest
		endif
		endm

; *dest = *dest + 1, Z
; OK farok
inc		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			incf	dest, 1
			banksel	0
		else
			incf	dest, 1
		endif
		endm

; *dest = *dest - 1, Z
; OK farok
dec		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			decf	dest, 1
			banksel	0
		else
			decf	dest, 1
		endif
		endm

; Rotate left, C
; OK farok
rol		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			rlf	dest, 1
			banksel	0
		else
			rlf	dest, 1
		endif
		endm

; OK farok
lsl		macro	dest
		clc
		rol	dest
		endm

; OK farok
asl		macro	dest
		clc
		rol	dest
		endm

; Rotate right, C
; OK farok
ror		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			rrf	dest, 1
			banksel	0
		else
			rrf	dest, 1
		endif
		endm

; OK farok
lsr		macro	dest
		clc
		ror	dest
		endm

; OK farok
asr		macro	dest
		ldb	status, c_flag, dest, 7
		ror	dest
		endm

; Complement, Z
; OK farok
com		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			comf	dest, 1
			banksel	0
		else
			comf	dest, 1
		endif
		endm

; *dest = -*dest, Z
; OK farok
neg		macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			comf	dest, 1
			incf	dest, 1
			banksel	0
		else
			comf	dest, 1
			incf	dest, 1
		endif
		endm

; Swap nibbles
; OK farok
swap	macro	dest
		if	((dest) & ~0x7F) != 0
			banksel	dest
			swapf	dest, 1
			banksel	0
		else
			swapf	dest, 1
		endif
		endm

; Jump to subroutine
; OK
jsr		macro	dest
		call	dest
		endm

; Far jump to subroutine (subroutine is in different page)
farjsr	macro	dest
		local	?here
		movlw	HIGH dest
		movwf	pclath
		call	dest
		movlw	HIGH ?here	; Restore page in pclath
		movwf	pclath
?here
		endm

; Return from subroutine
; OK
rts		macro
		return
		endm

; Decrement branch ne
; OK farok
decjne	macro	dest, br
		local	?over, ?out
		if ((dest) & ~0x7F) != 0
			banksel	dest
			decfsz	dest, 1
			goto	?over
			banksel	0
			goto	?out
?over
			banksel	0
			goto	br
?out
		else
			decfsz	dest, 1
			goto	br
		endif
	endm

; Increment branch ne
; OK farok
incjne	macro	dest, br
		local	?over, ?out
		if ((dest) & ~0x7F) != 0
			banksel	dest
			incfsz	dest, 1
			goto	?over
			banksel	0
			goto	?out
?over
			banksel	0
			goto	br
?out
		else
			incfsz	dest, 1
			goto	br
		endif
	endm

; Jump
; OK
jmp		macro	dest
		goto	dest
		endm

; Far jump
farjmp	macro	dest
		movlw	HIGH dest
		movwf	pclath
		goto	dest
		endm

; OK
jeq		macro	dest
		jbs		status, z_flag, dest
		endm

; OK
jne		macro	dest
		jbc		status, z_flag, dest
		endm

; OK
jcs		macro	dest
		jbs		status, c_flag, dest
		endm

; OK
jcc		macro	dest
		jbc		status, c_flag, dest
		endm

; OK
jas		macro	dest
		jbs		status, dc_flag, dest
		endm

; OK
jac		macro	dest
		jbc		status, dc_flag, dest
		endm

; Comparison
; OK
jlo		macro	dest
		jbc		status, c_flag, dest
		endm

; OK
jls		macro	dest
		jbc		status, c_flag, dest
		jbs		status, z_flag, dest
		endm

; OK
jhs		macro	dest
		jbs		status, c_flag, dest
		endm

; OK
jhi		macro	dest
		local	?skipit
		jbs		status, z_flag, ?skipit
		jbs		status, c_flag, dest
?skipit
		endm

; Short table lookup: the table is in the same 256 byte page

short_lookup	macro table, dest, src
		movf	src, 0
		call	table
		movwf	dest
		endm

; Normal table lookup: the table is in the same 2KB page

lookup	macro	table, dest, src
		movlw	HIGH table
		movwf	pclath
		movf	src, 0
		call	table
		movwf	dest
		endm

; Far table lookup: the table is in a different page

far_lookup	macro	table, dest, src
		local	?here
		movlw	HIGH table
		movwf	pclath
		movf	src, 0
		call	table
		movwf	dest
		movlw	HIGH ?here	; Restore page in pclath
		movwf	pclath
?here
		endm

; Table header
; Max table size is 255 bytes
table	macro
		addwf	pcl, 1
		endm

; Table entry

val		macro	value
		retlw	value
		endm

	list
