; UART functions for PIC16F720
;	processor	pic16f720
;	include	p16f720.inc
;	include	macros.inc
;	code

; Initialize UART
uart_init
;	ldi	SPBRG, 0xCF	; 1201 baud @ Fosc = 16 MHz, BRGH = 0
;	ldi	SPBRG, 0x67	; 2403 baud @ Fosc = 16 MHz, BRGH = 0
;	ldi	SPBRG, 0x19	; 9615 baud @ Fosc = 16 MHz, BRGH = 0
;	ldi	SPBRG, 0xC	; 19.23 K baud @ Fosc = 16 MHz, BRGH = 0
;	ldi	SPBRG, 0x67	; 1202 baud @ Fosc = 8 MHz, BRGH = 0
;	ldi	SPBRG, 0x33	; 2404 baud @ Fosc = 8 MHz, BRGH = 0
	ldi	SPBRG, 0xC	; 9615 baud @ Fosc = 8 MHz, BRGH = 0

	ldi	TXSTA, (1 << TXEN)
	ldi	RCSTA, (1 << SPEN) | (1 << CREN)
	rts

; Transmit character in arg1
uart_tx	jbc	TXSTA, TRMT, uart_tx
	ld	TXREG, arg1
	rts

; Check if any receive characters available
; NE if char available
; Check and clear overflow error if FIFO
; is empty.
uart_ne	ld	rtn, PIR1
	andi	rtn, (1 << RCIF)
	jne	uart_rx_ok
	jbc	RCSTA, OERR, uart_rx_nok
	bic	RCSTA, CREN
	bis	RCSTA, CREN
uart_rx_nok
	clr	rtn
uart_rx_ok
	rts

; Check if any receive characters available
; NE if char available
; Check and clear overflow error if FIFO
; is empty.
irq_uart_ne
	ld	irq_rtn, PIR1
	andi	irq_rtn, (1 << RCIF)
	jne	irq_uart_rx_ok
	jbc	RCSTA, OERR, irq_uart_rx_nok
	bic	RCSTA, CREN
	bis	RCSTA, CREN
irq_uart_rx_nok
	clr	irq_rtn
irq_uart_rx_ok
	rts

; Wait for character to become available and then read it
; Character returned in 'rtn'.
uart_rx	jsr	uart_ne
	jeq	uart_rx
	ld	rtn, RCREG
	rts

; Wait for character to become available and then read it
; Character returned in 'rtn'.
irq_uart_rx
	jsr	irq_uart_ne
	jeq	irq_uart_rx
	ld	irq_rtn, RCREG
	rts
