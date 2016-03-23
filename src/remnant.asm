; Hello Sprite
; originl version February 17, 2007
; John Harrison
; An extension of Hello World, based mostly from GALP

;* 2008-May-01 --- V1.0a
;*                 replaced reference of hello-sprite.inc with sprite.inc

INCLUDE "gbhw.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com
INCLUDE "sprite.inc" ; specific defs

SPEED		EQU	$0fff
ASCII_TILES_SIZE EQU 8*256 
MOVEMENT_SPEED EQU 1

; create variables
	SpriteAttr	playerSprite 
	
; IRQs
SECTION	"Vblank",HOME[$0040]
	jp	DMACODELOC ; *hs* update sprites every time the Vblank interrupt is called (~60Hz)
SECTION	"LCDC",HOME[$0048]
	reti
SECTION	"Timer_Overflow",HOME[$0050]
	reti
SECTION	"Serial",HOME[$0058]
	reti
SECTION	"p1thru4",HOME[$0060]
	reti

; ****************************************************************************************
; boot loader jumps to here.
; ****************************************************************************************
SECTION	"start",HOME[$0100]
nop
jp	Begin

; ****************************************************************************************
; ROM HEADER and ASCII character set
; ****************************************************************************************
; ROM header
	ROM_HEADER	ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE
INCLUDE "memory.asm"
ASCIIData:
	chr_IBMPC1	1,8 ; LOAD ENTIRE CHARACTER SET

INCLUDE "tilemap.inc"

; ****************************************************************************************
; Main code Initialization:
; set the stack pointer, enable interrupts, set the palette, set the screen relative to the window
; copy the ASCII character table, clear the screen
; ****************************************************************************************
Begin:
	nop
	di
	ld	sp, $ffff		; set the stack pointer to highest mem location + 1

; NEXT FOUR LINES FOR SETTING UP SPRITES *hs*
	call	InitDMA			; move routine to HRAM
	ld	a, IEF_VBLANK
	ld	[rIE],a			; ENABLE ONLY VBLANK INTERRUPT
	ei				; LET THE INTS FLY

Initialize:
	ld	a, %11100100 		; Window palette colors, from darkest to lightest
	ld	[rBGP], a		; set background and window pallette
	ldh	[rOBP0],a		; set sprite pallette 0 (choose palette 0 or 1 when describing the sprite)
	ldh	[rOBP1],a		; set sprite pallette 1

	ld	a,0			; SET SCREEN TO TO UPPER RIGHT HAND CORNER
	ld	[rSCX], a
	ld	[rSCY], a		
	ld  [isCameraMovingX], a
	ld  [isCameraMovingY], a
	call	StopLCD			; YOU CAN NOT LOAD $8000 WITH LCD ON
	; Load the background tile data from ROM and copy to VRAM.
	ld hl, background_tiles_tile_data
	ld de, _VRAM
	ld bc, background_tiles_tile_data_size
	call mem_Copy
ClearSpriteTable:
; *hs* erase sprite table
	ld	a,0
	ld	hl,OAMDATALOC
	ld	bc,OAMDATALENGTH
	call	mem_Set
InitBackgroundMap:
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON ; *hs* see gbspec.txt lines 1525-1565 and gbhw.inc lines 70-86
	ld	[rLCDC], a	
	ld	a, 32		; ASCII FOR BLANK SPACE
	ld	hl, _SCRN0
	ld	bc, SCRN_VX_B * SCRN_VY_B
	call	mem_SetVRAM
	; Set variables.
	ld a, background_tiles_tile_map_width
	ld [tilemapWidth], a
	ld a, background_tiles_tile_map_height
	ld [tilemapHeight], a
	ld bc, background_tiles_tile_data
	ld hl, pTileData
	ld a, b
	ld [hl+], a
	ld a, c
	ld [hl], a
	; Initialize tile map in VRAM
	call CopyTileMapBlock
SpriteSetup:
	PutSpriteYAddr	playerSprite, 0	; set player location to 0,0
	PutSpriteXAddr	playerSprite, 0
 	ld	a,1		;	; ibmpc1.inc ASCII character 1 is happy face :-)
 	ld 	[playerSpriteTileNum],a      ;sprite 1's tile address
 	ld	a,%00000000         	;set flags (see gbhw.inc lines 33-42)
 	ld	[playerSpriteFlags],a        ;save flags

; ****************************************************************************************
; Main Program Loop
; ****************************************************************************************
MainLoop:
	halt
	nop				; always put NOP after HALT (gbspec.txt lines 514-578)
	ld	bc,SPEED
	call SimpleDelay
	call HandleInput
	jr	MainLoop

; ****************************************************************************************
; Subroutines
; ****************************************************************************************
HandleInput:
	call	GetKeys
	push	af
	and	PADF_RIGHT
	call	nz,MoveRight
	pop	af
	push	af
	and	PADF_LEFT
	call	nz,MoveLeft
	pop	af
	push	af
	and	PADF_UP
	call	nz,MoveUp
	pop	af
	push	af
	and	PADF_DOWN
	call	nz,MoveDown
	pop	af
	push	af
	and	PADF_START
	call	nz,Yflip
	pop	af
	ret

MoveRight:
	GetSpriteXAddr	playerSprite
	ld b, a
	cp		SCRN_X-8	; already on RHS of screen?
	ret		z
	cp 		SCRN_MIDPOINT_X-8 ; If the player reaches the middle of the screen, scroll the camera right.
	call z, ScrollCameraRight
	ld a, [isCameraMovingX] ; If the camera is moving, then we don't need to update the player position on the screen.
	cp $01
	ret z
	ld a, b
	add 	a, MOVEMENT_SPEED
	PutSpriteXAddr	playerSprite,a
	ret
MoveLeft:	
	GetSpriteXAddr	playerSprite
	ld b, a
	cp		0	; already on LHS of screen?
	ret		z
	cp 		SCRN_MIDPOINT_X-8 ; If the player reaches the middle of the screen, scroll the camera right.
	call z, ScrollCameraLeft
	ld a, [isCameraMovingX] ; If the camera is moving, then we don't need to update the player position on the screen.
	cp $01
	ret z
	ld a, b
	sub 	a, MOVEMENT_SPEED
	PutSpriteXAddr	playerSprite,a
	ret
MoveUp:	
	GetSpriteYAddr	playerSprite
	ld b, a
	cp		0	; already on top of screen?
	ret		z
	cp 		SCRN_MIDPOINT_Y-8 ; If the player reaches the middle of the screen, scroll the camera right.
	call z, ScrollCameraUp
	ld a, [isCameraMovingY] ; If the camera is moving, then we don't need to update the player position on the screen.
	cp $01
	ret z
	ld a, b
	sub 	a, MOVEMENT_SPEED
	PutSpriteYAddr	playerSprite,a
	ret
MoveDown:	
	GetSpriteYAddr	playerSprite
	ld b, a
	cp		SCRN_Y - 8	; already at bottom of screen?
	ret		z
	cp 		SCRN_MIDPOINT_Y-8 ; If the player reaches the middle of the screen, scroll the camera right.
	call z, ScrollCameraDown
	ld a, [isCameraMovingY] ; If the camera is moving, then we don't need to update the player position on the screen.
	cp $01
	ret z
	ld a, b
	add 	a, MOVEMENT_SPEED
	PutSpriteYAddr	playerSprite,a
	ret
Yflip:	
	ld	a,[playerSpriteFlags]
	xor	OAMF_YFLIP		; toggle flip of sprite vertically
	ld	[playerSpriteFlags],a
	ret
SimpleDelay:
	dec	bc
	ld	a,b
	or	c
	jr	nz, SimpleDelay
	ret

; GetKeys: adapted from APOCNOW.ASM and gbspec.txt
GetKeys:                 ;gets keypress
	ld 	a,P1F_5			; set bit 5
	ld 	[rP1],a			; select P14 by setting it low. See gbspec.txt lines 1019-1095
	ld 	a,[rP1]
 	ld 	a,[rP1]			; wait a few cycles
	cpl				; complement A. "You are a very very nice Accumulator..."
	and 	$0f			; look at only the first 4 bits
	swap 	a			; move bits 3-0 into 7-4
	ld 	b,a			; and store in b

 	ld	a,P1F_4			; select P15
 	ld 	[rP1],a
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]
	ld	a,[rP1]			; wait for the bouncing to stop
	cpl				; as before, complement...
 	and $0f				; and look only for the last 4 bits
 	or b				; combine with the previous result
 	ret				; do we need to reset joypad? (gbspec line 1082)

; *hs* START
InitDMA:
	ld	de, DMACODELOC
	ld	hl, DMACode
	ld	bc, DMAEnd-DMACode
	call	mem_CopyVRAM			; copy when VRAM is available
	ret
DMACode:
	push	af
	ld	a, OAMDATALOCBANK		; bank where OAM DATA is stored
	ldh	[rDMA], a			; Start DMA
	ld	a, $28				; 160ns
DMAWait:
	dec	a
	jr	nz, DMAWait
	pop	af
	reti
DMAEnd:
; *hs* END

; ****************************************************************************************
; StopLCD:
; turn off LCD if it is on
; and wait until the LCD is off
; ****************************************************************************************
StopLCD:
        ld      a,[rLCDC]
        rlca                    ; Put the high bit of LCDC into the Carry flag
        ret     nc              ; Screen is off already. Exit.

; Loop until we are in VBlank

.wait:
        ld      a,[rLY]
        cp      145             ; Is display on scan line 145 yet?
        jr      nz,.wait        ; no, keep waiting

; Turn off the LCD

        ld      a,[rLCDC]
        res     7,a             ; Reset bit 7 of LCDC
        ld      [rLCDC],a

        ret

;-------------------------------------------------------------------------
; Internal RAM: Dynamic Variables reside here
;-------------------------------------------------------------------------
SECTION	"Tilemap Variables",BSS[_RS]

; Is the camera currently moving, or are we near the edge of the map?
isCameraMovingX:
DS 		1
isCameraMovingY:
DS      1
; The total height of the entire tile map.
tilemapHeight:
DS      2
; The total width of the entire tile map.
tilemapWidth:
DS      2
; A pointer to the current tile data.
pTileData:
DS      2