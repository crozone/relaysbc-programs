; Divide

	org	0x00
quotient	skip	1
remainder	skip	1
dividend	skip	1
divisor	skip	1
count	skip	1

	org	0x10
div	clr	remainder
	st	#-8, count
divlop	lsl	dividend
	rol	remainder
	rsbto	divisor, remainder
	jcc	toomuch
	lslo	quotient
	incjne	count, divlop
	jmp	divrtn
toomuch	addto	divisor, remainder
	lsl	quotient
	incjne	count, divlop
divrtn	jmp	0

	org	0x20
	st	#42, dividend
	st	#5, divisor
	jsr	divrtn, div
	halt
