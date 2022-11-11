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

;; TODO: How do these actually get decoded/used?

; Real | Bits | Hex
;
; 1110 | 0111 | 7
; 0100 | 0010 | 2
t_piece	equ	0x72

; 0110 | 0110 | 6
; 1100 | 0011 | 3
s_piece	equ	0x63

; 1100 | 0011 | 3
; 0110 | 0110 | 6
z_piece	equ	0x36

; 0010 | 0100 | 4
; 1110 | 0111 | 7
l_piece	equ	0x47

; 1110 | 0111 | 7
; 0010 | 0100 | 4
j_piece	equ	0x74

; 0110 | 0110 | 6
; 0110 | 0110 | 6
o_piece	equ	0x66

; 1111 | 1111 | F
; 0000 | 0000 | 0
i_piece	equ	0xF0



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
	; Rotate your head to the left and squint
	; Top
	st	#%1111_1111,	gameboard+19
	st	#%1111_0001,	gameboard+17
	st	#%1111_1001,	gameboard+15
	st	#%1111_1101,	gameboard+13
	st	#%1111_1111,	gameboard+11
	st	#%1111_1111,	gameboard+9
	st	#%1111_1101,	gameboard+7
	st	#%1111_1001,	gameboard+5
	st	#%1111_0001,	gameboard+3
	st	#%1111_1111,	gameboard+1
	; Bottom
	st	#%0000_1111,	gameboard+18
	st	#%0001_1111,	gameboard+16
	st	#%0011_1111,	gameboard+14
	st	#%0111_1110,	gameboard+12
	st	#%1111_1100,	gameboard+10
	st	#%1111_1100,	gameboard+8
	st	#%0111_1110,	gameboard+6
	st	#%0011_1111,	gameboard+4
	st	#%0001_1111,	gameboard+2
	st	#%0000_1111,	gameboard+0
	
	; Print game board
	jsr	render_board_ret,	render_board
	
	outc	#CR_CHAR
	outc	#LF_CHAR
	
	; Do line clear
	jsr	line_clr_ret,	line_clr
	
	; Print game board again
	jsr	render_board_ret,	render_board
	
	outc	#CR_CHAR
	outc	#LF_CHAR
	
	; Halt
	outc	#33	; !
	halt

; Render board subroutine
;
; How:
; Render the gameboard from left to right, top to bottom, to give the most simple console output (avoids ANSI console cursor movement).
;
; LOOP A: Starts at top of the board and then switches to bottom half of the board. The gameboard ptr offset changes from 1 to 0.
; LOOP B: Work down the rows using a single byte bitmask, shifting it right each iteration.
; LOOP C: Work along the columns from 0 to 10, incrementing the gameboard ptr by 2 each iteration.
;         Decide whether to render a block or empty character by ANDing the gameboard ptr value with the current bitmask

; Temporary variables for internal use
render_board_top	skip	1 ; boolean to select top or bottom of the board. 1 for top, 0 for bottom.
render_board_mask	skip	1 ; The row mask for selecting the row to render
render_board_col	skip	1 ; The current column iteration. -10 -> 0 (to allow for increment and jump if not zero)

render_board
	st	#1,	render_board_top
render_board_loop_a
	st	#%1000_0000,	render_board_mask
render_board_loop_b
	st	#gameboard,	render_board_ptr
	addto	render_board_top,	render_board_ptr	; Offset the gameboard ptr by 1 if we're rendering the top half
	st	#-10,	render_board_col	; Prepare column loop counter
render_board_loop_c
	st	render_board_mask,	tmp
render_board_ptr	insn AND_INSN	tmp,	0	; Indirect AND, store result in tmp
	
	; Print a block or an empty cell depending whether the board & mask > 0
	jne	tmp,	render_board_print_a
	outc	#EMPTY_CHAR
	jmp	render_board_print_b
render_board_print_a	outc	#BLOCK_CHAR
render_board_print_b
	addto	#2,	render_board_ptr	; Move onto next column byte
	incjne	render_board_col,	render_board_loop_c	; Row render loop
	
	; Newline to move down to the next row on the console
	outc	#CR_CHAR
	outc	#LF_CHAR

	lsr	render_board_mask		; Logical shift right (0 into top spot). This moves down a row.
	jcc	render_board_loop_b		; Loop if we haven't shifted all the way out yet
	
	; We've shifted all the way out
	; Move onto the other side of the board
	dec	render_board_top
	jeq	render_board_top,	render_board_loop_a	; Move onto bottom half of board

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
	; Prep work. Ensure rem_bits_value is zeroed.
	clr	rem_bits_value+0
	clr	rem_bits_value+1

	; Generate the line clear mask. Result in get_full_lines_mask.
	jsr	get_full_lines_ret,	get_full_lines
	
	; TODO: Count and save the number of bits in get_full_lines_mask for scoring

	; Iterate over each column and call the rem_bits subroutine to remove the bits from the column.
	st	#-10,	line_clr_i	; Prep the loop counter

	; Prepare line_clr_read_ptr_0 ptr to do a load from the gameboard.
	; Start at -2 since line_clr_read_ptr_0 is pre-incremented by 2 every loop.
	st	#gameboard-2,	line_clr_read_ptr_0
	; line_clr_read_ptr_1 is always 1 above line_clr_read_ptr_0 and is calculated on the fly every iteration.

; Line clear loop. It will call rem_bits with the line clear mask and each column of the gameboard.
line_clr_loop
	; Copy the line clear mask into the subroutine mask input.
	; This needs to be done every iteration since the rem_bits subroutine zeroes rem_bits_mask
	st	get_full_lines_mask+0,	rem_bits_mask+0
	st	get_full_lines_mask+1,	rem_bits_mask+1

	; Load the current column into the rem_bits subroutine rem_bits_value input
	; Iterate pointers into game board
	addto	#2,	line_clr_read_ptr_0	; Prep ptr +0
	insn INCTO_INSN	line_clr_read_ptr_0,	line_clr_read_ptr_1	; Prep ptr +1
	
	; No need to pre-clear load destination since it is zeroed by the subroutine every iteration.
	;clr	rem_bits_value+0		; TEST
	;clr	rem_bits_value+1		; TEST
line_clr_read_ptr_0	add	rem_bits_value+0,	0	; Load +0
line_clr_read_ptr_1	add	rem_bits_value+1,	0	; Load +1
	
	; Call rem_bits subroutine
	jsr	rem_bits_ret,	rem_bits
	
	; Prepare write back pointers (they're the same addresses as the read pointers)
	st	line_clr_read_ptr_0,	line_clr_write_ptr_0
	st	line_clr_read_ptr_1,	line_clr_write_ptr_1
	; Copy the result back into the gameboard
line_clr_write_ptr_0	st	rem_bits_result+0,	0
line_clr_write_ptr_1	st	rem_bits_result+1,	0

	incjne	line_clr_i,	line_clr_loop	; Loop
line_clr_ret	jmp	0		; Return from subroutine

; get_full_lines
;
; Generates a 2 byte, 16 bit bitmask indicating which rows in the gameboard are filled.
; This is the bitwise AND of all columns in the gameboard.
;
get_full_lines_mask	skip	2

get_full_lines
	st	#-10,	tmp
	st	#0xFF,	get_full_lines_mask+0
	st	#0xFF,	get_full_lines_mask+1
	st	#gameboard-2,	get_full_lines_ptr_0
get_full_lines_loop
	addto	#2,	get_full_lines_ptr_0
	insn INCTO_INSN	get_full_lines_ptr_0,	get_full_lines_ptr_1
get_full_lines_ptr_0	insn AND_INSN	get_full_lines_mask+0,	0
get_full_lines_ptr_1	insn AND_INSN	get_full_lines_mask+1,	0
	
	incjne	tmp,	get_full_lines_loop
get_full_lines_ret	jmp	0		; Return from subroutine

; rem_bits
;
; Remove the bits from rem_bits_value in the positions they are set in rem_bits_mask.
; For each bit removed, the more significant bits are shifted right to fill its place.
; The leftmost most significant bits are filled with zeroes.
;
; The output is placed in rem_bits_result.
; rem_bits_mask and rem_bits_value are zeroed as a result of the process.
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



; Game board
;
gameboard	skip	20
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


; New piece stage
; TODO

; Placeholder label to easily see how big the program is from the symbol table
END_OF_PROGRAM