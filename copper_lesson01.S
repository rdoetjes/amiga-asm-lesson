		INCLUDE	"Include/BareMetal.i"
;-----------------------------------------------------------
		SECTION	Code,CODE
		INCLUDE	"Include/SafeStart.i

Main:
		movem d0-a6,-(sp)
		lea.l	$dff000,a5
		lea.l	Copperlist,a0
		move.l	a0,COP1LC(a5)
		move.w	#$8080,DMACON(a5)

.wait:
		btst #6,CIAAPRA
		bne.b .wait

		movem (sp)+,d0-a6
		rts

		SECTION DATA,DATA_C
Copperlist:
		dc.w	$0007,$fffe
		dc.w	COLOR0,$000

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