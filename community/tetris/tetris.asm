; Tetris implementation
; Ryan Crosby 2022
;
; Run from 0x01.
;
; TODO:
;
; * Description with controls etc.
; * Smarter temporary variable management.
;       Define a small section of memory to use like a shared register pool.
;       Go through the subroutines and replace dedicated temporary variables with shared variables from the register pool that haven't been used yet in the execution flow.
;       Also inline most subroutines, most are called from a single spot.

;

; Constants
;
GB_ROWS	equ	20	; Tetris board has 20 rows visible

GB_LO_EMPTY	equ	0x01	; Empty gameboard with a solid boarder on the left edge. X=0, 1st byte bit 0 (LSB).
GB_HI_EMPTY	equ	0x08	; Empty gameboard with a solid boarder on the right edge. X=11, 2nd byte bit 3.

BLOCK_CHAR	equ	0x23	; #
EMPTY_CHAR	equ	0x20	; Space
BAR_CHAR	equ	0x7C	; |

CR_CHAR	equ	0x0D	; Carriage Return CR \r
LF_CHAR	equ	0x0A	; Linefeed LF \n

; Number constants
ZERO_CHAR	equ	0x30

; Alphabet constants
A_CHAR	equ	0x41
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

; Additional instructions
AND_INSN	equ	0x81800000	; The WRA version of andto. ANDs [aa] and [bb], and stores in [aa].
INCTO_INSN	equ	0x08200000	; Stores [aa] + 1 --> [bb] in one instruction.

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
; Piece patterns are stored as a single byte,	represening the piece in its starting/0 pose.
; The byte makes up two rows of 4 colums,	which is enough to fit every kind of piece lying "flat".
;
; Bits 0-3 are the bottom row,	bits 4-7 are the top row.
; The LSB of the row is the _leftmost_ square,	so pieces are rendered left to right LSB to RSB.
; This is the left to right mirror of the way that bits are normally written out
; left to right RSB to LSB,	so take care.
;

pieces_arr

;; NOTE: Do these need to actually be stored in memory? Or can they be made constants?
;;       Potential saving of 7 words.

; Real | Bits | Hex
;
; 1110 | 0111 | 7
; 0100 | 0010 | 2
t_piece	data	0x72

; 0110 | 0110 | 6
; 1100 | 0011 | 3
s_piece	data	0x63

; 1100 | 0011 | 3
; 0110 | 0110 | 6
z_piece	data	0x36

; 0010 | 0100 | 4
; 1110 | 0111 | 7
l_piece	data	0x47

; 1110 | 0111 | 7
; 0010 | 0100 | 4
j_piece	data	0x74

; 0110 | 0110 | 6
; 0110 | 0110 | 6
o_piece	data	0x66

; 1111 | 1111 | F
; 0000 | 0000 | 0
i_piece	data	0xF0



; Game state
;
lines_cleared	skip	1

current_piece	skip	1
current_pose	skip	1
current_x	skip	1
current_y	skip	1



; Start of application code
;
run
;	jsr	render_board_ret,	render_board
;	jmp	halt_prog

	; Reset score
	clr	lines_cleared
	; Initialize gameboard
	jsr	init_gb_ret,	init_gb
	
	; Outer loop
outer_game_loop
	; Select piece and init piece
	; TODO: Actual implementation, if we have room for a pseudorandom number generator...
	st	#0,	current_piece
	st	#0,	current_pose

	; Inner Loop
inner_game_loop
	; Render board

	; Accept input

	; Check for collision
	; - Undo move.
	; - If downwards collision:
	; -- Stamp game board
	; -- Check for lines cleared
	; -- Clear lines
	; -- Update lines_cleared

	; Check for endgame condition (any bits set on top row)
	; - If endgame, HALT.

	; GOTO Inner Loop.

	; Test loop:
	; 1. Prepare piece buffer
	; 2. Render piece buffer

	st	#1,	shift_stage_n	; Initial piece shift. Right by 1.

	st	#0,	current_piece	; TODO: Randomize
	st	#0,	current_pose	; Initial piece pose = 0
	st	#0,	current_x
	st	#16,	current_y	; Initial piece position in top of board (20 - 4)

	jsr	prep_piece_ret,	prep_piece	; Prepare piece stage
	jsr	shift_stage_ret,	shift_stage	; Move piece right by 1

tst_shift_loop

	;jsr	shift_stage_ret,	shift_stage	; Move piece right by 1
	dec	current_y		; Move piece down by 1
	jsr	check_cln_ret,	check_cln	; Check collision between piece and board
	jne	tmp,	print_hit	; Check if hit

	outc	#M_CHAR
	outc	#I_CHAR
	outc	#S_CHAR
	outc	#S_CHAR
	outc	#CR_CHAR		; \r
	outc	#LF_CHAR		; \n
	jmp	tst_shift_loop

print_hit
	out	tmp
	outc	#H_CHAR		; H
	outc	#I_CHAR		; I
	outc	#T_CHAR		; T
	jmp	halt_prog



	st	#piece_stage,	render_ptr
	st	#0,	render_row
	st	#4,	render_rows
	st	#0,	render_col
	st	#10,	render_cols

	jsr	render_ret,	render
halt_prog
	outc	#CR_CHAR
	outc	#LF_CHAR
	outc	#H_CHAR		; H
	outc	#A_CHAR		; A
	outc	#L_CHAR		; L
	outc	#T_CHAR		; T

	halt

render_board
	st	#gameboard-2,	render_ptr
	st	#0,	render_row
	st	#21,	render_rows
	st	#0,	render_col
	st	#12,	render_cols
	jsr	render_ret,	render

render_board_ret	jmp	0		; Return from subroutine



; Test subroutine to set up an example board, render it, perform line clear, and then render that.
test_0
; TODO: Setup test board

	jsr	render_board
	

test_0_ret	jmp	0		; Return from subroutine

; Render board subroutine
;

; TODO TODO TODO

; Outer loop: Row loop, 16x
; Inner loop: Column loop, 10x

; Strategy: We are going to render the gameboard from left to right, top to bottom, which allows for the most simple console output (avoids ANSI escape codes).
;
; Prepare a mask for comparison. Store 0x01 in a byte.
; Copy the mask into a result variable
; Indirect AND the current gameboard byte with result variable
; 
; 
;
;
;
; Loop over each row.
; For each column, left shift the entire column (both bytes).
; Rotate the carried bit from the top byte most sig bit back into the lowest sig bit of the bottom byte using the ADC (add + carry) command.
; If the LSB is set (if top byte is odd), write a '#'. Else write a ' '.
; After the full 10 columns are processed, write an \r\n
; Loop to next row.
;
; After the subroutine completes, the entire gameboard will have been completely rotated through and restored to the original state,
; and the gameboard will have been printed line by line to the console.
;
; TODO: To render the piece as well:
;     * "Stamp" (AND) the piece onto the game board (we need this function anyway)
;     * Render the gameboard
;     * "Unstamp" (clear bits) the piece back off the game board

render_board_i	skip	1
render_board_j	skip	1

render_board
; Prep column iterator
	st	#-10,	render_board_i
render_board_col_loop
	st	#-16,	render_board_j

render_board_row_loop

	jcc	r_print_e		; Print empty square if C==0
	outc	#BLOCK_CHAR		; Else print block
	jmp	r_after
r_print_e	outc	#EMPTY_CHAR
r_after
	outc	#BAR_CHAR		; | - XXX
	incjne	render_c_rem,	r_print_loop
	; End print loop

	; TODO: Move down 1, left render_cols
	; KLUDGE:
	outc	#CR_CHAR
	outc	#LF_CHAR

render_board_ret	jmp	0		; Return from subroutine.

; Line clear check
;
; Strategy:
; AND all of the bytes in the top half of the board together.
; AND all of the bytes in the bottom half of the board together.
; This creates a 16 bit bitmask with 1s in the positions of full rows that should be cleared.
;
; Column by column, use the bit-shifting algorithm to "delete" bits in positions the bitmask is set to 1.

; For i = -10; i < 0; i++
line_clr_mask	skip	2
line_clr_i	skip	1

line_clr
; Prep the result mask
	st	#255	line_clr_mask+1	; with each of the gameboard columns
	
; AND all of the rows together.
; First do the bottom half of the board (even bytes), then the top half of the board (odd bytes)

; Prep the outer loop which switches between the bottom half and top half of the board.
; Since we don't call any subroutines, it's safe to use tmp for this.
	st	#-2	tmp
line_clr_outer_loop	
	st	#gameboard+2,	line_clr_b_ptr	; Prep the gameboard pointer for the ANDing
	addto	tmp,	line_clr_b_ptr
	st	#-10,	line_clr_i	; Prep the loop counter

; The AND result will be calculated into line_clr_mask+1 always.
; The second (and last) time the outer loop runs, we shift the first value into line_clr_mask+0, and reset line_clr_mask+1.
; Then line_clr_mask+1 is overwritten by the second loop iteration.
	st	line_clr_mask+1,	line_clr_mask+0
	st	#255	line_clr_mask+1

line_clr_col_loop
; The pointer for the current byte in the gameboard.
; This is allows for an indirect AND into an accumulator variable.
line_clr_b_ptr	AND_INSN	line_clr_mask+1,	0

; Increment the current byte pointer by 2 to move over the bytes that make up the current half of the game board. 
	addto	#2,	line_clr_b_ptr

line_clr_col_end	incjne	line_clr_i,	line_clr_col_loop	; Inner loop
line_clr_outer_end	incjne	tmp,	line_clr_outer_loop	; Outer loop

; Now we have a bit mask that contains 1s in all the locations we need to clear lines.
; Iterate over each column and call the rem_bits subroutine to remove the bits from the column.
	st	#-10,	line_clr_i	; Prep the loop counter

; Prepare line_clr_col_bot_ptr and line_clr_col_top_ptr pointers to do a load from the gameboard
	st	#gameboard,	line_clr_col_bot_ptr
	st	#gameboard+1,	line_clr_col_top_ptr

; This is the line clear loop. It will call rem_bits with the line clear mask and each column of the gameboard.
line_clr_col2_loop
; Copy the line clear mask into the subroutine mask input.
; This needs to be done every iteration since the rem_bits subroutine zeroes rem_bits_mask
	st	line_clr_mask+0,	rem_bits_mask+0
	st	line_clr_mask+1,	rem_bits_mask+1

; Copy the current column into the rem_bits subroutine rem_bits_value input
; Need to indirect load. No need to clear rem_bits_value first since it is zeroed by the subroutine itself.
line_clr_col_bot_ptr	add	rem_bits_value+0,	0
line_clr_col_top_ptr	add	rem_bits_value+1,	0
	
; Call the rem_bits subroutine
	jsr	rem_bits_ret,	rem_bits
	
; Prepare copy back pointers
	st	line_clr_col_bot_ptr,	line_clr_col_bot_ptr2
	st	line_clr_col_top_ptr,	line_clr_col_top_ptr2
; Copy the result back over the column
line_clr_col_bot_ptr2	st	rem_bits_result+0,	0
line_clr_col_top_ptr2	st	rem_bits_result+1,	0
; Update pointers for the next iteration
	addto	#2,	line_clr_col_bot_ptr
	addto	#2,	line_clr_col_top_ptr
; Loop
	incjne	line_clr_i,	line_clr_col2_loop

line_clr_ret	jmp	0		; Return from subroutine

; rem_bits
;
; Remove the bits from rem_bits_val in the positions they are set in rem_bits_mask.
; For each bit removed, the more significant bits are shifted downwards to fill its place.
; The most significant bits are filled with zeroes.
; The output is placed in rem_bits_result.
;
rem_bits_mask	skip	2
rem_bits_value	skip	2
rem_bits_result	skip	2
rem_bits
	st	#-16,	tmp	; Loop 16 times
rem_bits_loop
	lsl	rem_bits_mask+0		; Logical shift left mask (0 -> bit 0)
	rol	rem_bits_mask+1		; (bit 15 -> carry)
	jcc	rem_bits_A		; GOTO A if carry clear
	; If Carry Set
	lsl	rem_bits_value+0		; Logical shift left value
	rol	rem_bits_value+1
	jmp	rem_bits_end
rem_bits_A	; Else
	lsl	rem_bits_value+0		; Logical shift left value (0 -> bit 0)
	rol	rem_bits_value+1		; (bit 15 -> carry)
	rol	rem_bits_result+0		; Rotate left into result (carry -> bit 0)
	rol	rem_bits_result+1		; (bit 15-> carry)
rem_bits_end	incjne	tmp,	rem_bits_loop	; Loop
rem_bits_ret	jmp	0		; Return



; Game board
;
gameboard	skip	20
;
; The gameboard is made up of bytes stacked vertically.
; There are two bytes end to end for each column, 10 colums wide.
; This makes a 16x10 game board, totalling 20 bytes.
; The lower address, even index byte is at the bottom of the board, the higher address, odd index byte is at the top.
; The less significant bits in each byte are towards the bottom of the board, the higher significant bits are towards the top.
;
; Ideally we would use three bytes per row to make a 24x10 gameboard in 30 bytes,
; but we simply don't have the room for it.
;
; Gameboard layout (byte.bit):
;
; 1.7 3.7 5.7 7.7 9.7
; 1.6 3.6 5.6 7.6 9.6
; 1.5 3.5 5.5 7.5 9.5
; 1.4 3.4 5.4 7.4 9.4
; 1.3 3.3 5.3 7.3 9.3
; 1.2 3.2 5.2 7.2 9.2
; 1.1 3.1 5.1 7.1 9.1
; 1.0 3.0 5.0 7.0 9.0
; 0.7 2.7 4.7 6.7 8.7
; 0.6 2.6 4.6 6.6 8.6
; 0.5 2.5 4.5 6.5 8.5
; 0.4 2.4 4.4 6.4 8.4
; 0.3 2.3 4.3 6.3 8.3
; 0.2 2.2 4.2 6.2 8.2
; 0.1 2.1 4.1 6.1 8.1
; 0.0 2.0 4.0 6.0 8.0


; New piece stage
; TODO