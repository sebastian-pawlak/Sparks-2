; "Sparks 2", Atari XL/XE Intro 256B
; code by tr1x
; requirements: original Atari XL/XE 64KB PAL
; version: 1.0
; release date: 2019-12-07

	org $0600

;debug	equ 1		; for graphics preview of sine wave
offset	equ 0		; display list offset, used for preview only

gtia10	equ $80		; graphics 10 (GTIA mode)
memdl1	equ $00cb
memdl2	equ $00cd
memvp1	equ $00cf
delta	equ $00d1
value	equ $00d3
memdbg1	equ $00d5
memdbg2	equ $00d7
gprior	equ $026f
pcolr1	equ $02c1
sinwav	equ $0800
vidptr	equ $4000	; video memory
dlist	equ $9c20	; display list
random	equ $d20a

	; generate fake sine wave array using parabolas
	ldy #$3f
	ldx #$00	
loopa1	lda value
	adc delta
	sta value
	lda value+1
	adc #$00	; accumulate carry flag
	sta value+1
	sta sinwav+$40,y
	sta sinwav+$80,x
	eor #$3f
	sta sinwav+$00,x
	sta sinwav+$c0,y
	lda delta
	adc #$04
	sta delta
	inx
	dey
	bpl loopa1

	; prepare display list
	ldx #<dlist+3
	stx memdl1
	lda #>dlist
	sta memdl1+1
	ldx #$c0
	iny		; ldy #$00
loopb1	lda #$4f	; ANTIC command: gr.mode | address
	sta (memdl1),y
	inc memdl1
	;bne skipb1	; not needed,
	;inc memdl1+1	; ..since does not occur in practice
skipb1	lda random
	and #%11000000	; $..00, $..40, $..80, $..c0
	sta (memdl1),y
	inc memdl1
	bne skipb2
	inc memdl1+1
skipb2	lda random
	and #%00111111
	;clc		; not needed in practice
	adc #$09
	sta (memdl1),y
	inc memdl1
	bne skipb3
	inc memdl1+1
skipb3	dex
	bne loopb1

	;lda #$41	; jump to the beginning of display list
	;sta dlist+$243	; ..is not necessary
	;lda #<dlist
	;sta dlist+$244
	;lda #>dlist
	;sta dlist+$245

	; set GTIA graphics mode
	lda #gtia10
	sta gprior

	; draw sine wave, twice
drawsin	;lda <vidptr	; not needed
	;sta memvp1
	lda >vidptr
	sta memvp1+1
	;lda <sinwav	; not needed
	;sta opcode1+1
loopc1
opcodc1	lda sinwav
	clc
opcodc2	adc #$2e
	lsr
opcodc3	lsr
	tay
opcodc4	ldx #$00
	bcs skipc2
	inx
	inx
skipc2	lda colors,x
	sta (memvp1),y
	inc memvp1
	inx
	lda colors,x
	sta (memvp1),y
	clc
	lda memvp1
	adc #$40-1
	sta memvp1
	bne skipc3
	inc memvp1+1
skipc3	inc opcodc1+1
	bpl skipc4
opcodc5	lda #$04
	ora opcodc4+1
	sta opcodc4+1
skipc4	bne loopc1
	ldx #$08
	stx opcodc4+1
	dex
	stx opcodc2+1
	lda #$ea
	sta opcodc3
	dec colors	; first byte of "colors" used as counter
	bne drawsin

	; for sine wave preview; not needed for normal operation
.if .def debug
	lda #<dlist+4
	sta memdbg1
	lda #>dlist
	sta memdbg1+1
	lda #<vidptr
	sta memdbg2
	lda #>vidptr+offset
	sta memdbg2+1
	ldx #$c0
	ldy #$00
loopd1	lda memdbg2
	sta (memdbg1),y
	inc memdbg1
	bne skipd1
	inc memdbg1+1
skipd1	lda memdbg2+1
	sta (memdbg1),y
	lda memdbg2
	clc
	adc #$40
	sta memdbg2
	bne skipd2
	inc memdbg2+1
skipd2	inc memdbg1
	bne skipd3
	inc memdbg1+1
skipd3	inc memdbg1
	bne skipd4
	inc memdbg1+1
skipd4	dex
	bne loopd1
	jmp *
.endif

	; display list animation
anim	lda #<dlist+4
	sta memdl2
	lda #>dlist
	sta memdl2+1
	ldx #$c0
loope1	ldy #$00
	lda (memdl2),y
	clc
	adc #64
	sta (memdl2),y
	bne skipe1
	iny
	lda (memdl2),y
	clc
	adc #1
	bpl skipe2
	lda #>vidptr
skipe2	sta (memdl2),y
skipe1	inc memdl2
	bne skipe3
	inc memdl2+1
skipe3	inc memdl2
	bne skipe4
	inc memdl2+1
skipe4	inc memdl2
	;bne skipe5	; not needed,
	;inc memdl2+1	; ..since does not occur in practice
skipe5	dex
	bne loope1
	bpl anim	; 1 byte less than "jmp anim"

colors	.byte $02, $11, $21, $10	; red dark
	.byte $02, $34, $23, $40	; red bright
	.byte $06, $55, $65, $50	; blue dark
	.byte $06, $78, $67, $80	; blue bright

	; color palette
	org pcolr1

palette	.byte $20|$02, $20|$04, $20|$06, $20|$08
	.byte $90|$02, $90|$04, $90|$08, $90|$0e
