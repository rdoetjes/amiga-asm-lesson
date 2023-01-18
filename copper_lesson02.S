		INCLUDE	"Include/BareMetal.i"
;-----------------------------------------------------------
		SECTION	Code,CODE
		INCLUDE	"Include/SafeStart.i

Main:
		movem d0-a6,-(sp)						; save all the registers on the stack
		lea.l	$dff000,a5						; set a5 to system registers base address dff000
		lea.l	Copperlist,a0					; put the copperlist pointer in a0
		move.l	a0,COP1LC(a5)				; tell the system where the copper list 1 is located in memory
		move.w	#$8080,DMACON(a5)		; enable the copper list dma

.wait:
		lea.l	copperBar1,a0					;copperBar pointer tell rotateCopperBar routine which bar to handle euhmm rotate
		moveq #3,d1									;viagra register ;) tells rotateCopperBar routine how wide your bar is ;()
		bsr.b	rotateCopperBar				; call the rotateCopperBar subroutine

		lea.l	copperBar2,a0					;copperBar pointer tell rotateCopperBar routine which bar to handle euhmm rotate
		moveq #3,d1									;viagra register ;) tells rotateCopperBar routine how wide your bar is ;()
		bsr.b	rotateCopperBar				; call the rotateCopperBar subroutine

		moveq #2,d1									; slow down the wait loop by 3 frames (slowing down the copper bars)
.vwait:
		cmp.b #$ac,VHPOSR(a5)				; check if the scan line hit vertical position $ac (center of screen)
		bne.b .vwait								; when the scan line did not yet hit the $ac vertical position that wait till it does
.wait_line
		cmp.b #$ac,VHPOSR(a5)				; check if the scan line is still drawing the line $ac
		beq.b .wait_line						; if it is drawing $ac then wait tioll it's done
		dbf d1,.vwait								; repeat the d1 times, d1 will be decremented each time dbf hits and when it's postive it will jump to .wait

		btst #6,CIAAPRA							; wait for mouse or fire button click
		bne.b .wait									; when mouse or fire button aren't presed jump to .wait

		movem (sp)+,d0-a6						; restore our registers
		rts

rotateCopperBar:
		move.w 6(a0),d7							; store first color for safe keeping in d7
		add #14,a0									; add 14 bytes to a0 pointer so we end up where the first color resides ($f58 in this case)
.rotate:
		move.w (a0),d0							; copy the color value in to d0
		move.w d0,-8(a0)						; copy the color value which is in d0 over the previous color (if we read coplor $f28 it will copier over the $f58 color in the copperlist)
		add #8,a0										; move a0 8 bytes up to the next color (jumping over the wait instruction and color register in the copper list)
		dbf	d1,.rotate							; decrement d1 and when it's >= 0 jump to .rotate and keeps copying the next line
		move.w d7,-8(a0)						; copy back that first color at the back, we need to offset by -8 because the add #8,a0 actually moved us passed it
		rts													; return from sub routine

		SECTION DATA,DATA_C
Copperlist:
		dc.w	$0007,$fffe
		dc.w	COLOR0,$000

copperBar1:
		dc.w	$f007,$fffe
		dc.w	COLOR0,$f7a
		dc.w	$f107,$fffe
		dc.w	COLOR0,$f58
		dc.w	$f207,$fffe
		dc.w	COLOR0,$f26
		dc.w	$f307,$fffe
		dc.w	COLOR0,$f58
		dc.w	$f407,$fffe
		dc.w	COLOR0,$f7a
		dc.w	$f507,$fffe
		dc.w	COLOR0,$000

		dc.w	$ffdf,$fffe

copperBar2:
		dc.w	$2007,$fffe
		dc.w	COLOR0,$f7a
		dc.w	$2107,$fffe
		dc.w	COLOR0,$f58
		dc.w	$2207,$fffe
		dc.w	COLOR0,$f26
		dc.w	$2307,$fffe
		dc.w	COLOR0,$f58
		dc.w	$2407,$fffe
		dc.w	COLOR0,$f7a
		dc.w	$2507,$fffe
		dc.w	COLOR0,$000

		dc.w	$ffff,$fffe
