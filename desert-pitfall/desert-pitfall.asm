    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with VCS register memory mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare the variables starting from memory address $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80
HumanX			byte
HumanY			byte
HumanHeight		byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize RAM variables and TIA registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$08
    sta COLUBK

    lda #$C4
    sta COLUPF
    
    lda #29
    sta HumanY

    lda #70
    sta HumanX
    
    lda #15
    sta HumanHeight

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
    lda #2
    sta VSYNC
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 3 vertical lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        sta WSYNC
    REPEND
    lda #0
    sta VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calcule HumanX Position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda HumanX
    and #$7F       ; same as AND 01111111, forces bit 7 to zero
                   ; keeping the value inside A always positive

    sec            ; set carry flag before subtraction

    sta WSYNC      ; wait for next scanline
    sta HMCLR      ; clear old horizontal position values

DivideLoop:
    sbc #15        ; Subtract 15 from A
    bcs DivideLoop ; loop while carry flag is still set

    eor #7         ; adjust the remainder in A between -8 and 7
    asl            ; shift left by 4, as HMP0 uses only 4 bits
    asl
    asl
    asl
    sta HMP0       ; set fine position value
    sta RESP0      ; reset rough position
    sta WSYNC      ; wait for next scanline
    sta HMOVE      ; apply the fine position offset


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 37 vertical lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 37
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the CTRLPF register to allow playfield reflection 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #$0
    stx CTRLPF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 192 vertical lines of PlayField
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #192

Scanline
    txa
    sec
    sbc HumanY
    cmp HumanHeight
    bcc DrawHumanSprite
    lda #0
    

DrawHumanSprite:
    tay
    lda Human,Y    		; load player bitmap slice data
    sta WSYNC              	; wait for next scanline
    sta GRP0               	; set graphics player 0 slice
    lda HumanColor,Y      	; load player color from lookup table
    sta COLUP0            	; set color player 0 slice


    txa
    ldy #$FF
    cmp #30
    bcc DrawPlayfield
    ldy #0
    
DrawPlayfield:
     	sty PF0
    	sty PF1
        sty PF2




    dex    			; X--    
    bne Scanline            	; repeat next scanline until finished

    ldy #0
    sty PF0
    sty PF1
    sty PF2
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 30 vertical lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK
    REPEAT 30
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Controle Joystique Car
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HumanJump:
    lda #%00010000
    bit SWCHA
    bne HumanDown
    inc HumanY
    ;lda HumanY
    ;clc
    ;adc #10
    ;sta HumanY

HumanDown:
    lda #%00100000
    bit SWCHA
    bne HumanLeft
    dec HumanY
 
HumanLeft:
    lda #%01000000
    bit SWCHA
    bne HumanRight
    dec HumanX
    
HumanRight:
    lda #%10000000
    bit SWCHA
    bne EndInputCheck
    inc HumanX


EndInputCheck:
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Human
        .byte #%00000000;$44
        .byte #%00111100;$44
        .byte #%00101000;$00
        .byte #%00101000;$00
        .byte #%00101000;$00
        .byte #%00111000;$00
        .byte #%10111010;$84
        .byte #%10111010;$84
        .byte #%10111010;$84
        .byte #%11111110;$84
        .byte #%00110000;$84
        .byte #%00111000;$F2
        .byte #%00111000;$F2
        .byte #%00111100;$44
        .byte #%00111000;$44

HumanColor
        .byte #$44;
        .byte #$44;
        .byte #$00;
        .byte #$00;
        .byte #$00;
        .byte #$00;
        .byte #$84;
        .byte #$84;
        .byte #$84;
        .byte #$84;
        .byte #$84;
        .byte #$F2;
        .byte #$F2;
        .byte #$44;
        .byte #$44;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset