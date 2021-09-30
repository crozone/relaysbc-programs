# Util

Utility functions and programs.

## Double-dabble

Source: `double-dabble.asm`

Assembled:  `double-dabble.lst`

**Run test program from address 0x10.**

The double-dabble function converts a hex byte into a 3 digit packed BCD spanning one and a half bytes.

The test program demonstrates the function by converting 243 into BCD using the `ddabble` function, before splitting out the nibbles and printing them individually as ASCII to the console.
