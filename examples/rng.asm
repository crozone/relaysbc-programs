
		org	0
acc		data	1
scratch		skip	1
lut		data	9
count		data	0x80

		org	5
loop		jsr	done, rng
		incjne	count, loop
		halt

		org	0x10
rng		st	acc, scratch
		rol	scratch
		rol	scratch
		rol	scratch
		andto	#0x3, scratch
		jeq	scratch, appendone
		dec	scratch
		jeq	scratch, appendzero
		dec 	scratch
		jeq 	scratch, appendzero

appendone	lslo	acc
		jmp	done
		
appendzero	lsl	acc
done		jmp	0
