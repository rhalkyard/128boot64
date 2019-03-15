; C128 boot sector that copies C64 autostart code to $8000, and then switches 
; to C64 mode.

.include "config.inc"

.import __CARTHDR_LOAD__, __CARTHDR_RUN__, __CARTHDR_SIZE__, __AUTOSTART64_SIZE__
.import devnum_sav

DEVNUM = $BA
GO64 = $FF4D

.segment "DISKHDR"
magic:  .byte "CBM"     ; magic number for boot sector

addr:   .addr $0000     ; address to load chained blocks to
bank:   .byte $00       ; bank to load chained blocks to
nblks:  .byte $00       ; number of chained blocks to load

msg:    .asciiz NAME    ; name for "BOOTING ..." message

prg:    .asciiz ""      ; don't load a .PRG - we do that in stage2

.segment "BOOT128"
; copy C64 autostart code into place
copy:   LDX  #< (__CARTHDR_SIZE__ + __AUTOSTART64_SIZE__ + 1)
@loop:  LDA __CARTHDR_LOAD__ - 1, X
        STA __CARTHDR_RUN__ - 1, X
        DEX
        BNE @loop

        ; last-used device ID ($BA) seems to get reset when switching to 64 
        ; mode. Save it, so that we can know to load from the drive we booted from.
        LDA DEVNUM
        STA devnum_sav

        JMP GO64 ; c64 mode will take it from here
