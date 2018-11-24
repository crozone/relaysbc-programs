; Prime Number Calculator (with hysteresis)
; Ryan Crosby 2018

; Run
	org 0x05
run	st	#0x02, sprimes_n	; Start prime search from 2
	st	#0x80, sprimes_arrptr	; Write results into array starting at 0x80
	jsr	sprimes_ret, sprimes
	halt

; Prime Search Function
;
; Searches for prime numbers, starting at n.
; When primes are found, they are saved to an array, and printed to console.
;
	org	0x10
sprimes_n	data	0x00
sprimes_arrptr	data	0x00
sprimes_arrlen	data	0x00
sprimes	clr	sprimes_arrlen
	st	sprimes_arrptr, isprime_arrptr	; This never changes, so we don't need to copy it inside the loop.
sprimes_start	st	sprimes_n, isprime_n
	st	sprimes_arrlen, isprime_arrlen
	jsr	isprime_ret, isprime
	jne	isprime_res, sprimes_next
			; We have a prime, write the prime to memory and print to console
	st	sprimes_arrptr, sprimes_ind	; Prime store instruction with pointer
	addto	sprimes_arrlen, sprimes_ind	; Add extra offset to pointer
sprimes_ind	st	sprimes_n, 0	; Write prime to array
	inc	sprimes_arrlen	; arrlen++;
	st	sprimes_n, print_n
	jsr	print_ret, print	; Print number
	outc	#0x2C	; Print comma
	outc	#0x20	; Print space
sprimes_next	incjne	sprimes_n, sprimes_start
sprimes_ret	jmp	0
	
; IsPrime Function
;
; Determines if n is prime using trial division by the previous prime numbers.
; Returns 0 if prime, or the factors of n if not.
;
isprime_n	skip	1	; The number to check for primeness
isprime_arrptr	skip	1	; The address of the array of previous primes
isprime_arrlen	skip	1	; The length of the previous primes array
isprime_res	skip	1	; The result. 0 if n was prime, or smaller factor if not prime.
isprime_resb	skip	1	; Second result. 0 if n was prime, or larger factor if prime.
isprime_divi	skip	1	; The current test divisor index into arr
isprime_div	skip	1	; The value of the current divisor
isprime_sqrt	skip	1	; The square root of n
isprime	jo	isprime_n, isprime_1	; Check if the number is odd. If so, do division search.
	rsbto	#0x02, isprime_n
	jne	isprime_n, isprime_even
	addto	#0x02, isprime_n	; Special case for 2
	clr	isprime_res
	clr	isprime_resb
	jmp	isprime_ret
isprime_even	addto	#0x02, isprime_n	; Revert rsbto
	st	#0x02, isprime_res	; We have an even number, it is divisible by 2
	lsrto	isprime_n, isprime_resb	; The larger factor is just n / 2, or n >> 1.
	jmp	isprime_ret
isprime_1	clr	isprime_res	; Clear the result, so in the case of a prime we can return directly.
	clr	isprime_resb	; Clear b result as well.
	st	#1, isprime_divi	; Start from index 1, since index 0 is preloaded with 2 and we have already checked for even-ness.
	st	isprime_n, sqrt_n	; Find the square root of n. We never have to divide by more than this.
	jsr	sqrt_ret, sqrt
	st	sqrt_res, isprime_sqrt
isprime_2	rsbto	isprime_arrlen, isprime_divi	; Check if our index is above arrlen, and if so return prime.
	jge	isprime_divi, isprime_ret	; If isprime_divi >= isprime_arrlen, jump to return
	addto	isprime_arrlen, isprime_divi	; Revert rsbto
	st	isprime_arrptr, isprime_load	; Put pointer to current divisor into add below.
	addto	isprime_divi, isprime_load	; Add divisor index offset
	clr	isprime_div
isprime_load	add	isprime_div, 0	; Load current divisor into div
	inc	isprime_divi	; Incrememnt array index
	rsbto	isprime_sqrt, isprime_div	; Check if the current divisor is greater than sqrt(n), and if so return prime.
	jhi	isprime_div, isprime_ret	; If isprime_div > isprime_sqrt, jump to return.
	addto	isprime_sqrt, isprime_div	; Revert rsbto
	st	isprime_n, div_dividend	; Do division
	st	isprime_div, div_divisor
	jsr	div_ret, div
	jne	div_remainder, isprime_2	; Check if remainder was 0. If it wasn't, we might still have a prime. Check next divisor.
	st	isprime_div, isprime_res	; Remainder was 0, not a prime. Store smaller factor in res.
	st	div_quotient, isprime_resb	; Store larger factor in resb
isprime_ret	jmp	0	; Return.

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
	
