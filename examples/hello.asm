	org	0x00

tmp	skip	1

msg	data	0x48
	data	0x65
	data	0x6C
	data	0x6C
	data	0x6F
	data	0x2C
	data	0x20
	data	0x57
	data	0x6F
	data	0x72
	data	0x6C
	data	0x64
	data	0x21
	data	0x0D
	data	0x0A
	data	0x00

	org	0x20

start	st	#msg, ptr	; Point to message
loop	clr	tmp		; Pre-clear
ptr	add	tmp, 0		; Read from pointer
	jeq	tmp, done	; Jump if end of message
	outc	tmp		; Write character to serial
	inc	ptr		; Increment pointer
	jmp	loop		; Loop...
done	halt
