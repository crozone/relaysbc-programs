; Prime Number Calculator
; Ryan Crosby 2018

; Run
	org 0x05
run	st	#0x02, sprimes_n	; Start prime search from 2
	st	#0x80, sprimes_i	; Write results into array starting at 0x80
	jsr	sprimes_ret, sprimes
	halt

; Prime Search Function
;
; Searches for prime numbers, starting at n.
; When primes are found, they are saved to an array starting at 0x80, and printed to console.
;
	org	0x10
sprimes_n	skip	1
sprimes_i	skip	1
sprimes	st	sprimes_n, isprime_n
	jsr	isprime_ret, isprime
	jne	isprime_res, sprimes_next
			; We have a prime, write the prime to memory and print to console
	st	sprimes_i, sprimes_ind ; Copy i pointer to store instruction
sprimes_ind	st	sprimes_n, 0
	st	sprimes_n, print_n
	jsr	print_ret, print	; Print number
	outc	#0x2C	; Print comma
	outc	#0x20	; Print space
	inc	sprimes_i
sprimes_next	incjne	sprimes_n, sprimes
sprimes_ret	jmp	0
	
; IsPrime Function
;
; Determines if n is prime using trial division.
; Returns 0 if prime, or the smaller factor of n if not.
;
isprime_n	skip	1	; The number to check for primeness
isprime_res	skip	1	; The result. 0 if n was prime, or smaller factor if not prime.
isprime_resb	skip	1	; Second result. 0 if n was prime, or larger factor if prime.
isprime_div	skip	1	; The current test divisor (i)
isprime_sqrt	skip	1	; The square root of n
isprime	rsbto	#0x02, isprime_n	; Check if the number is 2 or less, if so, return prime.
	jgt	isprime_n, isprime_gt2
	addto	#0x02, isprime_n	; Revert rsbto
	clr	isprime_res
	clr	isprime_resb
	jmp	isprime_ret	; Return prime.
isprime_gt2	addto	#0x02, isprime_n	; Revert rsbto
	jo	isprime_n, isprime_dodiv	; Check if the number is odd. If so, do division search.
	st	#0x02, isprime_res	; We have an even number, it is divisible by 2
	lsrto	isprime_n, isprime_resb	; The larger factor is just n / 2, or n >> 1.
	jmp	isprime_ret
isprime_dodiv	clr	isprime_res	; Clear the result, so in the case of a prime we can return directly.
	clr	isprime_resb	; Clear b result as well.
	st	#1, isprime_div	; Start dividing from 3 (starts at 1 but incremented by 2 on first isprime_2 loop)
	st	isprime_n, sqrt_n
	jsr	sqrt_ret, sqrt
	st	sqrt_res, isprime_sqrt
isprime_loop	rsbto	#2, isprime_sqrt	; Use sqrt as a loop coutner that counts down.
	jlt	isprime_sqrt, isprime_ret	; If loop counter < 0, isprime_div >= sqrt(n). We've exhausted all divisors and therefore have a prime.
	addto	#2, isprime_div		; i+=2 and do the next search
	st	isprime_n, div_dividend
	st	isprime_div, div_divisor
	jsr	div_ret, div
	jne	div_remainder, isprime_loop	; Check if remainder was 0. If it wasn't, we might still have a prime. Check next divisor.
	st	isprime_div, isprime_res	; Not a prime. Store smaller factor in res.
	st	div_quotient, isprime_resb	; Store larger factor in resb
isprime_ret	jmp	0

; Integer square root
sqrt_n	skip	1	; Find square root of this
sqrt_res	skip	1	; Result ends up here

sqrt	st	#0xFF, sqrt_res
sqrt_1	addto	#2, sqrt_res
	rsbto	sqrt_res, sqrt_n
	jcs	sqrt_1
	lsr	sqrt_res
sqrt_ret	jmp	0

; Divide

div_quotient	skip	1
div_remainder	skip	1
div_dividend	skip	1
div_divisor	skip	1
div_count	skip	1
div	clr	div_remainder
	st	#-8, div_count
div_lop	lsl	div_dividend
	rol	div_remainder
	rsbto	div_divisor, div_remainder
	jcc	div_toomuch
	lslo	div_quotient
	incjne	div_count, div_lop
	jmp	div_ret
div_toomuch	addto	div_divisor, div_remainder
	lsl	div_quotient
	incjne	div_count, div_lop
div_ret	jmp	0

; Print ASCII number (2 digits only!)
print_n	skip	1
print	st	print_n, div_dividend
	st	#0x0A, div_divisor
	jsr	div_ret, div
	addto	#0x30, div_quotient	; Convert left digit to ASCII number
	addto	#0x30, div_remainder	; Convert right digit to ASCII number
	outc	div_quotient	; Print left digit
	outc	div_remainder	; Print right digit
print_ret	jmp	0
	
