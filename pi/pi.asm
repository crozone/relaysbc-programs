; Calculate pi using Machin's formula
; Dag Stroman, March 19 2019
;
;
; Machin's formula:
;   pi/4=4*arctan(1/5)-arctan(1/239)
; where
;   arctan=(1/x)=1/x-1/3*x**3+1/5*x**5-...
;
; Rewriten to be pi/16=arctan(1/5)-arctan(1/239)/4. 
;
; The divide by 4 is easily implemented as two right shifts. Having the result in format
; pi/16 is very nice since it is the same as pi/0x10 meaning that the binary result needs
; no further transformation in order to be used in binary to decimal conversion.
;
; The code is a strightforward 'hack' and may be more optimized for size and
; likely also speed. It will also be fairly easy to increase precision (if made shorter).
; Could possible be rewritten to use pointers but this may hurt performance.
;
; Program start is at 0x35 and almost fills memory. There are about 14 bytes left :-).
; 
; By monitoring address 'total' (0x23) during execution the intermediary results of arctan 
; can be viewed. At completion, the value of pi in hex is also viewed there. The following
; intermediate results should be displayed:
;
; arctan(1/5):
;   0x33333333
;   0x32846ff5
;   0x3288a1b2
;   0x32888305
;   0x328883f9
;   0x328883f2
; arctan(1/239):
;   0x0112358e
;   0x01123526
; pi/16=arctan(1/5)-arctan(1/239)>>2:
;   0x3243f6a9
;
; Program output to TTL one '.' per round of division and a '!' when
; calculation is complete. There are two divisions per round in arclop, so there will be
; two '.' per intermediary result. The final result is converted to base 10 and printed
; to TTL:
;
;    > g 35
;    ................!
;    pi=3.14259265
;
; Program takes about 30 minutes to complete with moderate speed.
;
; Corresponding c-code for arctan:
;
;int arctan_invx(int x, unsigned power) {
;  int total;
;  int x_sq;
;  int divisor;
;  int delta = 0;
;  int negate;
;
;  total = power;
;  x_sq = x*x;
;  divisor = 1;
;  negate = 0;
;
;  while (1){
;    negate = ~negate;
;    divisor +=2;
;    power = power/x_sq;
;    delta = power / divisor;
;    if (delta == 0) {
;      break;
;    }
;    if (negate) {
;      delta = -delta;
;    }
;    total += delta;
;  }
;  return (total);
;}
;
;
; Some variables used by main	
       org 0x00
pi		skip 4
char		skip 1
mcount  	skip 1
product		skip 4
m10		skip 4
	
; Variables used by Long Divide
count	    	skip 1
quotient    	skip 4
remainder   	skip 4
dividend    	skip 4
ldivisor    	skip 4

; Variables used by the arctan loop
power	    	skip 4
total		skip 4
x_sq		skip 4	
adivisor 	skip 4
delta   	skip 4
negate  	skip 1	

; main 
	org 0x35
main
	outc 	#0x0a			; CR/LF
	outc 	#0x0d
; precalculation of power=one/x=0x0100000000/5=0x33333333.
; This will put the fixed decimal point in after the MSB nibble. 
	st	#0x33, power	
	st	#0x33, power+1
	st	#0x33, power+2
	st	#0x33, power+3
	st	power, total		; total = power
	st	power+1, total+1
	st	power+2, total+2
	st	power+3, total+3
	st	#0x19, x_sq		; x_sq=x*x=5*5=0x00000019
	st	#0x00, x_sq+1
	st	#0x00, x_sq+2
	st	#0x00, x_sq+3
	st	#1, adivisor		; adivisor = 1
	st	#0, adivisor+1	
	st	#0, adivisor+2	
	st	#0, adivisor+3
	st	#0, negate		; negate = 0
	jsr	arcrtn,arclop		; arctan(1/5)
	st	total,pi		; pi = result
	st	total+1,pi+1
	st	total+2,pi+2
	st	total+3,pi+3
; precalculation of power=one/x=0x0100000000/239=0x0112358e
	st	#0x8e, power	
	st	#0x35, power+1
	st	#0x12, power+2
	st	#0x01, power+3
	st	power, total		; total = power
	st	power+1, total+1
	st	power+2, total+2
	st	power+3, total+3
	st	#0x21, x_sq		; x_sq=239*239
	st	#0xdf, x_sq+1
	st	#0x00, x_sq+2
	st	#0x00, x_sq+3
	st	#1, adivisor		; adivisor = 1
	st	#0, adivisor+1	
	st	#0, adivisor+2	
	st	#0, adivisor+3
	st	#0, negate
	jsr	arcrtn,arclop		; arctan(1/239)
	lsr	total+3			; shift right (div by 2)
	ror	total+2		
	ror	total+1
	ror	total
	lsr	total+3
	ror	total+2			; shift right (div by 2)
	ror	total+1
	ror	total
	rsbto	total,pi		; subtract from pi
	rsbcto	total+1,pi+1
	rsbcto	total+2,pi+2
	rsbcto	total+3,pi+3
	st 	pi, total		; total = pi (ie show on display)
	st 	pi+1,total+1
	st 	pi+2,total+2
	st 	pi+3,total+3
	outc 	#0x21			; Done so far. print '!'			
	outc 	#0x0a			; CR/LF
	outc 	#0x0d
        outc 	#0x70			; "pi="
	outc 	#0x69
	outc 	#0x3d
	st 	#-9, count		; Print 9 base10 digits
print	st 	pi+3,char		; get MSB  
	andto 	#0xf0,char		; Get MSB nibble. This will be 0x30 first time.
	andto 	#0x0f,pi+3		; Mask of MSB nibble from pi.
	lsr 	char			; Shift down (ie 0x30 -> 0x03)
	lsr 	char			
	lsr 	char
	lsr 	char
	addto 	#0x30,char		; Make it ascii number
	outc 	char			; print
        addto	#-0x33,char		; Dirty trick. Check if this is 3
	jne 	char,nopnt		; If not, goto  nopnt
	outc 	#0x2e			; else print '.'

; start pi = pi * 10.
nopnt	st      #0, product		; clr result
        st      #0, product+1
        st      #0, product+2
        st      #0, product+3
	st	#10, m10		; multiplicator is 10
	st 	#0x00, m10+1
	st 	#0x00, m10+2
	st 	#0x00, m10+3	
        st      #-32, mcount		; shift counter
loop    lsl     product             	; left shift res
        rol     product+1
        rol     product+2
        rol     product+3
        lsl     m10			; left shift m10
        rol     m10+1
        rol     m10+2
        rol     m10+3
        jcc     over			; if carry is clear goto over
        addto   pi, product       	; otherwise add pi to product.
        adcto   pi+1, product+1
        adcto   pi+2, product+2
        adcto   pi+3, product+3
					; One could probably test ovf here
over    incjne  mcount, loop		; jump to loop until done.
	
	st	product,pi		; store product into pi
	st 	product+1,pi+1
	st 	product+2,pi+2
	st 	product+3,pi+3
	incjne  count, print		; jump to print until done
	outc 	#0x0a			; CR/LF
	outc 	#0x0d
	halt				; Done!

; this is the while loop of the arctan. See C-code for more info.
arclop   
	st	power, dividend	;	; dividend=power
	st	power+1, dividend+1
	st	power+2, dividend+2
	st	power+3, dividend+3

	st	x_sq,ldivisor		; ldivisor = x_sq
	st	x_sq+1,ldivisor+1
	st	x_sq+2,ldivisor+2
	st	x_sq+3,ldivisor+3

	jsr	divrtn, div		; quotient = power/x_sq

	st 	quotient, power		; power = quotient 
	st	quotient+1, power+1
	st	quotient+2, power+2
	st	quotient+3, power+3

	com 	negate			; negate = ~negate;
	
	addto	#0x02,adivisor		; adivisor +=2
	adcto 	#0x00,adivisor+1
	adcto 	#0x00,adivisor+2
	adcto 	#0x00,adivisor+3

	st	power, dividend	;	; dividend=power
	st	power+1, dividend+1	
	st	power+2, dividend+2
	st	power+3, dividend+3

	st	adivisor,ldivisor	; ldivisor=adivisor
	st	adivisor+1,ldivisor+1
	st	adivisor+2,ldivisor+2
	st	adivisor+3,ldivisor+3

	jsr	divrtn, div		; quotient=power/adivisor
	st	quotient, delta		; delta = quotient 
	st	quotient+1, delta+1
	st	quotient+2, delta+2
	st	quotient+3, delta+3

	jne	delta, cont		; if (delta!=0) jump to cont
	jne	delta+1,cont
	jne	delta+2,cont
	jne	delta+3,cont
	jmp 	arcrtn			; else we are done. Jump to arcrtn.
	
cont    jeq	negate, noneg		; if (negate==0) jump to noneg
	neg 	delta			; else delta = -delta
	ngc 	delta+1
	ngc 	delta+2
	ngc 	delta+3

noneg	addto 	delta, total		; total = total + delta
	adcto 	delta+1, total+1
	adcto 	delta+2, total+2
	adcto 	delta+3, total+3
	jmp 	arclop			; jump to next turn in arcloop
arcrtn	jmp 	0			; return to caller

	
; Division subroutine
div	clr	remainder		; clear reminder
	clr	remainder+1
	clr	remainder+2
	clr	remainder+3
	st	#-32, count		; walk through all 32 bits 
divlop	lsl	dividend		; left shift dividend...
	rol	dividend+1
	rol	dividend+2
	rol	dividend+3
	rol	remainder		; ... carry shifted into remainder
	rol	remainder+1
	rol	remainder+2
	rol	remainder+3
	rsbto	ldivisor, remainder	; subtract ldivisor from remainder
	rsbcto	ldivisor+1, remainder+1
	rsbcto	ldivisor+2, remainder+2	
	rsbcto	ldivisor+3, remainder+3	
	jcc	toomuch			; did not fit, goto toomuch

	lslo	quotient		; else left shift 1 into quotient.
	rol	quotient+1
	rol	quotient+2
	rol	quotient+3
	incjne	count, divlop		; if count!=0 goto divlop
	jmp	divend			; done. Jump to divend
toomuch	addto	ldivisor, remainder 	; add back ldivisor to remainder
	adcto	ldivisor+1, remainder+1 
	adcto	ldivisor+2, remainder+2 
	adcto	ldivisor+3, remainder+3 
	lsl	quotient	       ; left shift 0 into quotient
	rol	quotient+1
	rol	quotient+2
	rol	quotient+3	
	incjne	count, divlop		; run through the whole division
divend  outc 	#0x2e  			; print '.'
divrtn	jmp	0			; return to caller


;
; end of file

