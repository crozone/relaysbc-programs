; Multiply

	org	0x00
argx	skip	1
argy	skip	1
res_lo	skip	1
res_hi	skip	1
count	skip	1

	org	0x10
mul	st	#0, res_lo
	st	#0, res_hi
	st	#-8, count
loop	lsl	res_lo
	rol	res_hi
	lsl	argy
	jcc	over
	addto	argx, res_lo
	adcto	#0, res_hi
over	incjne	count, loop
mulrtn	jmp	0

; Try it
	org	0x20
	st	#9, argx
	st	#20, argy
	jsr	mulrtn, mul
	halt
