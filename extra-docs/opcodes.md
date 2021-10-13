# OP CODES

![sbrc block diagram](sbrc-block.gif)

| Value | OP CODE | Operation | Description |
| --- | --- | --- | --- |
| 0x00010000 | CC_N | Condition Code Negative | Jump if ALU A data is negative (A data bit 7 is set) |
| 0x00020000 | CC_Z | Condition Code Zero | Jump if ALU carry output is set (overflow condition). Used to test A data for zero (by complementing A data and add 1 via carry invert). Used to test for increment wrap around to zero. |
| 0x00040000 | CC_C | Condition Code Carry | Jump if carry register is clear. |
| 0x00080000 | CC_INV | Condition Code Invert | Invert the result of the jump condition check |
| 0x00100000 | CEN | Carry Enable | The current value of the carry register is fed into the ALU carry input. |
| 0x00200000 | CINV | Carry Invert | The carry input of the ALU is inverted. |
| 0x00400000 | COM | Complement | 1's complement, aka invert bits. ALU A data input. |
| 0x00800000 | BEN | B enable | Enable ALU B data input. If not enabled, ALU B data is 0. |
| 0x01000000 | AND | Bitwise AND | Switch ALU mode from ADD to AND. ALU output becomes the bitwise AND of ALU A data and ALU B data. |
| 0x02000000 | ROR | Rotate Right | Rotates the ALU output right by 1 bit. ALU carry output is moved into bit 7. Bit 0 is stored in the carry register. |
| 0x04000000 | JSR | Jump to Subroutine | CPU write data becomes the next instruction address [PC + 1]. This opcode in itself does not actually trigger a jump, that is handled by CC flags. |
| 0x08000000 | WRB | Write to B | Instructs the memory controller to store CPU write data in the B address. |
| 0x10000000 | OUT | Output enable | Write ALU output to output port. |
| 0x20000000 | IN | Input enable | Replace lower 4 bits of A input data with data from input port. |
| 0x40000000 | IMM | Immediate | Instructs the memory controller to output the literal value of the instruction A address as the A data. |
| 0x80000000 | WRA | Write to A | Instructs the memory controller to store CPU write data in the A address. |

### Condition Code detail

JUMP &equiv; CC_INV &oplus; &lpar; CC_N &and;  A_DATA.7 &or; CC_Z &and; ALU_CARRY_OUT &or; CC_C &and; &not;CARRY_FLAG &rpar;

If the result of the condition code check is true, the CPU will write the B address (the literal value of B, *not* "B data") to the program counter, causing the CPU to jump.
