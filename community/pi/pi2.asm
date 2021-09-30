; Calculate pi using Machin's formula v2.0
; Dag Stroman, March 31 2019
;
;
; Machin's formula:
;   pi/4=4*arctan(1/5)-arctan(1/239)
; where
;   arctan=(1/x)=1/x-1/3*x**3+1/5*x**5-...
;
; Rewriten to be pi/16=arctan(1/5)-arctan(1/239)/4. 
;
; The divide by 4 is included in the initial value of the second arctan parameters. Having the result in format
; pi/16 is very nice since it is the same as pi/0x10 meaning that the binary result needs
; no further transformation in order to be used in binary to decimal conversion.
;
; Changes since 1.0:
; - Several optimizations to save space, allowing for the other improvements below.
; - Two bytes increased precision, equal 5 additional decimal digits.
; - During calculations the last 4 bytes of the sum of all factors of the taylor series (ie the progress of the pi calculation) is viewed at 0x00.
; - Transform from binary to decimal improved when printing result. X*10 is now done as X<<3+X<<1 (ie 8x+2x). This is smaller and faster.
; - Division loop improved to skip some unnecessary subtraction. This saves about 25 minutes of calculation time. 
; - The resulting decimal value of pi is now also scrolled on the board memory display (at 0x00).
;
; Program start is at 0x2d and use all of board memory.
; 
; By monitoring address of symbol 'pi' (0x00) during execution the sum of all intermediary results can be seen. 
; The last 4 bytes the following intermediate results should be displayed:
;
; 0x333333333333			
; 0x32846ff513cc
; 0x3288a1b2fbf9
; 0x32888305546d
; 0x328883f9aa6b
; 0x328883f1ab54
; 0x328883f1f09d
; 0x328883f1ee37
; 0x328883f1ee4c
; 0x3243f68e50d8
; 0x3243f6a8886c
; 0x3243f6a8885a
;
; Program output to TTL one '.' per round of division and a '!' when
; calculation is complete. There are two divisions per round in arclop, so there will be
; two '.' per intermediary result. The final result is converted to base 10 and printed
; to TTL:
;
;    > g 2d
;    ........................!
;    pi=3.1415926535897
;
; At completion, the decimal value of pi is also scrolled on the board dísplay.
;
; Program takes about 40 minutes to complete with moderate speed.
; Please note that the program is NOT reentrant, ie you have to load the complete program into memory if and when you want to run it again.
;
; Below is some c-code that roughly corresponds to the assembly program:
;
; #include <stdio.h>
; long pi =   0x333333333333;
; long x_sq = 0x000000000019;
; long adivisor = 0x0000000001;
; long power = 0x333333333333;
; char negate = 0; 
; long quotient;
; int arctan() {
;   while (1){
;     negate = ~negate;
;     adivisor +=2;
;     power = power/x_sq;
;     quotient = power / adivisor;
;     if (quotient == 0) {
;       break;
;     }
;     if (negate) {
;       quotient = -quotient;
;     }
;     pi += quotient;
;   }
;   return (0);
; }
; int main() {
;   arctan();
;   power = 0x00448d639d74;
;   pi -= power;
;   x_sq = 0x00000000df21;
;   adivisor = 1;
;   negate = 1;
;   arctan();
;   printf("pi=0x%012lx\n",pi);
; }  
;
;
; Some variables used by main	
       org 0x00
pi		data 0x33	; Init with 0x100000000/5
		data 0x33
		data 0x33
		data 0x33
		data 0x33
		data 0x33
char		skip 1
	
; Variables used by Long Divide
count	    	skip 1
quotient    	skip 6
remainder   	skip 6
ldivisor    	skip 6

; Variables used by the arctan loop
; precalculation of power=one/x=0x0100000000/5=0x333333333333.	
; This will put the fixed decimal point in after the MSB nibble. 
power	    	data 0x33 
		data 0x33	
		data 0x33	
		data 0x33	
		data 0x33	
		data 0x33	

; x_sq=x*x=5*5=0x00000019
x_sq		data 0x19
		data 0x00
		data 0x00
		data 0x00
		data 0x00
		data 0x00
; adivisor = 1	
adivisor 	data 0x01
		data 0x00
		data 0x00
		data 0x00
		data 0x00
		data 0x00
	
; negate = 0	
negate  	data 0x00

; main 

main
	jsr	arcrtn,arclop		; arctan(1/5)
; Set variables for next round of arctan 
; precalculation of power=one/x=0x0100000000/239/4=0x00448d639374
	st	#0x74, power	
	st	#0x9d, power+1
	st	#0x63, power+2
	st	#0x8d, power+3
	st	#0x44, power+4
	st	#0x00, power+5
	rsbto	power, pi		; subtract this first factor from pi.
	rsbcto	power+1,pi+1
	rsbcto	power+2,pi+2
	rsbcto	power+3,pi+3
	rsbcto	power+4,pi+4
	rsbcto	power+5,pi+5
	st	#x_sq, clrptr		; x_sq=0
	jsr	clrrtn,clrreg
	st	#0x21, x_sq		; x_sq=239*239
	st	#0xdf, x_sq+1
	st	#adivisor,clrptr	; adivisor = 0
	jsr	clrrtn,clrreg
	st	#1, adivisor		; adivisor = 1
	st	#0xFF, negate		; ch sign for this turn
	jsr	arcrtn,arclop		; arctan(1/239)
	st	pi,quotient
	st	pi+1,quotient+1		; keep copy of pi, quotient is free and can be used.
	st	pi+2,quotient+2
	st	pi+3,quotient+3
	st	pi+4,quotient+4
	st	pi+5,quotient+5
	st	#pi, clrptr
	jsr	clrrtn, clrreg		; put 00:s into display...
	st 	#x_sq, clrptr
	jsr	clrrtn, clrreg		; ...and tmp storage
	outc 	#0x21			; Calculations done. Output '!'			
	outc 	#0x0a			; CR/LF
	outc 	#0x0d
        outc 	#0x70			; "pi="
	outc 	#0x69
	outc 	#0x3d
	st 	#-15, count		; Print 14 base10 digits
	st	#-1, negate		; Used to keep track of when to print '.'
print
	incjeq  count, end		; jump to end ++count!=0jump to print when done
	st 	quotient+5,char		; get MSB  
	andto 	#0xf0,char		; Get MSB nibble. This will be 0x30 first time.
	st 	#-4, power
lab4	lsl	char
	rol	x_sq			; shift this decimal (four bits, one nibble) into decimal result (kept in x_sq).
	rol	x_sq+1
	rol	x_sq+2
	rol	x_sq+3
	rol	x_sq+4
	rol	x_sq+5
	incjne	power, lab4
	st 	x_sq,pi			; and then update the display with decimal value.
	st 	x_sq+1,pi+1
	st 	x_sq+2,pi+2
	st 	x_sq+3,pi+3
	st 	x_sq+4,pi+4
	st 	x_sq+5,pi+5
	st 	quotient+5,char		; get MSB again  
	andto 	#0xf0,char		; Get MSB nibble again. 
	andto 	#0x0f,quotient+5	; Mask of MSB nibble from pi.
	lsr 	char			; Shift down (ie 0x30 -> 0x03)
	lsr 	char			
	lsr 	char
	lsr 	char	
	addto 	#0x30,char		; Make it ascii number
	outc 	char			; print
	incjne 	negate,nopnt		; If not, goto  nopnt
	outc 	#0x2e			; else print '.'

; pi = pi * 10.
nopnt
	jsr	rolrtn,rolquot	    	; *2
	st      quotient, remainder	; store this, remainder is available
        st      quotient+1, remainder+1
        st      quotient+2, remainder+2
        st      quotient+3, remainder+3
        st      quotient+4, remainder+4
        st      quotient+5, remainder+5
	jsr	rolrtn,rolquot	    	; *2
	jsr	rolrtn,rolquot	    	; *2
	addto	remainder, quotient	; and add 2pi, making it *10
	adcto 	remainder+1,quotient+1
	adcto 	remainder+2,quotient+2
	adcto	remainder+3,quotient+3	
	adcto	remainder+4,quotient+4	
	adcto	remainder+5,quotient+5	
	jmp	print
end	outc 	#0x0a			; CR/LF
	outc 	#0x0d
	halt				; Done!

; subroutine clear register 
clrreg	st #-6,count
clrptr	clr 0
	inc clrptr
	incjne count,clrptr
clrrtn	jmp 0
	
	
; subroutine left roll of quotient
rolquot	lsl	quotient		; *2
	rol	quotient+1
	rol	quotient+2
	rol	quotient+3
	rol	quotient+4
	rol	quotient+5	
rolrtn	jmp 0


; this is the while loop of the arctan. See C-code for more info.
arclop   
	st	x_sq,ldivisor		; ldivisor = x_sq
	st	x_sq+1,ldivisor+1
	st	x_sq+2,ldivisor+2
	st	x_sq+3,ldivisor+3
	st	x_sq+4,ldivisor+4
	st	x_sq+5,ldivisor+5

	jsr	divrtn, div		; quotient = power/x_sq

	st 	quotient, power		; power = quotient 
	st	quotient+1, power+1
	st	quotient+2, power+2
	st	quotient+3, power+3
	st	quotient+4, power+4
	st	quotient+5, power+5

	com 	negate			; negate = ~negate;
	
	addto	#0x02,adivisor		; adivisor +=2
	adcto 	#0x00,adivisor+1
	adcto 	#0x00,adivisor+2
	adcto 	#0x00,adivisor+3
	adcto 	#0x00,adivisor+4
	adcto 	#0x00,adivisor+5	

	st	adivisor,ldivisor	; ldivisor=adivisor
	st	adivisor+1,ldivisor+1
	st	adivisor+2,ldivisor+2
	st	adivisor+3,ldivisor+3
	st	adivisor+4,ldivisor+4
	st	adivisor+5,ldivisor+5

	jsr	divrtn, div		; quotient=power/adivisor
					; delta = quotient 

	jne	quotient, cont		; if (delta!=0) jump to cont
	jne	quotient+1,cont
	jne	quotient+2,cont
	jne	quotient+3,cont
	jne	quotient+4,cont
	jne	quotient+5,cont
	jmp 	arcrtn			; else we are done. Jump to arcrtn.
	
cont    jeq	negate, noneg		; if (negate==0) jump to noneg
	neg 	quotient			; else delta = -delta
	ngc 	quotient+1
	ngc 	quotient+2
	ngc 	quotient+3
	ngc 	quotient+4
	ngc 	quotient+5

noneg	addto 	quotient, pi		; pi = pi + quotient
	adcto 	quotient+1, pi+1
	adcto 	quotient+2, pi+2
	adcto 	quotient+3, pi+3
	adcto 	quotient+4, pi+4
	adcto 	quotient+5, pi+5
	jmp 	arclop			; jump to next turn in arcloop
arcrtn	jmp 	0			; return to caller

	
; Division subroutine
	;; out: remainder.
	;; out: quotient.
	;; in:    power (dividend)
	;; in:   ldivisor.
div	st      #remainder,clrptr	; clear reminder
	jsr	clrrtn, clrreg
	st      #quotient,clrptr	; clear quotient
	jsr	clrrtn, clrreg
	st	#-48, count		; walk through all 48 bits 
	st	#0xFF,char		; char used as flag
lab7	jne	power+5, divlop		; if MS byte != 0 then start divide.
	st 	power+4, power+5	; else avoid spending time on unnecessary subtraction attempts; shift divisor one byte.
	st 	power+3, power+4
	st 	power+2, power+3
	st 	power+1, power+2
	st 	power, power+1
	clr	power
	addto	#7,count
	incjeq	count, divend		; If count is zero here then dividend was zero. Skip division. 
	jmp lab7			; Check next byte and see if that is zero
divlop  ntoc	power+5			; get MS bit into carry so dividend preserved when shifted 48 times.
	rol	power			; left shift dividend...
	rol	power+1
	rol	power+2
	rol	power+3
	rol	power+4
	rol	power+5
	rol	remainder		; ... carry shifted into remainder
	rol	remainder+1
	rol	remainder+2
	rol	remainder+3
	rol	remainder+4
	rol	remainder+5

	jeq  	char, lab8	; if first bit has shifted into remainder goto lab8
	je	remainder, notyet ; no bit set in remainder. We dont even have to try subtraction.
	clr	char		; now first bit is in remainder. Clear flag and try subtraction. 
	
lab8	rsbto	ldivisor, remainder	; subtract ldivisor from remainder
	rsbcto	ldivisor+1, remainder+1
	rsbcto	ldivisor+2, remainder+2	
	rsbcto	ldivisor+3, remainder+3	
	rsbcto	ldivisor+4, remainder+4	
	rsbcto	ldivisor+5, remainder+5	
	jcc	toomuch			; did not fit, goto toomuch

	lslo	quotient		; else left shift 1 into quotient.
	rol	quotient+1
	rol	quotient+2
	rol	quotient+3	
	rol	quotient+4	
	rol	quotient+5	
	incjne	count, divlop		; run through the whole division
	jmp	divend
toomuch	addto	ldivisor, remainder 	; add back ldivisor to remainder
	adcto	ldivisor+1, remainder+1 
	adcto	ldivisor+2, remainder+2 
	adcto	ldivisor+3, remainder+3 
	adcto	ldivisor+4, remainder+4 
	adcto	ldivisor+5, remainder+5 
notyet	lsl	quotient	       ; left shift 0 into quotient
	rol	quotient+1
	rol	quotient+2
	rol	quotient+3	
	rol	quotient+4	
	rol	quotient+5	
	incjne	count, divlop		; run through the whole division
divend	outc 	#0x2e  			; print '.'
divrtn	jmp	0			; return to caller

;
; end of file

