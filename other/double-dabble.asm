; Double Dabble
; Ryan Crosby 2018
;
; The double dabble algorithm converts a binary/hex number into decimal BCD.
;
	org	0x00
test_ddabble_num	data	243	; Test number
test_ddabble_tmp	skip	1	; Scratch space for ASCII calculation
	org	0x10
test_ddabble	st	test_ddabble_num, ddabble_n
	jsr	ddabble_ret, ddabble	; Run Double Dabble algorithm on n
	st	ddabble_2, test_ddabble_tmp	; Hundreds digit is in lower nubble of 2
	addto	#0x30, test_ddabble_tmp	; Convert into ASCII by adding '0'
	outc	test_ddabble_tmp	; Print hundreds digit
	st	ddabble_01, test_ddabble_tmp	; Tens digit is in upper nibble of 01
	lsr	test_ddabble_tmp	; Shift tens digit into lower nibble (also removes ones digit)
	lsr	test_ddabble_tmp
	lsr	test_ddabble_tmp
	lsr	test_ddabble_tmp
	addto	#0x30, test_ddabble_tmp	; Convert into ASCII by adding '0'
	outc	test_ddabble_tmp	; Print tens digit
	st	ddabble_01, test_ddabble_tmp     ; Ones digit is in lower nibble of 01
	andto	#0x0F, test_ddabble_tmp	; Mask out 10s digit
	addto	#0x30, test_ddabble_tmp	; Convert into ASCII by adding '0'
	outc	test_ddabble_tmp	; Print ones digit
	halt

; Convert hex number to decimal by Double Dabble algorithm
;
	org	0x25
ddabble_n	skip	1	; The binary number to convert. This argument is destroyed.
ddabble_01	skip	1	; The first decimal digit (ones digit), lower nibble, and the second decimal digit (tens digit), upper nibble.
ddabble_2	skip	1	; The third decimal digit (hundreds digit), lower nibble.
ddabble_i	skip	1	; Interation counter
ddabble_tmp	skip	1	; Scratch space
	org	0x30
ddabble	clr	ddabble_01	; Subroutine start.
	clr	ddabble_2
	st	#-8, ddabble_i	; Run the loop 8 times for an 8 bit input.
ddabble_c2	jeq	ddabble_2, ddabble_c1	; Optimisation. If digit 2 is zero, don't need to check it.
	st	ddabble_2, ddabble_tmp
	rsbto	#0x04, ddabble_tmp
	jls	ddabble_tmp, ddabble_c1
	addto	#0x03, ddabble_2
ddabble_c1	jeq	ddabble_01, ddabble_r	; Optimisation. If digits 0 and 1 are both zero, don't need to check them.
	st	ddabble_01, ddabble_tmp
	andto	#0xF0, ddabble_tmp	; Mask off upper nibble (digit 1)
	rsbto	#0x40, ddabble_tmp
	jls	ddabble_tmp, ddabble_c0
	addto	#0x30, ddabble_01
ddabble_c0	st	ddabble_01, ddabble_tmp
	andto	#0x0F, ddabble_tmp	; Mask off lower nibble (digit 0)
	rsbto	#0x04, ddabble_tmp
	jls	ddabble_tmp, ddabble_r
	addto	#0x03, ddabble_01
ddabble_r	lsl	ddabble_n	; Left rotate all data by 1 bit
	rol	ddabble_01
	rol	ddabble_2
	incjne	ddabble_i, ddabble_c2	; Loop.
ddabble_ret	jmp	0	; Return subroutine.
