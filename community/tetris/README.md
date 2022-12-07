# Tetris

A Tetris clone implementation for the single board relay computer.

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

* All 6 tetrominos are included
* Tetrominos rotate with a passable rotation system
* Collisions with the edges and bottom of the gameboard are handled
* Collisions with the existing pieces on the gameboard are handled
* Line clearing is handled
* The number of lines cleared is maintained as the score
* Game over when new piece collides with existing pieces
* Hard drop
* Toggle gameboard rendering to improve speed

### Limitations and areas for improvement

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

If the piece is an I, T, J, L piece (i.e. `piece_kind` is even) its position is tweaked so that it rotates about an axis correctly. 

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
