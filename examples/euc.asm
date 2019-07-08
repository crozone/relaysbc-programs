; Euclid's algorithm

		org	0x00
a		skip	1		; First number
b		skip	1		; Second number
tmp		skip	1		; Tmp variable

		org	0x10
euclid		st	#144, a		; Initialize A
		st	#233, b		; Initialize B
euclop		jeq	b, eucdon	; Done ?
		st	a, tmp
		rsbto	b, tmp		; A - B -> TMP
		jls	tmp, over	; A <= B ?
		rsbto	b, a		; A - B -> A
		jmp	euclop
over		rsbto	a, b		; B - A -> B
		jmp	euclop
eucdon		halt
