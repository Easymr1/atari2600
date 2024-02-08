	processor 6502
	
	seg code
	org $F000		; Define the code origine at $F000

Start:
	sei				; Disable interrupts
	cld				; Disabled the BCD decimal math mode
	ldx #$FF		; Loads the X register with #$FF
	txs				; Transfer the X register to the (S)tack pointer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clear the page zero region ($00 to $FF)
; Meaning the entire RAM and also the entire TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	lda #0			; A = 0
	ldx #$FF		; X = #$FF
	sta $FF			; make sure $FF is zeroed before the loop starts
MemLoop:
	dex				; X--
	sta $0,X		; Store the value of A inside memory address $0 + X
	bne MemLoop		; Loop until X == 0 (z-flag is set)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fill the Rom size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org $FFFC
	.word Start		; Reset vector at $FFFC (where the program start)
	.word Start		; Interrupt vector at $FFFE (unused in the VCS)
