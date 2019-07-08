; Integer square root

	org	0x00
num	skip	1	; Find square root of this
result	skip	1	; Result ends up here

; Subroutine
	org	0x10
sqrt	st	#0xFF, result
sqrt1	addto	#2, result
	rsbto	result, num
	jcs	sqrt1
	lsr	result
s_done	jmp	0

; Try it
	org	0x20
	st	#144, num
	jsr	s_done, sqrt
	halt
