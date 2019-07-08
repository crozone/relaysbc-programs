; Bubble sort

	org	0x00
count	skip	1
flag	skip	1
tmp	skip	1
tmp1	skip	1
tmp2	skip	1

; Some numbers to sort..
dstart	data	5
	data	1
	data	10
	data	12
	data	3
	data	20
	data	4
	data	8
dend

	org	0x20

sort	st	#-(dend-dstart-1), count	; Number of items...
	clr	flag
	st	#dstart, ptr			; Set pointers
	st	#dstart+1, ptr1
loop
; Read items
	clr	tmp
ptr	add	tmp, 0
	clr	tmp1
ptr1	add	tmp1, 0
; Compare them
	st	tmp, tmp2
	rsbto	tmp1, tmp2
	jls	tmp2, noswap	; Branch if already in order
; Swap items
	st	ptr, ptr2	; Copy pointers
	st	ptr1, ptr3
ptr2	st	tmp1, 0
ptr3	st	tmp, 0
; Set flag to indicate we did something
	inc	flag
noswap	inc	ptr		; Advance pointers
	inc	ptr1
	incjne	count, loop	; loop
	jne	flag, sort	; Repeat until sorted
	halt
