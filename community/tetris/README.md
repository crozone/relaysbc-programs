# Relaytris

A Tetris-like game implementation for the single board relay computer.

## Memory Map

```
00: c810ff00 81000100 81000200 81000300 81000400 81000500 81000600 81000700
08: 000000ff 000000ff 81000a00 81000b00 81000c00 81000d00 81000e00 81000f00
10: 81001000 81001100 81001200 81001300 81001400 81001500 81001600 81001700
18: 81001800 81001900 81001a00 81001b00 81001c00 81001d00 000000ff 000000ff
20: 81002000 81002100 40e00603 48900103 49800703 81002500 81002600 81002700
28: 802207fe 08002504 08002605 08002706 81002c00 81002d00 81002e00 81002f00
30: 81003000 81003100 81003200 81003300 8408986c 08000600 8408a799 006a2040
38: 4800b2b1 8408bda8 006a0028 08000425 08000526 08000627 006a215f 48000020
40: 4800fe07 006a0248 4800b5b1 8408bda8 8408d1be 006a204b 4800b7b1 8408bda8
48: 0062204d 4800b5b1 8408bda8 8408fdd2 4018ff20 e8000000 49800f00 08600000
50: 00620042 48800100 8022005f 48800100 80220065 48800100 80220066 80220067
58: 80220069 80220068 8022006a 8022006b 80220001 802200fe d8083f4d 48e00106
60: 4800ff00 8408a799 00620064 80282040 80282038 48e00205 80280538 48e00204
68: 8028042c 8228215f 8108024d 8228024d 08000371 0a000491 02009100 08900371
70: 48807271 4018ff00 4808f080 48080f80 4808cc80 4808cc80 4808e480 48084e80
78: 48086c80 48086c80 4808e280 48088e80 4808c680 4808c680 4808e880 48082e80
80: 4010ff00 020a048d 0800802f 4980f02f 4800fc00 08808080 802a0085 0800802d
88: 02020398 020a9198 08002f31 08002d2f 81082d98 0202038f 02009100 4810fd71
90: 48003391 c0800000 08009194 0a008080 0a100000 48e00291 40e22c91 802a7190
98: 4018ff00 006200a7 020232a7 020230a7 02022ea7 02022ca7 0a003333 0a103232
a0: 0a003131 0a103030 0a002f2f 0a102e2e 0a002d2d 0a102c2c 802a009a 4018ff00
a8: 48002cae 480012b0 088005b0 088005b0 4800f800 8100ad00 8080ad00 8100af00
b0: 8080af00 4018ff00 0980adaf 0062afba 4018ffbd 0880adaf 4018ffb8 09c0adaf
b8: 0800b0b9 0800af00 8020ae00 8020b000 802a00ad 4018ff00 d8000d00 d8000a00
c0: 480001c5 48800ac5 480080cc 4800f6cd 0800cc00 81800000 006a00c8 d8087ec9
c8: d8002300 488002c5 802acdc4 48e014c5 d8000d00 d8000a00 820accc3 48e00bc5
d0: 0069c5c1 4018ff00 4800f600 4800ffbe 4800ffbf 48000ad7 0820d7d8 8180be00
d8: 8180bf00 488002d7 802a00d6 006abede 006abfde 4018fffd 8100de00 8100df00
e0: 4800f6c8 48000ae5 0800beba 0800bfbb 0820e5e6 8080de00 8080df00 8100e700
e8: 8100e800 4800f000 0880baba 0890bbbb 006400f2 0880dede 0890dfdf 40e0ffc8
f0: 48900001 4018fff6 0880dede 0890dfdf 0890e7e7 0890e8e8 802a00ea 0800e5f9
f8: 0800e6fa 0800e700 0800e800 488002e5 802ac8e2 4018ff00 d8085800
```

Total instructions: 255/256

## Why?

I wrote this as a technical demonstration of the relay computer's capabilities, basically just to prove that it could actually be done. Despite only having 256 instruction words and a tiny CPU made from 83 relays, it can implement a full tetris-like game, albiet very slowly.

This implementation also serves as a reference template for getting tetris-like games running on other highly constrained platforms. The techniques developed for this project should be easily ported to any CPU that has a basic ALU with a right shift instruction, making it ideal for old, esoteric, memory constrained computers. For my next project, I have my sights on an Intel 4004, and as far as I can tell nobody has written an actual tetris clone for it yet...

## Tetris-like clone

Legally, this game isn't actually Tetris. Even though it shares some of the non-copyrightable gameplay elements, it lacks a tetris license, as well as many of the key characteristics that would make it a real Tetris game, like coloured tetrominos, the modern rotation system, piece randomization, the modern gameboard size, a ghost piece, next-piece previews, a modern scoring system, any of the standard game modes, and most importantly, it lacks realtime gameplay. Therefore, this should be considered as strictly a tetris-like game implementation, aka a tetris clone. It was created purely as an educational technical demonstration for an esoteric platform and not as a commercial game.

## Assembling the game

To assemble the game, run `asm tetris.asm > tetris.lst`.

This requires the most current version of the assembler from the repo in order to support custom instructions with arguments. It will not compile correctly with Joe's original version of the asm executable.

A pre-built tetris.lst is already included in the repo for convenience.

## Playing the game

Write the compiled memory map into the relay computer.

**Run from address 0x01.**

The game renders the output to the serial console.

### Simulator

Run in the simulator with `sim -pc 1 tetris.lst`

The most current version of the simulator from the repo is recommended, since it has been modified to support interactive text programs (`outc`/`inwait`) better. The game will technically run on Joe's original simulator version, but it will not render the text output making it basically unplayable.

The keys 0-9, a-f on the keyboard can be used to emulate the relay computer numpad.

### Controls

The game is controlled with the relay computer numpad.

| Key | Action                                       |
| --- | -------------------------------------------- |
| 0   | Re-render the gameboard                      |
| 2   | Move piece down                              |
| 4   | Move piece left                              |
| 6   | Move piece right                             |
| 7   | Rotate piece left                            |
| 8   | Hard drop piece (move down until collision)  |
| 9   | Rotate piece right                           |
| A   | Enable automatic rendering (default)         |
| B   | Disable automatic rendering                  |
| C   | New Game                                     |
| D   | Exit game                                    |

## Demo

**TODO: Video of the game running in the simulator and on real hardware**

## Score

The game records how many lines were cleared during a game.

The lines cleared count is stored at address `0x01`

## Important symbols

| Symbol             | Address |
| ------------------ | ------- |
| lines_cleared      | 0x01    |
| rendering_off_flag | 0x02    |
| piece_kind         | 0x03    |
| piece_rotation     | 0x04    |
| piece_x            | 0x05    |
| piece_y            | 0x06    |

## Technical details

### Features:

* All 7 tetrominos are included
* Tetrominos rotate with a passable rotation system
* Collisions with the sides and bottom of the gameboard are handled
* Collisions with the existing pieces on the gameboard are handled
* Line clearing is handled and lines counted for scoring
* The total number of lines cleared is maintained as the score
* Game over when a new piece cannot be spawned because it collides with existing pieces on the board
* Hard drop (automatically loops piece down until a collision occurs)
* Toggle gameboard rendering (Automatic rendering can be turned off to improve game speed on real hardware)

### Limitations and areas for improvement

* Tetrominos are not randomly selected and instead simply cycle non-randomly (order is: I, O, T, S, J, Z, L). If anyone knows an rng algorithm that can pick a number from 0->6 in ~3 instructions, let me know!

* Technically the official Tetris gameboard is supposed to be at least 10x20 tall (modern is usually 10x40), but the game only renders a shorter 10x16. This is because the gameboard is two bytes in height, and rendering 10x24 would require three bytes, and take considerably more storage and instructions because of the extra indirect loading and bit shift code required. 10x16 will have to do and is still very playable.

* There are no wallkicks for rotation or anything fancy from modern official Tetris. An illegal spin is prevented to avoid collision, but the game will not move the piece ("wallkick") to help you accomplish a rotation. An exception to this is downwards collisions with the floor (and only the floor), which *will* actually kick the piece up ("floorkick") due to the way piece rendering is handled.

* The game is extremely slow on real hardware! Disabling automatic piece rendering helps.

### Implementation

#### Minimising instruction count

To save instruction space, many instructions are used as both instructions *and* variable storage. Any instruction that doesn't use its `bb` value for something (i.e. any instruction where the `ben` bit is disabled and the instruction doesn't jump) is available to use as storage, since its `bb` value is ignored. Using this technique, the game manages to have no `skip` directives (no variables are stored in halt instructions with the exception of 0x00), since all variables are stored in the bb value within other instructions.

A particularly useful example of this is the `CLRA_INSN` (`0x8100aabb`) instruction, which writes `0x00` to `[aa]` without using `bb`. When `aa` is set to the address of the instruction itself, it allows for a "variable storage" instruction to clear itself when executed. Since variables usually have to be cleared before use anyway, this saves an entire instruction.

For example:

`the_variable	insn 0x81000000	the_variable,	0`

`the_variable` is now a variable for `bb` storage, and it will also clear `the_variable` when executed as an instruction. Since many variables need to be initialized to zero, this saves an entire instruction compared to using a `clr` instruction and a separate `skip` or `halt` instruction to store the variable.

Another example is `outc`. `outc` writes the value of `[aa]` to the console, but it doesn't use `bb` in any way. This means that every `outc` instruction can also be used as a variable storage, which can save a few instructions in text-baed applications that use `outc` a lot.

#### Gameboard

The gameboard is represented by 20 bytes. The bytes are stacked on top of each other vertically, with the even numbered, lower address bytes on the bottom, and the odd numbered, higher address bytes on the top. The bytes are oriented with their lowest significant bits towards the bottom, so bit 0 is towards bottom, and bit 7 is towards the top.

#### Gameboard layout (byte.bit):

```
1.7 3.7 5.7 7.7 9.7 11.7 13.7 15.7 17.7 19.7
1.6 3.6 5.6 7.6 9.6 11.6 13.6 15.6 17.6 19.6
1.5 3.5 5.5 7.5 9.5 11.5 13.5 15.5 17.5 19.5
1.4 3.4 5.4 7.4 9.4 11.4 13.4 15.4 17.4 19.4
1.3 3.3 5.3 7.3 9.3 11.3 13.3 15.3 17.3 19.3
1.2 3.2 5.2 7.2 9.2 11.2 13.2 15.2 17.2 19.2
1.1 3.1 5.1 7.1 9.1 11.1 13.1 15.1 17.1 19.1
1.0 3.0 5.0 7.0 9.0 11.0 13.0 15.0 17.0 19.0
0.7 2.7 4.7 6.7 8.7 10.7 12.7 14.7 16.7 18.7
0.6 2.6 4.6 6.6 8.6 10.6 12.6 14.6 16.6 18.6
0.5 2.5 4.5 6.5 8.5 10.5 12.5 14.5 16.5 18.5
0.4 2.4 4.4 6.4 8.4 10.4 12.4 14.4 16.4 18.4
0.3 2.3 4.3 6.3 8.3 10.3 12.3 14.3 16.3 18.3
0.2 2.2 4.2 6.2 8.2 10.2 12.2 14.2 16.2 18.2
0.1 2.1 4.1 6.1 8.1 10.1 12.1 14.1 16.1 18.1
0.0 2.0 4.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0
```

#### Line clearing

Line clearing is accomplished by first generating a bitmask for the lines to be cleared. This is done by bitwise ANDing all of the gameboard columns together. The result is a 2 byte (16 bit) mask with 1s in all of the locations where rows should be cleared, and 0s where rows should be maintained.

The columns are then iterated over. The line clear bitmask, along with the current gameboard column, are copied for the function `rem_bits` to work on. `rem_bits` uses a bitshift rotation algorithm to remove the required bits from the gamebaord column. It does this by left rotating the line clear mask and checking the carry value. If the carry was clear, the gameboard column is left rotated, and then the carried bit is left rotated into the result value, so that the gameboard bit is remembered. If the carry was set, the gameboard column is left rotated, but the result is not rotated and the bit is discarded.

#### Piece rendering

Pieces are represented in code by a single byte constant. The lower 4 bits are the left vertical slice of the piece, and the upper 4 bits are right vertical slice. A mirrored version of the piece is included to make piece rotations efficient, halving the amount of piece rendering code required.

The active piece is first rendered to an intermediary `piece_stage` buffer, which is laid out in the same format as the gameboard. However, the piece stage is only 4x16 squares (8 bytes) in size. The piece stage only needs to be 4 columns wide since this is the widest any piece can be in any orientation. The entire piece stage can be shifted left or right over the gameboard using simple pointer arithmatic using the `piece_x` value.

Additionally, if the piece is an I, T, J, L piece (i.e. `piece_kind` index is even) its position is tweaked so that it rotates about an axis correctly.

#### Piece stage layout (byte.bit):

```
1.7 3.7 5.7 7.7
1.6 3.6 5.6 7.6
1.5 3.5 5.5 7.5
1.4 3.4 5.4 7.4
1.3 3.3 5.3 7.3
1.2 3.2 5.2 7.2
1.1 3.1 5.1 7.1
1.0 3.0 5.0 7.0
0.7 2.7 4.7 6.7
0.6 2.6 4.6 6.6
0.5 2.5 4.5 6.5
0.4 2.4 4.4 6.4
0.3 2.3 4.3 6.3
0.2 2.2 4.2 6.2
0.1 2.1 4.1 6.1
0.0 2.0 4.0 6.0
```

The piece is rendered into the `piece_stage` by the function `prep_piece`. It is rendered either vertically or horizontally, depending on whether the `piece_rotation` value is even or odd. If the second bit of the `piece_rotation` is set, the mirrored version of the piece is used by incrementing the piece template index by 1. The piece constant value is shifted into the top of the piece stage. Finally, the entire piece stage is shifted downwards in a loop to move the piece into the correct `piece_y` position.

Moving the piece left and right is accomplished by simply adjusting the `piece_x` value. The subroutine that relates the `piece_stage` to the gameboard uses pointer arithmetic to take `piece_x` into account when comparing the gameboard to the `piece_stage`.

#### Applying the piece stage to the gameboard

A single subroutine `stamp_piece` is responsible for all operations involving relating the piece stage to the gameboard. A single function is used for three separate operations to save on instructions, since most of the code is simply pointer arithmatic and doing indirect loads and stores of the piece stage and gameboard. The code that relates the two then only needs to operate on the loaded values.

`stamp_piece` operates in three modes, chosen by setting the value of `stamp_piece_op` to an inner subroutine address:

##### Gameboard Merge (`stamp_piece_op = #stamp_piece_merge_op`)

The piece stage is stamped to the gameboard. Any bits set in the piece stage will be added (`addto`) to the gameboard, effectively "stamping" the piece down onto the gameboard.

In order to save an instruction, the gameboard is not cleared (`bicto`) before the add is performed. This requires that the gameboard has the piece destination bits pre-cleared, in order to not trigger a carry in the add (which would cause an incorrect result). This is fine, since the gameboard is always pre-cleared before performing this operation.

##### Clear (`stamp_piece_op = #stamp_piece_clear_op`)

The piece stage is bitcleared from the gameboard. Any bits set in the piece stage are cleared (`bicto`) from the gameboard, effectively erasing the piece from the board.

##### Collision detect (`stamp_piece_op = #stamp_piece_coll_op`)

The piece stage is compared with the gameboard for any overlapping bits. If any bits are present in both the gameboard and the piece stage (`andto` result > 0), `tmp` is set to a non-zero value, indicating a collision has occured.

#### Gameboard scanout

The game renders the 10x16 gameboard using ASCII characters on the serial console using `outc`. The gameboard is rendered using '~' characters for empty cells, and '#' characters for filled cells. CR+LF (`\r\n`) is used for newlines.

The gameboard is scanned out from top to bottom, left to right. Even though this is difficult due to the bottom-to-top layout of the gameboard, it allows the least amount of characters to be output to the terminal by only requiring the newline character to change lines. It avoids any special ANSII terminal cursor movement commands, which saves a large number of `outc` instructions.

Scanout is accomplished using the following steps:

1. The current piece stage is "stamped" to the gameboard using `stamp_piece` with `stamp_piece_op = #stamp_piece_merge_op`.
2. The gameboard is rendered by the function `render_board`, using three nested loops to shift a sliding bitmask with a single bit set which represents the current row cell being rendered. The bitmask is ANDed with each gameboard column. When the bitmask and the current gameboard column AND > 0, the current cell is set. Then, the bitmask is shifted to move down to the next row.
3. If the last move was a collision, the `stamp_flag` variable is set. Rendering ends and the piece is left on the gameboard.
4. If the last move did not result in a downwards collision, `stamp_flag` is unset. The current piece is cleared back off the gameboard using `stamp_piece` with `stamp_piece_op = #stamp_piece_clear_op`.

#### Game over

If a collission occurs while spawning a new piece, the game will get stuck in an infinite loop of detecting a collision, trying to undo the piece state to the last known good state, re-rendering the piece top the old state, and then re-detecting the same collision because the undo state is the same as the piece spawn location.

To guard against this, an `undo_retry_count` variable is set to -2 every time a piece is successfully positioned without a collision. `undo_retry_count` is then incremented every time the game performs an "undo". If the count reaches 0 (2 consecutive undo loops), `game_over` is triggered and the game ends.

### Custom instructions

In order to use the fewest possible instructions, a lot of custom instructions are used. They are detailed in [extra-instructions.md](../../extra-docs/extra-instructions.md).
