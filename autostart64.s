; C64 program autostarter
; Copyright 2018, Richard Halkyard <rhalkyard@gmail.com>
;
.include "config.inc"

.export devnum_sav

CHROUT = $FFD2  ; output character
KBDBUF = $0277  ; start of keyboard buffer for C64 screen editor
KBDCNT = $C6    ; keyboard buffer count for C64 screen editor
DEVNUM = $BA    ; zeropage variable for last-used device #

.segment "CARTHDR"
        ; cartridge header
        .addr hardrst   ; hard reset vector
        .addr $fe5e     ; soft reset vector: return to NMI handler immediately after cartridge check
        .byte $C3, $C2, $CD, $38, $30   ; 'CBM80' magic number for autostart cartridge

.segment "AUTOSTART64"
hardrst: STX $D016       ; modified version of RESET routine (normally at $FCEF-$FCFE)
        JSR $FDA3
        JSR $FD50
        JSR $FD15
        JSR $FF5B
        CLI
        JSR $E453       ; modified version of BASIC cold-start (normally at $E394-$E39F)
        JSR $E3BF
        JSR $E422
        LDX #$FB
        TXS
        ; normally the main BASIC loop starts here, but we have more work to do ;)

print:  LDX #$00        ; Print load/run commands to screen
@loop:  LDA cmds, X
        BEQ @done
        JSR CHROUT
        INX
        BNE @loop
@done:

kbdinj: LDX #$00        ; Inject stored keystrokes into keyboard buffer
@loop:  LDA keys, X
        BEQ @done
        STA KBDBUF, X
        INC KBDCNT
        INX
        BNE @loop
@done:

        LDA devnum_sav  ; restore saved device #
        STA DEVNUM

        LDA #<bootmsg
        LDY #>bootmsg
        JMP $A478       ; jump into BASIC

DQUOTE = $22
BLUE = $1F
LBLUE = $9A
CR = $0D
UP = $91

bootmsg: .byte "BOOTING "
        .byte NAME
        .byte "...", CR, 0

cmds:
.if HIDECMDS
        .byte BLUE      ; make command text 'invisible' against default blue background
.endif
.repeat 2
        .byte CR        ; leave space for READY prompt, since this actually gets printed first
.endrepeat
        .byte "D=PEEK(", .sprintf("%d", DEVNUM), "):"
        .byte "LOAD", DQUOTE, FILE, DQUOTE, ",D,", .string(LOADMODE) 
.repeat 5;
        .byte CR        ; leave space for SEARCHING/LOADING/READY message sequence
.endrepeat
        .byte "RUN", CR ; last line must be CR-terminated before printing READY prompt
.repeat 7
        .byte UP        ; move cursor back up to starting point
.endrepeat
.if HIDECMDS
        .byte LBLUE     ; reset text colour so that status messages are visible
.endif
        .byte 0

keys:   .byte CR, CR, 0 ; keystrokes to inject into keyboard buffer

devnum_sav:     .byte 0