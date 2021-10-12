# Magic Instructions
Author: Ryan Crosby

## Preface

The single board relay computer uses a PIC microcontroller to implement the memory interface, clock control, and serial input/output. There are a few instructions which require explicit handling by the PIC to work, these are the "magic instructions" which are not implemented within the CPU itself.

All magic instructions have one thing in common: The WRA and WRB flags are both set. Writing back to both address A and address B is an illegal instruction, so the PIC traps these as special requests.

The instruction is AND'd against the bitmask 0xB8000000 (WRA & WRB & IN & OUT), and then checked for a specific value. All other bits within the instruction are ignored for the purpose of the special handling, and the instruction is otherwise still executed by the CPU as per usual.

## Instructions (canonical)

| OP CODE | Flags | Mnemonic | Operation |
| --- | --- | --- | --- |
| C810_FF00 | WRA, WRB | HALT | Halt CPU |
| E800_00bb | WRA, WRB, IN | INWAIT bb | Halt until input port changes or keypad or serial console character available. Save data to bb. |
| 9800_aa00 | WRA, WRB, OUT | OUTC aa | Print [aa] to console serial port |
| D800_aa00 | WRA, WRB, OUT | OUTC #aa | Print aa to console serial port. |

### HALT

The PIC checks for the condition:

```c
(current_insn & 0xB8000000) == 0x88000000
```

HALT &equiv; WRA &and; WRB &and; &not;IN &and; &not;OUT

If true, the clock is halted.

### INWAIT

The PIC checks for the condition:

```c
(current_insn & 0xB8000000) == 0xA8000000
```

INWAIT &equiv; WRA &and; WRB &and; IN &and; &not;OUT

If true, the clock is halted, and the PIC polls waiting for either the CPU data output to change (with debounce), or for a serial character to be read on the serial port. Then, it saves the value to [bb].

### OUTC

The PIC checks for the condition:

```c
(current_insn & 0xB8000000) == 0x98000000
```

OUTC &equiv; WRA &and; WRB &and; &not;IN &and; OUT

If true, writes the value of the CPU data output as a character to the serial port.

### UNUSED

There is one more magic instruction available but unused:

```c
(current_insn & 0xB8000000) == 0xB8000000
```

HALT &equiv; WRA &and; WRB &and; IN &and; OUT

Currently the behaviour of this instruction is undefined. In the current PIC code, if trace is enabled, it is treated like OUTC. If trace is disabled, it is treated like a NOP.

## Bit reference

| OP CODE | Operation |
| --- | --- |
| 0x00010000 | CC_N |
| 0x00020000 | CC_Z  |
| 0x00040000 | CC_C |
| 0x00080000 | CC_INV |
| 0x00100000 | CEN |
| 0x00200000 |CINV|
| 0x00400000 |COM|
| 0x00800000 |BEN|
| 0x01000000 |AND|
| 0x02000000 |ROR|
| 0x04000000 |JSR|
| 0x08000000 |WRB|
| 0x10000000 |OUT|
| 0x20000000 |IN|
| 0x40000000 |IMM|
| 0x80000000 |WRA|

