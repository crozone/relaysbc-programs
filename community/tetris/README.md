# Tetris

A Tetris clone implementation for the single board relay computer.

## Memory Map

```
00: c810ff00 8408f4d4 40e006d5 489001d5 498007d5 480003da 480000db 480000d9
08: 8408413e 8408fdf5 84086942 0800d800 8408786a 48008382 84088f79 006a0008
10: 48008782 84088f79 8408a390 00621517 8408b8a4 81001500 4018ff02 48008982
18: 84088f79 84083d3a e8000000 48e00200 00620027 48e00200 00620032 48e00200
20: 00620034 48e00100 00620036 48e00200 00620038 d8003f00 4018ff1a 4800ff00
28: 088000d8 8408786a 0062002d 48000115 4018ff10 48008382 84088f79 00620010
30: 48000115 4018ff08 48e001d7 4018ff0d 488001d7 4018ff0d 48e001d6 4018ff09
38: 488001d6 4018ff09 0800d6d9 0800d7da 0800d8db 4018ff00 0800d9d6 0800dad7
40: 0800dbd8 4018ff00 0800d547 0a00d600 0a000000 08904747 48804847 4018ff00
48: 48086656 48086656 4808f056 4808f056 48082756 48087256 48083656 48083656
50: 48086356 48086356 48087156 48084756 48081756 48087456 4010ff00 0202d65f
58: 080056fa 4980f0fa 4800fc00 08805656 802a005b 080056f8 4018ff69 4800fd47
60: 4800fc62 08006264 c0800000 0a005656 0a100000 48e00262 40e0f562 006c0061
68: 802a4760 4018ff00 00620078 0202fb78 0202f978 0202f778 0202f578 0a00fcfc
70: 0a10fbfb 0a00fafa 0a10f9f9 0a00f8f8 0a10f7f7 0a00f6f6 0a10f5f5 802a006b
78: 4018ff00 4800f57f 4800de81 0880d781 0880d781 4800f800 81007e00 80807e00
80: 81008000 80808000 4018ff00 09807e80 0062808c 08008000 4018ff8f 08807e80
88: 4018ff8a 09c07e80 0800818b 08008000 80207f00 80208100 802a007e 4018ff00
90: 48000195 4880de95 4800809c 4800f69d 08009c00 81800000 006a0098 d8087e99
98: d8002300 48800295 802a9d94 48e01495 d8000d00 d8000a00 820a9c93 48e0df95
a0: 00699591 d8000d00 d8000a00 4018ff00 8408c2b9 006aa1a8 006aa2a8 4018ffb8
a8: 8100a800 8100a900 4800f698 4800deaf 0800a18c 0800a28d 0820afb0 8080a800
b0: 8080a900 8408d3c3 0800afb4 0800b0b5 0800c300 0800c400 488002af 802a98ac
b8: 4018ff00 4800f600 4800ffa1 4800ffa2 4800debe 0820bebf 8180a100 8180a200
c0: 488002be 802a00bd 4018ff00 8100c300 8100c400 4800f000 08808c8c 08908d8d
c8: 006400ce 0880a8a8 0890a9a9 40e0f698 489000d4 4018ffd2 0880a8a8 0890a9a9
d0: 0890c3c3 0890c4c4 802a00c6 4018ff00 8100d400 8100d500 8100d600 8100d700
d8: 8100d800 8100d900 8100da00 8100db00 000000ff 000000ff 8100de00 8100df00
e0: 8100e000 8100e100 8100e200 8100e300 8100e400 8100e500 8100e600 8100e700
e8: 8100e800 8100e900 8100ea00 8100eb00 8100ec00 8100ed00 8100ee00 8100ef00
f0: 8100f000 8100f100 000000ff 000000ff 4018ff00 8100f500 8100f600 8100f700
f8: 8100f800 8100f900 8100fa00 8100fb00 8100fc00 4018ff00
```

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

### Controls

The game is controlled with the relay computer numpad.

In the simulator, the keys 0-9, a-f can be used.

* 2: Move piece down
* 4: Move piece left
* 6: Move piece right
* 7: Rotate piece left
* 9: Rotate piece right

## Demo

**TODO: Video of the game running in the simulator and on real hardware**

## Score

The game records how many lines were cleared during a game.

The lines cleared count is stored at address `0xD4`

## Important symbols

* lines_cleared = 0xd4
* piece_kind = 0xd5
* piece_rotation = 0xd6
* piece_x = 0xd7
* piece_y = 0xd8

## Technical details

### Features:

* All 6 tetrominos are included
* Tetrominos rotate with a passable rotation system
* Collisions with the edges and bottom of the gameboard are handled
* Collisions with the existing pieces on the gameboard are handled
* Line clearing is handled
* The number of lines cleared is maintained as the score

### Limitations and areas for improvement

* The game has a passable rotation system, but it's not perfect. The implementation is optimised for fewest instructions, and not all pieces pivot quite as nicely they should (especially the T piece). This makes T-spins sometimes impossible. It may be possible to fix this with only a few instructions. This is #1 priority for future fixes.

* Tetrominos are not randomly selected and instead simply cycle non-randomly. If anyone knows an rng algorithm that can pick a number from 0->6 in ~3 instructions, let me know!

* In the game over condition the game will enter an infinite loop. This is due to the game constantly detecting a collision and attempting to "undo" the last move. This could be solved with a few instructions and could be implemented if the game can be further optimised enough to free up some extra space.

* Technically the Tetris gameboard is supposed to be at least 10x20, but the game only renders 10x16. This is because the gameboard is two bytes high and rendering 10x24 would take considerably more storage and instructions, so 10x16 will have to do.

* There are no wallkicks for rotation or anything fancy from modern Tetris. An illegal spin is prevented to avoid collision, but the game will not move the piece to help you accomplish a rotation. An exception to this is collisions with the floor, which *will* actually kick the piece up due to how piece rendering is handled.

### Implementation

#### Minimising instruction count

The game currently uses 253 (0xFD) instructions, leaving only two spare(!).

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
    select next piece_kind and set initial position and rotation in the undo buffer
main_undo_then_render:
    restore the saved piece position from the undo buffer
main_render_fresh_piece:
    clear the piece stage
    render the current piece to the piece stage in its current rotation and location
main_check_collision:
    check if the piece stage is currently colliding with the gameboard
    If collision with gameboard:
        GOTO main_undo_then_render
main_full_render:
    stamp the piece stage to the gameboard
    print the gameboard to console
    If stamp flag is set:
        clear stamp flag
        clear any full lines in the gameboard. This also updates the lines_cleared score.
        GOTO main_next_piece
main_full_render_clr:
    clear the piece stage back off the gameboard
    save current piece state to the undo buffer
main_read_input:
    wait for user input (2, 4, 6, 7, 9)
    If user input 2 (move down):
        piece_y--
        shift piece_stage down by 1
        If collision with floor:
            set stamp flag
            GOTO main_full_render
        check collision with gameboard
        If collision with gameboard:
            set stamp flag
            GOTO main_undo_then_render
    If user input 4 (move left):
        piece_x--
        GOTO main_check_collision
    Else If user input 6 (move right):
        piece_x++
        GOTO main_check_collision
    Else If user input 7 (rotate left):
        piece_rotation--
        GOTO main_render_fresh_piece
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

In order to use the fewest possible instructions, a lot of custom instructions are used. They are detailed in extra-instructions.md
