# Relaysbc-programs
Programs written for Joe Allen's Relay Trainer single board relay computer.

## Helper methods:

### Double-dabble
Source: `double-dabble/double-dabble.asm`

Assembled:  `double-dabble/double-dabble.lst`

**Run test program from address 0x10.**

The double-dabble function converts a hex byte into a 3 digit packed BCD spanning one and a half bytes.

The test program demonstrates the function by converting 243 into BCD using the `ddabble` function, before splitting out the nibbles and printing them individually as ASCII to the console.

## Primes

### Primes-fast.asm
Source: `primes/primes.asm`

Assembled:  `primes/primes.lst`


The fastest version of the prime number search. Comfortably fits within SRAM.

Any primes found are saved to an array starting at 0x80, and printed to the console in ASCII decimal form.

This version also has a feature that erases the prime array before starting the prime search.

**Run from address 0x02.**

**View primes starting at address 0x80.**

This method uses an optimised prime check function that doesn't require square root. Instead, it checks whether the current divisor is greater than or equal to the previous quotient found. If so, it knows that the current divisor is greater than the candidate's square root, without ever having to do a square root calculation.

The prime check function does not handle n = 2 as a special case for performance reasons. Instead the main function cheats by emmiting 2 before the search loop.

The prime check function also uses a hysteresis prime array (like `primes-hist.asm`) to reduce the search space.

The main outer loop tracks the decimal value of the prime candidate in parallel to avoid needing a hex to decimal conversion function.

### Primes.asm
Source: `primes/primes.asm`

Assembled:  `primes/primes.lst`


My original prime number search program.

Doesn't rely on any prime hysteresis table, and uses a simple division method to print output.

Any primes found are saved to an array starting at 0x80, and printed to the console in ASCII decimal form.

**Run from address 0x05**

**View primes starting at address 0x80**


The prime search uses the basic trial division algorithm with the square root optimisation.

Candidates are selected linearly from 2..255 with an outer loop.
Each candidate is then divided by all integers 3..sqrt(candidate) in an inner loop. As soon as a division returns with a remainder of 0, we know the number is not prime and it is skipped. If the loop completes without a 0 remainder division, the number is prime.

### Primes-hist.asm
Source: `primes/primes-hist.asm`

Assembled:  `primes/primes-hist.lst`

Uses a hysteresis table of previously found primes to speed up the division search.

Any primes found are saved to an array starting at 0x80, and printed to the console in ASCII decimal form.

**Run from address 0x05**

**View primes starting at address 0x80**

### Primes-hist-huge.asm
Source: `primes/primes-hist-huge.asm`

Assembled:  `primes/primes-hist-huge.lst`

The same as primes-hist, but uses the double-dabble algorithm to print the result.

This makes the code rather huge, so it won't fit in SRAM.

Any primes found are saved to an array starting at 0xA0, and printed to the console in ASCII decimal form.

**Run from address 0x01**

**View primes starting at address 0xA0**
