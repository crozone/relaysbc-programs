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
	; Setup testing gameboard	
	st	#FF,	gameboard+0
	st	#F1,	gameboard+1
	st	#8F,	gameboard+2
	st	#FF,	gameboard+3
	st	#FF,	gameboard+4
	st	#FF,	gameboard+5
	st	#FF,	gameboard+6
	st	#5F,	gameboard+7
	st	#FF,	gameboard+8
	st	#FF,	gameboard+9
	st	#FF,	gameboard+10
	st	#FF,	gameboard+11
	st	#FF,	gameboard+12
	st	#FF,	gameboard+13
	st	#FF,	gameboard+14
	st	#FF,	gameboard+15
	st	#FF,	gameboard+16
	st	#FF,	gameboard+17
	st	#FF,	gameboard+18
	st	#FF,	gameboard+19
	
	
	; Print game board
	jsr	render_board_ret,	render_board
	halt
	
	; Do line clear
	jsr	line_clr_ret,	line_clr
	
	; Print game board again
	jsr	render_board_ret,	render_board
	
	; Halt
	halt


; Render board subroutine
;
; Strategy: We are going to render the gameboard from left to right, top to bottom, which allows for the most simple console output (avoids ANSI escape codes).
;
; SET board offset = 1
;
; LOOP A - Starts at top of the board and then switches to bottom half of the board
; Store the current board byte offset into the board byte index. 1 for the top half of the board, 0 for the bottom half.
; Prepare a mask for comparison. Store 0x80 in a byte.
;
; LOOP B - Works along the the row
; DO LOOP C
; Then:
;    

; LOOP C - Works left to right across the columns
; Copy the mask into a result variable
; Indirect AND the current gameboard byte with result variable
; Print an '#' if the result is > 1, else print ' '
; 
; Rotate the mask right.
; If carry not set, go 
; If carry is set, we're done with the top half of the board.

; Temporary variables for internal use
render_board_top	skip	1 ; byte offset to select top or bottom of the board. 1 for top, 0 for bottom.
render_board_mask	skip	1 ; The row mask for selecting the row to render
render_board_col	skip	1 ; The current column iteration. -10 -> 0 (to allow for increment and jump if not zero)

render_board
; Prep column iterator
	st	#1,	render_board_top
render_board_loop_a
	st	#80,	render_board_mask
render_board_loop_b
	st	#gameboard,	render_board_ptr
	addto	render_board_top,	render_board_ptr
	st	#-10,	render_board_col
render_board_loop_c
	clr	tmp
render_board_ptr	add	tmp,	0	; Load
	
	andto	render_board_mask,	tmp
	jne	tmp,	render_board_print_a
	outc	#ZERO_CHAR
	jmp	render_board_print_b
render_board_print_a	outc	#ZERO_CHAR+1
render_board_print_b
	addto	#2,	render_board_ptr	; Move onto next column byte
	incjne	render_board_col,	render_board_loop_c	; Row render loop

	outc	#CR_CHAR
	outc	#LF_CHAR

	lsr	render_board_mask		; Logical shift right (0 into top spot). This moves down a row.
	jcc	render_board_loop_b		; Loop if we haven't shifted all the way out yet
	
	; We've shifted all the way out
	; Move onto the other side of the board
	dec	render_board_top
	jeq	render_board_top,	render_board_loop_a	; Move onto bottom half of board

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
; 01.7 03.7 05.7 07.7 09.7 11.7 13.7 15.7 17.7 19.7
; 01.6 03.6 05.6 07.6 09.6 11.6 13.6 15.6 17.6 19.6
; 01.5 03.5 05.5 07.5 09.5 11.5 13.5 15.5 17.5 19.5
; 01.4 03.4 05.4 07.4 09.4 11.4 13.4 15.4 17.4 19.4
; 01.3 03.3 05.3 07.3 09.3 11.3 13.3 15.3 17.3 19.3
; 01.2 03.2 05.2 07.2 09.2 11.2 13.2 15.2 17.2 19.2
; 01.1 03.1 05.1 07.1 09.1 11.1 13.1 15.1 17.1 19.1
; 01.0 03.0 05.0 07.0 09.0 11.0 13.0 15.0 17.0 19.0
; 00.7 02.7 04.7 06.7 08.7 10.7 12.7 14.7 16.7 18.7
; 00.6 02.6 04.6 06.6 08.6 10.6 12.6 14.6 16.6 18.6
; 00.5 02.5 04.5 06.5 08.5 10.5 12.5 14.5 16.5 18.5
; 00.4 02.4 04.4 06.4 08.4 10.4 12.4 14.4 16.4 18.4
; 00.3 02.3 04.3 06.3 08.3 10.3 12.3 14.3 16.3 18.3
; 00.2 02.2 04.2 06.2 08.2 10.2 12.2 14.2 16.2 18.2
; 00.1 02.1 04.1 06.1 08.1 10.1 12.1 14.1 16.1 18.1
; 00.0 02.0 04.0 06.0 08.0 10.0 12.0 14.0 16.0 18.0


; New piece stage
; TODO