; Test input and output ports
; start at 0x10
; hit buttons 1, 2, 4, 8 over and over again until done

	org	0x00
down	skip	1
tmp	skip	1
count	skip	1
tmp1	skip	1

	org	0x10
start	st	#-4, down

first	jsr	delay_done, delay
	inwait	tmp
	out	tmp
	st	tmp, tmp1
	rsbto	#1, tmp1
	jeq	tmp1, next2
	halt

next2	jsr	delay_done, delay
	inwait	tmp
	out	tmp
	st	tmp, tmp1
	rsbto	#2, tmp1
	jeq	tmp1, next4
	halt

next4	jsr	delay_done, delay
	inwait	tmp
	out	tmp
	st	tmp, tmp1
	rsbto	#4, tmp1
	jeq	tmp1, next8
	halt

next8	jsr	delay_done, delay
	inwait	tmp
	out	tmp
	st	tmp, tmp1
	rsbto	#8, tmp1
	jeq	tmp1, check
	halt

check	incjne	down, first
	outc	#0x50
	halt

delay	st	#-8, count
wait	incjne	count, wait
delay_done	jmp 0

