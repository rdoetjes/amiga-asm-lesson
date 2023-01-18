
		INCLUDE	"Include/BareMetal.i"

;-----------------------------------------------------------

		SECTION	Code,CODE

		INCLUDE	"Include/SafeStart.i"

Main:		
		movem.l d0-a6,-(sp)
		lea 	$dff000,a5			; set the hardware registers base address to a5
		lea.l	Copperlist,a0		; set the coppper list pointer in a0
		move.l	a0,COP1LC(a5)		; Set the copper list pointer into teh COP1LC (copperlist one hardware address), effectively move.w a0,$dff080
		move.w  #$8080,DMACON(a5)	; enable bit 7 (copper DMA active) and 15 (DMA active), effectively move.w #$8080,$dff096
		move.w	#$8010,INTENA(a5)	; enable copper interrupt
		move.l	S_VBR,a0			; base memory (0)
		move.l	#IRQHandler,IRQ3(a0); Set the new vector
		bsr.b	MoveCopperBar

.wait:
		cmp.b	#2,rotate_bar
		beq.b	.rotate
.1
		cmp.b	#1,move_bar
		beq.b	.move

		btst 	#6,CIAAPRA
		bne 	.wait
		bra.b	.exit

.rotate	
		bsr.b	RotateBars	
		move.b	#0,rotate_bar
		bra.b	.1

.move
		bsr.b	MoveCopperBar
		move.b	#0,move_bar
		bra.b	.wait

.exit
		movem.l (sp)+,d0-a6
		rts

RotateBars:
	lea 	copperBar1,a0
	bsr.b	RotateCopperBar
	rts

IRQHandler:
	movem.l	d0-d7/a0-a6,-(sp)		;store all registers		
	move.w 	$dff000+INTENAR,a0 		; setup internar to read which interrupt was triggered
	move.w	(a0),d0					; read the triggered interrupt into d0

	btst	#4,d0					; copper (04) triggered than in increment frame count
	beq 	.inc_frame_count
	bra.s	.exit					; else exit from interrupt handler

.inc_frame_count
	add.b #1,rotate_bar				; add one to the frame count when the copper irq was triggered -- we can trigger that whereever on the screen unlike VERTB
	add.b #1,move_bar

.exit:
	move.w	#$0010,INTREQ(a5)		; Acknowledge the interrupt
	movem.l	(sp)+,d0-d7/a0-a6		; restore all registers
	rte								; return from interrupt

MoveCopperBar:
	move.b	(copperBar1Center),d3	; load the middle position stored in copperBar1Center into d3
	lea		copperBar1,a1			; load the start address copperBar1 in the copper list, so we can use offsets
	lea 	sine,a0					; looad the start address of the sine table, so we can use offsets

	move.w	(sineOffset),d0			; the actual offset in the sine tabe that we load and save every frame
	cmp.w	#endsine-sine,d0		; compare the number of points in the sine if d0 is at the end of the list reset the pointer
	bne.b	.getvalue				; d0 is not pointing at the end of the sine table so we can obtain the sine point
	move.w	#0,d0					; reset the sineOffset pointer because we were at the end of the sine table
	move.w	d0,(sineOffset)			; store the reset value in the sineOffset (we will add to it later on)
.getvalue:
	move.b	(a0,d0.w),d2			; read the sine point from the sine table into d2
	add.w	#1,sineOffset			; add the sineOffset to the next index into the sine table (for the next iteration)

	move.b	#9,d0					; the bar has 9 lines to move
.move:
	move.b	d2,d1					; move the sine point into d1 (so we do keep a copy of the sine)
	add.b	d3,d1					; add the sine point to the starting location of the copper bar. In essence we move the bar the amount of lines based on the sine point value
	add.b	#1,d3					; add 1 to d3 for the next line we are going to copy; in essence moving to the next line to move
	move.b  d1,(a1)					; store the new location in to the copper table wait line
	add.l	#8,a1					; move to the next copper table wait line location (8 bytes away)
	dbf		d0,.move				; decrement d0 (number of lines left to move) and move the next line 
	rts

RotateCopperBar:
		move.w	6(a0),d7			;remember the color so we can add it to the back
		moveq	#7,d1				; we need to copy 3 more bar colors upwards
		add 	#14,a0				; set the offset in a0 to the next color to read
.rotate:
		move.w	(a0),d0				;read the color into d0
		move.w	d0,-8(a0)			;copy that color we just read 8 bytes backwards from current ptr to overwrite the previou
		add 	#8,a0				;add 8 bytes to get to the next offset
		dbf		d1,.rotate			;decrement d1 and continue until 0
		move.w	d7,-8(a0)			;copy that first saved color at the back of our colorBar
		rts

;-----------------------------------------------------------
rotate_bar:			dc.b	$0
move_bar:			dc.b	$0
copperBar1Center:	dc.b 	$ae	
;-----------------------------------------------------------

	SECTION DATA,DATA_C

Copperlist:
		dc.w COLOR0,$000
 		; space to the bar
	copperBar1:
		dc.w $8007,$fffe
		dc.w COLOR0,$f0b
		dc.w $8107,$fffe
		dc.w COLOR0,$d09
		dc.w $8207, $fffe
		dc.w COLOR0,$c07
		dc.w $8307,$fffe
		dc.w COLOR0,$39f
		dc.w $8407,$fffe
		dc.w COLOR0,$f8d
		dc.w $8607,$fffe
		dc.w COLOR0,$39f
		dc.w $8707,$fffe
		dc.w COLOR0,$c07
		dc.w $8807,$fffe
		dc.w COLOR0,$d09
		dc.w $8907,$fffe
		dc.w COLOR0,$f0b

		dc.w $8a07,$fffe
		dc.w COLOR0,$000
		;space after ther bar
		dc.w INTREQ,$8010	; Trigger Copper interrupt	
		dc.w $ffff,$fffe
	
sineOffset:
		dc.b	0

	Include "Include/sine.s"

