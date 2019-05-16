; Glue code for the emulated environment
.equ RAMSTART		0x4000
.equ USER_CODE		0x4800
.equ STDIO_PORT		0x00
.equ STDIN_SEEK		0x01

jr	init	; 2 bytes
; *** JUMP TABLE ***
jp	strncmp
jp	addDE
jp	addHL
jp	upcase
jp	unsetZ
jp	intoDE
jp	intoHL
jp	findchar
jp	parseHexPair
jp	blkSel

init:
	di
	; We put the stack at the end of the kernel memory
	ld	hl, USER_CODE-1
	ld	sp, hl
	ld	h, 0	; input blkdev
	ld	l, 1	; output blkdev
	call	USER_CODE
	; signal the emulator we're done
	halt

emulGetC:
	in	a, (STDIO_PORT)
	or	a		; cp 0
	jr	z, .eof
	cp	a		; ensure z
	ret
.eof:
	call	unsetZ
	ret

emulPutC:
	out	(STDIO_PORT), a
	ret

emulSeek:
	; the STDIN_SEEK port works by poking it twice. First poke is for high
	; byte, second poke is for low one.
	ld	a, h
	out	(STDIN_SEEK), a
	ld	a, l
	out	(STDIN_SEEK), a
	ret

emulTell:
	; same principle as STDIN_SEEK
	in	a, (STDIN_SEEK)
	ld	h, a
	in	a, (STDIN_SEEK)
	ld	l, a
	ret

#include "core.asm"
.equ	BLOCKDEV_RAMSTART	RAMSTART
.equ	BLOCKDEV_COUNT		2
#include "blockdev.asm"
; List of devices
.dw	emulGetC, 0, emulSeek, emulTell
.dw	0, emulPutC, 0, 0
