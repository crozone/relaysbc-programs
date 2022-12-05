; Tetris implementation
; Ryan Crosby 2022
;
; Run from 0x01.
;
; Controls:
;
; Relay computer numpad is used to control the game.
;
; 2: Move piece down
; 4: Move piece left
; 6: Move piece right
; 7: Rotate piece left
; 9: Rotate piece right
;
; Game is rendered to console output.
;
; TODO:
;
; * Game over (Current code infinite loops on game over)
; * Further optimise code to free up some instruction space to implement above TODOs.
;

; =========
; Constants
; =========

; Gameboard parameters
; These constants are used for convenience. Changing the value won't change the actual sizes of the gameboards, code will need to be modified as well.
GAMEBOARD_STRIDE	equ	2	; How many bytes high is the gameboard. 2 bytes = 16 rows.
GAMEBOARD_COLS	equ	10	; How many columns wide is the gameboard. This is generic enough that it can be adjusted without altering any code.
GAMEBOARD_SIZE	equ	(GAMEBOARD_STRIDE*GAMEBOARD_COLS)	; Gameboard total size = stride * columns

PIECE_STAGE_SIZE	equ	(GAMEBOARD_STRIDE*4)	; The piece stage is the same height as the gameboard, but only 4 wide.

PIECE_X_OFFSET	equ	3	; The piece always spawns at x = 0. This offsets the piece so that x = 0 aligns with the center of the board.

SPACE_CHAR	equ	0x20	; Space
BLOCK_CHAR	equ	0x23	; #
EMPTY_CHAR	equ	0x7E 	; ~
BAR_CHAR	equ	0x7C	; |

CR_CHAR	equ	0x0D	; Carriage Return CR \r
LF_CHAR	equ	0x0A	; Linefeed LF \n

; Additional custom instructions
; To use these, call them like: insn INCTO_INSN aa, bb
IMADD_INSN	equ	0xC0800000	; aa + [bb] --> [aa]. Immediate version of ADD. If aa is 0, allows single instruction LOAD of [bb] to [0].
AND_INSN	equ	0x81800000	; The WRA version of andto. ANDs [aa] and [bb], and stores in [aa].
CLRA_INSN	equ	0x81000000	; Stores 0 --> [aa]. Implemented as [aa] & 0 --> [aa].
INCA_INSN	equ	0x80200000	; Stores [aa] + 1 --> [aa] in one instruction.
INCTO_INSN	equ	0x08200000	; Stores [aa] + 1 --> [bb] in one instruction.
ALTB_TOC_INSN	equ	0x00C00000	; Stores [aa] < [bb] --> Carry.
ALEB_TOC_INSN	equ	0x00E00000	; Stores [aa] <= [bb] --> Carry.
ST_JMP_INSN	equ	0x08080000	; Stores [aa] --> [bb] and jumps to bb.
OUTC_JMP_INSN	equ	0x98080000	; Writes [aa] to the console and jumps to bb. WRA and WRB are set to make OUT write to console.
LSR_JCC_INSN	equ	0x820A0000	; Rotates [aa] right, writes the result back to [aa], and jumps if the shifted out bit (carry output) was clear.
INCJMP_INSN	equ	0x80280000	; Stores [aa] + 1 --> [aa] and unconditionally jumps to bb

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

; ================
; Application code
; ================

; Temporary variable tmp at address 0x00.
;
; Used as a halt catch for any jumps to null (0x00). This usually indicates a subroutine hasn't had its return address set.
; Also used as a temporary storage register, and sometimes as the return value for subroutines that only need to return a status.

	org	0x00
stop
tmp	halt

; ENTRY POINT
	org	0x01
main
	; Clear all variables and gameboard

lines_cleared	insn CLRA_INSN	lines_cleared,	0
piece_kind	insn CLRA_INSN	piece_kind,	0
piece_rotation	insn CLRA_INSN	piece_rotation,	0
piece_x	insn CLRA_INSN	piece_x,	0
piece_y	insn CLRA_INSN	piece_y,	0
undo_retry_count	insn CLRA_INSN	undo_retry_count,	0

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

	insn 0x00000000	,	0xFF	; A wall for the gameboard to provide collisions at column -1
	insn 0x00000000	,	0xFF
gameboard
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
	insn 0x00000000	,	0xFF	; A wall for the gameboard to provide collisions at column 11
main_next_piece
	; Clear stamp flag
stamp_flag	insn CLRA_INSN	stamp_flag,	0
	; Clear hard drop flag
hard_drop_flag	insn CLRA_INSN	hard_drop_flag,	0

	; Choose the next piece kind.
	; TODO: Actual random generator. Currently only cycles through pieces incrementally.
	; Increment from 0 -> 6, then wrap.
	insn ALEB_TOC_INSN	#6,	piece_kind	; Set carry if piece_kind >= 6.
	adcto	#1,	piece_kind	; If carry set, increment by 2, otherwise increment by 1.
	andto	#0x07,	piece_kind	; Clear all bits above first three so that value wraps.
	
	; Reset piece rotation and location.
prev_piece_rotation	insn CLRA_INSN	prev_piece_rotation,	0
prev_piece_x	insn CLRA_INSN	prev_piece_x,	0
prev_piece_y	insn CLRA_INSN	prev_piece_y,	0
	; We don't have to reset the current piece_x, piece_y, piece_rotation here since
	; undo_piece_state is about to do it for us from the prev_ values we just cleared.
	
main_undo_then_render
	; Guard against an infinite undo loop. If we're in one, it means a GAME OVER condition.
	incjne	undo_retry_count,	main_not_game_over	; Check if out of undo retries.
	insn OUTC_JMP_INSN	#0x58,	stop	; Print 'X' and halt.
main_not_game_over
	jsr	undo_piece_state_ret,	undo_piece_state
main_render_fresh_piece
	; Clear any existing piece from the stage
	
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
piece_stage
	insn CLRA_INSN	piece_stage+0,	0
	insn CLRA_INSN	piece_stage+1,	0
	insn CLRA_INSN	piece_stage+2,	0
	insn CLRA_INSN	piece_stage+3,	0
	insn CLRA_INSN	piece_stage+4,	0
	insn CLRA_INSN	piece_stage+5,	0
	insn CLRA_INSN	piece_stage+6,	0
	insn CLRA_INSN	piece_stage+7,	0
	
	; Prepare a piece by rendering current piece_kind at piece_rotation
	jsr	prep_piece_ret,	prep_piece
	
	; Shift the piece to the correct y
	st	piece_y,	tmp
	jsr	shift_piece_ret,	shift_piece
	
	; If tmp is non-zero, piece collided with the bottom of the board.
	; Since the player isn't attempting to drop the piece, and we're re-rendering the state,
	; we don't actually care if there was a floor collision.
	; We only care if there's a gameboard collision.
main_check_collision
	; Check if there is going to be a collision
	st	#stamp_piece_coll_op,	stamp_piece_op
	jsr	stamp_piece_ret,	stamp_piece
	jne	tmp,	main_undo_then_render	; We have a collision. Undo changes and re-render.
	st	#-2,	undo_retry_count	; Reset retry count every time an undo isn't required.
main_full_render
	; Stamp to board
	st	#stamp_piece_merge_op,	stamp_piece_op
	jsr	stamp_piece_ret,	stamp_piece
	
	; If stamp flag set, clear the completed lines and do not unstamp it from the board. Instead, move onto the next piece.
	jeq	stamp_flag,	main_no_stamp_flag
	; Clear completed lines
	jsr	line_clr_ret,	line_clr
	jmp	main_next_piece
main_no_stamp_flag
	; Print game board to console
	jsr	render_board_ret,	render_board

	; Clear piece from board
	st	#stamp_piece_clear_op,	stamp_piece_op
	jsr	stamp_piece_ret,	stamp_piece

	; Save the piece state so that if the change causes a collision, previous state can be restored.
	jsr	save_piece_state_ret,	save_piece_state

	; ----------
	; Read input
	; ----------
main_read_input
	inwait	tmp
	neg	tmp	; Invert tmp so we can incjeq
	
	; --------------
	; Input 2 = Drop
	; --------------
	inc	tmp
	incjeq	tmp,	main_move_drop
	; --------------
	; Input 4 = Left
	; --------------
	inc	tmp
	incjeq	tmp,	main_move_left
	; --------------
	; Input 6 = Right
	; --------------
	inc	tmp
	incjeq	tmp,	main_move_right
	; --------------
	; Input 7 = Rotate left
	; --------------
	incjeq	tmp,	main_rot_left
	; --------------
	; Input 8 = Hard drop
	; --------------
	incjeq	tmp,	main_hard_drop
	; --------------
	; Input 9 = Rotate right
	; --------------
	incjeq	tmp,	main_rot_right

	; Unknown input, read user input again.
	insn OUTC_JMP_INSN	#0x3F,	main_read_input	; Print '?'
main_move_drop
	; Move piece y down, and also shift piece stage down
	dec	piece_y
	st	#-1,	tmp
	jsr	shift_piece_ret,	shift_piece
	
	; Check collision with floor
	jeq	tmp,	main_move_drop_2
	; We had a floor collision.
	; Set the stamp flag. The piece will be stamped during main_full_render.
	insn INCJMP_INSN	stamp_flag,	main_full_render	; Re-render board and restart game loop.
main_move_drop_2
	; Check collision with gameboard
	st	#stamp_piece_coll_op,	stamp_piece_op
	jsr	stamp_piece_ret,	stamp_piece
	jeq	tmp,	main_move_drop_3	; If no collision, jump to main_move_drop_3
	; We had a gameboard collision downwards.
	; Set the stamp flag. The piece will be stamped during main_full_render.
	insn INCJMP_INSN	stamp_flag,	main_undo_then_render	; Undo piece movement to move piece back up one, then re-render board and restart game loop.
main_move_drop_3
	; No collision.
	je	hard_drop_flag,	main_full_render	; No hard drop, re-render board.
	; Hard drop.
	; We skip the main loop where the previous piece position is saved, so update the prevous y manually here.
	st	piece_y,	prev_piece_y
	jmp	main_move_drop	; Immediately do the next drop.
main_move_left
	dec	piece_x
	jmp	main_check_collision
main_move_right
	insn INCJMP_INSN	piece_x,	main_check_collision
main_rot_left
	dec	piece_rotation
	jmp	main_render_fresh_piece
main_rot_right
	insn INCJMP_INSN	piece_rotation,	main_render_fresh_piece
main_hard_drop
	insn INCJMP_INSN	hard_drop_flag,	main_move_drop
main_end

save_piece_state
	st	piece_rotation,	prev_piece_rotation
	st	piece_x,	prev_piece_x
	st	piece_y,	prev_piece_y
save_piece_state_ret	jmp	0

undo_piece_state
	st	prev_piece_rotation,	piece_rotation
	st	prev_piece_x,	piece_x
	st	prev_piece_y,	piece_y
undo_piece_state_ret	jmp	0

; Prepare piece stage subroutine
; piece_kind = which piece to render. {0,1,2,3,4,5,6}
;
; Piece rotation. 4 different values for each direction. {0,1,2,3}. Only uses bottom two bits, so can increment forever.
;
prep_piece
	st	piece_kind,	prep_piece_target	; We're rendering the current piece_kind
	
	; Calculate jump table address for piece value
	;
	; Jump address = prep_piece_jmp + (2 * prep_piece_number) + prep_piece_rot.1
	;
	; Get the second bit from prep_piece_rot into carry flag
	lsrto	piece_rotation,	tmp	; We're rendering the current piece_rotation
	lsr	tmp
	adcto	prep_piece_target,	prep_piece_target
	; Add jump table base address
	addto	#prep_piece_jmp,	prep_piece_target
	; Do the jump
prep_piece_target	jmp	0
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

	; If piece_rotation.0 is set, render horizontally, else render vertically.
	jo	piece_rotation,	prep_piece_hor
prep_piece_vert
	st	prep_piece_value,	piece_stage+5
	andto	#0xF0,	piece_stage+5	; Clear lower 4 bits
	st	#-4,	tmp
prep_piece_vert_loop	lsl	prep_piece_value
	incjne	tmp,	prep_piece_vert_loop
	st	prep_piece_value,	piece_stage+3
	jmp	prep_piece_ret
prep_piece_hor
prep_piece_hor_i	equ	prep_piece_target		; Reuse prep_piece_target as the outer loop variable.
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

; shift_piece subroutine.
;
; Shifts the piece stage downwards by the set amount stored negated in tmp.
; If the piece is shifted to the bottom of the board, stops and returns non-zero in tmp.
shift_piece
	jeq	tmp,	shift_piece_ret
shift_piece_loop
	jo	piece_stage+6,	shift_piece_ret
	jo	piece_stage+4,	shift_piece_ret
	jo	piece_stage+2,	shift_piece_ret
	jo	piece_stage+0,	shift_piece_ret
	
	lsr	piece_stage+7
	ror	piece_stage+6
	lsr	piece_stage+5
	ror	piece_stage+4
	lsr	piece_stage+3
	ror	piece_stage+2
	lsr	piece_stage+1
	ror	piece_stage+0
	incjne	tmp,	shift_piece_loop
shift_piece_ret	jmp	0	; Return from subroutine

; stamp_piece: Stamp piece board subroutine.
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
stamp_piece
	; Prep pointers
	st	#piece_stage,	stamp_piece_ps_ptr
	st	#(gameboard+(PIECE_X_OFFSET*2)),	stamp_piece_gb_ptr
	addto	piece_x,	stamp_piece_gb_ptr
	addto	piece_x,	stamp_piece_gb_ptr	; stamp_piece_gb_ptr = #gameboard + 2 * piece_x
	
	; Prep loop
	st	#-PIECE_STAGE_SIZE,	tmp
stamp_piece_loop

stamp_piece_ps_val	insn CLRA_INSN	stamp_piece_ps_val,	0	; Self clearing variable stamp_piece_ps_val
stamp_piece_ps_ptr	add	stamp_piece_ps_val,	0	; Piece stage LOAD
	
stamp_piece_gb_val	insn CLRA_INSN	stamp_piece_gb_val,	0	; Self clearing variable stamp_piece_gb_val
stamp_piece_gb_ptr	add	stamp_piece_gb_val,	0	; Game board LOAD

	; Now do the operation specified.
stamp_piece_op	jmp	0	; This is set before calling the subroutine
	
stamp_piece_coll_op	; Check for collision
	andto	stamp_piece_ps_val,	stamp_piece_gb_val
	jeq	stamp_piece_gb_val,	stamp_piece_loop_end	; If collision didn't occur, keep looping.
	; Collision occured.
	st	stamp_piece_gb_val,	tmp	; Store colliding bits in tmp
	jmp	stamp_piece_ret		; Break out of loop and exit
stamp_piece_merge_op
	; Since we know the gameboard is clear underneath the piece, we don't have to clear the bits first
	;bicto	stamp_piece_ps_val,	stamp_piece_gb_val
	addto	stamp_piece_ps_val,	stamp_piece_gb_val
	jmp	stamp_piece_writeback
stamp_piece_clear_op
	bicto	stamp_piece_ps_val,	stamp_piece_gb_val
stamp_piece_writeback
	st	stamp_piece_gb_ptr,	stamp_piece_gb_wb_ptr
stamp_piece_gb_wb_ptr	st	stamp_piece_gb_val,	0	; Game board STORE
stamp_piece_loop_end	
	; Increment pointers
rem_bits_mask	insn INCA_INSN	stamp_piece_ps_ptr,	0	; Variable storage for rem_bits_mask, in rem_bits
	insn INCA_INSN	stamp_piece_gb_ptr,	0
	incjne	tmp,	stamp_piece_loop
stamp_piece_ret	jmp	0	; Return from subroutine

; render_board: Render board subroutine
;
; How:
; Render the gameboard from left to right, top to bottom, to give the most simple console output (avoids ANSI console cursor movement).
;
; LOOP A: Starts at top of the board and then switches to bottom half of the board. The gameboard ptr offset changes from 1 to 0. (or 2 -> 1 -> 0 if using a bigger game board)
; LOOP B: Work down the rows using a single byte bitmask, shifting it right each iteration.
; LOOP C: Work along the columns from 0 to 10, incrementing the gameboard ptr by 2 each iteration.
;         Decide whether to render a block or empty character by ANDing the gameboard ptr value with the current bitmask
;
render_board
	st	#(GAMEBOARD_STRIDE-1),	render_board_ptr	; Start the render_board_ptr with an offset of 1 to render the top half of the board.
; LOOP A
render_board_loop_a
	addto	#gameboard,	render_board_ptr	; Adjust the render_board_ptr to point into the gameboard. TODO: Move out of loop after implementing ALEB_TOC_INSN below since this won't be changed.
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
render_board_print_a
line_clr_i	outc	#BLOCK_CHAR		; Used as variable storage for line_clr_i in line_clr
render_board_print_b
	addto	#GAMEBOARD_STRIDE,	render_board_ptr	; Move onto next column byte
	incjne	render_board_col,	render_board_loop_c	; If we still have columns to render, continue LOOP C
; END LOOP C
	rsbto	#GAMEBOARD_SIZE,	render_board_ptr	; Reset render_board_ptr to pre-loop state
	
	; Newline to move down to the next row on the console
	; outc ignores bb, allowing it to be used as variable storage.
render_board_mask	outc	#CR_CHAR		; render_board_mask: The row bitmask for selecting the row to render
render_board_col	outc	#LF_CHAR		; render_board_col: The current column iteration loop counter.

	;lsr	render_board_mask		; Logical shift right (0 into top spot). This moves down a row.
	;jcc	render_board_loop_b		; If we haven't shifted the bitmask all the way out, continue LOOP B.
	insn LSR_JCC_INSN	render_board_mask,	render_board_loop_b
; END LOOP B
	; Offset the render_board_ptr by -1 so the next loop operates over the next lower 8 rows of the board.
	; Also subtract the gameboard address so we can compare with zero. This is added back on at the start of render_board_loop_a.
	rsbto	#(gameboard+1),	render_board_ptr	; TODO: Can replace with ALEB_TOC_INSN + jcs
	; If the render_board_ptr is now < 0, we have just rendered the lowest 8 rows of the board and are done.
	jge	render_board_ptr,	render_board_loop_a	; Otherwise continue LOOP A.
	
get_full_lines_mask	outc	#CR_CHAR		; get_full_lines_mask: variable for get_full_lines
	outc	#LF_CHAR
; END LOOP A
render_board_ret	jmp	0		; Return from subroutine.

; line_clr: Clears all full rows from the gameboard.
;
; How:
; 1. Call get_full_lines to generate a bitmask of all the complete rows
; 2. Call rem_bits on each column in the gameboard with a copy of the complete rows bitmask.
; 3. Copy the result back over the gameboard.
;
line_clr
	; Generate the line clear mask. Result in get_full_lines_mask.
	jsr	get_full_lines_ret,	get_full_lines

	; If the result was 0 and no lines were cleared, we can fastpath and exit now.
	jne	get_full_lines_mask+0,	line_clr_do_remove
	jne	get_full_lines_mask+1,	line_clr_do_remove
	jmp	line_clr_ret	; Fastpath to returning from the subroutine
line_clr_do_remove
	; Prep work. Ensure rem_bits_value is zeroed.
rem_bits_value	insn CLRA_INSN	rem_bits_value+0,	0	; rem_bits_value: 2 bytes. Variable storage for rem_bits.
	insn CLRA_INSN	rem_bits_value+1,	0	; Self clearing.

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
	; No need to pre-clear load destination since it is zeroed by the rem_bits subroutine from the previous loop.
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
;get_full_lines_mask	skip	2	; Stored in render_board
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
;rem_bits_mask	skip	2	; Stored in stamp_piece
;rem_bits_value	skip	2	; Stored in line_clr
rem_bits
	; Pre-clear the result	
rem_bits_result	insn CLRA_INSN	rem_bits_result+0,	0	; Self clearing variables
	insn CLRA_INSN	rem_bits_result+1,	0
	
	st	#-16,	tmp	; Loop 16 times
rem_bits_loop
	lsl	rem_bits_mask+0		; Logical shift left mask (0 -> bit 0)
	rol	rem_bits_mask+1		; (bit 15 -> carry)
	jcc	rem_bits_A		; GOTO A if carry clear
	; If Carry Set
	lsl	rem_bits_value+0		; Logical shift left value (0 -> bit 0)
	rol	rem_bits_value+1		; The carry result is discarded.
	
	; Count cleared lines, but only on first iteration (to avoid 10x points)
	insn ALEB_TOC_INSN	#(-GAMEBOARD_COLS),	line_clr_i	; If this is the first iteration of rem_bits (first column), store 1 in carry
	adcto	#0,	lines_cleared	; Add carry to lines cleared
	
	jmp	rem_bits_loop_end
rem_bits_A	; If Carry Clear
	lsl	rem_bits_value+0		; Logical shift left value (0 -> bit 0)
	rol	rem_bits_value+1		; (bit 15 -> carry)
	rol	rem_bits_result+0		; Rotate left to save the carry into result (carry -> bit 0)
	rol	rem_bits_result+1		; Carry from rotating result is discarded.
rem_bits_loop_end	incjne	tmp,	rem_bits_loop	; Loop
rem_bits_ret	jmp	0		; Return from subroutine

PROGRAM_SIZE	; Placeholder label to easily see how big the program is from the symbol table.
PROGRAM_FREE_SPACE	equ	(256-PROGRAM_SIZE)


