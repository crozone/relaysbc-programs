; Tetris implementation
; Ryan Crosby 2021
;
; Run from 0x01.
;
; TODO: Description with controls etc.
;

; Constants
;
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
; Also used as a temporary storage register, and as the 
;
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
current_cleared	skip	1

current_piece	skip	1
current_pose	skip	1
current_x	skip	1
current_y	skip	1



; Start of application code
;
run
;	jsr	render_board_ret,	render_board
;	jmp	halt_prog

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

; Prepares to call get_row.
; Sets up pointers within get row to blend the row at current_y with the first row of the piece stage.
prep_get_row
	st	#0	gr_count
	st	#gr_row_out,	gr_dest
	st	#piece_stage,	gs_ps_ptr
	st	#gameboard,	gs_gb_ptr
	st	current_y,	tmp
	lsl	tmp
	addto	tmp,	gs_gb_ptr

prep_get_row_ret	jmp	0		; Return from subroutine

; Get a row of the piece stage, combined with the approprate row of the board.
;
; This is used for rendering the game board to the display,
; as well as stamping the piece stage to the board after a downward collision.
;
; This subroutine is designed to be called 4 times, once for each row.
; Pointers will be advanced by one row after each call.
;
; prep_get_row should be called before the first call.
;
get_row_out	skip	2
gr_ps_fetch	skip	1
gr_count	skip	1
get_row

	inc	gr_count

	clr	tmp
gr_ps_ptr	add	tmp,	0	; Indirect fetch piece stage

	clr	gr_gb_fetch,
gr_gb_ptr	add	gr_gb_fetch,	0

	; Y = X | Y
	bicto	gr_gb_fetch,	tmp
	addto	gr_gb_fetch,	tmp

gr_dest	st	tmp,	0

	inc	gr_ps_ptr
	inc	gr_gb_ptr
	inc	gr_dest

	jo	gr_count,	get_row_ret

get_row_ret	jmp	0	; Return from subroutine


; Check for collision (AND) between the piece stage and the gameboard + current_y
; tmp will be set to non-zero if a collission occured.
; 
cc_count	skip	1
check_cln
	st	#-8,	cc_count
	st	#piece_stage,	cc_ps_ptr	; Prepare piece stage pointer

	st	#gameboard,	cc_gb_ptr	; Prepare gameboard pointer
	st	current_y,	tmp
	lsl	tmp
	addto	tmp,	cc_gb_ptr

cc_loop				; Begin AND loop
	clr	tmp
cc_gb_ptr	add	tmp,	0	; Indirect fetch gameboard into tmp

cc_ps_ptr	insn AND_INSN	tmp,	0	; Indirect AND piece stage byte over tmp. [aa] = [aa] & [bb]

	jne	tmp,	cc_break	; Break out of loop

	inc	cc_gb_ptr
	inc	cc_ps_ptr

	incjne	cc_count,	cc_loop

cc_break	
check_cln_ret	jmp	0		; Return from subroutine

; Shift piece stage by a given number of columns
; +ve column value = to the right of the gameboard = left shifting bits towards MSB
; -ve column value = to the left of the gameboard = right shifting bits towards LSB

shift_stage_n	skip	1
shift_stage
	addto	shift_stage_n,	current_x	; Adjust current piece position	

	st	shift_stage_n,	tmp
	jge	shift_stage_n,	ss_right
ss_left
	lsr	piece_stage+1		; 0 -> bit 7. Bit 0 -> C
	ror	piece_stage+0		; C -> bit 7. Bit 0 -> C
	lsr	piece_stage+3		; 0 -> bit 7. Bit 0 -> C
	ror	piece_stage+2		; C -> bit 7. Bit 0 -> C
	lsr	piece_stage+5		; 0 -> bit 7. Bit 0 -> C
	ror	piece_stage+4		; C -> bit 7. Bit 0 -> C
	lsr	piece_stage+7		; 0 -> bit 7. Bit 0 -> C
	ror	piece_stage+6		; C -> bit 7. Bit 0 -> C

	incjne	tmp,	ss_left

	jmp	shift_stage_ret
ss_right
	neg	tmp
ss_right_loop
	lsl	piece_stage+0		; 0 -> bit 0. Bit 7 -> C
	rol	piece_stage+1		; C -> bit 0. Bit 7 -> C
	lsl	piece_stage+2		; 0 -> bit 0. Bit 7 -> C
	rol	piece_stage+3		; C -> bit 0. Bit 7 -> C
	lsl	piece_stage+4		; 0 -> bit 0. Bit 7 -> C
	rol	piece_stage+5		; C -> bit 0. Bit 7 -> C
	lsl	piece_stage+6		; 0 -> bit 0. Bit 7 -> C
	rol	piece_stage+7		; C -> bit 0. Bit 7 -> C

	incjne	tmp,	ss_right_loop

shift_stage_ret	jmp	0



; Prepare piece buffer
;
; This function takes a piece number and a pose, and writes it to a buffer as 8 separate bytes,
; which is in the same layout as the piece board.
;
; The piece is written to position (0,0), which is the bottom leftmost corner of the buffer.
;
; This uses current_piece and current_pose.

; Private
template_cpy	skip	1
pp_tmp	skip	1
prep_piece
	; Calculate piece ptr
	st	#pieces_arr,	template_ptr
	addto	current_piece,	template_ptr

	; Indirect fetch piece template
	clr	template_cpy
template_ptr	add	template_cpy,	0

	; Clear piece stage buffer
	st	#piece_stage,	clrbuf_ptr
	st	#8,	clrbuf_len
	jsr	clrbuf_ret,	clrbuf

	; TODO: Hard part.
	; Depending on pose,	we need to render the piece template
	; at a different rotation (0=0,	1=90,	2=180,	3=270)

	st	#4,	rshift_n	; Prepare right shift function to do 4 right shifts.

	; For now,	just handle pose = 0 ...
	negto	current_pose,	pp_tmp

pp_case_0	jne	pp_tmp,	pp_case_1

	; Lower row
	st	template_cpy,	piece_stage
	andto	#0x0F,	piece_stage
	; Upper row
	st	template_cpy,	rshift_val
	jsr	rshift_ret,	rshift
	st	rshift_val,	piece_stage+2	; Next row up

pp_case_1	incjne	pp_tmp,	pp_case_2
	jmp	0		; HALT
pp_case_2	incjne	pp_tmp,	pp_case_3
	jmp	0		; HALT
pp_case_3	incjne	pp_tmp,	pp_break
	jmp	0		; HALT
pp_break
prep_piece_ret	jmp	0		; Return from subroutine

; Render buffer subroutine
;
render_ptr	skip	1
render_row	skip	1
render_rows	skip	1		; Rename height?
render_col	skip	1
render_cols	skip	1		; Rename stride?

render_r_rem	skip	1
render_c_rem	skip	1
render_tmp	skip	2
render
	; Calculate starting pointer within buffer.
	; We need to render from the top of the buffer (the end), downwards.
	; Eg, render [4,5], [2,3], [0,1]
	; start_ptr = render_ptr + (2 * render_row) + (2 * (render_rows - 1))

	st	render_ptr,	r_buf_lo

	st	render_row,	tmp
	lsl	tmp
	addto	tmp,	r_buf_lo

	st	render_rows,	tmp
	dec	tmp
	lsl	tmp
	addto	tmp,	r_buf_lo

	insn INCTO_INSN	r_buf_lo,	r_buf_hi

	; Prep outer loop counter
	negto	render_rows,	render_r_rem

r_loop
	clr	render_tmp+0
r_buf_lo	add	render_tmp+0,	0
	clr	render_tmp+1
r_buf_hi	add	render_tmp+1,	0

	; Prep render loop counter
	negto	render_cols,	render_c_rem
r_print_loop	; Start print loop
	; Shift entire temp buffer right
	lsr	render_tmp+1		; 0 -> bit 7. Bit 0 -> C
	ror	render_tmp+0		; C -> bit 7. Bit 0 -> C

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

	rsbto	#2,	r_buf_lo	; Subtract 2 from each pointer
	rsbto	#2,	r_buf_hi
	incjne	render_r_rem,	r_loop
r_loop_end

render_ret	jmp	0

; Clear buffer subroutine
;
clrbuf_ptr	skip	1
clrbuf_len	skip	1
clrbuf
	negto	clrbuf_len,	tmp
	st	clrbuf_ptr,	clrbuf_clr
clrbuf_loop
clrbuf_clr	clr	0		; Indirect clear
	inc	clrbuf_clr
	incjne	tmp,	clrbuf_loop
clrbuf_ret	jmp	0

; Right shift subroutine
;
rshift_val	skip	1
rshift_n	skip	1
rshift	negto	rshift_n,	tmp
rshift_loop	lsr	rshift_val
	incjne	tmp,	rshift_loop
rshift_ret	jmp	0		; Return from subroutine

; GAME BOARD
;
; Left of board is X = 1; right is X = 10
; Bottom of board is Y = 0, top is Y = 19
;
; There is a wall at X = 0 and X = 11
; There is a wall at Y = -1
;
; The game board is made up of 20 rows, of 10 columns each.
; Each row is represented by 2 bytes (16 bits).
; 2 bits represent the walls and are always set to 1.
; 4 additional bits are wasted at the MSB end of the odd bytes.
;
; The left wall is the LSB of the lower byte. The right wall is the 4th bit of the upper byte.
; The left of the board is bit 1 of the lower byte. The right of the board is bit 3 of the higher byte.
; The lowermost row is row Y=0, and is represented by bytes 0 (left) and 1 (right).
; The uppermost row is row Y=19, and is represented by bytes 38 (left) and 39 (right).
;
; BOARD LAYOUT:
;
; ...
; Row Y=3 : Byte 6 --> [ W 1234567 | 89A W XXXX ] <-- Byte 7
; Row Y=2 : Byte 4 --> [ W 1234567 | 89A W XXXX ] <-- Byte 5
; Row Y=1 : Byte 2 --> [ W 1234567 | 89A W XXXX ] <-- Byte 3
; Row Y=0 : Byte 0 --> [ W 1234567 | 89A W XXXX ] <-- Byte 1
;
; ROW LAYOUT:
;
;	LEFT            RIGHT
; X:	W 1 2 3 4 5 6 7   8 9 A W X X X X
;	- - - - - - - -   - - - - - - - -
; Bit:	0 1 2 3 4 5 6 7 | 0 1 2 3 4 5 6 7
;	^ LSB     MSB ^ | ^ LSB     MSB ^
; Byte:	0               | 1
;


	data	0xFF	; Provide a solid boarder "below" the gameboard, at Y=-1.
	data	0xFF	; This simplifies collision detection.
gameboard			; Solid boarder along left and right edge of board
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY
	data	GB_LO_EMPTY
	data	GB_HI_EMPTY



; Piece staging buffer.
; This buffer contains the current piece in the selected pose, in the same format as the game board.
; It is 4 rows high, each row is 2 bytes, just like the game board.
; This allows easy left/right movement of the piece (simple bitwise rotation of each row left or right),
; and easy updating of, or collision checking with, the game board (with bitwise operations).
piece_stage	skip	8
