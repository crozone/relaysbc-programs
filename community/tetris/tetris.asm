; Tetris implementation
; Ryan Crosby 2021
;
; Run from 0x01.
;
; TODO: Description with controls etc.
;

; Catch for any indirect jumps to null (0x00).
; Also serves as a temporary register or discard register for data.
;
	org	0x00
	halt

; ENTRY POINT
	org	0x01
exec	jmp	run	; Jump to start of program

; Constants
;
block_char	data	0x23	; #
empty_char	data	0x20	; Space
newline_char	data	0x0D	; Carriage Return CR \r
	data	0x0A	; Linefeed LF \n

; Pieces templates
;
test_piece	data	0x80
	data	0x01

; T piece
;
t_piece
;
; 0000 = 0
; 1110 = E
; 0100 = 4
; 0000 = 0
	data	0x0E
	data	0x40
; 0100 = 4
; 1100 = C
; 0100 = 4
; 0000 = 0
	data	0x4C
	data	0x40
; 0100 = 4
; 1110 = E
; 0000 = 0
; 0000 = 0
	data	0x4E
	data	0x00
; 0100 = 4
; 0110 = 6
; 0100 = 4
; 0000 = 0
	data	0x46
	data	0x40

; S piece
;
s_piece
;
; 0110 = 6
; 0100 = 4
; 1100 = C
; 0000 = 0
	data	0x64
	data	0xC0
; 1000 = 8
; 1110 = E
; 0010 = 2
; 0000 = 0
	data	0x8E
	data	0x20


; Game state
;
;score	data	2;
gameboard	data	25 ; 20 x 10 squares = 200 bits = 25 bytes




draw_loop_i	skip	1
run	; Start of application code
	
	st	#-4, draw_loop_i
	st	#t_piece, piece_ptr
	st	#0, pose
	
draw_loop_start
	; Draw piece
	st	#0, erase
	jsr	draw_piece_ret, draw_piece
	; Erase piece
	st	#1, erase
	jsr	draw_piece_ret, draw_piece
	
	; Next pose. TODO: How to know how many poses there are for a certian piece kind?
	inc	pose
	
	incjne	draw_loop_i, draw_loop_start
	
	outc	0x45 ; H
	outc	0x41 ; A
	outc	0x4C ; L
	outc	0x54 ; T
	
	halt

; Test code for printing piece in all 4 poses (0, 1, 2, 3)
;
; Arguments
piece_ptr	skip	1 ; Address of piece
pose	skip	1 ; Pose (angle) of piece. 0, 1, 2, 3.
erase	skip	1 ; If not zero, write the piece in spaces instead of block character, in order to erase it.
; Private
tmp_piece	skip	2 ; Temp storage for piece
loop_i	skip	1 ; Loop i counter
loop_j	skip	1 ; Loop counter

draw_piece
	; If erase, set the char to block char. Else, set it to empty char.
	jne	erase, use_erase_char
	st	block_char, print_char
	jmp	continue
use_erase_char	st	empty_char, print_char
continue
	; Calculate and store offset from piece start
	lsl	pose	; Multiply pose by 2 to get bytes offset
	
	; Setup indirect pointers to piece
	st	piece_ptr, cpy_A
	addto	pose, cpy_A
	st	cpy_A, cpy_B
	inc	cpy_B
	
	lsr	pose ; Restore pose

	; Indirect fetch
	clr	tmp_piece
cpy_A	add	tmp_piece, 0

	; Indirect fetch
	clr	tmp_piece+1
cpy_B	add	tmp_piece+1, 0
	
	st	#-4, loop_i	; Prep loop counter
loop_outer
	clr	cur_mov_n
	st	#-4, loop_j	; Prep loop counter
	
loop_drawline
	lsl	tmp_piece+1	; Shift left. Most sig bit goes into carry, 0 goes into least sig bit.
	rol	tmp_piece
	jcs	do_block
	inc	cur_mov_n ; Increment the number of empty blocks we will skip
	jmp	after
do_block	jsr	cur_mov_ret, cur_mov ; Fill in all the previous empty blocks
	clr	cur_mov_n
print_char	outc	#0	; Print character. Will be changed by setup code based on "erase" value.
after	incjne	loop_j, loop_drawline

	outc	newline_char	; New line
	outc	newline_char+1
	incjne	loop_i, loop_outer
draw_piece_ret	jmp	0

cur_mov_n	skip	1
cur_mov
	jeq	cur_mov_n, cur_mov_ret
	st	#0x30, move_char
	addto	cur_mov_n, move_char
	; CSI n C
	outc	#0x1B	; ESC
	outc	#0x5B	; [
move_char	outc	0	; 1-9 character right
	outc	#0x43	; C (A = Up, B = Down, C = Forward, D = Back)
cur_mov_ret	jmp	0


