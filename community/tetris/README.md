# Tetris

A Tetris clone implementation for the single board relay computer.

## Memory Map

```
00: c810ff00 81000100 81000200 81000300 81000400 81000500 81000600 000000ff
08: 000000ff 81000900 81000a00 81000b00 81000c00 81000d00 81000e00 81000f00
10: 81001000 81001100 81001200 81001300 81001400 81001500 81001600 81001700
18: 81001800 81001900 81001a00 81001b00 81001c00 000000ff 000000ff 81001f00
20: 81002000 40e00602 48900102 49800702 81002400 81002500 81002600 802a0629
28: d8085800 84086865 81002a00 81002b00 81002c00 81002d00 81002e00 81002f00
30: 81003000 81003100 84089069 08000500 84089f91 4800aaa9 8408b6a0 006a0027
38: 4800fe06 4800aea9 8408b6a0 00621f3e 8408dfcb 4018ff1f 8408cab7 4800b0a9
40: 8408b6a0 84086461 e8000000 08600000 48800100 8022004e 48800100 8022005a
48: 48800100 8022005c 8022005d 80220060 8022005f d8083f42 48e00105 4800ff00
50: 84089f91 00620053 80281f39 4800aaa9 8408b6a0 00620057 80281f27 020a2039
58: 08000526 4018ff4e 48e00104 4018ff35 80280435 48e00103 4018ff2a 8028032a
60: 8028204e 08000324 08000425 08000526 4018ff00 08002403 08002504 08002605
68: 4018ff00 0800026e 0a000300 0a000000 08906e6e 48806f6e 4018ff00 4808667d
70: 4808667d 4808f07d 4808f07d 4808277d 4808727d 4808367d 4808367d 4808637d
78: 4808637d 4808717d 4808477d 4808177d 4808747d 4010ff00 02020386 08007d2f
80: 4980f02f 4800fc00 08807d7d 802a0082 08007d2d 4018ff90 4800fd6e 48003189
88: 0800898b c0800000 0a007d7d 0a100000 48e00289 40e02a89 006c0088 802a6e87
90: 4018ff00 0062009f 0202309f 02022e9f 02022c9f 02022a9f 0a003131 0a103030
98: 0a002f2f 0a102e2e 0a002d2d 0a102c2c 0a002b2b 0a102a2a 802a0092 4018ff00
a0: 48002aa6 48000fa8 088004a8 088004a8 4800f800 8100a500 8080a500 8100a700
a8: 8080a700 4018ff00 0980a5a7 0062a7b3 0800a700 4018ffb6 0880a5a7 4018ffb1
b0: 09c0a5a7 0800a8b2 0800a700 8020a600 8020a800 802a00a5 4018ff00 480001bc
b8: 488009bc 480080c3 4800f6c4 0800c300 81800000 006a00bf d8087ec0 d8002300
c0: 488002bc 802ac4bb 48e014bc d8000d00 d8000a00 820ac3ba 48e00abc 0069bcb8
c8: d8000d00 d8000a00 4018ff00 8408e9e0 006ac8cf 006ac9cf 4018ffdf 8100cf00
d0: 8100d000 4800f6bf 480009d6 0800c8b3 0800c9b4 0820d6d7 8080cf00 8080d000
d8: 8408faea 0800d6db 0800d7dc 0800ea00 0800eb00 488002d6 802abfd3 4018ff00
e0: 4800f600 4800ffc8 4800ffc9 480009e5 0820e5e6 8180c800 8180c900 488002e5
e8: 802a00e4 4018ff00 8100ea00 8100eb00 4800f000 0880b3b3 0890b4b4 006400f5
f0: 0880cfcf 0890d0d0 40e0f6bf 48900001 4018fff9 0880cfcf 0890d0d0 0890eaea
f8: 0890ebeb 802a00ed 4018ff00
```

Total instructions: 251/256

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

| Key | Action                                      |
| --- | ------------------------------------------- |
| 2   | Move piece down                             |
| 4   | Move piece left                             |
| 6   | Move piece right                            |
| 7   | Rotate piece left                           |
| 8   | Hard drop piece (move down until collision) |
| 9   | Rotate piece right                          |

## Demo

**TODO: Video of the game running in the simulator and on real hardware**

## Score

The game records how many lines were cleared during a game.

The lines cleared count is stored at address `0x01`

## Important symbols

| Symbol         | Address |
| -------------- | ------- |
| lines_cleared  | 0x01    |
| piece_kind     | 0x02    |
| piece_rotation | 0x03    |
| piece_x        | 0x04    |
| piece_y        | 0x05    |

## Technical details

### Features:

* All 6 tetrominos are included
* Tetrominos rotate with a passable rotation system
* Collisions with the edges and bottom of the gameboard are handled
* Collisions with the existing pieces on the gameboard are handled
* Line clearing is handled
* The number of lines cleared is maintained as the score
* Game over when new piece collides with existing pieces
* Hard drop

### Limitations and areas for improvement

* The game has a passable rotation system, but it's not perfect. The implementation is optimised for fewest instructions, and not all pieces pivot quite as nicely they should (especially the T piece). This makes T-spins sometimes impossible. It may be possible to fix this with only a few instructions. This is #1 priority for future fixes.

* Tetrominos are not randomly selected and instead simply cycle non-randomly. If anyone knows an rng algorithm that can pick a number from 0->6 in ~3 instructions, let me know!

* Technically the Tetris gameboard is supposed to be at least 10x20, but the game only renders 10x16. This is because the gameboard is two bytes high and rendering 10x24 would take considerably more storage and instructions, so 10x16 will have to do.

* There are no wallkicks for rotation or anything fancy from modern Tetris. An illegal spin is prevented to avoid collision, but the game will not move the piece to help you accomplish a rotation. An exception to this is collisions with the floor, which *will* actually kick the piece up due to how piece rendering is handled.

* Slow on real hardware!

### Implementation

#### Minimising instruction count

To save instruction space, many instructions are used as both instructions *and* variable storage. Any instruction that doesn't use its `bb` value for something (i.e. the `ben` bit is disabled and the instruction doesn't jump) is available to use as storage, since its `bb` value is ignored anyway. Using this technique, the game manages to have no `skip` directives, since all variables are stored hidden within other instructions.

A particularly useful and easy example of this is the `CLRA_INSN` (`0x8100aabb`) instruction, which writes `0x00` to `[aa]` without using `bb` at all. This allows for a variable to clear itself when executed.

For example:

`the_variable	insn 0x81000000	the_variable,	0`

`the_variable` is now a variable for `bb` storage, and it will also clear `the_variable` when executed as an instruction. Since many variables need to be initialized to zero, this saves an entire instruction compared to using a `clr` instruction and a separate `skip` or `halt` instruction to store the variable.

Another example is `outc`. `outc` writes the value of `[aa]` to the console, but it doesn't use `bb` in any way. This means that every `outc` instruction can also be used as a variable storage, which can save a few instructions in a text-baed application that uses `outc` a lot.

#### Game loop

```
main:
    clear gameboard and all state
main_next_piece:
    clear stamp flag
    clear hard drop flag
    select next piece_kind and set initial position and rotation in the undo buffer
main_undo_then_render:
    increment undo_retry_count
    If undo_retry_count == 0:
        print 'X'
        halt
    restore the saved piece position from the undo buffer
main_render_fresh_piece:
    clear the piece stage
    render the current piece to the piece stage in its current rotation and location in x and y
main_check_collision:
    check if the piece stage is currently colliding with the gameboard
    If collision with gameboard:
        GOTO main_undo_then_render
    reset the undo_retry_count to -2
main_full_render:
    stamp the piece stage to the gameboard
    print the gameboard to console
    If stamp flag is set:
        clear any full lines in the gameboard. This also updates the lines_cleared score.
        GOTO main_next_piece
main_full_render_clr:
    clear the piece stage back off the gameboard
    save current piece state to the undo buffer
main_read_input:
    wait for user input (2, 4, 6, 7, 8, 9)
    If user input 2 (move down):
main_move_drop:
        piece_y--
        shift piece_stage down by 1
        If collision with floor:
            set stamp flag
            GOTO main_full_render
        check collision with gameboard
        If collision with gameboard:
            set stamp flag
            GOTO main_undo_then_render
        If hard_drop_flag set:
            store piece_y in undo buffer prev_piece_y
            GOTO main_move_drop (redo this move down sequence)
        Else:
            main_full_render
    If user input 4 (move left):
        piece_x--
        GOTO main_check_collision
    Else If user input 6 (move right):
        piece_x++
        GOTO main_check_collision
    Else If user input 7 (rotate left):
        piece_rotation--
        GOTO main_render_fresh_piece
    Else If user input 8 (hard drop):
        set hard_drop_flag
        GOTO main_move_drop
    Else If user input 9 (rotate right):
        piece_rotation++
        GOTO main_render_fresh_piece
    Else:
        print '?'
        GOTO main_read_input
```

#### Gameboard

The game renders a 10x16 gameboard using ASCII characters on the serial console using `outc`. The gameboard is rendered using '~' characters for empty cells, and '#' characters for filled cells. CR+LF is used for newlines.

The gameboard is represented by 20 bytes. The bytes are stacked vertically with the even numbered, lower address bytes on the bottom, and the odd numbered, higher address bytes on the top. The bytes are oriented with their lowest significant bits downwards, so bit 0 is at the bottom, and bit 7 is at the top.

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

Line clearing is accomplished by generating a bitmask for the lines to be cleared. This is done by bitwise ANDing all of the gameboard columns together. The result is a 16 bit mask with 1s in all the locations where lines should be cleared, and 0s everywhere else.

The line clear bitmask is then used against each column in a rotation algorithm that shift rotates the mask and column in sync, discarding bits from the column when the mask is 1. In this way, all the lines are cleared.

#### Piece rendering

Pieces are represented by a single byte constant. The lower 4 bits are half the piece, and the upper 4 bits are the other half. A mirrored version of the piece is also available to make rotations efficient, halving the amount of piece rendering code required.

Pieces are rendered to an intermediary `piece_stage` buffer, which is the same format as the gameboard, but only 4x16 (8 bytes) in size. The piece stage only needs to be 4 columns wide since this is the widest any piece can be in any orientation.

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

The piece is rendered into the `piece_stage` either vertically or horizontally, depending on whether the `piece_rotation` value is even or odd. If the second bit of the `piece_rotation` is set, the mirrored version of the piece is used. The piece constant value is shifted into the top of the piece stage. The entire piece stage is then shifted downwards in a loop to move the piece into its `piece_y` coordinate.

Moving the piece left and right is accomplished by simply adjusting the `piece_x` value. The subroutine that relates the `piece_stage` to the gameboard uses pointer arithmetic to take `piece_x` into account when comparing the gameboard to the `piece_stage`.

#### Applying the piece stage to the gameboard

A single subroutine `stamp_piece` is responsible for all operations that involve relating the piece stage to the gameboard. It operates in three modes, chosen by setting the value of `stamp_piece_op`:

##### Merge (`#stamp_piece_merge_op`)

The piece stage is added to the gameboard. Any bits set in the piece stage will be set (`addto`) in the gameboard, effectively "stamping" the piece down onto the board.

##### Clear (`#stamp_piece_clear_op`)

The piece stage is cleared from the gameboard. Any bits set in the piece stage are cleared (`bicto`) the gameboard, effectively "clearing" the piece from the board.

##### Collision detect (`#stamp_piece_coll_op`)

The piece stage is compared with the gameboard for any overlapping bits. If any bits are present in both the gameboard and the piece stage (`andto` result > 0), `tmp` is set to a non-zero value.



### Custom instructions

In order to use the fewest possible instructions, a lot of custom instructions are used. They are detailed in [extra-instructions.md](../../extra-docs/extra-instructions.md).
