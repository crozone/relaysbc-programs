; PC test
; Test all combinations of each half-adder in the PC incrementer.
; Set address to 0xF0 to watch counter
; Start at 0x14
; Prints P for pass.  Prints X if test finished, but count
; was incorrect.

	org	0x0
first	inc	count
	incjne	down, aa
	jmp	done

	org	0x3
x3	nop
	inc	count
	jmp	x7

	org	0x7
x7	nop
	inc	count
	jmp	xf

	org	0xf
xf	nop
	inc	count
	jmp	x1f

	org	0x14
start	clr	count
	st	#0xF0, down
	jmp	first
done	st	count, tmp
	rsbto	#0x88, tmp
	jeq	tmp, pass
	outc	#0x58
	halt
pass	outc	#0x50
	halt

	org	0x1f
x1f	nop
	inc	count
	jmp	x3f

	org	0x3f
x3f	nop
	inc	count
	jmp	x7f

	org	0x55
x55	nop
	inc	count
	jmp	x3

	org	0x7f
x7f	nop
	inc	count
	jmp	xff

	org	0xAA
aa	nop
	inc	count
	jmp	x55

	org	0xF0
count	data	0
down	data	0xF0
tmp	skip	1

	org	0xFF
xff	nop
