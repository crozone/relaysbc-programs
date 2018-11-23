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
	org	0x20
isprime_n	skip	1	; The number to check for primeness
isprime_res	skip	1	; The result
isprime_div	skip	1	; The current test divisor (i)
isprime_sqrt	skip	1	; The square root of n
isprime	jo	isprime_n, isprime_1	; Check if the number is odd. If so, do division search.			
	st	#2, isprime_res	; We have an even number, it is divisible by 2
	jmp	isprime_ret
isprime_1	clr	isprime_res	; Clear the result, so in the case of a prime we can return directly.
	st	#2, isprime_div	; Start dividing from 3 (starts at 2 but incremented by 1 on first isprime_2 loop)
	st	isprime_n, sqrt_n
	jsr	sqrt_ret, sqrt
	st	sqrt_res, isprime_sqrt
	rsb	isprime_sqrt, isprime_div	; Use isprime_sqrt as loop counter. isprime_sqrt = -isprime_sqrt + isprime_div
	dec	isprime_sqrt	; Since incjne increments before the check, we need to subtract one more
	jge	isprime_sqrt, isprime_ret	; If isprime_sqrt >= 0, the loop is already ended (the number is prime).
isprime_2	incjeq	isprime_sqrt, isprime_ret	; If loop counter = 0, isprime_div = sqrt(n). We've exhausted all divisors and therefore have a prime.
	inc	isprime_div		; i++ and do the next search
	st	isprime_n, div_dividend
	st	isprime_div, div_divisor
	jsr	div_ret, div
	jne	div_remainder, isprime_2	; Check if remainder was 0. If it wasn't, we might still have a prime. Check next divisor.
	st	div_quotient, isprime_res
isprime_ret	jmp	0

; Integer square root
	org	0x40
sqrt_n	skip	1	; Find square root of this
sqrt_res	skip	1	; Result ends up here

sqrt	st	#0xFF, sqrt_res
sqrt_1	addto	#2, sqrt_res
	rsbto	sqrt_res, sqrt_n
	jcs	sqrt_1
	lsr	sqrt_res
sqrt_ret	jmp	0

; Divide

        org     0x50
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
	org 0x70
print_n	skip	1
print	st	print_n, div_dividend
	st	#0x0A, div_divisor
	jsr	div_ret, div
	addto	#0x30, div_quotient	; Convert left digit to ASCII number
	addto	#0x30, div_remainder	; Convert right digit to ASCII number
	outc	div_quotient	; Print left digit
	outc	div_remainder	; Print right digit
print_ret	jmp	0
	
