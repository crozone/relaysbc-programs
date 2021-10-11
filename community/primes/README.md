# Primes

Programs written to perform a prime search.

`primes-hist.asm` is the best version so far.

## Versions:

### Primes-hist.asm
Source: `primes/primes-hist.asm`

Assembled:  `primes/primes-hist.lst`


Currently the fastest version of the prime number search. Comfortably fits within SRAM.

Any primes found are saved to an array starting at 0x80, and printed to the console in ASCII decimal form.

This version also has a feature that erases the prime array before starting the prime search.

**Run from address 0x01.**

**View primes starting at address 0x80.**

This method uses an optimised prime check function that doesn't require square root. Instead, it checks whether the current divisor is greater than or equal to the previous quotient found. If so, it knows that the current divisor is greater than the candidate's square root, without ever having to do a square root calculation.

The prime check function does not handle n = 2 as a special case for performance reasons. Instead the main function cheats by emitting 2 before the search loop.

The prime check function also uses a hysteresis prime array. By only dividing by primes that were previously found, the search space is significantly reduced.

The main outer loop tracks the decimal value of the prime candidate in parallel to avoid needing a hex to decimal conversion function.

### Primes.asm
Source: `primes/primes.asm`

Assembled:  `primes/primes.lst`


My original prime number search program.

Doesn't rely on any prime hysteresis table.

Any primes found are saved to an array starting at 0x80, and printed to the console in ASCII decimal form.

**Run from address 0x05**

**View primes starting at address 0x80**


The prime search uses the basic trial division algorithm with the square root optimisation.

Candidates are selected linearly from 2..255 with an outer loop.
Each candidate is then divided by all integers 3..sqrt(candidate) in an inner loop. As soon as a division returns with a remainder of 0, we know the number is not prime and it is skipped. If the loop completes without a 0 remainder division, the number is prime.

