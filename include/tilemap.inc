;If all of these are already defined, don't do it again.

        IF      !DEF(TILEMAP_INC)
TILEMAP_INC  SET  1

SCRN_MIDPOINT_X EQU SCRN_X / 2
SCRN_MIDPOINT_Y EQU SCRN_Y / 2

        PUSHS           ; Push the current section onto assember stack.

INCLUDE "background_tiles.inc"

    SECTION "TileMap Code",HOME

; Copies a row of tiles to the background map.
; Input:
;	de - destination
;	hl - source
CopyTileMapRow::
	ld bc, SCRN_VX_B
	call mem_CopyVRAM
	ret
	
; Copies a column of tiles to the background map.
; Input:
;	de - destination
;	hl - source
CopyTileMapColumn::
	ld bc, 1
	ld a, SCRN_VY_B
.row
	call CopyTileMapRow
	dec a
	jr nz, .row
	ret

; Copies a block of tiles to the background map.
; Input:
CopyTileMapBlock::
	; Copy the ROM tile map to the background map.
	ld a, SCRN_VY_B
	ld de, _SCRN0
	ld hl, background_tiles_map_data
.row
	ld bc, SCRN_VX_B
	push af
	call mem_CopyVRAM
	pop af
	ld bc, background_tiles_tile_map_width-SCRN_VX_B
	add hl, bc
	dec a
	jr nz, .row
	ret

;;----------------------------------------------------------------------
; The following methods scroll the camera a given direction, 
; which is equivalent to updating the rSCX and rSCY values. 
; The camera will scroll until it gets close to the boundaries 
; of the current tile map, at which point it will stop.  While 
; it is scrolling, isCameraMoving will be set to true.
;;-----------------------------------------------------------------------

; Scrolls the camera right until it reaches the right boundary of the tile map.
ScrollCameraRight::
	push af
	ld a, [rSCX]
	cp SCRN_VX - SCRN_X
	jr z, .stopScrolling
	add a, MOVEMENT_SPEED
	ld [rSCX], a
	ld a, $01
	ld [isCameraMovingX], a
	pop af 
	ret
.stopScrolling
	ld a, $00
	ld [isCameraMovingX], a
	pop af
	ret

; Scrolls the camera left until it reaches the left boundary of the tile map.
ScrollCameraLeft::
	push af
	ld a, [rSCX]
	cp 0
	jr z, .stopScrolling
	sub a, MOVEMENT_SPEED
	ld [rSCX], a
	ld a, $01
	ld [isCameraMovingX], a
	pop af 
	ret
.stopScrolling
	ld a, $00
	ld [isCameraMovingX], a
	pop af
	ret

; Scrolls the camera up until it reaches the upper boundary of the tile map.
ScrollCameraDown::
	push af
	ld a, [rSCY]
	cp SCRN_VY - SCRN_Y
	jr z, .stopScrolling
	add a, MOVEMENT_SPEED
	ld [rSCY], a
	ld a, $01
	ld [isCameraMovingY], a
	pop af 
	ret
.stopScrolling
	ld a, $00
	ld [isCameraMovingY], a
	pop af
	ret

; Scrolls the camera down until it reaches the lower boundary of the tile map.
ScrollCameraUp::
		push af
	ld a, [rSCY]
	cp 0
	jr z, .stopScrolling
	sub a, MOVEMENT_SPEED
	ld [rSCY], a
	ld a, $01
	ld [isCameraMovingY], a
	pop af 
	ret
.stopScrolling
	ld a, $00
	ld [isCameraMovingY], a
	pop af
	ret

        POPS           ; Pop the current section off of assember stack.

		ENDC    ;TILEMAP_INC