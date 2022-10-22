
; Copyright 2021 ing. E. Th. van den Oosterkamp
;
; Example software for the book "BareMetal Amiga Programming" (ISBN 9798561103261)
;
; Permission is hereby granted, free of charge, to any person obtaining a copy 
; of this software and associated files (the "Software"), to deal in the Software 
; without restriction, including without limitation the rights to use, copy,
; modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
; and to permit persons to whom the Software is furnished to do so,
; subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in 
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


		INCLUDE	"Include/BareMetal.i"

;-----------------------------------------------------------

		SECTION	Code,CODE_C		

		INCLUDE	"Include/SafeStart.i"

Main:		
		LEA.L	CopBPL,a0		; APTR to bitplane ptrs in coplist
		LEA.L	Bitplanes,a1		; APTR Start of bitplane 1
		MOVE.L	a1,d0
		MOVE.W	d0,6(a0)		; Place low word into coplist
		SWAP	d0
		MOVE.W	d0,2(a0)		; Place high word into coplist
		SWAP	d0
		ADD.L	#44*32,d0
		MOVE.W	d0,14(a0)		; Place low word into coplist
		SWAP	d0
		MOVE.W	d0,10(a0)		; Place high word into coplist

		LEA.L	Coplist,a0		; APTR Top of coplist
		MOVE.L	a0,COP1LC(a5)		; Set start address for coplist

; Prepare the playfield

		MOVE.W	#$2200,BPLCON0(a5)	; 2 bitplanes, enable colour on composite
		MOVE.W	#0,BPLCON1(a5)		; No delay/shift on odd or even bitplane
		MOVE.W	#0,BPLCON2(a5)		; Functionality not required

		MOVE.W	#0,FMODE(a5)		; AGA: Use 16 bit DMA transfers
		MOVE.W	#$2C81,DIWSTRT(a5)	; Left/top corner of display window
		MOVE.W	#$2CC1,DIWSTOP(a5)	; Right/bottom corner of display window
		MOVE.W	#$30,DDFSTRT(a5)	; Location of first DMA fetch each line
		MOVE.W	#$D0,DDFSTOP(a5)	; Location of last DMA fetch each line

		MOVE.W	#$8080,DMACON(a5)	; Enable Copper DMA

; Wait for the user to click the mouse and clean up

.WaitLoop	
		add.w	#1,Font_color_idx
		lea.l	Font_colors,a1
		move.w	Font_color_idx,d1
		move.w	(a1,d1.W),d1		
		cmp.w 	#$00,d1
		beq.b	.reset_color
		bra.b	.color_font
.reset_color
		move.w 	#0,Font_color_idx
		move.w	Font_colors,d1
.color_font
		move.w	d1,Cur_color
		move.w 	d1,f_color+2	;inc color bit plane 2

		MOVE.L	VPOSR(a5),d0		; Get VPOSR and VHPOSR 
		LSR.L	#8,d0			; Shift vertical pos to lowest 9 bits
		AND.W	#$01FF,d0		; Remove unwanted bits
		CMP.W	#$0090,d0		; On line $90?
		BNE.B	.Skip			; No? Do nothing
		
		BSR.B	Scroller
.Wait		
		move.w	Cur_color,d1
		move.w 	d1,f_color+2	;inc color bit plane 2
		MOVE.L	VPOSR(a5),d0		; Get vertical an horizontal position
		LSR.L	#8,d0			; Shift vertical pos to lowest 9 bits
		AND.W	#$01FF,d0		; Remove unwanted bits
		CMP.W	#$0090,d0		; On line $90?
		BEQ.B	.Wait			; Wait until no longer on line $90
.Skip	
		BTST	#6,CIAAPRA		; Check for left mouse click
		BNE.B	.WaitLoop		; No click, keep testing
		MOVE.W	#$0180,DMACON(a5)	; Disable bitplane and Copper DMA
		RTS

;-----------------------------------------------------------

Scroller:	
		MOVE.W	ScrollWait,d0	; Get the amount of waiting left
		BEQ.W	.GoScroll		; No need to wait? Get scrolling
		SUBQ.W	#1,d0			; One wait has been done
		MOVE.W	d0,ScrollWait		; Store the lower value
		BRA.W	.DoNothing		; Still waiting - do nothing
.GoScroll	
		MOVE.W	ScrollDelay,d3	; D3 - Delay value for BPLCON1
		MOVE.W	ScrollSpeed,d0	; Number of pixels to scroll per call
		SUB.W	d0,d3			; Decrease delay
		BGE.W	.Done			; Not wrapped? We're done
		AND.W	#$000F,d3		; Keep only lower nibble

		MOVE.W	FontOffset,d2	; Font offset to 1st word of char
		BEQ.B	.GetNextChar		; No offset? Need new char.
		ADDQ.W	#2,d2			; Move offset to 2nd word
		CLR.W	FontOffset		; Next time get next char
		BRA.B	.MoveChar
.GetNextChar	
		LEA.L	Text,a0		; APTR Scrolling text		
		MOVE.W	ScrollPos,d0	; Current position within text
		MOVEQ	#0,d2
		MOVE.B	(a0,d0.w),d2		; Get next character of text
		BNE.B	.NotTxtEnd
		MOVEQ	#0,d0
		MOVE.B	(a0),d2
.NotTxtEnd	
		ADDQ.W	#1,d0
		MOVE.W	d0,ScrollPos
		CMPI	#$60,d2			; Lower case letter?
		BLO.B	.LowerCase		; No? No need to convert
		SUB.B	#$20,d2			; Convert to upper case
.LowerCase	
		MOVE.W	#4,ScrollSpeed
		MOVE.B	d2,d0			; Copy of current char
		SUB.B	#$20,d2			; First char in font starts at $20
		ASL.W	#2,d2			; Chars are 4 bytes wide
		MOVE.W	d2,FontOffset
		CMPI.B	#'I',d0			; Short character?
		BNE.B	.MoveChar
		CLR.W	FontOffset		; Do not process a 2nd half
.MoveChar	
		LEA.L	Bitplanes,a0		; APTR Destination
		LEA.L	2(a0),a1		; APTR Source
		LEA.L	Font,a2		; APTR Source
		MOVEQ	#64-1,d0		; Number of lines to move
.MoveLine	
		MOVEQ	#11-1,d1		; Number of LONGs on one line
.MoveLongs	
		MOVE.L	(a1)+,(a0)+		; Move data on line one word to the left
		DBF	d1,.MoveLongs		; Until whole line is done
		MOVE.W	(a2,d2.w),-2(a0)	; Copy one word of font to end of line
		ADD.W	#240,d2			; Advance to Next line of font
		DBF	d0,.MoveLine		; Process the next line
.Done		
		MOVE.W	d3,ScrollDelay		; Store for next time
		MOVE.W	d3,d0			; Copy the delay value
		ASL.W	#4,d3			; Move to next nibble
		OR.W	d0,d3			; Place both in same word
		MOVE.W	d3,CopDelay+2		; Set delay in coplist
.DoNothing	
		RTS


;-----------------------------------------------------------
	EVEN
ScrollWait:		DC.W	0	; Number of times to wait
ScrollSpeed:	DC.W	1	; Number of pixels to scroll per call
ScrollDelay:	DC.W	0	; Storage for the delay value
ScrollPos:		DC.W	0	; Position within the scroll text
FontOffset:		DC.W	0	; Offset into font for current char
Font_colors:
	dc.w		$f66,$f66,$f66,$f66,$f66,$f66,$f66,$f66
	dc.w		$f66,$f66,$f66,$f66,$f76,$f76,$f76,$f76
	dc.w		$f76,$f76,$f76,$f76,$f76,$f76,$f76,$f76
	dc.w		$f75,$f75,$f75,$f75,$f75,$f75,$f75,$f75
	dc.w		$f75,$f75,$f75,$f75,$f75,$f85,$f85,$f85
	dc.w		$f85,$f85,$f85,$f85,$f85,$f85,$f85,$f85
	dc.w		$f85,$f85,$f85,$f85,$f85,$f85,$f85,$f85
	dc.w		$f85,$f85,$f85,$f85,$f85,$f85,$f85,$e94
	dc.w		$f95,$f95,$f94,$f94,$f94,$f94,$f94,$f94
	dc.w		$f94,$f94,$f94,$f94,$f94,$f94,$f94,$f94
	dc.w		$f94,$f94,$f94,$f94,$f94,$f94,$f94,$f94
	dc.w		$f94,$fa4,$fa4,$fa4,$fa4,$fa4,$fa4,$fa4
	dc.w		$fa4,$fa4,$fa4,$fa4,$fa4,$fa4,$fa4,$fa4
	dc.w		$fa4,$fa4,$fa4,$fa4,$fa3,$fa3,$fa3,$ea2
	dc.w		$fa3,$fa3,$fa3,$fb3,$fb3,$fb3,$fb3,$fb3
	dc.w		$fb3,$fb3,$fb3,$fb3,$fb3,$fb3,$fb3,$fb3
	dc.w		$fb3,$fb3,$fb3,$fb3,$fb3,$fb3,$fb3,$fb3
	dc.w		$fb3,$fb3,$fb3,$fb3,$fc3,$fc3,$fc3,$fc3
	dc.w		$fc3,$fc3,$fc3,$ec2,$fc3,$fc3,$fc2,$fc2
	dc.w		$fc2,$fc2,$fc2,$fc2,$fc2,$fc2,$fc2,$fc2
	dc.w		$fc2,$fc2,$fc2,$fc2,$fc2,$fc2,$fd2,$fd2
	dc.w		$fd2,$fd2,$fd2,$fd2,$fd2,$fd2,$ed1,$fd2
	dc.w		$fd2,$fd2,$fd2,$fd2,$fd2,$fd2,$fd2,$fd2
	dc.w		$fd2,$fd2,$fd2,$fd2,$fd2,$fd2,$fd2,$fd2
	dc.w		$fe1,$fe1,$ee0,$fe1,$fe1,$fe1,$fe1,$fe1
	dc.w		$fe1,$fe1,$fe1,$fe1,$fe1,$fe1,$fe1,$fe1
	dc.w		$fe1,$ee0,$fe1,$fe1,$fe1,$fe1,$fe1,$fe1
	dc.w		$fe1,$fe1,$ff1,$ff1,$ef0,$ff1,$ff1,$ff1
	dc.w		$ff1,$ff1,$ff1,$ff1,$ef0,$ff1,$ff1,$ff1
	dc.w		$ff1,$ff1,$ef0,$ff0,$ff0,$ff0,$ff0,$ef0
	dc.w		$ff0,$ff0,$ff0,$ef0,$ff0,$ff0,$ef0,$ff0
	dc.w		$ef0,$ef0,$ef0,$ef0,$ef0,$ff0,$ff0, $0000
Font_color_idx	DC.W $00
Cur_color		DC.W $00

Text:		
	DC.B	"[Welcome to Retro Recipes'"
	DC.B	"    Rrrretro Show! "
	DC.B	"Today's Home brew... This basic Amiga demo.... "    
	DC.B	"By Callous Coder (Ray Doetjes), inspired by ing. Th van den Oosterkamp     ",0
	EVEN

;-----------------------------------------------------------

Coplist:	
		DC.W	$4a07,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0c22	; BackgroundL White
		DC.W	$4b07,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0c22+10	; BackgroundL White
		DC.W	$4c07,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0c22+20	; BackgroundL White
f_color:		
		DC.W	COLOR1,$0000	; Color 1: Blue
		DC.W	COLOR2,$048d	; Color 2: Light grey
		DC.W	COLOR3,$0000	; Color 3: Dark grey
		DC.W	BPL1MOD,4-2	; 4 bytes larger, 2 bytes for scroll
		DC.W	BPL2MOD,4-2	; 4 bytes larger, 2 bytes for scroll
CopBPL:		
		DC.W	BPL1PTH,0	; High word APTR bitplane 1
		DC.W	BPL1PTL,0	; Low word APTR bitplane 1
		DC.W	BPL2PTH,0	; High word APTR bitplane 2
		DC.W	BPL2PTL,0	; Low word APTR bitplane 2
CopDelay:	
		DC.W	BPLCON1,0	; Delay for odd/even bitplanes
		DC.W	$4F07,$fffe	; WAIT for line $4F
		DC.W	COLOR0,$0111	; Background: Dark blue
		DC.W	$5007,$fffe	; WAIT for line $50
		DC.W	DMACON,$8100	; Enable bitplane DMA

		DC.W	$7007,$fffe	; WAIT for line $70
		DC.W	DMACON,$0100	; Disable bitplane DMA
		DC.W	$7107,$fffe	; WAIT for line $71
		DC.W	COLOR1,$1056	; Color 1: Green
		DC.W	COLOR2,$0555	; Color 2: Grey
		DC.W	COLOR3,$0333	; Color 3: Dark grey
		DC.W	BPL1MOD,-130	
		DC.W	BPL2MOD,-130
		DC.W	$7207,$fffe	; WAIT for line $72
		DC.W	COLOR0,$0011	; Background: Dark green
		DC.W	DMACON,$8100	; Enable bitplane DMA

		DC.W	$8207,$fffe	; WAIT for line $82
		DC.W	DMACON,$0100	; Disable bitplane DMA
		DC.W	$8807,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0c22+20	; BackgroundL White
		DC.W	$8907,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0c22+10	; BackgroundL White
		DC.W	$8a07,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0c22	; BackgroundL White
		DC.W	$8d07,$fffe	; WAIT for line $85
		DC.W	COLOR0,$0c22+10	; BackgroundL White
		DC.W	$8307,$fffe	; WAIT for line $4E
		DC.W	COLOR0,$0000	; Background: Black

		DC.W	$ffff,$fffe	; Wait indefinitely

;-----------------------------------------------------------
		
Font:		INCBIN	"Assets/Font32.RAW"

;-----------------------------------------------------------

		SECTION	Data,BSS_C		

Bitplanes:	DS.B	(352*32*4)/8

;-----------------------------------------------------------