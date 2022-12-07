# Extra Instructions
Author: Ryan Crosby

## Preface

The single board relay computer does not use a predefined set of encoded instructions.
Instead, it uses wide instructions with 16 bits of flags, each of which trigger certain functionality within the CPU and/or memory controller.
As a result, an instruction decoder is not required, which saves the need for additional relay logic.

An additional benefit of this design is the flexibility it affords in controlling the CPU behaviour.
The instructions listed in the reference card and design documentation are only a few of the instructions that can possibly be run on the relay computer.

This document is an attempt to record some additional useful instructions which are not included in the original documentation.

## Instructions

If an instruction is "bb free", the bb value is not used at all. This allows the instruction to also be used as variable storage without affecting its behaviour.

| OP CODE   | Mnemonic (unofficial) | Operation               | bb free |
| --------- | -------------- | ------------------------------ | --- |
| C080_aabb | imadd aa bb    | aa + [bb] &rarr; [aa]          | No  |
| C180_aabb | imand aa bb    | aa & [bb] &rarr; [aa]          | No  |
| 8180_aabb | and aa bb      | [aa] & [bb] &rarr; [aa]        | No  |
| 8100_aa00 | clra aa        | 0 &rarr; [aa]                  | Yes |
| 8020_aa00 | inca aa        | [aa] + 1 &rarr; [aa]           | Yes |
| 0820_aabb | incto aa bb    | [aa] + 1 &rarr; [bb]           | No  |
| 00C0_aabb | altbtoc aa bb  | [aa] < [bb] &rarr; C           | No  |
| 00E0_aabb | alebtoc aa bb  | [aa] <= [bb] &rarr; C          | No  |
| 80D0_aabb | rsbc aa bb     | [bb] - [aa] - ~C &rarr; [aa]   | No  |
| 81C0_aabb | bic aa bb      | ~[aa] & [bb] &rarr; [aa]       | No  |
| 0808_aabb | stjmp aa bb    | [aa] &rarr; [bb], bb &rarr; PC | No  |
| 9808_aabb | outcjmp aa bb  | [aa] &rarr; serial console, bb &rarr; PC | No |
| 820A_aabb | lsrje aa bb   | Shift right [aa], 0 &rarr; [aa].7, [aa].0 &rarr; C. If new C == 0 then bb &rarr; PC | No |
| 8202_aabb | lsrjo aa bb   | Shift right [aa], 0 &rarr; [aa].7, [aa].0 &rarr; C. If new C == 1 then bb &rarr; PC | No |
| 821A_aabb | rorje aa bb   | Shift right [aa], C &rarr; [aa].7, [aa].0 &rarr; C. If new C == 0 then bb &rarr; PC | No |
| 8212_aabb | rorj0 aa bb   | Shift right [aa], C &rarr; [aa].7, [aa].0 &rarr; C. If new C == 1 then bb &rarr; PC | No |
| 8028_aabb | incjmp aa bb   | [aa] + 1 &rarr; [aa], bb &rarr; PC | No |
| 802C_aabb | incjcs aa bb   | [aa] + 1 &rarr; [aa]. If C == 1, bb &rarr; PC | No |
| 8024_aabb | incjcc aa bb   | [aa] + 1 &rarr; [aa]. If C == 0, bb &rarr; PC | No |


### imadd aa bb

C080_aabb

aa + [bb] &rarr; [aa]

Stores the value of #aa + [bb] in the [aa] address.

This can be used with address 0x00 to load from an indirect pointer in a single instruction:

```
st	#1,	the_ptr				; Prepare the_ptr pointer
the_ptr	imadd	#0x00,	0	; LOAD address 0x01 into address 0x00. No need to pre-clear address 0x00.
; Address 0x00 now contains the loaded value
```

### imand aa bb

C180_aabb

aa & [bb] &rarr; [aa]

Stores the value of immediate aa & [bb] in the [aa] address.

This can be used with address 0xFF to load from an indirect pointer in a single instruction:

```
st	#1,	the_ptr				; Prepare the_ptr pointer
the_ptr	imand	#0xFF,	0	; LOAD address 0x01 into address 0xFF. No need to pre-clear address 0xFF.
; Address 0xFF now contains the loaded value
```

### and aa bb

8180_aabb

[aa] & [bb] &rarr; [aa]

Computes [aa] & [bb] and stores it in [aa]

Useful for performing indirect reads (similar to add), and computing AND at the same time.

```assembly
	st	0x01,	ptr	; Prepare indirect fetch pointer
	st	0xF0,	tmp	; Prepare destination with bitmask
ptr	and	tmp,	0	; AND into tmp
```

### clra aa

8100_aa00

0 &rarr; [aa]

This version of `clr` does not use the bb value, allowing the instruction to be also used as variable storage.

A useful way to use this is to create a self-clearing variable:

```
the_var	clra	the_var,	0
```

`the_var` can now be used as a variable, and will also zero itself when executed. Since many variables need to be initialized to zero anyway, this saves needing to use separate `clr` and `halt`(`skip`) instructions, saving one instruction overall.

### inca aa

8020_aa00

[aa] + 1 &rarr; [aa]

This version of `inc` does not use the bb value, allowing it to be used as variable storage.

A useful way to use this is to create a self-incrementing variable:

```
the_var	inca	the_var,	0
```


### incto aa bb

0820_aabb

[aa] + 1 &rarr; [bb]

Store the value of [aa] + 1 to [bb].

Effectively the same as:

```assembly
st	aa	bb
inc	bb
```

 but saves an instruction.

### altbtoc aa bb

00C0_aabb

[aa] < [bb] &rarr; C

If [aa] is less than [bb], carry is set. Else, carry is cleared.

### alebtoc aa bb

[aa] <= [bb] &rarr; C

If [aa] is less than or equal to [bb], carry is set. Else, carry is cleared.

`altbtoc` and `alebtoc` are useful for quickly comparing numbers and then jumping with `jcs` or `jcc`, without the need to store the actual subtraction result in any intermediate variable.

It can be used with `incjcs`/`incjcc`. This is useful for checking whether a pointer has reached some value in a loop, as an alternative to setting up the typical `incjne` loop.

```
	st	#array_start,	arr_ptr

loop
arr_ptr	imadd	#0x00,	0
	; Use value stored in 0x00 here

	alebtoc	#array_end,	arr_ptr	; arr_ptr >= #array_end -> carry set
	incjcc	arr_ptr,	loop	; Loop if arr_ptr < #array_end

```

Since `altbtoc` and `alebtoc` just set carry, they can also be used with instructions like `adc #0, bb` to conditionally increment a variable without branching.

### rsbc aa bb

80D0_aabb

[bb] - [aa] - ~C &rarr; [aa]

The same as `rsbcto`, but stores the result in [aa].

### rsbc aa bb

80D0_aabb

[bb] - [aa] - ~C &rarr; [aa]

The same as `rsbto`, but stores the result in [aa].

### bic aa bb

81C0_aabb

~[aa] & [bb] &rarr; [aa]

The same as `bicto`, but stores the result in [aa].

### stjmp aa bb

0808_aabb

[aa] &rarr; [bb], bb &rarr; PC

Stores the value of [aa] in [bb], then jumps to address bb.

This is useful for implementing a jump table that looks up a value from an index, for example:

```
	st	#jmp_table,	jmp_target
	addto	offset,	jmp_target	; Offset the jump address into the jump table
	; Do the jump
jmp_target	jmp	0	; Indirect jump into jmp_table
jmp_table	; Begin jump table
	stjmp	#CONSTANT_A,	jmp_output
	stjmp	#CONSTANT_B,	jmp_output
	stjmp	#CONSTANT_C,	jmp_output
	stjmp	#CONSTANT_D,	jmp_output
jmp_output	nop	; jmp_output stores the jump table result in bb.
```

### outcjmp aa bb

9808_aabb

[aa] &rarr; serial console, bb &rarr; PC

Writes the value of [aa] (or #aa if immediate) to the serial console, and then jumps to the address bb.

This is useful when printing characters to the console in a loop, since it saves an instruction compared to `outc` + `jmp`.

### lsrje aa bb

820A_aabb

Shift right [aa], 0 &rarr; [aa].7, [aa].0 &rarr; C. If new C == 0 then bb &rarr; PC

Equivalent to `lsr` and then `jcc`, but in a single instruction. Useful for looping and shifting a bitmask right, until the first 1 bit is shifted out.


### lsrjo aa bb

8202_aabb

Shift right [aa], 0 &rarr; [aa].7, [aa].0 &rarr; C. If new C == 1 then bb &rarr; PC

Equivalent to `lsr` and then `jcs`, but in a single instruction. Useful for looping and shifting a bitmask right, until the first 0 bit is shifted out.

### rorje aa bb

821A_aabb

Shift right [aa], C &rarr; [aa].7, [aa].0 &rarr; C. If new C == 0 then bb &rarr; PC

Equivalent to `ror` and then `jcc`, but in a single instruction.

### rorjo aa bb

8212_aabb

Shift right [aa], C &rarr; [aa].7, [aa].0 &rarr; C. If new C == 1 then bb &rarr; PC

Equivalent to `ror` and then `jcs`, but in a single instruction.

### incjmp aa bb

8028_aabb

[aa] + 1 &rarr; [aa], bb &rarr; PC

Increments [aa] and then unconditionally jumps to bb.

### incjcs aa bb

802C_aabb

[aa] + 1 &rarr; [aa]. If C == 1, bb &rarr; PC

Increments [aa]. If the existing carry flag is set, jumps to [bb].

Note, the existing carry flag is not the ALU carry output. The carry output from the increment is not used in the jump condition.

### incjcc

8024_aabb

[aa] + 1 &rarr; [aa]. If C == 0, bb &rarr; PC

Increments [aa]. If the existing carry flag is clear, jumps to [bb].

Note, the existing carry flag is not the ALU carry output. The carry output from the increment is not used in the jump condition.
