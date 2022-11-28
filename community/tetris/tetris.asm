; Tetris implementation
; Ryan Crosby 2022
;
; Run from 0x01.
;
; Completed:
;
; * Gameboard format
; * Gameboard rendering to console
; * Line clearing
;
; ~120 instructions left to implement the rest of TODO.
;
; TODO:
;
;
; * Description with controls etc.
; * Smarter temporary variable management.
;       Define a small section of memory to use like a shared register pool.
;       Go through the subroutines and replace dedicated temporary variables with shared variables from the register pool that haven't been used yet in the execution flow.
;       Also inline most subroutines, most are called from a single spot.

;

; Constants
;

; Gameboard parameters
; These constants are used for convenience. Changing the value won't change the actual sizes of the gameboards, code will need to be modified as well.
GAMEBOARD_STRIDE	equ	2	; How many bytes high is the gameboard. 2 bytes = 16 rows.
GAMEBOARD_COLS	equ	10	; How many columns wide is the gameboard. This is generic enough that it can be adjusted without altering any code.
GAMEBOARD_SIZE	equ	(GAMEBOARD_STRIDE*GAMEBOARD_COLS)	; Gameboard total size = stride * columns

PIECE_STAGE_SIZE	equ	(GAMEBOARD_STRIDE*4)	; The piece stage is the same height as the gameboard, but only 4 wide.

SPACE_CHAR	equ	0x20	; Space
BLOCK_CHAR	equ	0x23	; #
EMPTY_CHAR	equ	0x7E 	; ~
BAR_CHAR	equ	0x7C	; |

CR_CHAR	equ	0x0D	; Carriage Return CR \r
LF_CHAR	equ	0x0A	; Linefeed LF \n

; Number constants
ZERO_CHAR	equ	0x30	; 0

; Alphabet constants
A_CHAR	equ	0x41	; A
B_CHAR	equ	A_CHAR+1
C_CHAR	equ	A_CHAR+2
D_CHAR	equ	A_CHAR+3
E_CHAR	equ	A_CHAR+4
F_CHAR	equ	A_CHAR+5
G_CHAR	equ	A_CHAR+6
H_CHAR	equ	A_CHAR+7
I_CHAR	equ	A_CHAR+8
J_CHAR	equ	A_CHAR+9
K_CHAR	equ	A_CHAR+10
L_CHAR	equ	A_CHAR+11
M_CHAR	equ	A_CHAR+12
N_CHAR	equ	A_CHAR+13
O_CHAR	equ	A_CHAR+14
P_CHAR	equ	A_CHAR+15
Q_CHAR	equ	A_CHAR+16
R_CHAR	equ	A_CHAR+17
S_CHAR	equ	A_CHAR+18
T_CHAR	equ	A_CHAR+19
U_CHAR	equ	A_CHAR+20
V_CHAR	equ	A_CHAR+21
W_CHAR	equ	A_CHAR+22
X_CHAR	equ	A_CHAR+23
Y_CHAR	equ	A_CHAR+24
Z_CHAR	equ	A_CHAR+25

; Additional custom instructions
; To use these, call them like: insn INCTO_INSN aa, bb
IMADD_INSN	equ	0xC0800000	; aa + [bb] --> [aa]. Immediate version of ADD. If aa is 0, allows single instruction LOAD of [bb] to [0].
AND_INSN	equ	0x81800000	; The WRA version of andto. ANDs [aa] and [bb], and stores in [aa].
CLRA_INSN	equ	0x81000000	; Stores 0 --> [aa]. Implemented as [aa] & 0 --> [aa].
INCTO_INSN	equ	0x08200000	; Stores [aa] + 1 --> [bb] in one instruction.
ALTB_TOC_INSN	equ	0x00C00000	; Stores [aa] < [bb] --> Carry.
ALEB_TOC_INSN	equ	0x00E00000	; Stores [aa] <= [bb] --> Carry.
ST_JMP_INSN	equ	0x08080000	; Stores [aa] --> [bb] and jumps to bb.
OUTC_JMP_INSN	equ	0x98080000	; Writes [aa] to the console and jumps to bb. WRA and WRB are set to make OUT write to console.
LSR_JCC_INSN	equ	0x820A0000	; Rotates [aa] right, writes the result back to [aa], and jumps if the shifted out bit (carry output) was clear.

; Catch for any jumps to null (0x00). This usually indicates a subroutine hasn't had its return address set.
;
; Also used as a temporary storage register, and sometimes as the return value for subroutines that only need to return a status.

	org	0x00
tmp	halt

; ENTRY POINT
	org	0x01
exec	jmp	run	; Jump to start of program


; Pieces templates
;
; Piece patterns are stored as a single byte.
; The 4 lsb bits represent the left of the piece, the 4 msb bits representing the right of the piece.
; The alignment and bit direction matches the piece stage.
;
; A "flipped" version of each piece is also stored, which is similar to the piece being left-to-right bitswapped.
; However using a dedicated version of the flipped piece removes the need for a bitswap subroutine,
; which actually saves instructions overall, and also allows the pieces to be tweaked so that they rotate correctly.
;
; The Gameboy left-handed rotation system was used as a reference, but the code doesn't attempt to exactly adhere to any particular system,
; it just attempts to look somewhat acceptable and use minimal instructions.


; I piece
;
;3   7
; 0 1
; 0 1
; 0 1
; 0 1
;0   4
I_PIECE	equ	0xF0
I_PIECE_FLIP	equ	I_PIECE	; I piece is the same flipped

; O (square) piece
;
;3   7
; 0 0
; 1 1
; 1 1
; 0 0
;0   4
O_PIECE	equ	0x66
O_PIECE_FLIP	equ	O_PIECE	; Square is same in any rotation

; T piece
;
;3   7
; 0 0
; 1 0
; 1 1
; 1 0
;0   4
T_PIECE	equ	0x27

; T piece flipped
;
;3   7
; 0 0
; 0 1
; 1 1
; 0 1
;0   4
T_PIECE_FLIP	equ	0x72

; S piece
;
;3   7
; 0 0
; 1 0
; 1 1
; 0 1
;0   4
S_PIECE	equ	0x36
S_PIECE_FLIP	equ	S_PIECE	; S piece is the same rotated

; S piece
;
;3   7
; 0 0
; 0 1
; 1 1
; 1 0
;0   4
Z_PIECE	equ	0x63
Z_PIECE_FLIP	equ	Z_PIECE	; Z piece is the same rotated

; J piece
;
;3   7
; 0 0
; 0 1
; 0 1
; 1 1
;0   4
J_PIECE	equ	0x71

; J piece flipped
;
;3   7
; 0 0
; 1 1
; 1 0
; 1 0
;0   4
J_PIECE_FLIP	equ	0x47

; L piece
;
;3   7
; 0 0
; 1 0
; 1 0
; 1 1
;0   4
L_PIECE	equ	0x17

; L piece flipped
;
;3   7
; 0 0
; 1 1
; 0 1
; 0 1
;0   4
L_PIECE_FLIP	equ	0x74

; Start of application code
;
test_piece_loop_i	skip	1
test_piece_loop_j	skip	1

run

	clr	piece_kind
	clr	piece_rotation
	st	#3,	piece_x
	clr	piece_y

	; Setup testing gameboard
	; Rotate your head to the left and squint
	; Top
	; st	#%1111_1111,	gameboard+19
	; st	#%1111_0001,	gameboard+17
	; st	#%1111_1001,	gameboard+15
	; st	#%1111_1101,	gameboard+13
	; st	#%1111_1111,	gameboard+11
	; st	#%1111_1111,	gameboard+9
	; st	#%1111_1101,	gameboard+7
	; st	#%1111_1001,	gameboard+5
	; st	#%1111_0001,	gameboard+3
	; st	#%1111_1111,	gameboard+1
	; ; Bottom
	; st	#%0000_1111,	gameboard+18
	; st	#%0001_1111,	gameboard+16
	; st	#%0011_1111,	gameboard+14
	; st	#%0111_1110,	gameboard+12
	; st	#%1111_1100,	gameboard+10
	; st	#%1111_1100,	gameboard+8
	; st	#%0111_1110,	gameboard+6
	; st	#%0011_1111,	gameboard+4
	; st	#%0001_1111,	gameboard+2
	; st	#%0000_1111,	gameboard+0

	; ; Top
	; st	#%0000_0010,	gameboard+19
	; st	#%0000_0010,	gameboard+17
	; st	#%0000_0010,	gameboard+15
	; st	#%0000_0011,	gameboard+13
	; st	#%0000_0010,	gameboard+11
	; st	#%0000_0010,	gameboard+9
	; st	#%0000_0010,	gameboard+7
	; st	#%0000_0010,	gameboard+5
	; st	#%0000_0111,	gameboard+3
	; st	#%0011_1111,	gameboard+1
	; ; Bottom
	; st	#%0000_1111,	gameboard+18
	; st	#%0001_1111,	gameboard+16
	; st	#%0011_1111,	gameboard+14
	; st	#%1111_1111,	gameboard+12
	; st	#%0000_1111,	gameboard+10
	; st	#%0011_1111,	gameboard+8
	; st	#%0111_1111,	gameboard+6
	; st	#%0000_1111,	gameboard+4
	; st	#%1111_1101,	gameboard+2
	; st	#%1111_1111,	gameboard+0
	
	; Print game board
	jsr	render_board_ret,	render_board
	
	outc	#CR_CHAR
	outc	#LF_CHAR
	
	; Do line clear
	jsr	line_clr_ret,	line_clr
	
	; Print game board
	jsr	render_board_ret,	render_board
	
	outc	#CR_CHAR
	outc	#LF_CHAR
	
	st	#-7,	test_piece_loop_i
test_piece_loop_a
	clr	piece_rotation
	st	#-4,	test_piece_loop_j
test_piece_loop_b
	; Clear any existing piece
	jsr	clear_piece_stage_ret,	clear_piece_stage
	
	; Prepare a piece
	st	piece_kind,	prep_piece_number
	st	piece_rotation,	prep_piece_rot
	jsr	prep_piece_ret,	prep_piece
	
	; Stamp to board
	st	#stamp_piece_merge_op,	stamp_piece_op
	jsr	stamp_piece_ret,	stamp_piece
	
	; Print game board
	jsr	render_board_ret,	render_board
	
	outc	#CR_CHAR
	outc	#LF_CHAR
	
	; Clear piece from board
	st	#stamp_piece_clear_op,	stamp_piece_op
	jsr	stamp_piece_ret,	stamp_piece
	
	inc	piece_rotation
	incjne	test_piece_loop_j,	test_piece_loop_b
	inc	piece_kind
	incjne	test_piece_loop_i,	test_piece_loop_a
	
	; Halt
	outc	#33	; !
	halt

; Prepare piece stage subroutine
; prep_piece_number = which piece to render. {0,1,2,3,4,5,6}
;
; Piece rotation. 4 different values for each direction. {0,1,2,3}.
;
; prep_piece_number is consumed during this operation.
;
prep_piece_rot	skip	1
prep_piece
	;andto	#0x03,	prep_piece_rot
	;andto	#0x07,	prep_piece_number
	
	; Calculate jump table address for piece value
	;
	; Jump address = prep_piece_jmp + (2 * prep_piece_number) + prep_piece_rot.1
	;
	; Get the second bit from prep_piece_rot into carry flag
	lsrto	prep_piece_rot,	tmp
	lsr	tmp
	adcto	prep_piece_number,	prep_piece_number
	; Add jump table base address
	addto	#prep_piece_jmp,	prep_piece_number
	; Do the jump
prep_piece_number	jmp	0
prep_piece_jmp	; Begin jump table
	insn ST_JMP_INSN	#O_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#O_PIECE_FLIP,	prep_piece_value
	insn ST_JMP_INSN	#I_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#I_PIECE_FLIP,	prep_piece_value
	insn ST_JMP_INSN	#T_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#T_PIECE_FLIP,	prep_piece_value
	insn ST_JMP_INSN	#S_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#S_PIECE_FLIP,	prep_piece_value
	insn ST_JMP_INSN	#Z_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#Z_PIECE_FLIP,	prep_piece_value
	insn ST_JMP_INSN	#J_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#J_PIECE_FLIP,	prep_piece_value
	insn ST_JMP_INSN	#L_PIECE,	prep_piece_value
	insn ST_JMP_INSN	#L_PIECE_FLIP,	prep_piece_value
prep_piece_value	nop	; prep_piece_value stores the jump table result.

	; If prep_piece_rot.0 is set, render horizontally, else render vertically.
	jo	prep_piece_rot,	prep_piece_hor
prep_piece_vert
	st	prep_piece_value,	piece_stage+5
	andto	#0xF0,	piece_stage+5	; Clear lower 4 bits
	st	#-4,	tmp
prep_piece_vert_loop	lsl	prep_piece_value
	incjne	tmp,	prep_piece_vert_loop
	st	prep_piece_value,	piece_stage+3
	jmp	prep_piece_ret
prep_piece_hor
prep_piece_hor_i	equ	prep_piece_number	; Reuse prep_piece_number as the outer loop variable
	st	#-3,	prep_piece_hor_i
prep_piece_hor_loop_a
	st	#(piece_stage+7),	prep_piece_hor_ptr
prep_piece_hor_loop_b
	st	prep_piece_hor_ptr,	prep_piece_hor_wb_ptr
prep_piece_hor_ptr	insn IMADD_INSN	tmp,	0	; LOAD
	lsr	prep_piece_value
prep_piece_hor_wb_ptr	rorto	tmp,	0	; STORE
	rsbto	#2,	prep_piece_hor_ptr
	insn ALEB_TOC_INSN	#piece_stage,	prep_piece_hor_ptr
	jcs	prep_piece_hor_loop_b		; Loop if #piece_stage <= prep_piece_hor_ptr
	incjne	prep_piece_hor_i,	prep_piece_hor_loop_a
prep_piece_ret	jmp	0

; Stamp piece board subroutine.
;
; This subroutine handles several functions:
;
; * ADDing the piece_stage to the gameboard (Stamping the piece down)
; * BICing the piece_stage to the gameboard (Clearing the piece off)
; * Checking for any common bits (AND result > 0) between piece_stage and gameboard (Checking for collision).
;
; stamp_piece_op must be set to #stamp_piece_coll_op, #stamp_piece_merge_op, or #stamp_piece_clear_op before executing.
;
; When executing stamp_piece_coll_op, tmp will be non-zero if a collision occured.
;
stamp_piece_ps_val	skip	1
stamp_piece_gb_val	skip	1
stamp_piece
	
	; Prep pointers
	st	#piece_stage,	stamp_piece_ps_ptr
	st	#gameboard,	stamp_piece_gb_ptr
	st	piece_x,	tmp
	lsl	tmp	; Multiply piece_x by 2 to get gameboard ptr offset
	addto	tmp,	stamp_piece_gb_ptr
	
	; Prep loop
	st	#-PIECE_STAGE_SIZE,	tmp
stamp_piece_loop
	clr	stamp_piece_ps_val
stamp_piece_ps_ptr	add	stamp_piece_ps_val,	0	; Piece stage LOAD
	
	clr	stamp_piece_gb_val
stamp_piece_gb_ptr	add	stamp_piece_gb_val,	0	; Game board LOAD

	; Now do the operation specified.
stamp_piece_op	jmp	0	; This is set before calling the subroutine
	
stamp_piece_coll_op	; Check for collision
	andto	stamp_piece_ps_val,	stamp_piece_gb_val
	je	stamp_piece_gb_val,	stamp_piece_loop_end
	st	stamp_piece_gb_val,	tmp	; Store colliding bits in tmp
	jmp	stamp_piece_ret
stamp_piece_merge_op
	; Since we know the gameboard is clear underneath the piece, we don't have to clear the bits first
	;bicto	stamp_piece_ps_val,	stamp_piece_gb_val
	addto	stamp_piece_ps_val,	stamp_piece_gb_val
	jmp	stamp_piece_writeback
stamp_piece_clear_op
	bicto	stamp_piece_ps_val,	stamp_piece_gb_val
stamp_piece_writeback
	st	stamp_piece_gb_ptr,	stamp_piece_gb_wb_ptr
stamp_piece_gb_wb_ptr	st	stamp_piece_gb_val,	0
stamp_piece_loop_end	
	; Increment pointers
	inc	stamp_piece_ps_ptr
	inc	stamp_piece_gb_ptr
	incjne	tmp,	stamp_piece_loop
stamp_piece_ret	jmp	0	; Return from subroutine

; Render board subroutine
;
; How:
; Render the gameboard from left to right, top to bottom, to give the most simple console output (avoids ANSI console cursor movement).
;
; LOOP A: Starts at top of the board and then switches to bottom half of the board. The gameboard ptr offset changes from 1 to 0. (or 2 -> 1 -> 0 if using a bigger game board)
; LOOP B: Work down the rows using a single byte bitmask, shifting it right each iteration.
; LOOP C: Work along the columns from 0 to 10, incrementing the gameboard ptr by 2 each iteration.
;         Decide whether to render a block or empty character by ANDing the gameboard ptr value with the current bitmask

; Temporary variables for internal use
render_board_mask	skip	1 ; The row bitmask for selecting the row to render
render_board_col	skip	1 ; The current column iteration loop counter.

render_board
	st	#(GAMEBOARD_STRIDE-1),	render_board_ptr	; Start the render_board_ptr with an offset of 1 to render the top half of the board.
; LOOP A
render_board_loop_a
	addto	#gameboard,	render_board_ptr	; Adjust the render_board_ptr to point into the gameboard
	st	#%1000_0000,	render_board_mask	; Initialize the bitmask for testing the column byte for which row is set
; LOOP B
render_board_loop_b
	st	#(-GAMEBOARD_COLS),	render_board_col	; Prepare column loop counter
; LOOP C
render_board_loop_c
	st	render_board_mask,	tmp
render_board_ptr	insn AND_INSN	tmp,	0	; Indirect AND, store result in tmp
	
	; Print a block or an empty cell depending whether the board & mask > 0
	jne	tmp,	render_board_print_a
	insn OUTC_JMP_INSN	#EMPTY_CHAR,	render_board_print_b	; Print empty char and jump over the block char print
render_board_print_a	outc	#BLOCK_CHAR
render_board_print_b
	addto	#GAMEBOARD_STRIDE,	render_board_ptr	; Move onto next column byte
	incjne	render_board_col,	render_board_loop_c	; If we still have columns to render, continue LOOP C
; END LOOP C
	rsbto	#GAMEBOARD_SIZE,	render_board_ptr	; Reset render_board_ptr to pre-loop state
	
	; Newline to move down to the next row on the console
	outc	#CR_CHAR
	outc	#LF_CHAR

	;lsr	render_board_mask		; Logical shift right (0 into top spot). This moves down a row.
	;jcc	render_board_loop_b		; If we haven't shifted the bitmask all the way out, continue LOOP B.
	insn LSR_JCC_INSN	render_board_mask,	render_board_loop_b
; END LOOP B
	; Offset the render_board_ptr by -1 so the next loop operates over the next lower 8 rows of the board.
	; Also subtract the gameboard address so we can compare with zero. This is added back on at the start of render_board_loop_a.
	rsbto	#(gameboard+1),	render_board_ptr
	; If the render_board_ptr is now < 0, we have just rendered the lowest 8 rows of the board and are done.
	jge	render_board_ptr,	render_board_loop_a	; Otherwise continue LOOP A.
; END LOOP A
render_board_ret	jmp	0		; Return from subroutine.

; line_clr
;
; Clears all full rows from the gameboard.
;
; How:
; 1. Call get_full_lines to generate a bitmask of all the complete rows
; 2. Call rem_bits on each column in the gameboard with a copy of the complete rows bitmask.
; 3. Copy the result back over the gameboard.
;
line_clr_i	skip	1	; We cannot use tmp as loop counter since we call subroutines which overwrite tmp.
line_clr
	; Generate the line clear mask. Result in get_full_lines_mask.
	jsr	get_full_lines_ret,	get_full_lines

	; If the result was 0 and no lines were cleared, we can fastpath and exit now.
	jne	get_full_lines_mask+0,	line_clr_do_remove
	jne	get_full_lines_mask+1,	line_clr_do_remove
	jmp	line_clr_ret	; Fastpath to returning from the subroutine

	; TODO: Count and save the number of bits in get_full_lines_mask for scoring

line_clr_do_remove
	; Prep work. Ensure rem_bits_value is zeroed.
	clr	rem_bits_value+0
	clr	rem_bits_value+1

	; Iterate over each column and call the rem_bits subroutine to remove the bits from the column.
	st	#(-GAMEBOARD_COLS),	line_clr_i	; Prep the loop counter

	; Prepare line_clr_read_ptr_0 ptr to do a load from the gameboard.
	st	#gameboard,	line_clr_read_ptr_0
	; line_clr_read_ptr_1 is always 1 above line_clr_read_ptr_0 and is calculated on the fly every iteration.

; Line clear loop. It will call rem_bits with the line clear mask and each column of the gameboard.
line_clr_loop
	; Copy the line clear mask into the subroutine mask input.
	; This needs to be done every iteration since the rem_bits subroutine zeroes rem_bits_mask
	st	get_full_lines_mask+0,	rem_bits_mask+0	; Prep mask +0
	st	get_full_lines_mask+1,	rem_bits_mask+1	; Prep mask +1

	; Load the current column into the rem_bits subroutine rem_bits_value input
	insn INCTO_INSN	line_clr_read_ptr_0,	line_clr_read_ptr_1	; Prep ptr +1
	; No need to pre-clear load destination since it is zeroed by the subroutine every iteration.
line_clr_read_ptr_0	add	rem_bits_value+0,	0	; Load +0
line_clr_read_ptr_1	add	rem_bits_value+1,	0	; Load +1

	; Call rem_bits subroutine
	jsr	rem_bits_ret,	rem_bits

	; Prepare write back pointers (they're the same addresses as the read pointers)
	st	line_clr_read_ptr_0,	line_clr_write_ptr_0	; Prep ptr +0
	st	line_clr_read_ptr_1,	line_clr_write_ptr_1	; Prep ptr +1
	; Copy the result back into the gameboard
line_clr_write_ptr_0	st	rem_bits_result+0,	0	; Store +0
line_clr_write_ptr_1	st	rem_bits_result+1,	0	; Store +1

	; Iterate gameboard ptr
	addto	#2,	line_clr_read_ptr_0	; Iterate ptr +0
	incjne	line_clr_i,	line_clr_loop	; Loop
line_clr_ret	jmp	0		; Return from subroutine

; get_full_lines
;
; Generates a 2 byte, 16 bit bitmask indicating which rows in the gameboard are filled.
; This is the bitwise AND of all columns in the gameboard.
;
get_full_lines_mask	skip	2

get_full_lines
	st	#(-GAMEBOARD_COLS),	tmp
	st	#0xFF,	get_full_lines_mask+0
	st	#0xFF,	get_full_lines_mask+1
	st	#gameboard,	get_full_lines_ptr_0
get_full_lines_loop
	insn INCTO_INSN	get_full_lines_ptr_0,	get_full_lines_ptr_1
get_full_lines_ptr_0	insn AND_INSN	get_full_lines_mask+0,	0
get_full_lines_ptr_1	insn AND_INSN	get_full_lines_mask+1,	0
	addto	#2,	get_full_lines_ptr_0
	incjne	tmp,	get_full_lines_loop
get_full_lines_ret	jmp	0		; Return from subroutine

; rem_bits
;
; Remove the bits from rem_bits_value in the positions they are set in rem_bits_mask.
; For each bit removed, the more significant bits are shifted right to fill its place.
; The leftmost most significant bits are filled with zeroes.
;
; The output is placed in rem_bits_result.
; rem_bits_mask and rem_bits_value are zeroed as a result of this process.
;
rem_bits_mask	skip	2
rem_bits_value	skip	2
rem_bits_result	skip	2
rem_bits
	; Pre-clear the result
	clr	rem_bits_result+0
	clr	rem_bits_result+1
	st	#-16,	tmp	; Loop 16 times
rem_bits_loop
	lsl	rem_bits_mask+0		; Logical shift left mask (0 -> bit 0)
	rol	rem_bits_mask+1		; (bit 15 -> carry)
	jcc	rem_bits_A		; GOTO A if carry clear
	; If Carry Set
	lsl	rem_bits_value+0		; Logical shift left value (0 -> bit 0)
	rol	rem_bits_value+1		; The carry result is discarded.
	jmp	rem_bits_loop_end
rem_bits_A	; If Carry Clear
	lsl	rem_bits_value+0		; Logical shift left value (0 -> bit 0)
	rol	rem_bits_value+1		; (bit 15 -> carry)
	rol	rem_bits_result+0		; Rotate left to save the carry into result (carry -> bit 0)
	rol	rem_bits_result+1		; Carry from rotating result is discarded.
rem_bits_loop_end	incjne	tmp,	rem_bits_loop	; Loop
rem_bits_ret	jmp	0		; Return from subroutine

; VARIABLES

; Game state
;
lines_cleared	skip	1

piece_kind	skip	1
piece_rotation	skip	1
piece_x	skip	1
piece_y	skip	1

; Game board
;
; The gameboard is made up of bytes stacked vertically.
; There are two bytes end to end for each column, 10 colums wide.
; This makes a 16x10 game board, totalling 20 bytes.
; The lower, even index byte is at the bottom of the board. The higher, odd index byte is at the top.
; The less significant bits in each byte are towards the bottom of the board, the higher significant bits are towards the top.
;
; Ideally we would use three bytes per row to make a 24x10 gameboard in 30 bytes,
; but this increases both gameboard storage size and the code required to deal with it.
;
; Gameboard layout (byte.bit):
;
; 1.7 3.7 5.7 7.7 9.7 11.7 13.7 15.7 17.7 19.7
; 1.6 3.6 5.6 7.6 9.6 11.6 13.6 15.6 17.6 19.6
; 1.5 3.5 5.5 7.5 9.5 11.5 13.5 15.5 17.5 19.5
; 1.4 3.4 5.4 7.4 9.4 11.4 13.4 15.4 17.4 19.4
; 1.3 3.3 5.3 7.3 9.3 11.3 13.3 15.3 17.3 19.3
; 1.2 3.2 5.2 7.2 9.2 11.2 13.2 15.2 17.2 19.2
; 1.1 3.1 5.1 7.1 9.1 11.1 13.1 15.1 17.1 19.1
; 1.0 3.0 5.0 7.0 9.0 11.0 13.0 15.0 17.0 19.0
; 0.7 2.7 4.7 6.7 8.7 10.7 12.7 14.7 16.7 18.7
; 0.6 2.6 4.6 6.6 8.6 10.6 12.6 14.6 16.6 18.6
; 0.5 2.5 4.5 6.5 8.5 10.5 12.5 14.5 16.5 18.5
; 0.4 2.4 4.4 6.4 8.4 10.4 12.4 14.4 16.4 18.4
; 0.3 2.3 4.3 6.3 8.3 10.3 12.3 14.3 16.3 18.3
; 0.2 2.2 4.2 6.2 8.2 10.2 12.2 14.2 16.2 18.2
; 0.1 2.1 4.1 6.1 8.1 10.1 12.1 14.1 16.1 18.1
; 0.0 2.0 4.0 6.0 8.0 10.0 12.0 14.0 16.0 18.0
;
; Neat trick: Since every instruction of the gameboard would normally be a HALT instruction and mostly wasted,
; we can actually use the instruction to clear it's own B value. This gives us gameboard clearing and piece stage clearing "for free".

	data	0xFF		; A wall for the gameboard to provide collisions at -1
	data	0xFF
clear_gameboard
gameboard	;skip	GAMEBOARD_SIZE
	insn CLRA_INSN	gameboard+0,	0
	insn CLRA_INSN	gameboard+1,	0
	insn CLRA_INSN	gameboard+2,	0
	insn CLRA_INSN	gameboard+3,	0
	insn CLRA_INSN	gameboard+4,	0
	insn CLRA_INSN	gameboard+5,	0
	insn CLRA_INSN	gameboard+6,	0
	insn CLRA_INSN	gameboard+7,	0
	insn CLRA_INSN	gameboard+8,	0
	insn CLRA_INSN	gameboard+9,	0
	insn CLRA_INSN	gameboard+10,	0
	insn CLRA_INSN	gameboard+11,	0
	insn CLRA_INSN	gameboard+12,	0
	insn CLRA_INSN	gameboard+13,	0
	insn CLRA_INSN	gameboard+14,	0
	insn CLRA_INSN	gameboard+15,	0
	insn CLRA_INSN	gameboard+16,	0
	insn CLRA_INSN	gameboard+17,	0
	insn CLRA_INSN	gameboard+18,	0
	insn CLRA_INSN	gameboard+19,	0
	insn 0x00000000	,	0xFF	; no-op/clc, but specified as custom instruction se we can set B value.
	insn 0x00000000	,	0xFF	; A wall for the gameboard to provide collisions at 11
clear_gameboard_ret	jmp	0	; Return from subroutine
	

; Piece stage
;
; Piece stage layout (byte.bit):
;
; 1.7 3.7 5.7 7.7
; 1.6 3.6 5.6 7.6
; 1.5 3.5 5.5 7.5
; 1.4 3.4 5.4 7.4
; 1.3 3.3 5.3 7.3
; 1.2 3.2 5.2 7.2
; 1.1 3.1 5.1 7.1
; 1.0 3.0 5.0 7.0
; 0.7 2.7 4.7 6.7
; 0.6 2.6 4.6 6.6
; 0.5 2.5 4.5 6.5
; 0.4 2.4 4.4 6.4
; 0.3 2.3 4.3 6.3
; 0.2 2.2 4.2 6.2
; 0.1 2.1 4.1 6.1
; 0.0 2.0 4.0 6.0
;
clear_piece_stage
piece_stage	;skip	PIECE_STAGE_SIZE
	insn CLRA_INSN	piece_stage+0,	0
	insn CLRA_INSN	piece_stage+1,	0
	insn CLRA_INSN	piece_stage+2,	0
	insn CLRA_INSN	piece_stage+3,	0
	insn CLRA_INSN	piece_stage+4,	0
	insn CLRA_INSN	piece_stage+5,	0
	insn CLRA_INSN	piece_stage+6,	0
	insn CLRA_INSN	piece_stage+7,	0
clear_piece_stage_ret	jmp	0

; Placeholder label to easily see how big the program is from the symbol table
END_OF_PROGRAM
