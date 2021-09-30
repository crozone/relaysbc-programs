; Test JSR MUX
; start at 0x10, print 'P' for pass
; set display to 0x00

	org	0x00
first	skip	1	; Should get 55
second	skip	1	; Should get AA
count	skip	1
down	skip	1
tmp	skip	1

	org	0x10
start	st	#0xF0, down
	clr	count
loop	clr	first
	clr	second
	jmp	do_first
check	st	first, tmp
	rsbto	#0x55, tmp
	jeq	tmp, next
	halt
next	st	second, tmp
	rsbto	#0xAA, tmp
	jeq	tmp, next1
	halt
next1	inc	count
	incjne	down, loop
pass	outc	#0x50
	halt

	org	0x54
do_first
	jsr	first, do_second

	org	0xA9
do_second
	jsr	second, check
