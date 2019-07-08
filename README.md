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

Prime search programs are found in `primes/`

See `primes/README.md` for details.

