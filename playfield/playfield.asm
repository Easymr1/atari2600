	processor 6502
        include "vcs.h"
        include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	seg 
        org $f000

Reset:
	CLEAN_START
        
        ldx #$80
        stx COLUBK
        
        lda #$1c
        sta COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
	lda #$2
        sta VBLANK
        sta VSYNC
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three line of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	REPEAT 3
        	sta WSYNC
        REPEND
        lda #0
        sta VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 37 recommended line of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        REPEAT 37
        	sta WSYNC
        REPEND
        lda #0
        sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the CTRLPF register to allow playfield reflection 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #%00000001
        stx CTRLPF
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        lda #0
        sta PF0
        sta PF1
        sta PF2
	    REPEAT 7
        	sta WSYNC
        REPEND
        
        lda #%11100000
        sta PF0
        lda #%11111111
        sta PF1
        lda #%11111111
        sta PF2
        ;ldx #$1E
        ;stx COLUPF
       	REPEAT 7
        	sta WSYNC
        REPEND
        
        lda #%01100000
        sta PF0
        lda #%00000000
        sta PF1
        lda #%10000000
        sta PF2
       	REPEAT 164
        	sta WSYNC
        REPEND
        
        lda #%11100000
        sta PF0
        lda #%11111111
        sta PF1
        lda #%11111111
        sta PF2
       	REPEAT 7
        	sta WSYNC
        REPEND
        
        lda #0
        sta PF0
        sta PF1
        sta PF2
	REPEAT 7
        	sta WSYNC
        REPEND
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	lda #2
        sta VBLANK
        REPEAT 30
        	sta WSYNC
        REPEND
        lda #0
        sta VBLANK
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	jmp StartFrame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Epilogue

	org $fffc
        .word Reset	; reset vector
        .word Reset	; BRK vector
