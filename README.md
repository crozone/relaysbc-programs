# Relaysbc-programs
Programs written for Joe Allen's Relay Trainer single board relay computer.

## Primes.asm
Source: `primes/primes.asm`

Image:  `primes/primes.ram`


A prime number searching program.


Run from address 0x05.

View primes starting at address 0x80.


The prime search uses the basic trial division algorithm with the square root optimisation.

Candidates are selected linearly from 2..255 with an outer loop.
Each candidate is then divided by all integers 3..sqrt(candidate) in an inner loop. As soon as a division returns with a remainder of 0, we know the number is not prime and it is skipped. If the loop completes without a 0 remainder division, the number is prime.

Any primes found are saved to an array starting at 0x80, and printed to the console in ASCII decimal form.

Function addresses:

```
run = 0x05
sprimes = 0x12
isprime = 0x24
div = 0x55
sqrt = 0x42
print = 0x71
```
