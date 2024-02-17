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
CarY            byte
CarX            byte
CarHeight       byte

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

    lda #180
    sta CarY

    lda #60
    sta CarX

    lda #9
    sta CarHeight

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
;; Calcule CarX Position
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda CarX
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
    REPEAT 35
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the CTRLPF register to allow playfield reflection 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #$01
    stx CTRLPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 192 vertical lines of PlayField
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Draw PlayField 
    ldy #$F0
    sty PF0
    ldy #$FC
    sty PF1
    sta WSYNC

;; Draw Player0
    ldx #192

Scanline:
    txa
    sec
    sbc CarY
    cmp CarHeight
    bcc DrawBitMap          ; if result < SpriteHeight, call subroutine
    lda #0                  ; else, set index to 0

DrawBitMap:
    tay
    lda CarSprite,Y     ; load player bitmap slice data
    sta WSYNC               ; wait for next scanline
    sta GRP0                ; set graphics player 0 slice
    lda CarColor,Y      ; load player color from lookup table
    sta COLUP0              ; set color player 0 slice

    dex                     ; X--
    bne Scanline            ; repeat next scanline until finished

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
CarUp:
    lda #%00010000
    bit SWCHA
    bne CarDown
    inc CarY

CarDown:
    lda #%00100000
    bit SWCHA
    bne CarLeft
    dec CarY

CarLeft:
    lda #%01000000
    bit SWCHA
    bne CarRight
    dec CarX

CarRight:
    lda #%10000000
    bit SWCHA
    bne EndInputCheck
    inc CarX

EndInputCheck:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CarSprite
    .byte #%00000000;$82
    .byte #%00111000;$82
    .byte #%00111000;$00
    .byte #%00111000;$82
    .byte #%00111000;$82
    .byte #%00111000;$82
    .byte #%00111000;$00
    .byte #%00111000;$00
    .byte #%00111000;$82

CarColor
    .byte #$82;
    .byte #$00;
    .byte #$82;
    .byte #$82;
    .byte #$82;
    .byte #$00;
    .byte #$00;
    .byte #$82;
    .byte #$82;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset