# Pi

Programs for calculating Pi to several decimal places.

## Attribution

`pi.asm`  - Dag Stroman, March 19 2019

https://sourceforge.net/p/relaysbc/discussion/general/thread/1c2390dc87/

`pi2.asm` - Dag Stroman, March 31 2019

https://sourceforge.net/p/relaysbc/discussion/general/thread/8de0dbedd4/

## Versions

### pi.asm

Source: `pi.asm`

Assembled: `pi.lst`

Calculates Pi to 8 decimal places using Machin's formula with 4 bytes of precision.

**Run from address 0x35**

**View results at address 0x23**

By monitoring address 'total' (0x23) during execution the intermediary results of arctan 
can be viewed. At completion, the value of pi in hex is also viewed there. The following
intermediate results should be displayed:

```
arctan(1/5):
  0x33333333
  0x32846ff5
  0x3288a1b2
  0x32888305
  0x328883f9
  0x328883f2
arctan(1/239):
  0x0112358e
  0x01123526
pi/16=arctan(1/5)-arctan(1/239)>>2:
  0x3243f6a9
```

Program outputs to TTL one '.' per round of division and a '!' when calculation is complete.
There are two divisions per round in arclop, so there will be two '.' per intermediary result.

The final result is converted to base 10 and printed to TTL:

```
> g 35
................!
pi=3.14259265
```

Program takes about 30 minutes to complete with moderate speed.

Due to the program's size, at cannot fit in EEPROM.

### pi2.asm

Source: `pi2.asm`

Assembled: `pi2.lst`

Calculates Pi to 13 decimal places using Machin's formula with 6 bytes precision.

**Run from 0x2d**

**View results at address 0x00**

By monitoring address of symbol 'pi' (0x00) during execution the sum of all intermediary results can be seen. 
The last 4 bytes the following intermediate results should be displayed:

```
0x333333333333			
0x32846ff513cc
0x3288a1b2fbf9
0x32888305546d
0x328883f9aa6b
0x328883f1ab54
0x328883f1f09d
0x328883f1ee37
0x328883f1ee4c
0x3243f68e50d8
0x3243f6a8886c
0x3243f6a8885a
```

Program outputs to TTL one '.' per round of division and a '!' when calculation is complete.
There are two divisions per round in arclop, so there will be two '.' per intermediary result.
The final result is converted to base 10 and printed to TTL:

```
> g 2d
........................!
pi=3.1415926535897
```

At completion, the decimal value of pi is also scrolled on the board display.

Program takes about 40 minutes to complete with moderate speed.

Please note that the program is NOT reentrant, ie you have to load the complete program into memory if and when you want to run it again.

Due to the program's size, at cannot fit in EEPROM.

#### Demo

This video shows the final calculation stage of `pi2.asm`, outputting Pi to both the serial console and the LCD display.

https://www.youtube.com/watch?v=yid_RYGp4x0
