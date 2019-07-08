; Simon type game

		org	0x00
pat_len		skip	1			; Pattern length
rng		skip	1			; Random number generator
count		skip	1			; Counter
delay_count	skip	1
tmp		skip	1
tmp1		skip	1

; Start

done		org	0x0f
		halt
start		st	#0xfd, pat_len		; Initial length
main_loop	jsr	show_rtn, show_pat	; Show pattern
		jsr	read_rtn, read_pat	; Read pattern from user
		jcc	done			; We fail
		dec	pat_len			; Increase length
		jmp	main_loop

; Show pattern

show_pat	st	#1, rng
		st	pat_len, count
show_loop	st	rng, tmp
		rol	tmp
		rol	tmp
		rol	tmp
		andto	#3, tmp
		st	#1, tmp1

		jeq	tmp, tdone
tloop		lsl	tmp1
		dec	tmp
		jne	tmp, tloop

tdone		out	tmp1
		jsr	delay_rtn, delay
		out	#0
		jsr	rng_rtn, rng_step
		incjne	count, show_loop
show_rtn	jmp	0

; Delay

delay		st	#0xFA, delay_count
delay_loop	incjne	delay_count, delay_loop
delay_rtn	jmp	0

; Random number generator: rng = rng*49 + 47 = rng * 32 + rng * 16 + rng + 47

rng_step	st	rng, tmp
		lsl	tmp
		lsl	tmp
		lsl	tmp
		lsl	tmp
		addto	tmp, rng
		lsl	tmp
		addto	tmp, rng
		addto	#47, rng
rng_rtn		jmp	0

; Read pattern

read_pat	st	#1, rng
		st	pat_len, count
read_loop
		inwait	tmp
		jeq	tmp, read_loop
		out	tmp
		st	#0xff, tmp1
cvt_loop	inc	tmp1
		lsr	tmp
		jcc	cvt_loop
		st	rng, tmp
		rol	tmp
		rol	tmp
		rol	tmp
		andto	#3, tmp
		rsbto	tmp1, tmp
		jne	tmp, fail
		out	#0
		jsr	rng_rtn, rng_step
unpress		in	tmp
		jne	tmp, unpress
		incjne	count, read_loop
		stc
read_rtn	jmp	0
fail		out	#15
		jsr	delay_rtn, delay
		jsr	delay_rtn, delay
		out	#0
		clc
		jmp	read_rtn
