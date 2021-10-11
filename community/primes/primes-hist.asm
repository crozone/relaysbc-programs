; Prime Number Calculator (with hysteresis)
; Ryan Crosby 2018 - 2021
;
; Run from 0x01.
;
; Primes will be saved to an array at 0x80 (by default). To change this address, change the value of 0x02.
; Primes will also be written to the serial console in decimal ASCII form.
;

; Constants
;
SPACE_CHAR	equ	0x20
COMMA_CHAR	equ	0x2C
ZERO_CHAR	equ	0x30

; Catch for any indirect jumps to null (0x00).
; Also use this as a temporary variable
;
	org	0x00
tmp	halt

; Configure the location for the primes destination array.
;
	org	0x01

; ENTRY POINT
	org	0x01
exec	jmp	run	; Jump to start of program

	org	0x02
arr_start	data	0x80

; Run. Main program starts here.
run	st	arr_start,	clrp_arrhead	; Erase from array start
	jsr	clrp_ret,	clrp	; Erase primes array
	st	arr_start,	sprimes_arrptr	
	jsr	sprimes_ret,	sprimes	; Start finding primes
run_ret	jmp	0

; Clear primes array function. This zeroes the primes array until it hits a 0x00.
;
clrp_tmp	skip	1		; Needed for indirect load
clrp
clrp_loop	clr	clrp_tmp		; Prep tmp for load
clrp_arrhead	add	clrp_tmp,	0	; Load value from array head
	jeq	clrp_tmp,	clrp_ret	; Stop as soon as we hit a 0x00 in the array
	st	clrp_arrhead,	clrp_ind
clrp_ind	clr	0		; Current array head is not 0x00, so clear it
	incjne	clrp_arrhead,	clrp_loop	; Increment array head pointer and loop
clrp_ret	jmp	0		; Return

; Prime Search Function
;
; Searches for prime numbers, starting at n.
; When primes are found, they are saved to an array, and printed to console.
;
; In order to save memory and reduce copying, we use the variables on isprime as state storage rather than tracking them at the start of this function.
;
sprimes_arrptr	skip	1		; Pointer to the location of the primes array
sprimes_arrhead	skip	1		; Pointer to the head of the primes array
	
	; We're about to cheat by pre-populating 2 into the start of the primes array and printing it as if we found it.
	; 2 is the only even prime, which makes checking for it inside the loop costly.
	; By pre-printing it we get some significant performance gains.
sprimes	st	sprimes_arrptr,	sprimes_arrhead
	st	sprimes_arrhead,	sprimes_stind1	; Prep indirect store into [sprimes_arrptr]
sprimes_stind1	st	#2,	0	; Write 2 to the start of the primes array.
	inc	sprimes_arrhead		; Increment the head by 1

	outc	#ZERO_CHAR+2		; Print 2 to console.
	outc	#COMMA_CHAR		; Print comma
	outc	#SPACE_CHAR		; Print space
	
	; Prep the decimal prime print function
	st	#3, dec_out_val+0
	clr	dec_out_val+1
	clr	dec_out_val+2

	; Prep the isprime function
	st	#3,	isprime_n	; Start the prime search from three, since we've already found 2.
	st	sprimes_arrptr,	isprime_arrptr	; The array pointer never changes in the loop, so we only need to copy it once.
	
	; Start the main prime search loop.
sprimes_start	jsr	isprime_ret,	isprime	; Check if the current isprime_n is prime.
	jne	isprime_res,	sprimes_next	; Move onto the next test number if we didn't find a prime.
	
	; We have a prime, write the prime to memory and print to console.
	st	sprimes_arrhead,	sprimes_stind2	; Prime store instruction with pointer
sprimes_stind2	st	isprime_n,	0	; Write prime to array
	inc	sprimes_arrhead		; Increment array head
	jsr	dev_out_print_ret,	dev_out_print	; Print prime to console
	outc	#COMMA_CHAR		; Print comma
	outc	#SPACE_CHAR		; Print space


sprimes_next	addto	#2,	isprime_n	; Increment the prime candidate. Jump by 2 to skip even numbers that can't be prime.
	jcs	sprimes_ret		; If we overflowed the test prime (carry set), stop testing.
	jsr	dev_out_inc2_ret,	dev_out_inc2	; Increment decimal value of prime candidate by 2.
	jmp	sprimes_start		; Jump back to start of loop.
sprimes_ret	jmp	0		; Return to the calling function.

; Fast IsPrime Function with hysteresis
;
; Determines if n is prime using trial division by the previous prime numbers, up to the square root of n.
; Returns isprime_res = 0 if prime, or the factors of n if not (isprime_res and isprime_resb)
;
; For speed: Does not handle n = 2.
;            2 is prime, but the cost of doing a special case check 2 it is avoided. Check for n = 2 before calling this function.
;
isprime_n	skip	1		; The number to check for primeness
isprime_arrptr	skip	1		; The address of the array of previous primes
isprime_res	skip	1		; The result. 0 if n was prime, or smaller factor if not prime.
isprime_resb	skip	1		; Second result. 0 if n was prime, or larger factor if prime.
isprime_arri	skip	1		; The current test divisor index into arr
isprime_div	skip	1		; The value of the current divisor
isprime	jo	isprime_n,	isprime_start	; Check if the number is odd. If so, do division search. Technically we don't need to do this, but it's only one instruction.
	st	#0x02,	isprime_res	; We have an even number, it is divisible by 2
	lsrto	isprime_n,	isprime_resb	; The larger factor is just n / 2, or n >> 1.
	jmp	isprime_ret		; Return.
isprime_start	clr	isprime_res		; Clear the result, so in the case of a prime we can return directly.
	clr	isprime_resb		; Clear b result as well.
	st	#0xFF,	div_quotient	; We need this to start from largest number for sqrt check below.
	st	#1,	isprime_arri	; Start from index 1, since index 0 is preloaded with 2. We already know n is not even, so no point dividing by 2.

	; Load divisor out of array from current arri index.
isprime_loop	st	isprime_arrptr,	isprime_ld	; Put pointer to current divisor into add below.
	addto	isprime_arri,	isprime_ld	; Add divisor index offset
	clr	isprime_div		; Prepare to do an indirect load with add. For this, destination must be 0.
isprime_ld	add	isprime_div,	0	; Load current divisor from arri into div
	jeq	isprime_div,	isprime_ret	; Return if the divisor is 0. If it's 0, we have reached the end of the divisor array (zero terminated)
	
	; Sqrt check:
	;
	; We now need to check whether our divisor is greater than the square root of our prime candidate.
	; If it is, we know that the number is prime, and we can short circuit out of this function.
	; The trick for doing this is to check whether our current divisor is greater than or equal to the last quotient found.
	rsbto	isprime_div,	div_quotient
	jls	div_quotient,	isprime_ret	; Return.

	inc	isprime_arri		; Incrememnt array index
	
	; Prepare to do division check
	st	isprime_n,	div_dividend	; Do division
	st	isprime_div,	div_divisor
	jsr	div_ret,	div	; Do division
	jne	div_remainder,	isprime_loop	; Check if remainder was 0. If it wasn't, we might still have a prime. Check next divisor.

	; The candidate is not prime.
	st	isprime_div,	isprime_res	; Remainder was 0, not a prime. Store smaller factor in res.
	st	div_quotient,	isprime_resb	; Store larger factor in resb
isprime_ret	jmp	0		; Return.

; Divide
;
div_quotient	skip	1
div_remainder	skip	1
div_dividend	skip	1
div_divisor	skip	1
div_count	skip	1
div	clr	div_remainder
	st	#-8,	div_count
div_lop	lsl	div_dividend
	rol	div_remainder
	rsbto	div_divisor,	div_remainder
	jcc	div_toomuch
	lslo	div_quotient
	incjne	div_count,	div_lop
	jmp	div_ret
div_toomuch	addto	div_divisor,	div_remainder
	lsl	div_quotient
	incjne	div_count, 	div_lop
div_ret	jmp	0

; Track decimal representation of the prime for fast printing
;
; [0] - ones digit
; [1] - tens digit
; [2] - hundreds digit
;
dec_out_val	skip	3

; Increment by 2 function.
;
; This function increments the above decimal representation by 2 every time it is run.
;
dev_out_inc2	rsbto	#8,	dec_out_val+0	; Subtract 8 to test if we're about to overflow the ones digit.
	jge	dec_out_val+0,	dev_out_overflow_0	; If (([0] + 2) - 10) < 0, we have overflowed the ones digit [0].
	addto	#10,	dec_out_val+0	; No overflow, add 10 on to increment by 2 overall
dev_out_inc2_ret	jmp	0		; Return subroutine

dev_out_overflow_0	rsbto	#9,	dec_out_val+1	; We had an overflow, subtract 9 to test if we're about to overflow.
	jge	dec_out_val+1,	dev_out_overflow_1	; I (([1] + 1) - 10) < 0, we have overflowed the tens digit.
	addto	#10,	dec_out_val+1	; No overflow on tens yet, add 10 to increment by 1 overall
	jmp	dev_out_inc2_ret		; Return
dev_out_overflow_1	inc	dec_out_val+2		; Increment the hundreds digit and return. Don't bother to overflow check hundreds digit.
	jmp	dev_out_inc2_ret		; Return

; Print function.
;
; This function prints the above decimal representation to the console. It handles the conversion to ASCII characters internally.
;
dev_out_print	jeq	dec_out_val+2,	dev_out_print_1	; Skip printing leading zero
	addto	#ZERO_CHAR,	dec_out_val+2	; Convert to ASCII character
	outc	dec_out_val+2		; Print hundreds digit
	rsbto	#ZERO_CHAR, dec_out_val+2		; Revert ASCII conversion
dev_out_print_1	jne	dec_out_val+1,	dev_out_print_1_a
	jne	dec_out_val+2,	dev_out_print_1_a
	jmp	dev_out_print_0		; Skip printing leading zero if this and previous digit was zero
dev_out_print_1_a	addto	#ZERO_CHAR,	dec_out_val+1
	outc	dec_out_val+1
	rsbto	#ZERO_CHAR,	dec_out_val+1
dev_out_print_0	addto	#ZERO_CHAR,	dec_out_val+0
	outc	dec_out_val+0
	rsbto	#ZERO_CHAR,	dec_out_val+0
dev_out_print_ret	jmp	0

