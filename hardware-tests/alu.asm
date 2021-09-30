; ALU tests

	org	0x00
arg1	skip	1
arg2	skip	1
count	skip	1

	org	0x10

	st	#-8, count
loop

; Test condition flags
; Testing Zero
	clr	arg1
	jeq	arg1, next
	halt

next	jne	arg1, hal
	inc	arg1
	jne	arg1, next1
	halt
hal	halt
hal1	halt
hal2	halt
hal3	halt
hal4	halt
hal5	halt
hal6	halt
hal7	halt

next1	jeq	arg1, hal1

; Testing carry
	stc
	jcs	next2
	halt

next2	stc
	jcc	hal2

	clc
	jcs	hal3

	stc
	jcs	next3
	halt

next3	clc
	jcc	next4
	halt

; Test negative
next4
	st	#0x80, arg1
	jmi	arg1, next5
	halt

next5	jpl	arg1, hal4

	st	#0x7F, arg1
	jmi	arg1, hal5

	jpl	arg1, next6
	halt

; Test even / odd
next6	st	#1, arg1
	je	arg1, hal6
	jo	arg1, next7
	halt
next7	st	#0xFE, arg1
	jo	arg1, hal7
	je	arg1, next8
	halt

hal8	halt
hal9	halt
hal10	halt
hal11	halt
hal12	halt
hal13	halt
hal14	halt
hal15	halt
hal16	halt
hal17	halt
hal18	halt
hal19	halt
hal20	halt
hal21	halt
hal22	halt
hal23	halt
hal24	halt
hal25	halt
hal26	halt
hal27	halt
hal28	halt
hal29	halt
hal30	halt
hal31	halt
hal32	halt
hal33	halt
hal34	halt
hal35	halt
hal36	halt
hal37	halt
hal38	halt
hal39	halt
hal40	halt
hal41	halt
hal42	halt
hal43	halt
hal44	halt
hal45	halt

; Test AND
next8	st	#0x55, arg1
	andto	#0x55, arg1
	rsbto	#0x55, arg1
	jne	arg1, hal8

	st	#0xAA, arg1
	andto	#0x55, arg1
	jne	arg1, hal9

	st	#0xAA, arg1
	andto	#0xAA, arg1
	rsbto	#0xAA, arg1
	jne	arg1, hal10

	st	#0x55, arg1
	andto	#0xAA, arg1
	jne	arg1, hal11

; Test ROR
	st	#0x55, arg1
	stc
	ror	arg1
	rsbto	#0xAA, arg1
	jne	arg1, hal12

	st	#0xAA, arg1
	clc
	ror	arg1
	rsbto	#0x55, arg1
	jne	arg1, hal13

	clr	arg1
	lsro	arg1
	rsbto	#0x80, arg1
	jne	arg1, hal14

	st	#0xFF, arg1
	lsr	arg1
	rsbto	#0x7F, arg1
	jne	arg1, hal15

; Test adder
	st	#0xAA, arg1
	addto	#0x55, arg1
	rsbto	#0xFF, arg1
	jne	arg1, hal16

	st	#0x55, arg1
	addto	#0xAA, arg1
	rsbto	#0xFF, arg1
	jne	arg1, hal17

	st	#0x55, arg1
	clc
	adcto	#0x55, arg1
	jcs	hal18
	rsbto	#0xAA, arg1
	jne	arg1, hal19

	st	#0xAA, arg1
	stc
	adcto	#0xAA, arg1
	jcc	hal20
	rsbto	#0x55, arg1
	jne	arg1, hal21

	st	#0x00, arg1
	stc
	adcto	#0x01, arg1
	rsbto	#0x02, arg1
	jne	arg1, hal22

	st	#0x01, arg1
	stc
	adcto	#0x00, arg1
	rsbto	#0x02, arg1
	jne	arg1, hal23

	st	#0x01, arg1
	addto	#0x03, arg1
	rsbto	#0x04, arg1
	jne	arg1, hal24

	st	#0x03, arg1
	addto	#0x01, arg1
	rsbto	#0x04, arg1
	jne	arg1, hal25

	st	#0x03, arg1
	addto	#0x07, arg1
	rsbto	#0x0A, arg1
	jne	arg1, hal26

	st	#0x07, arg1
	addto	#0x03, arg1
	rsbto	#0x0A, arg1
	jne	arg1, hal27

	st	#0x07, arg1
	addto	#0x0F, arg1
	rsbto	#0x16, arg1
	jne	arg1, hal28

	st	#0x0f, arg1
	addto	#0x07, arg1
	rsbto	#0x16, arg1
	jne	arg1, hal29

	st	#0x0f, arg1
	addto	#0x1f, arg1
	rsbto	#0x2e, arg1
	jne	arg1, hal30

	st	#0x1f, arg1
	addto	#0x0f, arg1
	rsbto	#0x2e, arg1
	jne	arg1, hal31

	st	#0x1f, arg1
	addto	#0x3f, arg1
	rsbto	#0x5e, arg1
	jne	arg1, hal32

	st	#0x3f, arg1
	addto	#0x1f, arg1
	rsbto	#0x5e, arg1
	jne	arg1, hal33

	st	#0x3f, arg1
	addto	#0x7f, arg1
	rsbto	#0xbe, arg1
	jne	arg1, hal34

	st	#0x7f, arg1
	addto	#0x3f, arg1
	rsbto	#0xbe, arg1
	jne	arg1, hal35

	st	#0x7f, arg1
	addto	#0xff, arg1
	jcc	hal36
	rsbto	#0x7e, arg1
	jne	arg1, hal37

	st	#0xff, arg1
	addto	#0x7f, arg1
	jcc	hal38
	rsbto	#0x7e, arg1
	jne	arg1, hal39

	st	#0xff, arg1
	addto	#0xff, arg1
	jcc	hal40
	rsbto	#0xfe, arg1
	jne	arg1, hal41

	incjne	count, loop
	outc	#0x50
	halt

