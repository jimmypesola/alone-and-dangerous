		!to "aad.prg", cbm

; Memory (VIC Bank at $4000, character set at $4800, sprite blocks at $5000-$6fff)

;	CODE #1:
;	$0400-$07e7 -> -- Color buffer, 1000 bytes
;
;	$0810-$1eff -> -- Routines and tables
;
;	MUSIC:
; 	$2000-$2fff -> 4096 bytes --- SID player routine (during dev use it for code)
;	                              (multi-sids are possible, sound effects are supported and enabled.)
;
;	CODE #2:
;	$3000-$3fff -> 4096 bytes --- Main entry code here.
;
;	GRAPHICS MEMORY:
;       $4000-$47ff -> 2048 bytes -- Screen 0 at $4000, and Screen 1 at $4400 here.
;
;	$4800-$4fff -> 2048 bytes --- Charset here.
;
;	$5000-$6fff -> 8192 bytes --- Sprite bank of 128 sprites here.
;
;	GAME DATA:
;	$7000-$bfff -> 20480 bytes --- RLE compressed map data (interior + outdoor).
;	                               Outdoor map is 16x13 (=208) "rooms" with interiors included, 16x8 with interiors excluded.
;
;	CODE #3:
;	$c000-$cfff -> 4096 bytes --- code routines   
;
;	$e000-$efff -> 4096 bytes --- Compressed sprite data.
;	$f000-$f5ff -> 1536 bytes --- Tables and game data (prel.)

; TODO: Fix door tables! Right now making door exit coords...
; TODO: Fix choppable tree / crushable rock / unlockable door (can be mixed in?) / table
; TODO: If all enemies are killed in some room, spawn item / door.
; TODO: Make shops
; TODO: Make more enemies
; TODO: Make bosses


; Strategy: 
; 1. Create a loader, rle compressed data. Load two bytes, then unpack.
; 2. Configure memory, switch in RAM at BASIC ROM ($a000-$bfff).
; 3. Load compressed map data to $7000-$bfff, load 2 maps: main map 1 and interiors map 1. 
;    in that order, and place both as near the end of that RAM area as possible.
; 4. Unpack map to beginning of $7000, then the interiors map directly after it.

; 100. New Improved map to screen
;      - Each screen is packed using RLE
;      - Pointer tables (high and low bytes) to addresses where each screen's RLE data starts.
;      - Each new screen is unpacked to tilebuffer address and drawn to screen at $4000-$43ff (or at $4400-$47ff)
;      - When drawn, scrolling is started to bring in this screen.
;      - Use indexed table of "rooms" where each room can be reused in map? Saves more space allowing larger maps!


; shift in RAM at Kernal ROM ($e000-$ffff)
; 

offx=$bc	; map x screen offset (from top left corner) (rough scroll, 16 pixels)
offy=$be	; map y screen offset (from top left corner)
screen_id=$b8	; indicates the currently active screen (0=$4000,1=$4400)
scroll_x=$b9	; variables for scrolling the screen (fine scroll 1 pixel)
scroll_x2=$ba
scroll_y=$bb

tmp=$06
tmp_addr=$07 ; and $08

tmp2=$09

scrollstate=$0a
tmp_addr2=$0b

tmp3=$0d
tmp4=$0e

transit_color	= $07	; alias for tmp_addr !
transit_char	= $0b	; alias for tmp_addr2 !
transit_back	= $56	; alias for safe_tmp + safe_tmp2 !
transit_colback	= $58	; alias for safe_tmp3 + safe_tmp4 !
transit_column1	= $06	; alias for tmp !
transit_column2	= $09	; alias for tmp2 !
transit_column3	= $0d	; alias for tmp3 !

screen_pos = $0f

player_inv = $10	; %00000000 00000001	; Sword			- First weapon, melee
			; %00000000 00000010	; Shield		- Blocks some attacks
			; %00000000 00000100	; Hatchet		- Allows wood cutting
			; %00000000 00001000	; Bow			- Ranged weapon consuming arrows
			; %00000000 00010000	; Torch			- Allows vision in the dark
			; %00000000 00100000	; Magic Glove		- Gives a giant's strength, can lift rocks
			;						  (enables level 1 spells)
			; %00000000 01000000	; Raft			- Can travel over water 
			; %00000000 10000000	; Armor			- Doubles health 
			; %00000001 00000000	; Magic Necklace	- Enables level 2 spells
			; %00000010 00000000	; Red potion		- Restore health 
			; %00000100 00000000	; Blue potion		- 1 spell charge
			; %00001000 00000000	; Green potion		- 2 spell charges
			; %00001100 00000000	; Yellow potion		- 3 spell charges 
			; %11110000 00000000	; Key			- 0-15 keys

players_spells = $12	; %00000001	- Spell 1	- Cast spell ??
			; %00000010	- Spell 2	- Cast spell ??
			; %00000100	- Spell 3	- Cast spell ??
			; %00001000	- Spell 4	- Cast spell ??
			; %00010000	- Spell 5	- Cast spell ??
			; %00100000	- Spell 6	- Cast spell ??
			; %01000000	- Spell 7	- Cast spell ??
			; %10000000	- Spell 8	- Cast spell ??

; Sprite multiplexer vars
; --------------------------
areg = $13
xreg = $14
yreg = $15

maxspr = $16

vspr_counter = $17

PlayerBusyTimer = $18

RandomNumber = $19
RandomIdx = $1a

xdif = $1b
ydif = $1c


AnimFrame = $1e
PlayerState = $1f

jumplo = $20
jumphi = $21

bal = $22
bah = $23

; --------------------------

ErrorStatus = $24	; $00 	= no errors
			; $01	= doortablemulti cannot be empty!

MobsPresent = $25
CurrentMobSpeed = $26

PlayerPullForceX = $27
PlayerPullForceY = $28

PlayerWeaponPower = $29

indextable=$30	; sprite multiplexer indices: must have at least 16 entries, but reserve 32

DictLen = 288	; Room dictionary length (back reference to rooms "already seen", i.e. 
		; compression for rooms which data are identical.)

; Keyscanner ZERO PAGE Variables
ScanResult = $50

; Reserved temporary zero page vars
StatsUpdated = $51
tmp_hp_digits = $52 ; ...and $53,$54,$55 !
tmp_gold_incr = $52 ; ...and $53,$54,$55 !
tmp_gold_value = $53


; tmp vars that should be used outside interrupt code
safe_tmp=$56
safe_tmp2=$57
safe_tmp3=$58
safe_tmp4=$59

MapID = $5a

PlayerPowerState = $5b

; Animation counter
AnimCounter = $5f	; For each sprite

KeyStopper = $60	; KeyStopper, when a key is held down to prevent repetition.
RandomPos = $61

; Player animation state variable and values
PlayerAnimState = $62 ; NOTE: used with above AnimCounter (index 2 in sprite anim table)

Inventory = $80	; Room for some items, let's say 16 bytes.

linebuffer=$90 ; 40 bytes, ends in $b7


; ----------------------
; Scroll state values
; ----------------------

state_idle = 0
state_scroll_up = 1
state_scroll_down = 2
state_scroll_left = 3
state_scroll_right = 4

; ----------------------
; Player and HUD data
; ----------------------
player = 0 	; (in indexes 0-15)
weapon = 1
enemy = 2 

max_enemies = 6
items = 16

; sprite offset constants
xoffset = 24
yoffset = 50

;memory
spritepointer = $43f8

; ----------------------
; Player anim state values
; ----------------------
PlayerStopFacingSouth = 0
PlayerStopFacingWest = 1
PlayerStopFacingNorth = 2
PlayerStopFacingEast = 3
PlayerRunSouth = 4
PlayerRunWest = 5
PlayerRunNorth = 6
PlayerRunEast = 7
PlayerAttackSouth = 8
PlayerAttackWest = 9
PlayerAttackNorth = 10
PlayerAttackEast = 11
PlayerDying = 12
PlayerDies = 13

; ----------------------
; Player behavior state values
; ----------------------
PlayerStateInControl = 0
PlayerStateAttack = 1
PlayerStateHit = 2
PlayerStateTransitInit = 3
PlayerStateTransitDrawBack = 4
PlayerStateTransit = 5
PlayerStateTransitEnd = 6
PlayerStateDying = 7
PlayerStateDead = 8
PlayerStateFades = 9
PlayerStateStartLootChest = 10
PlayerStateLootChest = 11
PlayerStateSwitchMap = 12

; ----------------------
; Enemy animation state values
; ----------------------
EnemyStopFacingSouth = 0
EnemyStopFacingWest = 1
EnemyStopFacingNorth = 2
EnemyStopFacingEast = 3
EnemyRunSouth = 4
EnemyRunWest = 5
EnemyRunNorth = 6
EnemyRunEast = 7
EnemyAttackSouth = 8
EnemyAttackWest = 9
EnemyAttackNorth = 10
EnemyAttackEast = 11
EnemyDying = 12

; ----------------------
; Enemy behavior
; state values
; ----------------------
EnemyIdle = 0
EnemyWaiting = 1
EnemyMoving = 2
EnemyAttacking = 3
EnemyHit = 4
EnemyDead = 5
EnemyLoot = 6
EnemyIsNpc = 7

; ----------------------
; Player "Power" state,
; for controlling colors
; and damage resistance
; ----------------------
PlayerPowerNormal = 0
PlayerPowerStage1 = 1
PlayerPowerStage2 = 2
PlayerPowerStage3 = 3

; ----------------------
; Collision values
; returned from
; player_read_controls
; subroutine
; ----------------------
CollisionPassable = 0
CollisionDoor = 1
CollisionBlocking = 2
CollisionTree = 3
CollisionChest = 4
CollisionLockedDoor = 5
CollisionRunestone = 6
CollisionInfostone = 7
CollisionCrushableBoulder = 8
CollisionMovablePillar = 9
CollisionCenotaph = 10

; ----------------------
; Tile indices
; ----------------------
TileChestClosedLeft = 22
TileChestClosedRight = 23
TileChestOpenLeft = 62
TileChestOpenRight = 63

; ----------------------
;  General constants
; ----------------------
c_up		= 0
c_down		= 1
c_left		= 2
c_right		= 3

;------------------------------------------------------------------------------------
; Kernal area variables [$f000-$fffd], use this space to save on load memory
;------------------------------------------------------------------------------------

; PLAYER/ENEMY DATA TABLES
player_max_hp 	=	$f000	;!byte $00,$06	; store as strings, for efficiency 
player_hp 	=	$f002	;!byte $00,$06			; bcd string
player_level 	=	$f004	;!byte $00,$01			; bcd string
player_gold	=	$f006	;!byte $00,$00,$00,$00,$00	; bcd string
enemy_hp	=	$f00b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15dc
enemy_ap	=	$f013	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15e4
enemy_gold	=	$f01b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15ec
enemy_state	=	$f023	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15f4
enemy_anim_state=	$f02b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15fc
enemy_lootidx	=	$f033	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $1604
enemy_nextpos_x	=	$f03b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $160c
enemy_nextpos_y	=	$f043	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $1614
enemy_timer	=	$f04b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $161c
enemy_pull_force_x =	$f053	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $1624
enemy_pull_force_y =	$f05b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $162c

CurrentRoomIdx =	$f063	; 1-byte room index on map

; 16-bit mob data currently on screen
CurrentMobType = 	$f064	; list of up to 9 bytes
MobSrc =		$f06c	; 2-byte address where mob data is fetched

;-----------------------------------------------------------
; tile-to-screen lookup tables
; contains the relative positions for tiles on screen
;-----------------------------------------------------------
tilepos_lo 	=	$f100
tilepos_hi_a	=	$f200
tilepos_hi_b	=	$f300
colormem_hi	=	$f400

;-----------------------------------------------------------
; Sprite tables (160 bytes)
;-----------------------------------------------------------
; y-coordinate table for virtual sprites
ytable		=	$f500	; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00

; x-coordinate table for virtual sprites
xtablelo	=	$f520	; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00

; x-coordinate table for virtual sprites (high byte)
xtablehi	=	$f540	; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00

; color table for virtual sprites
color		=	$f560	; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00

; frame index for virtual sprites
frame		=	$f580	; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00
				; !byte $00,$00,$00,$00,$00,$00,$00,$00

; tile buffer for temporarily storing current map room
tilebuffer	=	$1f00

; color memory buffer (cannot use $f600 - $f9ff, some important pointer in kernal is overwritten)
colorbuffer	=	$0400

;------------------------------------------------------------------------------------


; --------------------------------------------
; MACROS
; --------------------------------------------

; immediate_a_mod_n
; Parameters: 	a - Dividend.
;		n - Divisor [immediate]
; Return value: a
!macro immediate_a_mod_n .n {

		sec
-		sbc #.n
		bcs -
		adc #.n
}

; immediate_a_div_by_n
; Parameters: 	a - Dividend.
;		n - Divisor [immediate]
; Return value: y
!macro immediate_a_div_by_n .n {

		ldy #0
		sec
-		iny
		sbc #.n
		bcs -
		dey
}

; immediate_xa_div_by_n_16
; Parameters: 	a - Dividend low.
;               x - Dividend high.
;		n - Divisor [immediate]
; Return value: ay
!macro immediate_xa_div_by_n_16 .n {

	sta tmp		; dividend low
	stx tmp2	; dividend high

	lda #0	        ;preset remainder to 0
	sta tmp3
	sta tmp4
	ldx #16	        ;repeat for each bit: ...

-	asl tmp		;dividend lb & hb*2, msb -> Carry
	rol tmp2	;dividend+1
	rol tmp3	;remainder lb & hb * 2 + msb from carry
	rol tmp4	;remainder+1
	lda tmp3
	sec
	sbc #.n		;substract divisor to see if it fits in
	tay
	lda tmp4
	sbc #0
	bcc +		;if carry=0 then divisor didn't fit in yet

	sta tmp4
	sty tmp3	;else save substraction result as new remainder,
	inc tmp		;and INCrement result cause divisor fit in 1 times

+	dex
	bne -
	ldy tmp
	lda tmp2
}

; move_sprite_left
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_left .sprite,.speed {

		lda xtablelo+.sprite
		sec
		sbc #.speed
		sta xtablelo+.sprite
		bcs +
		dec xtablehi+.sprite
+
}

; move_sprite_right
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_right .sprite,.speed {

		lda xtablelo+.sprite
		clc
		adc #.speed
		sta xtablelo+.sprite
		bcc +
		inc xtablehi+.sprite
+
}

; move_sprite_up
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_up .sprite,.speed {

		lda ytable+.sprite
		sec
		sbc #.speed
		sta ytable+.sprite
}

; move_sprite_down
; Parameters: 	.sprite - sprite offset index
; 	 	.speed  - sprite pixels / frame
!macro move_sprite_down .sprite,.speed {

		lda ytable+.sprite
		clc
		adc #.speed
		sta ytable+.sprite
}


; MACROS END
; --------------------------------------------



; RUN command

		*=$0800
begin_code_800
		!byte $00,$0d,$08,$0a,$00,$9e
		!byte $20,$31,$32,$32,$38,$38


		*=$0810
;-----------------------------------------------------------
; raster routine - main rendering loop
; parameters:
;-----------------------------------------------------------
scrollirq
		sta areg
		stx xreg
		sty yreg
		jsr $2003

		; Scroll state jump table
		lda scrollstate
		cmp #state_scroll_left
		bne +
		jmp scrollStateLeft

+		cmp #state_scroll_right
		bne +
		jmp scrollStateRight

+		cmp #state_scroll_up
		bne +
		jmp scrollStateUp

+		cmp #state_scroll_down
		bne +
		jmp scrollStateDown

		;-----------------------------------------------------
		; Scroll state idle, don't enter here unless "idle"
		;-----------------------------------------------------

+		jsr set_music_sprites_irq
		jsr draw_stats
		jmp scrollEnd

;---------------------------------------
; Scroll left
;---------------------------------------
scrollStateLeft
		lda scroll_x
		cmp #64
		bne +
		lda scroll_x2
		cmp #1
		bne +
			; scroll finished
			lda #state_idle
			sta scrollstate
			lda #(62)
			sta xtablelo+player
			lda #1 
			sta xtablehi+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			jmp scrollEnd

+
		jsr move_screen_left
		jmp scrollEnd

;---------------------------------------
; Scroll right
;---------------------------------------
scrollStateRight

		jsr move_screen_right
		lda scroll_x
		cmp #0
		bne +
		lda scroll_x2
		cmp #0
		bne +
		
			; scroll finished
			lda #state_idle
			sta scrollstate
			lda #(26)
			sta xtablelo+player
			lda #0 
			sta xtablehi+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			jmp scrollEnd
+
		jmp scrollEnd

;---------------------------------------
; Scroll up
;---------------------------------------
scrollStateUp

		lda scroll_y
		cmp #192
		bne +
			; scroll finished
			lda #state_idle
			sta scrollstate
			lda #(216)
			sta ytable+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			jmp scrollEnd
		
+		jsr move_screen_up
		jmp scrollEnd

;---------------------------------------
; Scroll down
;---------------------------------------
scrollStateDown
		jsr move_screen_down
		lda scroll_y
		cmp #4
		bne +
			; scroll finished
			lda #state_idle
			sta scrollstate
			lda #(54)
			sta ytable+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			jmp scrollEnd
+
		jmp scrollEnd

;---------------------------------------
; Scroll end
;---------------------------------------
scrollEnd

		asl $d019
		lda $d011
		and #$1f
		sta $d011

		lda $d012
		cmp #$f2
		; if raster line is less than 242, then set interrupt!
		bcs +
			lda #$f2
			sta $d012

			lda #<statusline	; so, set raster interrupt at next sprite 0 y coordinate.
			sta $fffe
			lda #>statusline
			sta $ffff

			inc $d019	; acknowledge raster irq.
			lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.
			jmp ++
+		; else

			lda #<scrollirq
			sta $fffe
			lda #>scrollirq
			sta $ffff

			lda #$00	; Set main interrupt to happen at line 32
			sta $d012
++
		lda areg
		ldx xreg
		ldy yreg

		rti


;-----------------------------------------------------------
; player_read_controls
; - Do map collision checking also here.
;   @return - nothing
; Postconditions:
;               plr_r_ctrl_dir  - player direction
;               plr_r_ctrl_coll - player collision
;
;               plr_r_ctrl_dir:
;               1 - east
;               2 - west
;               3 - north
;		4 - south
;
;               plr_r_ctrl_coll:
;               1 - door
;               2 - block
;               3 - tree
;               4 - chest
;               5 - locked door
;               6 - runestone
;               7 - infostone
;               8 - boulder
;               9 - pillar
;               10 - grave
;               (see collision_map array for more info)
; Destroys a,x
;-----------------------------------------------------------
player_read_controls

		; Reset weapon sprite
		lda #0
		sta xtablelo+weapon
		sta xtablehi+weapon
		sta ytable+weapon

		jsr read_keyboard
		
		lda ScanResult
		bne +	
			; No keys are pressed so Player is standing

			ldx #0
			stx plr_r_ctrl_dir

			lda PlayerAnimState
			and #3 ; Get direction no matter which state
			sta PlayerAnimState
			jmp +++	; Release all pressed keys
+
		and #2 ; Check for A key (left)
		beq +
			ldx #1
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #player
			jsr get_tile_left_of_sprite

			ldx #PlayerRunWest
			stx PlayerAnimState

			; Check collision for tile in a
			tax
			lda collision_map,x
			sta plr_r_ctrl_coll
			cmp #CollisionBlocking
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_left player,1

			jmp +++

+		lda ScanResult
		and #4 ; Check for D key (right)
		beq +
			ldx #2
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #player
			jsr get_tile_right_of_sprite

			ldx #PlayerRunEast
			stx PlayerAnimState

			; Check collision for tile in a
			tax
			lda collision_map,x
			sta plr_r_ctrl_coll
			cmp #CollisionBlocking
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_right player,1

			jmp +++

+		lda ScanResult
		and #8 ; Check for W key (up)
		beq +
			ldx #3
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #player
			jsr get_tile_above_sprite

			ldx #PlayerRunNorth
			stx PlayerAnimState

			; Check collision for tile in a
			tax
			lda collision_map,x
			sta plr_r_ctrl_coll
			cmp #CollisionBlocking
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_up player,1

			jmp +++

+		lda ScanResult
		and #16 ; Check for S key (down)
		beq +
			ldx #4
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #0
			ldx #player
			jsr get_tile_below_sprite

			ldx #PlayerRunSouth
			stx PlayerAnimState

			; Check collision for tile in a
			tax
			lda collision_map,x
			sta plr_r_ctrl_coll
			cmp #CollisionBlocking
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_down player,1

			jmp +++

+		lda ScanResult
		and #32 ; Check for Return key (attack)
		beq +++
			lda KeyStopper
			and #$20
			bne ++++
				lda KeyStopper	; filter "Return" key for next repeat
				ora #$20
				sta KeyStopper

				; Check if next to chest
				lda plr_r_last_tileidx
				cmp #TileChestClosedLeft
				bne +
					; save chest tile idx and location
					sta tmp_chest_idx
					lda plr_r_last_tilepos
					sta tmp_chest_loc

					; set loot timer
					lda #100
					sta PlayerBusyTimer
					lda #PlayerStateStartLootChest
					sta PlayerState
					jmp ++++

+				cmp #TileChestClosedRight
				bne +
					; save chest tile idx and location
					sta tmp_chest_idx
					lda plr_r_last_tilepos
					sta tmp_chest_loc

					; set loot timer
					lda #100
					sta PlayerBusyTimer
					lda #PlayerStateStartLootChest
					sta PlayerState
					jmp ++++

+				; else
					; At this point we can assume it is an attack
					lda #10
					sta PlayerBusyTimer

					lda #<sword_swing
					ldy #>sword_swing
					ldx #14
					jsr $2006

					jsr player_start_attack

					;ldx #0	; this is used as return value, must be 0 or weird things WILL happen!
					jmp ++++
+++
		; Reset keystopper
		lda KeyStopper
		and #$df
		sta KeyStopper
++++

		rts
; --------------------------------------------
; player_read_controls local vars
; --------------------------------------------
plr_r_ctrl_dir
		!byte $00
plr_r_ctrl_coll
		!byte $00
plr_r_last_tilepos
		!byte $00
plr_r_last_tileidx
		!byte $00
; --------------------------------------------



; --------------------------------------------
; --------------------------------------------
; SHORT UTILITY ROUTINES
; --------------------------------------------
; --------------------------------------------

; get_tile_left_of_sprite (spriteX-1)/16
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
get_tile_left_of_sprite

		ldy #xoffset
		iny		; this will make the check happen 1 pixel to the left of the sprite origin.
		sty tmp
		lda xtablelo,x

		sec
		sbc tmp		; first remove the xoffset: spriteX = (spriteX - offx - 1)
		sta tmp
		lda xtablehi,x	; get sprite MSB
		sbc #0
		lsr		; move bit 0 to carry
		lda tmp
		ror		; bring in carry and divide by 16 => store (sprX-1)/16 in tmp
		lsr
		lsr
		lsr
		sta tmp

		; say, sprite y is at 160 => (160 - 52 + 8) / 16 = 116 / 16 = 7 = y

		; pseudocode:
		; y = sprite_y[.sprite];
		; y = (y - yoffset + 8) / 16 + offy;

		lda ytable,x
		sec
		sbc #yoffset	; first remove the yoffset
		clc
		adc #8		; check preferably from the center of the sprite
		lsr
		lsr
		lsr
		lsr
		tay

		clc
		lda get_index_from_map_coords,y
		adc tmp
		tax
		lda tilebuffer,x
		stx plr_r_last_tilepos
		sta plr_r_last_tileidx
		rts

; get_tile_right_of_sprite
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
get_tile_right_of_sprite

		lda #xoffset
		sec
		sbc #16
		sta tmp
		lda xtablelo,x
		sec
		sbc tmp		; first remove the xoffset
		sta tmp
		lda xtablehi,x
		sbc #0
		lsr		; sets carry if bit 0 = 1	
		lda tmp
		ror		; bring in carry
		lsr
		lsr
		lsr
		sta tmp

		lda ytable,x
		sec
		sbc #yoffset	; first remove the yoffset
		clc
		adc #8
		lsr
		lsr
		lsr
		lsr
		tay

		clc
		lda get_index_from_map_coords,y
		adc tmp
		tax
		lda tilebuffer,x
		stx plr_r_last_tilepos
		sta plr_r_last_tileidx
		rts

; get_tile_above_sprite
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
get_tile_above_sprite

		lda #xoffset
		sec
		sbc #8
		sta tmp
		lda xtablelo,x
		sec
		sbc tmp		; first remove the xoffset
		sta tmp
		lda xtablehi,x
		sbc #0
		lsr
		lda tmp
		ror		; bring in carry
		lsr
		lsr
		lsr
		sta tmp2

		lda #yoffset
		clc
		adc #1		; check 1 pixel above sprite
		sta tmp
		lda ytable,x
		sec
		sbc tmp		; first remove the yoffset
		lsr
		lsr
		lsr
		lsr
		tay

		clc
		lda get_index_from_map_coords,y
		adc tmp2
		tax
		lda tilebuffer,x
		stx plr_r_last_tilepos
		sta plr_r_last_tileidx
		rts

; get_tile_below_sprite
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
get_tile_below_sprite

		lda #xoffset
		sec
		sbc #8		; center x from sprite
		sta tmp
		lda xtablelo,x
		sec
		sbc tmp		; first remove the xoffset
		sta tmp
		lda xtablehi,x
		sbc #0
		lsr
		lda tmp
		ror		; bring in carry
		lsr
		lsr
		lsr
		sta tmp2

		lda #yoffset
		sec
		sbc #16
		sta tmp
		lda ytable,x
		sec
		sbc tmp		; first remove the yoffset
		lsr
		lsr
		lsr
		lsr
		tay

		clc
		lda get_index_from_map_coords,y
		adc tmp2
		tax
		lda tilebuffer,x
		stx plr_r_last_tilepos
		sta plr_r_last_tileidx
		rts

;-----------------------------------------------------------

;-----------------------------------------------------------
; calc_individual_forces
; destroys registers a,x
;-----------------------------------------------------------
calc_individual_forces	; $1229


		lda #0
		sta tmp
		ldx #0

		; Check player's forces
		lda PlayerPullForceX

		beq +++	; if it's zero, skip this

		bpl +
			; it's negative ($fa), so the value must be inverted and carry must be set (two's complement)
			ldy #1
			sty tmp
			inc PlayerPullForceX
			dec xtablehi+player	; borrow 1, carry will compensate it
			sec
			jmp ++

+			; it's positive, just add it
			ldy #2
			sty tmp
			dec PlayerPullForceX
			clc
++
		; Apply force to player's x coordinate
		adc xtablelo+player
		sta xtablelo+player
		lda xtablehi+player
		adc #0
		sta xtablehi+player
		ldx #1
+++
		lda PlayerPullForceY

		beq +++ ; if it's zero, skip this

		bpl +
			; it's negative, so the value must be inverted and carry must be set (two's complement)
			ldy #3
			sty tmp
			inc PlayerPullForceY
			sec
			jmp ++

+			; it's positive, just add it
			ldy #4
			sty tmp
			dec PlayerPullForceY
			clc
++
		; Apply force to player's y coordinate
		adc ytable+player
		sta ytable+player
		ldx #1
+++
		cpx #0
		bne +
			jmp ++	; skip collision detection, it is costly!
+

		; If collided with forest, water, walls, stones, etc, then undo the force
		lda tmp
		bne +
		jmp ++
+
		cmp #1
		bne +	; x force was negative

			ldx #player
			jsr get_tile_left_of_sprite
			cmp #20
			bcc +++
				dec PlayerPullForceX
				lda PlayerPullForceX
				eor #$ff
				sec
				sta tmp
				lda xtablelo+player
				adc tmp
				sta xtablelo+player
				lda xtablehi+player
				adc #0
				sta xtablehi+player
				lda #0
				sta PlayerPullForceX
+++
				jmp ++
+		cmp #2 ; x force was positive
		bne +

			ldx #player
			jsr get_tile_right_of_sprite
			cmp #20
			bcc +++
				inc PlayerPullForceX
				lda xtablelo+player
				sec
				sbc PlayerPullForceX
				sta xtablelo+player
				lda xtablehi+player
				sbc #0
				sta xtablehi+player
				lda #0
				sta PlayerPullForceX
+++
				jmp ++
+		cmp #3 ; y force was negative
		bne +

			ldx #player
			jsr get_tile_above_sprite
			cmp #20
			bcc +++
				dec PlayerPullForceY
				lda PlayerPullForceY
				eor #$ff
				sec
				sta tmp
				lda ytable+player
				adc tmp
				sta ytable+player
				lda #0
				sta PlayerPullForceY
+++
				jmp ++
+
		; y force was positive
			ldx #player
			jsr get_tile_below_sprite
			cmp #20
			bcc ++
				inc PlayerPullForceY
				lda ytable+player
				sec
				sbc PlayerPullForceY
				sta ytable+player
				lda #0
				sta PlayerPullForceY
++

; ------------------------------------------

		lda MobsPresent
		bne +
		rts
+		tax

		; do {
-			dex
			lda enemy_pull_force_x,x
			beq +++ ; skip if zero
			bpl +
				; It's negative
				inc enemy_pull_force_x,x
				dec xtablehi+enemy,x
				sec
				jmp ++

+				; It's positive
				dec enemy_pull_force_x,x
				clc

++
			; Apply force to enemy's x coordinate
			adc xtablelo+enemy,x
			sta xtablelo+enemy,x
			lda xtablehi+enemy,x
			adc #0
			sta xtablehi+enemy,x
+++
			lda enemy_pull_force_y,x
			beq +++	; skip if zero
			bpl +
				; It's negative
				inc enemy_pull_force_y,x
				sec
				jmp ++

				; It's positive
				dec enemy_pull_force_y,x
				clc
++
			; Apply force to enemy's y coordinate
			adc ytable+enemy,x
			sta ytable+enemy,x
+++
			cpx #0
			bne -
		; } while (x != 0);

		rts

;-----------------------------------------------------------
; check_player_enemy_collision
; returns: a=1 if collision, 0 if no collision
;-----------------------------------------------------------
check_player_enemy_collision	; $12c4

		lda xtablelo+player
		sec
		sbc xtablelo+enemy,x	; a = player_x - enemy_x[x];
		tay
		lda xtablehi+player
		sbc xtablehi+enemy,x
		bpl +
		; difference is negative, how far?

			; if (a >= -11) then {
			cmp #$ff
			bne ++
			cpy #$f3
			bcs +++
				jmp ++	; check next enemy
+++				; else
				; collision in X, check also Y
				jmp +++
			; }

+			; difference is positive, how far?

			; if (a <= 12) then {
			cmp #$00
			bne ++
			cpy #$0c
			bcc +++
				jmp ++	; check next enemy
+++				; else
				; collision in X, check also Y
			; }
		lda ytable+player
		sec
		sbc ytable+enemy,x		; a = player_y - enemy_y[x];
		bcs +
		; difference is negative, how far?

			; if (a >= -11) then {
			cmp #$f3
			bcs +++
				jmp ++	; check next enemy
+++				; else
				; collision in Y too, return with 1 or higher (depending on loot type)
				lda frame+enemy+16,x     ; contains loot type (80 is heart, 81 is coins, 82 is key)
				rts
			; }

+			; difference is positive, how far?

			; if (a <= 12) then {
			cmp #$0c
			bcc +++
				jmp ++	; check next enemy
+++				; else
				; collision in Y too, return with success
				lda frame+enemy+16,x     ; contains loot type (if applicable)
				rts
			; }
++

		lda #PlayerStateInControl
		rts

;-----------------------------------------------------------
; check_weapon_enemy_collision
; returns: a=x if collision
;-----------------------------------------------------------
check_weapon_enemy_collision	; $12c4

		lda xtablelo+weapon
		sec
		sbc xtablelo+enemy,x	; a = weapon_x - enemy_x[x];
		tay
		lda xtablehi+weapon
		sbc xtablehi+enemy,x
		bpl +
		; difference is negative, how far?

			; if (a >= -14) then {
			cmp #$ff
			beq ++++
				jmp ++
++++			cpy #$f2
			bcs +++
				jmp ++	; check next enemy
+++				; else
				; collision in X, check also Y
				jmp +++
			; }

+			; difference is positive, how far?

			; if (a < 14) then {
			cmp #$00
			beq ++++
				jmp ++
++++			cpy #$0e
			bcc +++
				jmp ++	; check next enemy
+++				; else
				; collision in X, check also Y
			; }
		lda ytable+weapon
		sec
		sbc ytable+enemy,x		; a = player_y - enemy_y[x];
		bcs +
		; difference is negative, how far?

			; if (a >= -16) then {
			cmp #$f2
			bcs +++
				jmp ++	; exit with a=0
+++				; else
				; collision in Y too, return with success

				lda enemy_state,x	; check if enemy is alredy being hurt or is dying
				cmp #EnemyHit
				beq ++			; and if so, don't hurt anymore, exit with a=0
				cmp #EnemyDying
				beq ++
					lda #EnemyHit
					sta enemy_state,x
					lda #32
					sta enemy_timer,x
					lda enemy_hp,x
					sec
					sbc PlayerWeaponPower
					sta enemy_hp,x
					bcs +++
						lda #0
						sta enemy_hp,x
						lda #EnemyDying		; Player has slain the enemy
						sta enemy_state,x
						sta enemy_anim_state,x
						lda #24
						sta enemy_timer,x
+++
				inx
				txa
				dex
				rts
			; }

+			; difference is positive, how far?

			; if (a < 16) then {
			cmp #$0e
			bcc +++
				jmp ++	; exit with a=0
+++				; else
				; collision in Y too, return with success

				lda enemy_state,x	; check if enemy is alredy being hurt or is dying
				cmp #EnemyHit
				beq ++			; and if so, don't hurt anymore, exit with a=0
				cmp #EnemyDying
				beq ++
					lda #EnemyHit
					sta enemy_state,x
					lda #32
					sta enemy_timer,x
					lda enemy_hp,x
					sec
					sbc PlayerWeaponPower
					sta enemy_hp,x
					bcs +++
						lda #0
						sta enemy_hp,x
						lda #EnemyDying		; Player has slain the enemy
						sta enemy_state,x
						sta enemy_anim_state,x
						lda #24
						sta enemy_timer,x
+++
				inx
				txa
				dex
				rts
			; }
++

		lda #$00
		rts

;-----------------------------------------------------------
; decrease_hp
; Removes 'a' units from player's HP stat (damage)
; NOTE: a shall contain a BCD value
; If result is negative, then carry will be cleared
;-----------------------------------------------------------
decrease_hp
		sta tmp_hp_digits
		lda player_hp
		asl
		asl
		asl
		asl
		ora player_hp+1

		sed

		sec
		sbc tmp_hp_digits
		bcs +
		lda #0
+
		cld

		sta tmp_hp_digits
		and #$0f
		sta player_hp+1
		lda tmp_hp_digits
		and #$f0
		lsr
		lsr
		lsr
		lsr
		sta player_hp

		lda tmp_hp_digits

		rts
;-----------------------------------------------------------
; increase_hp
; Adds 'a' units to player's HP stat (healing)
; NOTE: a shall contain a BCD value
; If result overflows (>=100), then carry will be set
;-----------------------------------------------------------
increase_hp
		; Need to backup HP first here
		; Then add indices 1 and 0
		sta tmp_hp_digits
		lda player_hp+1
		sta backup_hp+1
		lda player_hp
		sta backup_hp

		asl
		asl
		asl
		asl
		ora player_hp+1

		clc
		sed
		adc tmp_hp_digits
		cld

		bcs +	; if carry set or player_max_hp - tmp_hp_digits < 0:
			sta tmp_hp_digits

			lda player_max_hp
			asl
			asl
			asl
			asl
			ora player_max_hp+1

			sed
			sec
			sbc tmp_hp_digits
			cld

		bcc +

			lda tmp_hp_digits
			and #$f0
			lsr
			lsr
			lsr
			lsr
			sta player_hp
			lda tmp_hp_digits
			and #$0f
			sta player_hp+1

			rts

+		; else:

			; restore backup
			lda backup_hp
			sta player_hp
			lda backup_hp+1
			sta player_hp+1

			rts
		; end if
backup_hp
		!byte $00,$00
;-----------------------------------------------------------
; decrease_gold
; Pay 'a' coins from player's gold
; NOTE: a shall contain a BCD value (2 digits)
; If result is negative (<0), then carry will be cleared
;-----------------------------------------------------------
decrease_gold
		sta tmp_gold_incr

		; backup gold first
		lda player_gold+4
		sta backup_gold+4
		lda player_gold+3
		sta backup_gold+3
		lda player_gold+2
		sta backup_gold+2
		lda player_gold+1
		sta backup_gold+1
		lda player_gold
		sta backup_gold

		; subtract from digits 4 and 3
		lda player_gold+3
		asl
		asl
		asl
		asl
		ora player_gold+4

		sed

		sec
		sbc tmp_gold_incr
		bcs +
			lda #0
+
		php

		sta tmp_gold_incr
		and #$f0
		lsr
		lsr
		lsr
		lsr
		sta player_gold+3
		lda tmp_gold_incr
		and #$0f
		sta player_gold+4

		plp

		bcs ++

		; if carry, do also digits 2 and 1
		lda player_gold+1
		asl
		asl
		asl
		asl
		ora player_gold+2

		sec
		sbc #1
		bcs +
			lda #0
+
		php

		sta tmp_gold_incr
		and #$f0
		lsr
		lsr
		lsr
		lsr
		sta player_gold+1
		lda tmp_gold_incr
		and #$0f
		sta player_gold+2

		plp

		bcs ++

		; if still carry, do also digit 0
		lda player_gold

		sec
		sbc #1
		bcs +	; if all digits < 0, reset all digits to backup!
			lda backup_gold+4
			sta player_gold+4
			lda backup_gold+3
			sta player_gold+3
			lda backup_gold+2
			sta player_gold+2
			lda backup_gold+1
			sta player_gold+1
			lda backup_gold
+
		sta player_gold
++
		cld

		; if carry is cleared after this subroutine, then NOT ENOUGH GOLD!

		rts
backup_gold
		!byte $00,$00,$00,$00,$00

;-----------------------------------------------------------
; increase_gold
; Adds 'a' coins to player's gold stat
; NOTE: a shall contain a BCD value
; If result overflows (>=100), then carry will be set
;-----------------------------------------------------------
increase_gold

		; add indices 4 and 3
		sta tmp_gold_incr
		clc
		lda player_gold+1
		asl
		asl
		asl
		asl
		ora player_gold+2
		sta tmp_gold_value+1
		clc
		lda player_gold+3
		asl
		asl
		asl
		asl
		ora player_gold+4


		; add values now (in BCD mode)
		sed
		sta tmp_gold_value
		clc
		adc tmp_gold_incr	; add 0-7 bits
		sta tmp_gold_value
		bcc ++	; skip if no more digits need update
		lda tmp_gold_value+1
		adc #0			; add 8-15 bits
		sta tmp_gold_value+1
		lda player_gold
		adc #0			; add 16-23 bits
		sta player_gold
		cmp #10
		bcc +
			lda #9
			sta player_gold
			sta player_gold+1
			sta player_gold+2
			sta player_gold+3
			sta player_gold+4
+
		; Adding complete, now convert back to displayable digits
		clc
		lda tmp_gold_value+1
		and #$f0
		lsr
		lsr
		lsr
		lsr
		sta player_gold+1
		lda tmp_gold_value+1
		and #$0f
		sta player_gold+2
++
		clc
		lda tmp_gold_value
		and #$f0
		lsr
		lsr
		lsr
		lsr
		sta player_gold+3
		lda tmp_gold_value
		and #$0f
		sta player_gold+4

		cld

		rts

;-----------------------------------------------------------
; KERNAL RAM TABLES (will be generated in RAM behind kernal)
;-----------------------------------------------------------
generate_tables

		; create player stats data
		ldx #99
		lda #0
-		sta $f000,x
		dex
		bne -

		; initialize max HP, and HP to 6, level to 1
		lda #6
		sta player_max_hp+1
		lda #6
		sta player_hp+1
		lda #1
		sta player_level+1

		; generate tile positions low byte
		lda #0
		ldx #0
-				ldy #20
--				sta $f100,x
				clc
				adc #2
				inx
				dey
				bne --
			clc
			adc #40
			cpx #240
			bne -

		; generate tile positions high byte for screen 0,1 and color ram
		lda #$40
		sta tmp
		lda #$44
		sta tmp2
		lda #$d8
		sta tmp3
		ldx #0
-			lda tmp
			sta $f200,x
			lda tmp2
			sta $f300,x
			lda tmp3
			sta $f400,x
			inx
			cpx #$44
			bne -
		inc tmp
		inc tmp2
		inc tmp3
		ldx #0
-			lda tmp
			sta $f244,x
			lda tmp2
			sta $f344,x
			lda tmp3
			sta $f444,x
			inx
			cpx #$44
			bne -
		inc tmp
		inc tmp2
		inc tmp3
		ldx #0
-			lda tmp
			sta $f288,x
			lda tmp2
			sta $f388,x
			lda tmp3
			sta $f488,x
			inx
			cpx #$40
			bne -
		inc tmp
		inc tmp2
		inc tmp3
		ldx #0
-			lda tmp
			sta $f2c8,x
			lda tmp2
			sta $f3c8,x
			lda tmp3
			sta $f4c8,x
			inx
			cpx #$28
			bne -

		; initialize sprite data area (160 bytes), start address is ytable
		ldx #160
		lda #0
-		dex
		sta ytable,x
		bne -
		
		rts


; --------------------------------------------
; RANDOM DATA
; --------------------------------------------

random_table	!byte  41,  1,101,238,141, 77,142, 39
		!byte 203,187,228,174,153,199,188,196
		!byte 104, 35,122, 71, 94,124,246,148
		!byte 197,102, 14, 95, 29,  6,100,250
		!byte 177, 53,185,147,247,251, 17,214
		!byte 233,173,183,252, 34,230, 33, 18
		!byte  78,149,137, 51, 40,125,202, 80
		!byte 239, 27, 30, 62,211,242,218,204
		!byte 107,192,249,236, 97,231, 15,130
		!byte 105,  3,209,159, 10,240,180, 26
		!byte 220, 45,  8,155,208,166, 58, 68
		!byte 215, 73,157, 52, 54, 38,143, 28
		!byte 193,226,126,194,223,164,114,120
		!byte 172,225,118,150,154,145,109,171
		!byte  21, 89,184, 13,169,241,224,  7
		!byte 210, 25,253,201,243,  5, 22,110
		!byte   9,167,115,248,135,134, 57, 46
		!byte 106,235,245, 43, 59,129, 67, 75
		!byte 182,216, 99,175,190,191,162, 66
		!byte 117, 50, 69, 37,151, 83,103,163
		!byte  36, 20, 11,206,131,156,168, 65
		!byte 133, 98,165,144, 55,  4,232, 84
		!byte  24, 72, 85,222, 74,244, 60, 70
		!byte 237, 91,229,127,132,221,179,161
		!byte 158, 23, 44, 56,178, 49,139,138
		!byte 112, 90, 32,234,123,170, 12, 81
		!byte 108, 93,181,116, 82, 92,186,111
		!byte 113,121,219, 79, 76,200, 88, 31
		!byte 213, 47, 96, 61,136, 19,198, 16
		!byte   2, 48, 63,119, 87,189,254,205
		!byte  64, 86,128, 42,176,195,146,227
		!byte 140,212,217,207,152,160,255,0

; --------------------------------------------
; LOOKUP TABLES END
; --------------------------------------------


; --------------------------------------------
; get_random
; stores a random byte value in RandomNumber variable
; destroys registers: none
get_random
		sta safe_tmp
		stx safe_tmp2
		lda #0
		ora $dc09
		asl
		asl
		asl
		asl
		ora $dc08
		ora $d012
		pha
		and #7
		tax
		pla
		adc random_table,x
		eor RandomIdx
		sta RandomNumber
		inc RandomIdx
		ldx safe_tmp2
		lda safe_tmp
		rts

; --------------------------------------------
; get_door_target_location
; - Relocate player at target screen position
;   and redraw screen.
; - Use x to determine in which direction door
;   was found relative to player's location.
; - Returns:    a - door target location on map
; --------------------------------------------
get_door_target_location

		; Get screens array location!
		;-----------------------------

		; store direction
		stx tmp3

		; All these rows mean: a = offy * 16 / 12
		lda offy
		jsr transform_a_mul_16_div_12
		sta tmp

		; This is a = offx / 20
		ldy #$ff
		ldx offx+1
		lda offx
-			iny
			sec
			sbc #20
			bcs -
			dex	; offx is 16 bits so check that bit 8 is also subtracted from
			bpl -
		tya
		clc
		adc tmp		; x = offy * 4 / 3 + offx / 20 == screen pos!
		tax		; -------------------------------------------
		sta tmp	; screen_pos

		; Use x now to fetch current screen location in door table
		lda doortable,x

		; if (a >= $e0) {
		cmp #$f0
		bcc +
			; This is a dungeon entrance! Return = dungeon_id | 0xf0
			rts
+		cmp #$e0
		bcc +
			; use doortablemulti to look up doors

			sec
			sbc #$e0	; - remove $e0 from x offset
			tax		; "door set" offset in doortablemulti

			ldy #$ff
			cpx #0
			bne ++
			jmp +++
			; if (x != 0) {
				ldy #0
				jmp ++

			; } else {
+++
-				; while (x >= 0) {
					iny
					; while(a != #$ff) {
						lda doortablemulti,y
						cmp #$ff
						bne -
					; }
					dex
					bpl -
				; }
				sty tmp2	; store doortablemulti byte offset calculated from "door set" offset
			;}
++
			jsr get_entered_door_index	; returns x as index to doortablemulti

			txa
			clc
			adc tmp2	; apply door index + doortablemulti byte offset to get final door

			tax
			lda doortablemulti,x
			rts

+		; } else {
       			; (a >= $f0)
			; target location is a dungeon
			; nop
		; }
		rts

doorbuf		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	; 8 doors max


;-----------------------------------------------------------
; get_entered_door_index
; - destroys all registers
; - parameters:
;	tmp 	- screen position where to look
;	tmp3	- direction: 1=west, 2=east, 3=north, 4=south
; - returns:
;	a	- screen tile location where door was found
;	x	- index in doortablemulti where door was found
; ---------------------------------------------------------------
get_entered_door_index
		ldx #0
		ldy #0
-			lda tilebuffer,x
			cmp #13 ; type = a; index = x;
			beq save_door_type ;   save_door_type(type, index);
			cmp #14
			beq save_door_type
--			inx
			cpx #240
			bne -
		jmp ++
		; -------------------------------------------------------------------------
save_door_type
				txa
				sta doorbuf,y	; fill in positions where doors were found.
				iny
				jmp --
		; -------------------------------------------------------------------------
++
		ldx #$ff
		ldy tmp3	; check direction
		cpy #1		; west
		bne ++
			dec tmp
++		cpy #2		; east
		bne ++
			inc tmp
++		cpy #3		; north
		bne ++
			lda tmp
			sec
			sbc #20
			sta tmp
++		cpy #4		; south
		bne +
			lda tmp
			sec
			sbc #20
			sta tmp
++
-		; do {
			inx
			lda doorbuf,x
			cmp tmp		; compare with current position
			beq ++		; if found, return a, x
			lda #$ff
			cmp tmp
			bne -
		; while (a != #$ff);

		ldx #$ff
++		rts
; --------------------------------------------



; --------------------------------------------
; transform_a_div_16_mul_12
; Recalculates a = a / 16 * 12
; Destroys y
; --------------------------------------------
transform_a_div_16_mul_12

		; All these rows mean: a = a / 16 * 12
		tay
		lda #0
		cpy #$10
		bcc +		; if offy < 12 goto +
		adc #11		; adding actually 16 here, carry is always set!
		cpy #$20
		bcc +		; if offy < 24 goto +
		adc #11
		cpy #$30
		bcc +
		adc #11
		cpy #$40
		bcc +
		adc #11
		cpy #$50
		bcc +
		adc #11
		cpy #$60
		bcc +
		adc #11
		cpy #$70
		bcc +
		adc #11
		cpy #$80
		bcc +
		adc #11
		cpy #$90
		bcc +
		adc #11
		cpy #$a0
		bcc +
		adc #11
		cpy #$b0
		bcc +
		adc #11
+		rts
; --------------------------------------------

; --------------------------------------------
; transform_a_mul_16_div_12
; Recalculates a = a * 16 / 12
; Destroys y
; --------------------------------------------
transform_a_mul_16_div_12

		tay
		lda #0
		cpy #12
		bcc +		; if offy < 12 goto +
		adc #15		; adding actually 16 here, carry is always set!
		cpy #24
		bcc +		; if offy < 24 goto +
		adc #15
		cpy #36
		bcc +
		adc #15
		cpy #48
		bcc +
		adc #15
		cpy #60
		bcc +
		adc #15
		cpy #72
		bcc +
		adc #15
		cpy #84
		bcc +
		adc #15
		cpy #96
		bcc +
		adc #15
		cpy #108
		bcc +
		adc #15
		cpy #120
		bcc +
		adc #15
		cpy #132
		bcc +
		adc #15
		cpy #144
		bcc +
		adc #15		
+		rts
; --------------------------------------------



; -------------------------------------------------
; Generate save code (weap | map, items, maxhp + money + keys)
; -------------------------------------------------
generate_code
		lda MapID
		asl
		asl
		asl
		asl
		ora PlayerWeaponPower
		sta generate_code_data

		lda player_inv
		sta generate_code_data+1

		rts

generate_code_data
		!byte $00,$00,$00,$00,$00,$00,$00,$00
; -------------------------------------------------


; -------------------------------------------------
;  Transition between a buffered screen and
;  the visible screen.
;
;  HOW TO USE:
;   - Initialize transit_x to 0.
;   - Call repeatedly and check transit_x;
;     when transit_x == 40, then transition is
;     completed.
;
;  (Transits 1 char column at a time and
;  increments transit_x in the end.)
; -------------------------------------------------

transit_screen
		lda #$d8
		sta transit_color+1
		lda #$f6
		sta transit_colback+1

		; front buffer should be stored in transit_char
		lda screen_id
		bne +
			lda #$40
			jmp ++
+
			lda #$44
++
		sta transit_char+1

		lda #0
		sta transit_color
		sta transit_colback
		sta transit_char
		sta transit_back

		; back buffer should be stored in transit_back
		lda screen_id
		bne +
			lda #$44
			jmp ++
+
			lda #$40
++
		sta transit_back+1

		; init column start positions
		lda transit_x	; will contain the current transition x position
		sta transit_column1
		sta transit_column2
		sta transit_column3
		beq +
			; decrease char column position by 1
			dec transit_column3
			dec transit_column2
+		beq +
			; decrease char column position by 2
			dec transit_column3
+
		; init count
		ldx #0

-		; for each screen line (x) do:
			ldy transit_column1
			cpy #40
			bcs +
				ldy transit_column1
				lda #0
				sta (transit_color),y
+

			ldy transit_column2
			cpy #40
			bcs +
				lda #4
				sta (transit_char),y
				lda #0
				sta (transit_color),y
+

			ldy transit_column3
			cpy #40
			bcs +
				lda (transit_back),y
				sta (transit_char),y
				lda (transit_colback),y
				sta (transit_color),y
+

			lda transit_color
			clc
			adc #40
			sta transit_color
			sta transit_char
			sta transit_back
			sta transit_colback
			bcc +
				inc transit_color+1
				inc transit_char+1
				inc transit_back+1
				inc transit_colback+1
+
			inx
			cpx #24
			bcc -

		inc transit_x
		rts

transit_x	!byte $00
; --- these are moved to top!
;transit_color		= $07	; alias for tmp_addr !
;transit_char		= $0b	; alias for tmp_addr2 !
;transit_column1	= $06	; alias for tmp !
;transit_column2	= $09	; alias for tmp2 !
; -------------------------------------------------

;-----------------------------------------------------------
; swap_screen
; parameters:
; destroys registers: yes
;-----------------------------------------------------------
swap_screen
	lda screen_id
	beq show_4400

	; $4000 -> screen buffer
	; $4400 -> back buffer

	lda #0
	sta screen_id
	lda $d018
	and #$0f
	sta $d018

	; copy sprite pointers
	lda $47f8
	sta $43f8
	lda $47f9
	sta $43f9
	lda $47fa
	sta $43fa
	lda $47fb
	sta $43fb
	lda $47fc
	sta $43fc
	lda $47fd
	sta $43fd
	lda $47fe
	sta $43fe
	lda $47ff
	sta $43ff
	jmp show_4000
show_4400
	; $4400 -> screen buffer
	; $4000 -> back buffer

	lda #1
	sta screen_id
	lda $d018
	and #$0f
	ora #$10
	sta $d018

	; copy sprite pointers
	lda $43f8
	sta $47f8
	lda $43f9
	sta $47f9
	lda $43fa
	sta $47fa
	lda $43fb
	sta $47fb
	lda $43fc
	sta $47fc
	lda $43fd
	sta $47fd
	lda $43fe
	sta $47fe
	lda $43ff
	sta $47ff
show_4000
	rts

;-----------------------------------------------------------
; copy_screen
; parameters: none
; destroys registers: yes
;-----------------------------------------------------------
copy_screen
	ldx #0
	lda screen_id
	beq +
	; if screen id == 1:

	; $4400 -> screen buffer
	; $4000 -> back buffer
-
			lda $4400,x
			sta $4000,x
			lda $4500,x
			sta $4100,x
			lda $4600,x
			sta $4200,x
			lda $46e8,x
			sta $42e8,x
			inx
		bne -

		jmp ++
+	; else screen id == 0:
	; $4000 -> screen buffer
	; $4400 -> back buffer
-
			lda $4000,x
			sta $4400,x
			lda $4100,x
			sta $4500,x
			lda $4200,x
			sta $4600,x
			lda $42e8,x
			sta $46e8,x
			inx
		bne -

++
	rts


;-----------------------------------------------------------
; clear_status_bar
; parameters: none
; destroys registers: a, x
;-----------------------------------------------------------
clear_status_bar
	ldx #28
	lda #$c0
-	sta $43bf,x
	sta $47bf,x
	dex
	bne -
	rts

;-----------------------------------------------------------



get_index_from_map_coords
		!byte $00,$14,$28,$3c,$50,$64,$78,$8c
		!byte $a0,$b4,$c8,$dc

; -------------------------------------------------

		*=$1b00
map_data_start
; MAIN WORLD DOORS - Each cell here is a reference to another cell. TODO: Store on disk with world.
;                    These tables can be loaded from disk (they will not change.)
doortable	; e0-ef indicates offset in "doortablemulti". $f0-$fe are dungeons 1-15, $ff means no door
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $ff,$83,$83,$80,$ff,$87,$ff,$88,$ff,$89,$8a,$ff,$8b,$ff,$ff,$8f ; $00
		!byte $ff,$85,$86,$ff,$81,$ff,$ff,$ff,$ff,$ff,$ff,$8d,$ff,$8e,$ff,$ff ; $10
		!byte $ff,$84,$92,$82,$8c,$ff,$93,$96,$e0,$ff,$97,$ff,$99,$ff,$91,$9a ; $20
		!byte $9b,$9f,$ff,$ff,$ff,$9d,$9c,$ff,$95,$ff,$ff,$98,$ff,$ff,$ff,$ff ; $30
		!byte $ff,$9e,$c0,$ff,$ff,$ff,$a1,$a2,$ff,$a3,$ff,$a6,$a5,$a7,$aa,$a8 ; $40
		!byte $a9,$ff,$a0,$ab,$ff,$ac,$ad,$b4,$ff,$e1,$e2,$ff,$ff,$ff,$ff,$b5 ; $50
		!byte $b7,$ff,$b6,$b8,$ff,$ff,$ff,$b9,$ff,$ba,$ff,$ff,$bb,$bf,$ff,$ff ; $60
		!byte $bc,$bd,$be,$ff,$ff,$ff,$a4,$c1,$c2,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $70
		; --------------------------------------------------------------------------
		!byte $03,$14,$23,$e3,$21,$11,$12,$05,$07,$09,$0a,$0c,$24,$1b,$1d,$0f ; $80
		!byte $28,$2e,$22,$26,$28,$38,$27,$2a,$3b,$2c,$2f,$30,$36,$35,$41,$31 ; $90
		!byte $52,$46,$47,$49,$76,$4c,$4b,$4d,$4f,$50,$4e,$53,$55,$56,$59,$59 ; $a0
		!byte $59,$5a,$5a,$5a,$57,$5f,$62,$60,$63,$67,$69,$6c,$70,$71,$72,$6d ; $b0
		!byte $42,$77,$78                                                     ; $c0

doortablemulti
		!byte $94,$90,$ff
		!byte $ae,$af,$b0,$ff
		!byte $b1,$b2,$b3,$ff
		!byte $01,$02,$ff

doorexits	; Exit tile position on *target* screen if door exists on that screen.
		; Let's say, if doortable position x contains $81, then the exit tile
		; coordinate found on screen position $81 is $bc.
		; f0-ff indicates offset in "doorexitsmulti".
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$2b,$be,$2a,$00,$2b,$00,$be,$00,$be,$be,$00,$be,$00,$00,$2b ; $00
		!byte $00,$3e,$33,$00,$be,$00,$00,$00,$00,$00,$00,$3e,$00,$33,$00,$00 ; $10
		!byte $00,$2a,$be,$be,$be,$00,$be,$be,$f0,$00,$be,$00,$be,$00,$be,$be ; $20
		!byte $be,$be,$00,$00,$00,$2a,$2a,$00,$be,$00,$00,$be,$00,$00,$00,$00 ; $30
		!byte $00,$2a,$be,$00,$00,$00,$3e,$33,$00,$be,$00,$be,$2a,$2a,$be,$be ; $40
		!byte $be,$00,$2a,$be,$00,$2a,$be,$be,$00,$f1,$f2,$00,$00,$00,$00,$be ; $50
		!byte $be,$00,$be,$be,$00,$00,$00,$be,$00,$be,$00,$00,$be,$2a,$00,$00 ; $60
		!byte $be,$be,$be,$00,$00,$00,$be,$3e,$33,$00,$00,$00,$00,$00,$00,$00 ; $70
		; -------------------------------------------------------------------
		!byte $36,$84,$a9,$f3,$6e,$39,$2a,$41,$92,$bf,$60,$6d,$80,$ae,$73,$3e ; $80
		!byte $af,$8f,$be,$6c,$6d,$2f,$d0,$6e,$6d,$5d,$18,$a5,$6b,$2e,$b6,$aa ; $90
		!byte $90,$c5,$b7,$d4,$6c,$7d,$59,$40,$83,$40,$94,$1d,$b9,$81,$2a,$b9 ; $a0
		!byte $bd,$3e,$31,$b5,$69,$92,$84,$82,$52,$40,$70,$7f,$80,$5e,$37,$ad ; $b0
		!byte $a8,$58,$1a                                                     ; $c0

doorexitsmulti
		!byte $2a,$be,$ff
		!byte $be,$be,$be,$ff
		!byte $3e,$33,$be,$ff
		!byte $34,$5a,$ff

; special entries
;		$00-$3f = locked doors (if grass then must magically be revealed) (position)
;		$40-$7f = chests (position, content)
;		$80-$bf = destroyable blocks (not stones! they are all breakable.) (position, content)
;		$c0-$fe = runestones (spells) (spell number)

; notes:        - If $00-$3f but no door, then reveal a life container instead.
special_entries
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$80,$81,$ff,$c0,$82,$ff,$83,$ff,$84,$85,$ff,$86,$ff,$ff,$c1
		!byte $ff,$ff,$ff,$87,$c2,$ff,$ff,$ff,$ff,$88,$c3,$40,$ff,$89,$ff,$ff
		!byte $ff,$01,$8a,$ff,$ff,$ff,$8b,$8c,$02,$ff,$03,$ff,$8d,$ff,$04,$8e
		!byte $8f,$90,$91,$ff,$ff,$ff,$92,$ff,$05,$ff,$ff,$ff,$ff,$93,$ff,$ff
		!byte $ff,$c4,$94,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$95,$06,$96,$97,$98
		!byte $ff,$ff,$ff,$99,$41,$ff,$07,$9a,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $9b,$ff,$ff,$9c,$ff,$ff,$ff,$9d,$ff,$9e,$ff,$ff,$9f,$a0,$ff,$a1
		!byte $ff,$ff,$a2,$ff,$08,$ff,$a3,$ff,$a4,$ff,$ff,$ff,$ff,$ff,$ff,$09
		; -------------------------------------------------------------------
		!byte $42,$43,$ff,$44,$45,$ff,$ff,$44,$45,$45,$45,$45,$46,$ff,$47,$c5
		!byte $48,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff

; screen tile positions for:
locked_doors		; $00 - $3f
		!byte $ff
; screen tile positions and content for:
chests			; $40 - $7f
		!byte $ff
; screen tile positions and content for:
destroyable_blocks	; $80 - $bf
		!byte $ff
; content for:
runestones		; $c0 - $fe
		!byte $ff



; -------------------------------------------------

mobs_entries
		;          Enemy types:
                ;          0 - slime    (green - easy)
                ;          1 - spider   (green - easy)
                ;          2 - skeleton (green - easy)
                ;          3 - knight   (green - easy)
                ;          4 - slime    (blue - moderate)
		;          5 - spider   (blue - moderate)
		;          6 - skeleton (blue - moderate)
		;          7 - knight   (blue - moderate)
                ;          8 - slime    (purple - hard)
		;          9 - spider   (purple - hard)
		;          a - skeleton (purple - hard)
		;          b - knight   (purple - hard)
                ;          c - slime    (orange - extreme)
		;          d - spider   (orange - extreme)
		;          e - skeleton (orange - extreme)
		;          f - knight   (orange - extreme)
		;         10 - free
		;         80 - NPC 0    (key giver for first "sword" chest)
; $00
grp_nothing
		!byte $00		; empty room
; $01
grp_4x_blueknights
		!byte $01,$07,$04	; # of groups; type (up to 256); qty in group x; type; qty in group x+1; ...
; $02
grp_4x_blueskellies
		!byte $01,$06,$04
; $03
grp_4x_greenknights
		!byte $01,$03,$04
; $04
grp_4x_bluespiders
		!byte $01,$05,$04
; $05
grp_4x_greenskellies
		!byte $01,$02,$04
; $06
grp_4x_greenspiders
		!byte $01,$01,$04
; $07
grp_4x_greenslimes
		!byte $01,$00,$04


; $08
grp_1x_greenskelly
		!byte $01,$02,$01
; $09
grp_1x_greenslime
		!byte $01,$00,$01
; $0a
grp_6x_greenslime
		!byte $01,$00,$06
; $0b
grp_6x_greenspiders
		!byte $01,$01,$06
; $0c
grp_2x_greenslime
		!byte $01,$00,$02
; $0d
grp_1x_npc_0	!byte $01,$80,$01

mobs_entries_list	; room for enemy configurations
		!byte $00,$01,$04,$07,$0a,$0d,$10,$13,$16,$19,$1c,$1f,$22,$25,$28,$2b
		!byte $2e,$31,$34,$37,$3a,$3d,$40,$43,$46,$49,$4c,$4f,$52,$55,$58,$5b
		!byte $5e,$61,$64,$67,$6a,$6d,$70,$73,$76,$79,$7c,$7f,$82,$85,$88,$8b
		!byte $8e,$91,$94,$97,$9a,$9d,$a0,$a3,$a6,$a9,$ac,$af,$b2,$b5,$b8,$bb
		!byte $be,$c1,$c4,$c7,$ca,$cd,$d0,$d3,$d6,$d9,$dc,$df,$e2,$e5,$e8,$eb
;-----------------------------------------------------------
; level data constants (occupies $0440 bytes = 1092 bytes)
;-----------------------------------------------------------
map_data_end
		*=$1e00
world
		; mobs_entries references

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $01,$02,$02,$02,$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00
		!byte $04,$04,$05,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $01
		!byte $04,$06,$06,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $02
		!byte $04,$06,$06,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $03
		!byte $04,$04,$06,$07,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $04
		!byte $0c,$07,$06,$07,$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $05
		!byte $09,$0b,$00,$06,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $06
		!byte $00,$0a,$08,$0a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $07

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $08
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $09
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0d,$00,$00,$00 ; $0b
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $0c
end_code_800
; -------------------------------------------------



; -------------------------------------------------
;
;		TILE BUFFER AREA
;		; $1f00 - $1fff
;		; do not allocate anything here
;
; -------------------------------------------------



; -------------------------------------------------
		; Game music
; -------------------------------------------------
		*=$2000
		!binary "game_music.bin"

		; Configure memory and loader starts here later.
		*=$3000
begin_code_3k
;-----------------------------------------------------------
; main - entry point of game execution, set things up
; parameters:
;-----------------------------------------------------------
		;tmp

		sei

		lda #$7f
		sta $dc0d	; Turn off CIA interrupts
		sta $dd0d

		cld		; clear decimal flag

		lda #$35	; Turn off kernal and basic
		sta $01
		jsr generate_tables

		ldx #$ff
		txs		; reset stack pointer
		;ldx #0		; x = 0
		;stx $dc0e

		ldx #1
		stx $d01a	; Enable raster interrupts

		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011

		lda $dd00	; Set VIC bank to $4000-$7fff	; We want more sprites!
		and #$fe
		sta $dd00

		lda #<maininter
		sta $fffe
		lda #>maininter
		sta $ffff

		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		ldx #$02	; Fill zero page variable space with value $80 (128)
		lda #$80
-		sta $00,x
		inx
		bne -

		lda #8		; Set max multiplexed sprites to 16
		sta maxspr

		;lda #$ff
		;sta xspeed	; init x speed for sprites to $ff

		;lda #$01	; init y speed for sprites to $01
		;sta yspeed

		lda #$10	; init x difference to 10
		sta xdif
		lda #$f8	; init y difference to 9
		sta ydif

		; init multiplexing jump table (didn't find a way to do this in compile time with ACME.)
		lda #<exitinter
		sta t_jumplo
		lda #>exitinter
		sta t_jumphi
		lda #<dospr0_4
		sta t_jumplo+1
		lda #>dospr0_4
		sta t_jumphi+1
		lda #<dospr1_5
		sta t_jumplo+2
		lda #>dospr1_5
		sta t_jumphi+2
		lda #<dospr2_6
		sta t_jumplo+3
		lda #>dospr2_6
		sta t_jumphi+3
		lda #<dospr3_7
		sta t_jumplo+4
		lda #>dospr3_7
		sta t_jumphi+4

		jsr initsort	; initialize sorting indices

		jsr setup
		;jsr calc_stats

		; init random number table
		ldy #0

--		lda #80
		ldx #8

-		adc random_table,x
		dex
		adc $dc08
		sta random_table,x
		cpx #0
		bne -

		iny
		bne --

		asl $d019	; ack IRQs
		lda $dc0d
		;lda $dd0d

		cli
-
		jmp -

;-----------------------------------------------------------
; player_takes_damage
;
;-----------------------------------------------------------
player_takes_damage

		ldx PlayerBusyTimer
		beq +
			dex			; Player is busy and cannot move, either swinging sword or
			stx PlayerBusyTimer	; taking damage.

			lda #0
			sta xtablelo+weapon
			sta xtablehi+weapon
			sta ytable+weapon

			lda AnimCounter
			and #3
			tax
			lda damage_flash,x
			sta color+player
		rts
+
		lda #PlayerStateInControl
		sta PlayerState
		lda #0
		sta color+player
		rts

;-----------------------------------------------------------
; player_attacks
;
;-----------------------------------------------------------
player_attacks
		ldx PlayerBusyTimer
		beq +
			dex			; Player is busy and cannot move, either swinging sword or
			stx PlayerBusyTimer	; taking damage.
			rts
+
		lda #PlayerStateInControl
		sta PlayerState
		rts

;-----------------------------------------------------------
; player_dying
;
;-----------------------------------------------------------
player_dying
		ldx PlayerBusyTimer
		beq +
			dex			; Player is dying and cannot move.
			stx PlayerBusyTimer
			rts
+
		lda #PlayerDies
		sta PlayerAnimState
		lda #PlayerStateDead
		sta PlayerState
		lda #24
		sta PlayerBusyTimer
		rts

;-----------------------------------------------------------
; player_dies
;
;-----------------------------------------------------------
player_dies
		ldx PlayerBusyTimer
		beq +
			dex			; Player dies. No control given to player. Start fadeout.
			stx PlayerBusyTimer
			rts
+
		lda #0
		sta xtablelo+player
		sta xtablehi+player
		sta ytable+player
		sta xtablelo+enemy
		sta xtablehi+enemy
		sta ytable+enemy
		sta xtablelo+enemy+1
		sta xtablehi+enemy+1
		sta ytable+enemy+1
		sta xtablelo+enemy+2
		sta xtablehi+enemy+2
		sta ytable+enemy+2
		sta xtablelo+enemy+3
		sta xtablehi+enemy+3
		sta ytable+enemy+3
		sta xtablelo+enemy+4
		sta xtablehi+enemy+4
		sta ytable+enemy+4
		sta xtablelo+enemy+5
		sta xtablehi+enemy+5
		sta ytable+enemy+5
		sta MobsPresent
		lda #PlayerStateFades
		sta PlayerState
		lda #32
		sta PlayerBusyTimer
		rts

;-----------------------------------------------------------
; player_fades
;
;-----------------------------------------------------------
player_fades
		ldx #0
		lda player_fades_counter
		beq ++
		cmp #1
		beq +++
		cmp #2
		beq ++++
		cmp #3
		beq +++++
		jmp ++++++	; #4
++
		; fill color buffer step 1/4
-		lda $d800,x
		and #$0f
		tay
		lda gradient_fader,y
		sta $4400,x
		dex
		bne -
		inc player_fades_counter
		rts

+++
		; fill color buffer step 2/4
-		lda $d900,x
		and #$0f
		tay
		lda gradient_fader,y
		sta $4500,x
		dex
		bne -
		inc player_fades_counter
		rts

++++
		; fill color buffer step 3/4
-		lda $da00,x
		and #$0f
		tay
		lda gradient_fader,y
		sta $4600,x
		dex
		bne -
		inc player_fades_counter
		rts
+++++
		; fill color buffer step 4/4
-		lda $db00,x
		and #$0f
		tay
		lda gradient_fader,y
		sta $4700,x
		dex
		bne -
		inc player_fades_counter
		rts
++++++
		; color buffer is now complete, fill color ram:
		ldx #0
-		lda $4400,x
		sta $d800,x
		inx
		bne -
-		lda $4500,x
		sta $d900,x
		inx
		bne -
-		lda $4600,x
		sta $da00,x
		inx
		bne -
-		lda $4700,x
		sta $db00,x
		inx
		bne -
		stx player_fades_counter	; reset fade counter

		ldx PlayerBusyTimer
		beq +
			dex			; Player fades out. No control given to player.
			stx PlayerBusyTimer

			txa
			lsr
			lsr
			tax
			lda fadeout_colors_bg_border,x
			sta $d021
			lda fadeout_colors_extra_color1,x
			sta $d022
			lda fadeout_colors_extra_color2,x
			sta $d023
			rts
+
		; write "game over" on screen
		lda #$c7	; G
		sta $41ef
		lda #$c1	; A
		sta $41f0
		lda #$cd	; M
		sta $41f1
		lda #$c5	; E
		sta $41f2
		lda #$cf	; O
		sta $41f4
		lda #$d6	; V
		sta $41f5
		lda #$c5	; E
		sta $41f6
		lda #$d2	; R
		sta $41f7
		lda #1
		sta $d9ef
		sta $d9f0
		sta $d9f1
		sta $d9f2
		sta $d9f4
		sta $d9f5
		sta $d9f6
		sta $d9f7
		
		rts

player_fades_counter
		!byte $00


;-----------------------------------------------------------
; ctrl_player - read keyboard + move player + check map collision
; returns:
; 0 - player has moved to another screen by going close
;     to a screen edge.
; 1 - player is still on same screen.
;-----------------------------------------------------------
ctrl_player
		lda PlayerState
		bne +
		; ---- PlayerStateInControl ----

			jsr player_read_controls

			; NOTE: This subroutine may change the player's
			; state!
			ldx plr_r_ctrl_coll
			jsr ctrl_player_check_collisions
			ldx #0
			stx plr_r_ctrl_coll

			lda #1
			jmp ctrl_player_check_edges

+		cmp #PlayerStateHit
		bne +

			jsr player_takes_damage
			jmp ctrl_player_check_edges

+		cmp #PlayerStateAttack
		bne +
			jsr player_attacks
			jmp ctrl_player_check_edges

+		cmp #PlayerStateTransitInit
		bne +
			
			jsr unpack_next_screen	; destroys tmp also
			lda #PlayerStateTransitDrawBack
			sta PlayerState
			lda #1
			jmp ctrl_player_end	; don't check edges!

+		cmp #PlayerStateTransitDrawBack
		bne +
			sta put_tile_attr
			jsr draw_screen
			lda #PlayerStateTransit
			sta PlayerState
			lda #0
			ldx #0
-				sta xtablelo,x
				sta xtablehi,x
				sta ytable,x
				inx
				cpx #15
				bne -
			lda #1
			jmp ctrl_player_end	; don't check edges!

+		cmp #PlayerStateTransit
		bne +
			jsr transit_screen
			lda transit_x
			cmp #42
			bcc keep_transit
				lda #PlayerStateTransitEnd
				sta PlayerState
keep_transit
			lda #1
			jmp ctrl_player_end	; don't check edges!

+		cmp #PlayerStateTransitEnd
		bne +

			lda #0
			sta transit_x
			sta PlayerState

			jsr setup_enemies

			; set new player pos
			lda tmp_trans_xhi
			sta xtablehi+player
			lda tmp_trans_xlo
			sta xtablelo+player
			lda tmp_trans_y
			sta ytable+player

			jmp ctrl_player_check_edges

+		cmp #PlayerStateStartLootChest
		bne +
			; should be chest!
			ldx tmp_chest_loc
			ldy tmp_chest_idx

			jsr open_chest
			; TODO: Spawn item

			lda #PlayerStateLootChest
			sta PlayerState

			lda #1
			jmp ctrl_player_end	; don't check edges!
			
+		cmp #PlayerStateLootChest
		bne +
			lda #0
			sta PlayerBusyTimer

			lda #PlayerStateInControl
			sta PlayerState
			jmp ctrl_player_check_edges
			
+		cmp #PlayerStateDying
		bne +
			jsr player_dying
			lda #1
			jmp ctrl_player_end	; report death, skip edges scroll check

+		cmp #PlayerStateDead
		bne +

			jsr player_dies
			lda #1
			jmp ctrl_player_end	; report death, skip edges scroll check

+		cmp #PlayerStateSwitchMap
		bne +
			; TODO: Switch map
			jmp ctrl_player_check_edges

+		; else	;cmp #PlayerStateFades

			jsr player_fades

			jsr read_keyboard
			lda ScanResult
			and #32
			beq *+5
				jsr setup
				lda player_max_hp+1
				sta player_hp+1
				lda player_max_hp
				sta player_hp
				lda #0
				sta player_gold
				sta player_gold+1
				sta player_gold+2
				sta player_gold+3
				sta player_gold+4
			lda #1
			rts

ctrl_player_check_edges

		; Check for screen left edge
		lda xtablelo+player
		cmp #$19
		bcs +
		lda xtablehi+player
		bne +
			lda #state_scroll_left
			sta scrollstate
			lda #0
			sta scroll_x
			sta scroll_x2
			sta scroll_y
			lda #0
			sta $d015
			jsr set_scroll_irq
			lda #0
		jmp ctrl_player_end
+
		; Check for screen right edge
		lda xtablelo+player
		cmp #$48
		bcc +
		lda xtablehi+player
		beq +
			lda #state_scroll_right
			sta scrollstate
			lda #68
			sta scroll_x
			lda #1
			sta scroll_x2
			lda #0
			sta scroll_y
			lda #0
			sta $d015
			jsr set_scroll_irq
			lda #0
		jmp ctrl_player_end
+
		; Check for screen top edge
		lda ytable+player
		cmp #$34
		bcs +
			lda #state_scroll_up
			sta scrollstate
			lda #0
			sta scroll_x
			sta scroll_y
			lda #0
			sta $d015
			jsr set_scroll_irq
			lda #0
		jmp ctrl_player_end
+
		; Check for screen bottom edge
		lda ytable+player
		cmp #$d9
		bcc +
			lda #state_scroll_down
			sta scrollstate
			lda #196
			sta scroll_x
			sta scroll_y
			lda #0
			sta $d015
			jsr set_scroll_irq
			lda #0
		jmp ctrl_player_end
+
		lda #1
ctrl_player_end
		rts

; data used by ctrl_player routine and its
; subroutines:
tmp_doorexit	!byte $00
tmp_trans_xhi	!byte $00
tmp_trans_xlo	!byte $00
tmp_trans_y	!byte $00
tmp_chest_loc	!byte $00
tmp_chest_idx	!byte $00
;-----------------------------------------------------------


;-----------------------------------------------------------
; ctrl_player_check_collisions
; check which tiles the player collided with.
;-----------------------------------------------------------
ctrl_player_check_collisions
		cpx #CollisionDoor
		beq +
			jmp ++
+		; ------------------Found Door---------------------

			ldx plr_r_ctrl_dir
			jsr get_door_target_location ; uses direction variable x
			sta tmp3 ; target screen position
			cmp #$f0
			bcc +
				; TODO: Load new map
				and #$0f
				ldx #PlayerStateSwitchMap
				stx PlayerState
				rts
+
			lda tmp  ; get source screen position (again)
			tax
			lda doorexits,x ; fetch doorexit for target screen at source screen.

+			cmp #$f0
			bcc +
				sec
				sbc #$e0 ; subtract 224 to get multi door offset
				clc
				adc tmp2 	; NOTE: We will reuse tmp2 containing the byte offset in
						;       doortablemulti! See get_door_target_location subroutine.
				tax
				lda doorexitsmulti,x
+
			sta tmp_doorexit ; keep door exit here

			lda tmp3 ; fetch target screen position again
			jsr transform_a_div_16_mul_12
			sta offy ; extract y tile offset

			lda tmp3
			+immediate_a_mod_n 16
			sta tmp
			asl     ; a * 2
			asl     ; a * 4
			clc
			adc tmp ; a * 5
			asl 	; a * 10
			asl	; a * 20
			sta offx 	; extract x tile offset
			bcc +		; spans to 16-bit?
				lda #1	; set bit 9
				sta offx+1
+
			; with x and y tile offsets we can now unpack the target screen
			lda #PlayerStateTransitInit
			sta PlayerState		; NOTE: will change the player's state!
			lda #0
			sta transit_x

			; Place player target position at door exit location (fetched from table)
			lda tmp_doorexit

			; transform Y
			+immediate_a_div_by_n 20
			tya
			clc
			asl
			asl
			asl
			asl
			adc #yoffset
			sta tmp_trans_y

			; transform X
			lda tmp_doorexit
			+immediate_a_mod_n 20
			clc
			asl
			asl
			asl
			asl				; multiply by 16
			rol tmp_trans_xhi
			adc #xoffset
			sta tmp_trans_xlo
			bcc +
				lda #1
				sta tmp_trans_xhi
+
			lda #1
			rts
++
		cmp #CollisionChest
		bne ++
			; TODO: Check if anything is needed here
++
		rts
;-----------------------------------------------------------


;-----------------------------------------------------------
; open_chest
; open the chest indicated by tile position and
; tile index.
;
; parameters:
; (in) x register : screen position (0-239)
; (in) y register : tile index
;
; returns:
; a : result:
;               1 = Chest opened.
;               2 = No chest found at specified position!
;-----------------------------------------------------------
open_chest
		lda screen_id
		eor #01
		sta screen_id
			
		cpy #TileChestClosedLeft
		bne +
			ldy #TileChestOpenLeft
			jsr put_tile
			inx
			iny
			jsr put_tile
			lda #1

			lda screen_id
			eor #01
			sta screen_id

			rts

+		cpy #TileChestClosedRight
		bne +
			ldy #TileChestOpenRight
			jsr put_tile
			dex
			dey
			jsr put_tile
			lda #1

			lda screen_id
			eor #01
			sta screen_id

			rts
		
+		lda #0
		rts
;-----------------------------------------------------------


;-----------------------------------------------------------
; setup - set custom character set and border colors
;
;-----------------------------------------------------------
setup
		; set charset at $4800, screen at $4000
		lda #$02
		sta $d018

		; set multicolor mode
		lda $d016
		ora #$10
		and #$17
		sta $d016

		; set background colors
		lda #0
		sta $d020
		lda #9
		sta $d021
		lda #15
		sta $d022
		lda #11
		sta $d023

		; set map #
		lda #0
		sta MapID

		; set screen offset on map [ x = map ID]
		ldx MapID

		lda MapStartX,x
		sta offx
		lda MapStartHiX,x
		sta offx+1
		lda MapStartY,x
		sta offy

		; set mob source to world
		lda #<world
		sta MobSrc
		lda #>world
		sta MobSrc+1

		; position the sprites
		; -- get sprite coords via world coordinates

		lda StartLocX,x
		+immediate_a_mod_n 20	; Clamp to 0-19 range
		asl			; multiply by 16
		asl
		asl
		asl
		sta xtablelo+player
		lda #0
		adc xtablehi+player
		sta xtablehi+player

		; Add X offset
		lda #xoffset
		adc xtablelo+player
		sta xtablelo+player
		lda #0
		adc xtablehi+player
		sta xtablehi+player
		
		lda StartLocY,x
		+immediate_a_mod_n 12	; Clamp to 0-11 range
		asl			; multiply by 16
		asl
		asl
		asl
		sta ytable+player

		; Add Y offset
		lda #yoffset
		adc ytable+player
		sta ytable+player

		; Set Player state to stopped facing south
		lda #PlayerStopFacingSouth
		sta PlayerAnimState

		; Set Player sprite color (indicates armor or special power)
		lda #PlayerPowerNormal
		sta PlayerPowerState


		; enable multicolor for sprites 4, 5, 6, and 7
		lda #$f0
		sta $d01c

		; set all sprites shared extra colors
		lda #9
		sta $d025
		lda #10
		sta $d026

		; set player contour and fill colors 
		lda #0
		sta color+player
		lda #13
		sta color+player+16

		; set sprite data
		lda #$44
		sta frame+player	; data for player contours
		lda #$40
		sta frame+player+16	; data for player fill colors

		; screen buffer at $4000, backbuffer at $4400
		lda #0
		sta screen_id
		lda #0
		sta scroll_x
		sta scroll_y
		sta scrollstate

		lda #0
		sta CurrentRoomIdx
		sta PlayerBusyTimer
		sta MobsPresent
		sta PlayerPullForceX
		sta PlayerPullForceY
		sta AnimFrame
		sta KeyStopper
		sta PlayerState
		sta StatsUpdated

		lda #1
		sta PlayerWeaponPower

		jsr unpack_next_screen

		lda #0
		sta put_tile_attr
		jsr draw_screen
		jsr swap_screen
		jsr copy_screen
		jsr swap_screen
		jsr draw_stats

		; init music
		lda #0
		jsr $2000
		rts


;-----------------------------------------------------------
; set_music_sprites_irq - set sprites raster interrupt
;
;-----------------------------------------------------------
set_music_sprites_irq
		sei
		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011

		lda #<maininter
		sta $fffe
		lda #>maininter
		sta $ffff

		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.
		;lda $dd0d	; acknowledge pending irqs.

		jsr initsort
		cli

		rts

;-----------------------------------------------------------



;-----------------------------------------------------------
; set_scroll_irq - set scrolling raster interrupt
;
;-----------------------------------------------------------
set_scroll_irq

		sei

		; Do RLE unpacking and drawing of new screen to off screen buffer, then scroll it in.
		; Scroll state jump table
		lda scrollstate
		cmp #state_scroll_left
		bne +
			lda offx+1	; offx is 9-bit (16 bits storage)
			pha
			lda offx
			pha
			sec
			sbc #20
			sta offx
			bcs ++	; if offx < 0, decrease offx+1 too
			dec offx+1
++			jsr unpack_next_screen	; Unpack RLE encoded screen data from offx and offy
			pla
			sta offx
			pla
			sta offx+1

+		cmp #state_scroll_right
		bne +
			lda offx+1
			pha
			lda offx
			pha
			clc
			adc #20
			sta offx
			bcc ++
			inc offx+1
++			jsr unpack_next_screen
			pla
			sta offx
			pla
			sta offx+1

+		cmp #state_scroll_up
		bne +
			lda offy
			pha
			sec
			sbc #12
			sta offy
			jsr unpack_next_screen
			pla
			sta offy

+		cmp #state_scroll_down
		bne +
			lda offy
			pha
			clc
			adc #12
			sta offy
			jsr unpack_next_screen
			pla
			sta offy
+
		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011

		lda #<scrollirq  	;this is how we set up
		sta $fffe  	;the address of our interrupt code
		lda #>scrollirq
		sta $ffff

		lda #$fc  	;trigger raster interrupt at raster line 232
		sta $d012

		jsr clear_status_bar

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		cli		

		rts


;-----------------------------------------------------------
; move_screen_left - scroll screen left by 4 pixels
;
; destroys registers: yes
;-----------------------------------------------------------

move_screen_left

		; increment x scroll
		lda scroll_x
		clc
		adc #4
		sta scroll_x
		pha
		lda scroll_x2
		adc #0
		sta scroll_x2

		pla
		and #7
		ora #$10
		sta $d016
		and #7
	
		; if scroll is 0, 8, 16 etc.. then shift color
		; if scroll is 4, 12, 20 etc.. then shift chars
		beq do_shift_color_right
		cmp #4
		beq do_shift_chars_right
		jmp endshiftright
do_shift_color_right
		jsr swap_screen
		jsr shift_color_right
		jsr color_left

		lda scroll_x
		and #$0f
		bne +
		dec offx	; offset screen position left
		bpl +
		dec offx+1
+
		jmp endshiftright
do_shift_chars_right
		jsr shift_chars_right
		jsr draw_left

endshiftright

		rts


;-----------------------------------------------------------
; move_screen_right - scroll screen right by 4 pixels
;
; destroys registers: yes
;-----------------------------------------------------------

move_screen_right

		; increment x scroll
		lda scroll_x
		sec
		sbc #4
		sta scroll_x
		pha
		lda scroll_x2
		sbc #0
		sta scroll_x2

		pla
		and #7
		ora #$10
		sta $d016
		and #7
	
		; if scroll is 0, 8, 16 etc.. then shift color
		; if scroll is 4, 12, 20 etc.. then shift chars
		cmp #4
		beq do_shift_color_left
		cmp #0
		beq do_shift_chars_left
		jmp endshiftleft
do_shift_color_left
		jsr swap_screen
		jsr shift_color_left
		jsr color_right

		lda scroll_x
		and #$0f
		cmp #4
		bne +
		inc offx	; offset screen position right
		bne +
		inc offx+1
+
		jmp endshiftleft
do_shift_chars_left
		jsr shift_chars_left
		jsr draw_right

endshiftleft

		rts


;-----------------------------------------------------------
; move_screen_up - scroll screen up by 4 pixels
;
; destroys registers: yes
;-----------------------------------------------------------

move_screen_up

		; increment y scroll
		lda scroll_y
		clc
		adc #4
		sta scroll_y

		and #7
		ora #$18
		sta $d011
		and #7
	
		; if scroll is 0, 8, 12, 16 etc.. then shift color else shift chars
		beq do_shift_down_color
		cmp #$04
		beq do_shift_chars_down
		jmp endshiftdown
do_shift_down_color
		jsr swap_screen
		jsr shift_color_down
		jsr color_top

		lda scroll_y
		and #$0f
		cmp #0
		bne +
		dec offy	; offset screen position downwards
+
		jmp endshiftdown
do_shift_chars_down
		jsr shift_chars_down
		jsr draw_top

endshiftdown

		rts

;-----------------------------------------------------------
; move_screen_down - scroll screen down by 4 pixels
;
; destroys registers: yes
;-----------------------------------------------------------

move_screen_down

		; decrement y scroll
		lda scroll_y
		sec
		sbc #4
		sta scroll_y

		and #7
		ora #$18
		sta $d011
		and #7
		cmp #4
	
		; if scroll is 4, 12, 20 etc.. then shift color
		; if scroll is 0, 8, 16 etc.. then shift chars
		beq do_shift_up_color
		cmp #0
		beq do_shift_chars_up
		jmp endshiftup
do_shift_up_color
		jsr swap_screen
		jsr shift_color_up
		jsr color_bottom

		lda scroll_y
		and #$0f
		cmp #4
		bne +
		inc offy	; offset screen position upwards
+
		jmp endshiftup
do_shift_chars_up
		jsr shift_chars_up
		jsr draw_bottom
endshiftup

		rts

;-----------------------------------------------------------
; put_tile - draw a tile from the tile set
;
; (in) x register : screen position (0-239)
; (in) y register : tile index
; destroys registers: none
;-----------------------------------------------------------
put_tile
		pha
		txa
		pha
		tya
		pha

		; find the backbuffer, then draw to it, 
		lda screen_id
		beq tile_to_back
; tile_to_front
		lda tilepos_hi_a,x
		jmp end_tile
tile_to_back
		lda tilepos_hi_b,x
end_tile

		; begin storing pointer to first row of tile data in tmp_addr
		sta tmp_addr+1

		; finish storing pointer to first row of tile data in tmp_addr
		lda tilepos_lo,x
		sta tmp_addr

		; push the screen position onto stack used to get the indirect address
		txa
		pha

		; Prepare tile index
		tya
		asl
		asl	; multiply by 4
		tax

		ldy #0
		lda tiledata,x
		sta (tmp_addr),y
		iny
		lda tiledata+1,x
		sta (tmp_addr),y
		ldy #40
		lda tiledata+2,x
		sta (tmp_addr),y
		iny
		lda tiledata+3,x
		sta (tmp_addr),y

		; Save the tile index for now
		stx tmp2

		; Pop out the screen position again
		pla
		tax

		; Get high byte for tile color data and store in tmp_addr
		lda put_tile_attr
		bne +
			lda colormem_hi,x
			jmp ++
+
			lda colormem_hi,x	; => $d8 + $1e = $f6 ($f600) color buffer
			clc
			adc #$1e
++
		sta tmp_addr+1

		; get low byte for first row of color data and store in tmp_addr
		lda tilepos_lo,x
		sta tmp_addr

		; Recover the tile index
		ldx tmp2

		ldy #0
		lda colordata,x
		sta (tmp_addr),y
		iny
		lda colordata+1,x
		sta (tmp_addr),y
		ldy #40
		lda colordata+2,x
		sta (tmp_addr),y
		iny
		lda colordata+3,x
		sta (tmp_addr),y

		pla
		tay
		pla
		tax
		pla
		rts
put_tile_attr
		!byte $00	; if > 0 then draw color to a buffer

;-----------------------------------------------------------
; draw_left - draws the left of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------
draw_left
		ldx #0 ; initialize the row counter
		ldy offx ; read the column counter
		dey	; these three lines below equals: x = (x-1) % 20
		tya
		+immediate_a_mod_n 20

-		; while (x < 12)

			tay ; keep column counter in y
			pha ; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			txa
			pha ; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			tax	; keep 20y in x
			tya
			clc
			adc tmp	; screenpos = 20y + (x-1) % 20
			tay	; transfer final offset to y again

			; get the tile index from map (for drawing)
			; Find the tile at the final offset
			lda tilebuffer,y	; fetch tile here
			asl
			asl ; multiply by 4
			pha ; <<< TILE IDX

			; find the backbuffer, then draw to it, 
			lda screen_id
			beq + 
			; if backbuffer is a
				lda tilepos_hi_a,x
				jmp ++

+			; else backbuffer is b
				lda tilepos_hi_b,x

++			; endif

			; begin storing pointer to first row of tile data in tmp_addr
			sta tmp_addr2+1

			; finish storing pointer to first row of tile data in tmp_addr
			lda tilepos_lo,x
			sta tmp_addr2

			; -------------------------------
			; Tile y positions 0-11
			; -------------------------------

			; pop tile index and store in x
			pla ; >>> TILE IDX
			tax

			; autodetect which part of tile to draw
			lda scroll_x
			and #$08
			beq +
			; if left part of tile

				; draw left part of tile only
				ldy #0
				lda tiledata,x
				sta (tmp_addr2),y
				ldy #40
				lda tiledata+2,x
				sta (tmp_addr2),y

				jmp ++

+			; else right part of tile

				; draw right part of tile only
				ldy #0
				lda tiledata+1,x
				sta (tmp_addr2),y
				ldy #40
				lda tiledata+3,x
				sta (tmp_addr2),y

++			; endif

			pla ; get the row counter
			tax ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER

			inx
			cpx #12 ; check row counter
			beq +
			jmp -

		; end while

+		rts

;-----------------------------------------------------------
; color_left - colors the left of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------
color_left

		ldx #0 ; initialize the row counter
		ldy offx ; initialize the column counter
		dey	; these three lines below equals: col = (col-1) % 20
		tya
		+immediate_a_mod_n 20

-		; while (x < 12)

			tay ; keep column counter in y
			pha ; <<< COLUMN COUNTER 

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			txa
			pha ; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			tax	; keep 20y in x
			tya
			clc
			adc tmp	; screenpos = 20y + x
			tay	; transfer final offset to y again, but we still have column count on stack

			; get the tile index from map (for drawing)
			; Find the tile at the final offset
			lda tilebuffer,y
			asl
			asl ; multiply by 4, every 4th address is a new tile
			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda colormem_hi,x
			sta tmp_addr2+1

			; get low byte for first row of color data and store in tmp_addr
			lda tilepos_lo,x
			sta tmp_addr2

			; -------------------------------
			; Tile y positions 0-11
			; -------------------------------

			; pop tile index and store in x
			pla ; >>> TILE IDX
			tax

			; autodetect which part of tile to draw
			lda scroll_x
			and #$08
			bne +
			; if left side of tile

				; color left part of tile only
				ldy #0
				lda colordata,x
				sta (tmp_addr2),y
				ldy #40
				lda colordata+2,x
				sta (tmp_addr2),y

				jmp ++
+			; else right side of tile

				; color right part of tile only
				ldy #0
				lda colordata+1,x
				sta (tmp_addr2),y
				ldy #40
				lda colordata+3,x
				sta (tmp_addr2),y
++			; endif

			pla ; get the row counter
			tax ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER

			inx
			cpx #12 ; check column counter
			beq +
		jmp -

		; end while

+		rts



;-----------------------------------------------------------
; draw_right - draws the right of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------
draw_right
		; Find the y offset
		ldx #0 ; initialize the row counter
		ldy offx
		;dey	; these three lines below equals: x = (x+1) % 20
		tya
		+immediate_a_mod_n 20

-		; while (x < 12)

			tay ; keep column counter in y
			pha ; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			txa
			pha ; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			tax	; keep 20y+19 in x
			tya
			clc
			adc tmp	; screenpos = 20y + (x+1) % 20
			tay	; transfer final offset to y again, but we still have column count on stack

			; get the tile index from map (for drawing)
			; Find the tile at the final offset
			lda tilebuffer,y	; fetch tile here
			asl
			asl ; multiply by 4
			pha ; <<< TILE IDX

			; find the backbuffer, then draw to it, 
			lda screen_id
			beq +
			; if backbuffer a
				lda tilepos_hi_a,x	; backbuffer a
				jmp ++

+			; else backbuffer b
				lda tilepos_hi_b,x	; backbuffer b

++			; endif

			; begin storing pointer to first row of tile data in tmp_addr
			sta tmp_addr2+1

			; finish storing pointer to first row of tile data in tmp_addr
			lda tilepos_lo,x
			sta tmp_addr2

			; -------------------------------
			; Tile y positions 0-11
			; -------------------------------

			; pop tile index and store in x
			pla ; >>> TILE IDX
			tax

			; autodetect which part of tile to draw
			lda scroll_x
			and #$08
			bne +
			; if left side of tile

				; draw left part of tile only
				ldy #39
				lda tiledata,x
				sta (tmp_addr2),y
				ldy #79
				lda tiledata+2,x
				sta (tmp_addr2),y
				jmp ++

+			; else right side of tile
				; draw right part of tile only
				ldy #39
				lda tiledata+1,x
				sta (tmp_addr2),y
				ldy #79
				lda tiledata+3,x
				sta (tmp_addr2),y
++			; endif

			pla ; get the row counter
			tax ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER

			inx
			cpx #12 ; check row counter
			beq +
			jmp -

		; end while

+		rts

;-----------------------------------------------------------
; color_right - colors the right of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------

color_right

		; Find the y offset
		ldx #0 ; initialize the row counter
		ldy offx ; intialize the column counter
		;dey	; these three lines below equals: x = (x+1) % 20
		tya
		+immediate_a_mod_n 20

-		; while (x < 12)

			tay ; keep column counter in y
			pha	; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			txa
			pha	; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			tax	; keep 20y in x
			tya
			clc
			adc tmp	; screenpos = 20y + (x+1) % 20
			tay	; transfer final offset to y again, but we still have column count on stack

			; get the tile index from map (for drawing)
			; Find the tile at the final offset
			lda tilebuffer,y
			asl
			asl ; multiply by 4
			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda colormem_hi,x
			sta tmp_addr2+1

			; get low byte for first row of color data and store in tmp_addr
			lda tilepos_lo,x
			sta tmp_addr2

			pla ; >>> TILE IDX
			tax

			; -------------------------------
			; Tile y positions 0-11
			; -------------------------------

			; autodetect which part of tile to draw
			lda scroll_x
			and #$08
			beq +
			; if left part of tile

				; color left part of tile only
				ldy #39
				lda colordata,x
				sta (tmp_addr2),y
				ldy #79
				lda colordata+2,x
				sta (tmp_addr2),y
				jmp ++
+			; else right part of tile

				; color right part of tile only
				ldy #39
				lda colordata+1,x
				sta (tmp_addr2),y
				ldy #79
				lda colordata+3,x
				sta (tmp_addr2),y

++			; endif

			pla ; get the row counter
			tax ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER

			inx
			cpx #12 ; check column counter
			beq +
			jmp -

		; end while

+		rts

;-----------------------------------------------------------
; draw_top - draws the top of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------

draw_top
		ldx #0 ; initialize the column counter
		ldy offy ; read the row counter
		dey
		tya
		+immediate_a_mod_n 12
		tay
-		; while (x < 20)	; iterate each column

			txa
			pha	; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			tya
			pha	; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			txa
			clc
			adc tmp	; screenpos = ((y-1) % 20)*20 + x
			tay	; transfer final offset to y again

			; get the tile index from map (for drawing)
			lda tilebuffer,y
			asl
			asl ; multiply by 4
			pha	; <<< TILE IDX

			; find the backbuffer, then draw to it, 
			lda screen_id
			beq +
			; if backbuffer is a

				lda tilepos_hi_a,x
				jmp ++

+			; else backbuffer is b
				lda tilepos_hi_b,x
++			; endif

			; begin storing pointer to first row of tile data in tmp_addr
			sta tmp_addr2+1

			; finish storing pointer to first row of tile data in tmp_addr
			lda tilepos_lo,x
			sta tmp_addr2

			; -------------------------------
			; Tile x positions 0-19
			; -------------------------------

			; pop tile index and store in x
			pla ; >>> TILE IDX
			tax

			; autodetect which part of tile to draw
			lda scroll_y
			and #$08
			beq +
			; if top part of tile

				; draw top part of tile only
				ldy #0
				lda tiledata,x
				sta (tmp_addr2),y
				iny
				lda tiledata+1,x
				sta (tmp_addr2),y
				jmp ++

+			; else bottom part of tile

				; draw bottom part of tile only
				ldy #0
				lda tiledata+2,x
				sta (tmp_addr2),y
				iny
				lda tiledata+3,x
				sta (tmp_addr2),y

++			; endif

			pla ; get the row counter
			tay ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER
			tax

			inx
			cpx #20 ; check column counter
			beq +
			jmp -
+		rts

;-----------------------------------------------------------
; color_top - colors the top of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------

color_top
		; Find the y offset
		ldx #0
		ldy offy
		dey
		tya
		+immediate_a_mod_n 12
		tay

-		; while (x < 20)	; iterate each column

			txa
			pha	; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			tya
			pha	; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			txa
			clc
			adc tmp	; screenpos = ((y-1) % 20)*20 + x
			tay	; transfer final offset to y again

			; get the tile index from map (for drawing)
			lda tilebuffer,y
			asl
			asl ; multiply by 4
			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda colormem_hi,x
			sta tmp_addr2+1

			; get low byte for first row of color data and store in tmp_addr
			lda tilepos_lo,x
			sta tmp_addr2

			pla ; >>> TILE IDX
			tax

			; -------------------------------
			; Tile y positions 0-11
			; -------------------------------

			; detect which part of tile to draw
			lda scroll_y
			and #$08
			bne +
			; if top part of tile

				; color top part of tile only
				ldy #0
				lda colordata,x
				sta (tmp_addr2),y
				iny
				lda colordata+1,x
				sta (tmp_addr2),y
				jmp ++

+			; else bottom part of tile

				; color bottom part of tile only
				ldy #0
				lda colordata+2,x
				sta (tmp_addr2),y
				iny
				lda colordata+3,x
				sta (tmp_addr2),y
++			; endif

			pla ; get the row counter
			tay ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER
			tax

			inx
			cpx #20 ; check column counter
			beq +
			jmp -

		; end while

+		rts


;-----------------------------------------------------------
; draw_bottom - draws the bottom of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------

draw_bottom
		ldx #0 ; initialize the column counter
		ldy offy ; read the row counter
		tya
		+immediate_a_mod_n 12	; this should always land offy at 11 on first call
		tay

-		; while (x < 20)	; iterate each column

			txa
			pha	; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			tya
			pha	; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			txa
			clc
			adc tmp	; screenpos = ((y-1) % 20)*20 + x
			tay	; transfer final offset to y again

			; get the tile index from map (for drawing)
			lda tilebuffer,y
			asl
			asl ; multiply by 4
			pha	; <<< TILE IDX
		
			; find the backbuffer, then draw to it, 
			lda screen_id
			beq +
			; if backbuffer a
				lda tilepos_hi_a+220,x
				jmp ++

+			; else backbuffer b
				lda tilepos_hi_b+220,x

++			; endif

			; begin storing pointer to first row of tile data in tmp_addr
			sta tmp_addr2+1

			; finish storing pointer to first row of tile data in tmp_addr
			lda tilepos_lo+220,x
			sta tmp_addr2

			; -------------------------------
			; Tile x positions 0-19
			; -------------------------------

			; pop tile index and store in x
			pla ; >>> TILE IDX
			tax

			; autodetect which part of tile to draw
			lda scroll_y
			and #$08
			bne +
			; if top part of tile
				; draw top part of tile only
				ldy #40
				lda tiledata,x
				sta (tmp_addr2),y
				iny
				lda tiledata+1,x
				sta (tmp_addr2),y
				jmp ++

+			; else bottom part of tile
				; draw bottom part of tile only
				ldy #40
				lda tiledata+2,x
				sta (tmp_addr2),y
				iny
				lda tiledata+3,x
				sta (tmp_addr2),y

++			; endif

			pla ; get the row counter
			tay ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER
			tax

			inx
			cpx #20 ; check column counter
			beq +
			jmp -
+		rts

;-----------------------------------------------------------
; color_bottom - colors the bottom of the screen once
;
; destroys registers: yes!
;-----------------------------------------------------------

color_bottom
		; Find the y offset
		ldx #0
		ldy offy
		tya
		+immediate_a_mod_n 12
		tay

-		; while (x < 20)	; iterate each column

			txa
			pha	; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			tya
			pha	; <<< ROW COUNTER
			sta tmp ; keep 1y
			asl	; 2y
			asl	; 4y
			clc
			adc tmp	; 5y
			asl	; 10y
			asl	; 20y
			sta tmp
			txa
			clc
			adc tmp	; screenpos = ((y-1) % 20)*20 + x
			tay	; transfer final offset to y again

			; get the tile index from map (for drawing)
			lda tilebuffer,y
			asl
			asl ; multiply by 4
			pha ; <<< TILE IDX
		
			; Get high byte for tile color data and store in tmp_addr
			lda colormem_hi+220,x
			sta tmp_addr2+1

			; get low byte for first row of color data and store in tmp_addr
			lda tilepos_lo+220,x
			sta tmp_addr2

			pla ; >>> TILE IDX
			tax

			; detect which part of tile to draw
			lda scroll_y
			and #$08
			beq +
			; if top part of tile
				; color top part of tile only
				ldy #40
				lda colordata,x
				sta (tmp_addr2),y
				iny
				lda colordata+1,x
				sta (tmp_addr2),y
				jmp ++

+			; else bottom part of tile
				; color bottom part of tile only
				ldy #40
				lda colordata+2,x
				sta (tmp_addr2),y
				iny
				lda colordata+3,x
				sta (tmp_addr2),y
++			; endif

			pla ; get the row counter
			tay ; >>> ROW COUNTER

			pla ; >>> COLUMN COUNTER
			tax

			inx
			cpx #20 ; check column counter
			beq +
			jmp -

		; end while

+		rts

;-----------------------------------------------------------
; unpack_next_screen - reads next screen data
;
; destroys registers: yes!
;-----------------------------------------------------------

unpack_next_screen
		; find room data via dictionary, fetch 16-bit dictionary entry by offx and offy
		; first divide offx and offy by 20

		lda #0
		sta tmp_addr
		sta tmp_addr+1

		lda offx+1
		sta tmp
		lda offx

		; divide offx by 20 to get screen x
		ldx #0
		sec
-		inx
		sbc #20
		bcs -
		dec tmp	; decrease high byte of offx whenever we cross the boundary of 0
		bpl -
		dex
		txa
		sta tmp

		lda offy

		; divide offy by 12 to get screen y
		ldx #0
		sec
-		inx
		sbc #12
		bcs -
		dex	; x = screen y
		stx tmp_addr

		; calculate now 16*y+x in tmp_addr
		asl tmp_addr
		rol tmp_addr+1
		asl tmp_addr
		rol tmp_addr+1
		asl tmp_addr
		rol tmp_addr+1
		asl tmp_addr
		rol tmp_addr+1
		lda tmp ; x
		clc
		adc tmp_addr
		bcc +
			inc tmp_addr+1
			clc
+
		; multiply by 2 to get 16 bit offset
		sta tmp_addr
		asl tmp_addr
		rol tmp_addr+1

		; add 16-bit map data address
		clc
		lda #<mapdata
		adc tmp_addr
		sta tmp_addr
		lda #>mapdata
		adc tmp_addr+1
		sta tmp_addr+1
		
		; got the 16-bit dictionary entry now in tmp_addr, 
		; use it to load the compressed data start address
		clc
		ldy #0
		lda (tmp_addr),y
		adc #<mapdata
		sta tmp_addr2
		iny
		lda (tmp_addr),y
		adc #>mapdata
		sta tmp_addr2+1

		; uncompress data at tmp_addr2
		ldy #0
		lda (tmp_addr2),y	; total data length
		cmp #240
		beq ++
		sta tmp
		; if length != 0 then {
-			iny
				lda (tmp_addr2),y	; fetch num_tiles
				tax
				iny
					lda (tmp_addr2),y
buffer					sta tilebuffer
					inc buffer+1
					bne +
						inc buffer+2
+					dex
					bne buffer
				dec tmp
				dec tmp
			bne -

			; reset pointer
			lda #$1f
			sta buffer+2
			lda #$00
			sta buffer+1

			; uncompressed data now at tilebuffer
			rts

++		; } else {
			; data already uncompressed, copy directly to tilebuffer
			tax
-				iny
				lda (tmp_addr2),y
				sta tilebuffer-1,y
				dex
			bne -

			; uncompressed data now at tilebuffer
			rts
		; }


;-----------------------------------------------------------
; draw_screen - draws the complete screen once
;
; destroys registers: yes!
;-----------------------------------------------------------

draw_screen

		ldx #0
-			lda tilebuffer,x
			tay
			jsr put_tile
			inx
			cpx #240
			bne -

		rts

;-----------------------------------------------------------
; shift_chars_down - pans screen upwards by 8 pixels
;                  (double buffered)
;
; destroys registers: x, a
;-----------------------------------------------------------
shift_chars_down
		ldx #$00
		lda screen_id
		bne shift_loop0_0_1

shift_loop0_0_0 ; screen_id = 0 (always draw to back buffer, here screen 1)
		lda $4000,x
		sta $4428,x
		lda $4100,x
		sta $4528,x
		lda $4200,x
		sta $4628,x
		lda $4298,x
		sta $46c0,x
		inx
		bne shift_loop0_0_0
		rts

shift_loop0_0_1	; screen_id = 1 (always draw to back buffer, here screen 0)
		lda $4400,x
		sta $4028,x
		lda $4500,x
		sta $4128,x
		lda $4600,x
		sta $4228,x
		lda $4698,x
		sta $42c0,x
		inx
		bne shift_loop0_0_1
		rts

;-----------------------------------------------------------
; shift_chars_up - pans screen downwards by 8 pixels
;                    (double buffered)
;
; destroys registers: x, a
;-----------------------------------------------------------
shift_chars_up
		ldx #$00
		lda screen_id
		bne shift_loop1_0_1

shift_loop1_0_0 ; screen_id = 0 (always draw to back buffer, here screen 1)
		lda $4028,x
		sta $4400,x
		lda $4128,x
		sta $4500,x
		lda $4228,x
		sta $4600,x
		lda $42c0,x
		sta $4698,x
		inx
		bne shift_loop1_0_0
		rts

shift_loop1_0_1	; screen_id = 1 (always draw to back buffer, here screen 0)
		lda $4428,x
		sta $4000,x
		lda $4528,x
		sta $4100,x
		lda $4628,x
		sta $4200,x
		lda $46c0,x
		sta $4298,x
		inx
		bne shift_loop1_0_1
		rts

;-----------------------------------------------------------
; shift_chars_right - pan screen left by 8 pixels
;                    (double buffered)
;
; destroys registers: x, a
;-----------------------------------------------------------
shift_chars_right
		ldx #$00
		lda screen_id
		bne shift_loop2_0_1

shift_loop2_0_0 ; screen_id = 0 (always draw to back buffer, here screen 1)
		lda $4000,x
		sta $4401,x
		lda $4100,x
		sta $4501,x
		lda $4200,x
		sta $4601,x
		lda $42bf,x
		sta $46c0,x
		inx
		bne shift_loop2_0_0
		rts

shift_loop2_0_1	; screen_id = 1 (always draw to back buffer, here screen 0)
		lda $4400,x
		sta $4001,x
		lda $4500,x
		sta $4101,x
		lda $4600,x
		sta $4201,x
		lda $46bf,x
		sta $42c0,x
		inx
		bne shift_loop2_0_1
		rts

;-----------------------------------------------------------
; shift_chars_left - pan screen right by 8 pixels
;                     (double buffered)
;
; destroys registers: x, a
;-----------------------------------------------------------
shift_chars_left
		ldx #$00
		lda screen_id
		bne shift_loop3_0_1

shift_loop3_0_0 ; screen_id = 0 (always draw to back buffer, here screen 1)
		lda $4001,x
		sta $4400,x
		lda $4101,x
		sta $4500,x
		lda $4201,x
		sta $4600,x
		lda $42c0,x
		sta $46bf,x
		inx
		bne shift_loop3_0_0
		rts

shift_loop3_0_1	; screen_id = 1 (always draw to back buffer, here screen 0)
		lda $4401,x
		sta $4000,x
		lda $4501,x
		sta $4100,x
		lda $4601,x
		sta $4200,x
		lda $46c0,x
		sta $42bf,x
		inx
		bne shift_loop3_0_1
		rts

;-----------------------------------------------------------
; shift_color_down - shifts color down by 8 pixels
;                  (almost unbuffered ;)
; destroys registers: x, a
;-----------------------------------------------------------
shift_color_down
		ldx #$28
-		dex
		lda $d9e0,x
		sta linebuffer,x
		cpx #0
		bne -

		ldx #$28
-		dex
		lda $d9b8,x
		sta $d9e0,x
		lda $d990,x
		sta $d9b8,x
		lda $d968,x
		sta $d990,x
		lda $d940,x
		sta $d968,x
		lda $d918,x
		sta $d940,x
		lda $d8f0,x
		sta $d918,x
		lda $d8c8,x
		sta $d8f0,x
		lda $d8a0,x
		sta $d8c8,x
		lda $d878,x
		sta $d8a0,x
		lda $d850,x
		sta $d878,x
		lda $d828,x
		sta $d850,x
		lda $d800,x
		sta $d828,x
		cpx #0
		bne -

		ldx #$28
-		dex
		;lda $db98,x
		;sta $dbc0,x
		lda $db70,x
		sta $db98,x
		lda $db48,x
		sta $db70,x
		lda $db20,x
		sta $db48,x
		lda $daf8,x
		sta $db20,x
		lda $dad0,x
		sta $daf8,x
		lda $daa8,x
		sta $dad0,x
		lda $da80,x
		sta $daa8,x
		lda $da58,x
		sta $da80,x
		lda $da30,x
		sta $da58,x
		lda $da08,x
		sta $da30,x
		lda $d9e0,x
		sta $da08,x
		cpx #0
		bne -

		ldx #$28
-		dex
		lda linebuffer,x
		sta $da08,x
		cpx #0
		bne -

		rts

;-----------------------------------------------------------
; shift_color_up - shifts color up by 8 pixels
;                    (unbuffered)
; destroys registers: x, a
;-----------------------------------------------------------
shift_color_up
		ldx #$28
-		dex
		lda $da08,x
		sta linebuffer,x
		cpx #0
		bne -

		ldx #$28
-		dex
		lda $d828,x	; from char# 79 to 40
		sta $d800,x	; from char 39 to 0
		lda $d850,x
		sta $d828,x
		lda $d878,x
		sta $d850,x
		lda $d8a0,x
		sta $d878,x
		lda $d8c8,x
		sta $d8a0,x
		lda $d8f0,x
		sta $d8c8,x
		lda $d918,x
		sta $d8f0,x
		lda $d940,x
		sta $d918,x
		lda $d968,x
		sta $d940,x
		lda $d990,x
		sta $d968,x
		lda $d9b8,x
		sta $d990,x
		lda $d9e0,x
		sta $d9b8,x
		cpx #0
		bne -

		ldx #$28
-		dex
		lda $da08,x
		sta $d9e0,x
		lda $da30,x
		sta $da08,x
		lda $da58,x
		sta $da30,x
		lda $da80,x
		sta $da58,x
		lda $daa8,x
		sta $da80,x
		lda $dad0,x
		sta $daa8,x
		lda $daf8,x
		sta $dad0,x
		lda $db20,x
		sta $daf8,x
		lda $db48,x
		sta $db20,x
		lda $db70,x
		sta $db48,x
		lda $db98,x
		sta $db70,x
		lda $dbc0,x
		sta $db98,x
		cpx #0
		bne -

		ldx #$28
-		dex
		lda linebuffer,x
		sta $d9e0,x
		cpx #0
		bne -

		rts


;-----------------------------------------------------------
; shift_color_right - shifts color left by 8 pixels
;                    (unbuffered)
; destroys registers: x, y, a
;-----------------------------------------------------------
shift_color_right

		ldy $d900
		ldx #$ff
-
		lda $d800,x
		sta $d801,x
		dex
		bne -
		lda $d800
		sta $d801

		lda $da00
		pha
		ldx #$ff
-
		lda $d900,x
		sta $d901,x
		dex
		bne -
		sty $d901

		ldy $db00
		ldx #$ff
-
		lda $da00,x
		sta $da01,x
		dex
		bne -
		pla
		sta $da01

		ldx #$be
-
		lda $db00,x
		sta $db01,x
		dex
		bne -
		sty $db01

		rts

;-----------------------------------------------------------
; shift_color_left - shifts color right by 8 pixels
;                     (unbuffered)
; destroys registers: x, a
;-----------------------------------------------------------
shift_color_left
		ldx #0
-
		lda $d801,x
		sta $d800,x
		inx
		bne -
		ldx #0
-
		lda $d901,x
		sta $d900,x
		inx
		bne -
		ldx #0
-
		lda $da01,x
		sta $da00,x
		inx
		bne -
		ldx #$40
-
		lda $dac0,x
		sta $dabf,x
		inx
		bne -
		lda $dbc0
		sta $dbbf

		rts

;-----------------------------------------------------------
; read_keyboard
; parameters: x - column, y - row
; return value; sets zero flag
; destroys: a, x, y, C, Z, N, $dc00, $dc01, $50-$5f
;-----------------------------------------------------------
read_keyboard
		lda #0
		sta ScanResult

		lda #%11111111  ; CIA#1 Port A set to output 
		sta $dc02             
		lda #%00000000  ; CIA#1 Port B set to input
		sta $dc03             
    
check_space
		lda #%01111111  ; select row 8
		sta $dc00 
		lda $dc01       ; load column information
		and #%00010000  ; test 'space' key to exit 
		bne check_a
		lda #1
		ora ScanResult
		sta ScanResult
check_a
		lda #%11111101  ; select row 2
		sta $dc00 
		lda $dc01       ; load column information
		and #%00000100  ; test 'a' key  
		bne check_d
		lda #2
		ora ScanResult
		sta ScanResult
check_d
		lda #%11111011  ; select row 3
		sta $dc00 
		lda $dc01       ; load column information
		and #%00000100  ; test 'd' key  
		bne check_w
		lda #4
		ora ScanResult
		sta ScanResult
check_w
		lda #%11111101  ; select row 2
		sta $dc00 
		lda $dc01       ; load column information
		and #%00000010  ; test 'w' key 
		bne check_s
		lda #8
		ora ScanResult
		sta ScanResult
check_s
		lda #%11111101  ; select row 2
		sta $dc00 
		lda $dc01       ; load column information
		and #%00100000  ; test 's' key 
		bne check_return
		lda #16
		ora ScanResult
		sta ScanResult
check_return
		lda #%11111110	; select row 1
		sta $dc00	; load column information
		lda $dc01	; test 'return' key
		and #%00000010
		bne skip
		lda #32
		ora ScanResult
		sta ScanResult
skip
		rts


;-----------------------------------------------------------
; draw_stats - show a stats bar on the top - use chars
; parameters: -
; return value: -
; destroys: a, x, y, C, Z, N
;-----------------------------------------------------------
draw_stats
		lda #1
		ldx #39	; set status text to white color
-		sta $dbc0,x
		dex
		bne -
		sta $dbc0

		lda #$c0	; set whitespace (clear) status bar
		ldx #39
-		sta $43c0,x
		dex
		bne -
		sta $43c0

		lda #$ee	; Heart symbol here
		sta $43c2
		lda #2
		sta $dbc2

		ldx #0
		clc
		lda player_hp
		beq +
			adc #$dc
			sta $43c4,x
			inx
+
		lda player_hp+1
		clc
		adc #$dc
		sta $43c4,x
		inx

		lda #$f1	; /
		sta $43c4,x
		inx

		lda player_max_hp
		beq +
			clc
			adc #$dc
			sta $43c4,x
			inx
+
		lda player_max_hp+1
		clc
		adc #$dc
		sta $43c4,x

		lda #$ef	; Key symbol here
		sta $43ca
		lda #7
		sta $dbca

		lda #$dc
		sta $43cc

		lda #15
		sta $dbd0
		lda #$f0	; Coin symbol here
		sta $43d0

		ldx #0
		lda player_gold
		beq +
			clc
			adc #$dc
			sta $43d2,x
			inx
+		lda player_gold+1
		bne ++
		cpx #0
		beq +
++			clc
			adc #$dc
			sta $43d2,x
			inx
+		lda player_gold+2
		bne ++
		cpx #0
		beq +
++			clc
			adc #$dc
			sta $43d2,x
			inx
+		lda player_gold+3
		bne ++
		cpx #0
		beq +
++			clc
			adc #$dc
			sta $43d2,x
			inx
+		lda player_gold+4
		clc
		adc #$dc
		sta $43d2,x

		rts
;-----------------------------------------------------------

end_code_3k

; ***** FREE SPACE: 346 bytes




;-----------------------------------------------------------
; graphix data for tiles, sprites and the map
;
;-----------------------------------------------------------

		; Color buffer		@ $0400 - $07e7
		; Tables and routines	@ $0810 - $1eff
		; Screen unpack buffer	@ $1f00 - $1fef
		; Music			@ $2000 - $2fff
		; Initial game code	@ $3000 - $3fff
		; Primary screen data 	@ $4000 - $43ff
		; Secondary screen data	@ $4400 - $47ff
		; Character data 	@ $4800 - $4fff
		; Sprite data		@ $5000 - $6fff
		; Game tile map		@ $7000 - $95e3
		; Tile color table	@ $95e4 - $96e3
		; Tile data		@ $96e4 - $97e3
		; More game code	@ $c000 - $cfff
		; Sprite data		@ $e000 - $efff
		; Game data		@ $f000 - $f5ff

		; Map data, 20480 bytes (if needed)
		*=$7000
mapdata
		!binary "aad_map_big.rle"

		; Map color data 256 bytes
colordata
		!binary "aad_charset_attrs_big.bin"

		; Map tile data 256 bytes
tiledata
		!binary "aad_tiles_big.bin"

		; Primary screen
		*=$4000
screen_1

		; Secondary screen
		*=$4400
screen_2

		; Character data $4800-$4fff ; 256*8 bytes
		*=$4800
chardata
		!binary "aad_charset_big.bin"

		; Sprites from $5000-$6fff ; 128*64 bytes sprites
		*=$5000
spritedata
		!binary "sprites.bin"	; 128 unpacked sprite entries, will add up to 128 packed sprite entries (32 bytes * 128 = 4096 = 4k) at $e000-$efff

		; Ends at $6fff

		*=$c000
begin_code_c000
;-----------------------------------------------------------
; Music player interrupt
;
;-----------------------------------------------------------
music_sprites_interrupt
		sta areg
		stx xreg
		sty yreg

		sei

		jsr $2003

		lda #$1b	; Default settings, normal text mode, set raster high bit to 0

		sta $d011
		lda #<maininter	; so, set raster interrupt at next sprite 0 y coordinate.
		sta $fffe
		lda #>maininter
		sta $ffff

		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		lda areg
		ldx xreg
		ldy yreg

		cli

		rti

;-----------------------------------------------------------
; Sprite multiplexer interrupt
;
;-----------------------------------------------------------
maininter

		sta areg	; save registers to zero page
		stx xreg
		sty yreg

		;inc $d020
		jsr $2003
		;dec $d020	; set cycle measuring indicator color in the border

		lda #$00	; initialize no double height, sprite over chars priority,
		sta $d017	; no double width (make table for this and double height?)
		sta $d01b
		sta $d01d
		lda #$f0	; multicolor for sprites 4,5,6,7
		sta $d01c

		ldx maxspr	; read how many sprites are currently enabled, if more than 4, then multiplex!
		cpx #$05
		bcs morethan4

		; Less or equal to 4 two-layer sprites
		; sprites
		; ------------- 

		lda #$4c	;jmp $0000	; self-modifying code, sets the jmp opcode at "switch label"
		sta switch

		lda activatetab,x	; enable the sprites we want to use, only using max 8
		sta $d015

		lda t_jumplo,x		; get jump table low byte word value -> sort x # of sprites.
		sta jumplo
		lda t_jumphi,x		; get jump table high byte word value -> sort x # of sprites.
		sta jumphi
		lda #$00
		sta $d010		; init y high bit for all sprites to 0
		jmp (jumplo)		; ---> Jump to the sprite sorter routine. 

		; More than 4 two-layer sprites
		; sprites
		; -------------

morethan4	lda #$ff		; just enable all sprites directly, we use all in multiplexing
		sta $d015
		lda #$04		; store 4 in counter => vsprites 0-3 are already allocated to sprites 0-3,
		sta vspr_counter	; multiplexing is done for sprites 4-16

		lda #$2c		;bit $0000 ; self-modifying code, sets the bit opcode at "switch label", kind of a nop
		sta switch
		lda #$00

		; get the next postitions of the virtual sprites to distribute over the sprites 0-7; 
		; the positions need to be known before we start sorting them in the next frame.

; 4 two-layer sprites:
;--------------------------------------
dospr3_7	ldy indextable+3	; Get the next virtual sprite index from sorted list.
		ldx ytable,y		; Get current y coordinate of virtual sprite y and
		stx $d007		; store it in the sprite 3 and 7 y coordinate.
		stx $d00f		;
		ldx xtablelo,y		; Do the same for sprite 3 and 7 x coordinate.
		stx $d006		;
		stx $d00e
		ldx frame,y		; Load the virtual sprite y current top layer frame into sprite 3
		stx spritepointer+3
		ldx frame+16,y		; Load the virtual sprite y current bottom layer frame into sprite 7
		stx spritepointer+7
		ldx color,y		; Load the virtual sprite y current top layer color into sprite 7
		stx $d02a
		ldx color+16,y		; Load the virtual sprite y current bottom layer color into sprite 7
		stx $d02e
		ldx xtablehi,y		; Accumulate the high bits for the sprites in a.
		beq dospr2_6
		lda #$88
;--------------------------------------
dospr2_6	ldy indextable+2	; Repeat the above for the rest of the sprite pairs...
		ldx ytable,y
		stx $d005
		stx $d00d
		ldx xtablelo,y
		stx $d004
		stx $d00c
		ldx frame,y
		stx spritepointer+2
		ldx frame+16,y
		stx spritepointer+6
		ldx color,y
		stx $d029
		ldx color+16,y
		stx $d02d
		ldx xtablehi,y
		beq dospr1_5
		ora #$44
;--------------------------------------
dospr1_5	ldy indextable+1
		ldx ytable,y
		stx $d003
		stx $d00b
		ldx xtablelo,y
		stx $d002
		stx $d00a
		ldx frame,y
		stx spritepointer+1
		ldx frame+16,y
		stx spritepointer+5
		ldx color,y
		stx $d028
		ldx color+16,y
		stx $d02c
		ldx xtablehi,y
		beq dospr0_4
		ora #$22
;--------------------------------------
dospr0_4	ldy indextable
		ldx ytable,y
		stx $d001
		stx $d009
		ldx xtablelo,y
		stx $d000
		stx $d008
		ldx frame,y
		stx spritepointer+0
		ldx frame+16,y
		stx spritepointer+4
		ldx color,y
		stx $d027
		ldx color+16,y
		stx $d02b

		;inc $d020	; Indication in border that we now start drawing.

		ldx xtablehi,y
		beq +
		ora #$11
+		sta $d010	; set the high bits for those sprites that need it :)

switch		jmp exitinter	; if number of sprites > 4 => it's a no-op using bit instruction,
				; otherwise it's a jmp instruction. So multiplexing will be
				; skipped if number of sprites <= 4.

		ldx xreg
		clc
		ldy vspr_counter
;--------------------------------------
nextspr0	lda $d001
		adc #$17	; sprite 0 y + 23
		sbc $d012	; if (sprite_0_y + 23 > rasterline) then draw sprite 0.
		bcc blit0	; I.e. we know that sprite 0 is now free and can be drawn again as the next
		cmp #$03	; "virtual" sprite.
		bcs next0	; if ((sprite_0_y + 23 - rasterline) >= 3) then add at least 3 lines for checking
		lda #$03	; for space for sprite 0 to be drawn again using the next virtual sprite.
next0		clc
		adc $d012	; $d012 = $d012 + 3
		sta $d012

		lda #<inter0	; so, set raster interrupt at next sprite 0 y coordinate.
		sta $fffe
		lda #>inter0
		sta $ffff

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		lda areg
		ldy yreg
		rti		; Go into waiting after sprite 0 y coordinate for interrupt has been set.

		; Sprite 0 next interrupt:.
		; --------------
inter0		sta areg	; arrival of next irq, for sprite 0. The next virtual sprite will be picked
		sty yreg	; for drawing.

		ldy vspr_counter

blit0		lda indextable,y	; Get the next sorted virtual sprite index.
		tay

		lda ytable,y		; Get the y coordinate for the next virtual two-layer sprite.
		sta $d001
		sta $d009
		lda xtablelo,y		; Get the x coordinate for the next virtual two-layer sprite.
		sta $d000
		sta $d008
		lda frame,y		; Get the current top layer frame for the next virtual sprite.
		sta spritepointer
		lda frame+16,y		; Get the current bottom layer frame for the next virtual sprite.
		sta spritepointer+4
		lda color,y		; Get the top layer color for the next virtual sprite.
		sta $d027
		lda color+16,y		; Get the bottom layer color for the next virtual sprite.
		sta $d02b

		lda xtablehi,y		; Get the high bit for x coord for next virtual sprite:
		beq no0
		lda #$11		; Set msb for both layer sprites
		ora $d010
		bne yes0
no0		lda #$ee		; Unset msb for both layer sprites
		and $d010
yes0		sta $d010		; Quite a mess here, eh? :)

		ldy vspr_counter		; Increment the counter (get next virtual sprite).
		iny
		sty vspr_counter

		cpy maxspr		; If more virtual sprites are pending, go for next :)
		bne nextspr1
		jmp exitinter

;--------------------------------------
nextspr1	lda $d003		; Repeat all above for sprites 1-7.
		adc #$17
		sbc $d012
		bcc blit1
		cmp #$03
		bcs next1
		lda #$03
next1		clc
		adc $d012
		sta $d012

		lda #<inter1
		sta $fffe
		lda #>inter1
		sta $ffff

		inc $d019
		lda $dc0d

		lda areg
		ldy yreg
		rti

inter1		sta areg
		sty yreg

		ldy vspr_counter

blit1		lda indextable,y
		tay

		lda ytable,y
		sta $d003
		sta $d00b
		lda xtablelo,y
		sta $d002
		sta $d00a
		lda frame,y
		sta spritepointer+1
		lda frame+16,y
		sta spritepointer+5
		lda color,y
		sta $d028
		lda color+16,y
		sta $d02c

		lda xtablehi,y
		beq no1
		lda #$22
		ora $d010
		bne yes1
no1		lda #$dd
		and $d010
yes1		sta $d010

		ldy vspr_counter
		iny
		sty vspr_counter
		cpy maxspr
		bne nextspr2
		jmp exitinter

;--------------------------------------
nextspr2	lda $d005
		adc #$17
		sbc $d012
		bcc blit2
		cmp #$03
		bcs next2
		lda #$03
next2		clc
		adc $d012
		sta $d012

		lda #<inter2
		sta $fffe
		lda #>inter2
		sta $ffff

		inc $d019
		lda $dc0d

		lda areg
		ldy yreg
		rti

inter2		sta areg
		sty yreg

		ldy vspr_counter

blit2		lda indextable,y
		tay

		lda ytable,y
		sta $d005
		sta $d00d
		lda xtablelo,y
		sta $d004
		sta $d00c
		lda frame,y
		sta spritepointer+2
		lda frame+16,y
		sta spritepointer+6
		lda color,y
		sta $d029
		lda color+16,y
		sta $d02d

		lda xtablehi,y
		beq no2
		lda #$44
		ora $d010
		bne yes2
no2		lda #$bb
		and $d010
yes2		sta $d010

		ldy vspr_counter
		iny
		sty vspr_counter

		cpy maxspr
		bne nextspr3
		jmp exitinter

;--------------------------------------
nextspr3	lda $d007
		adc #$17
		sbc $d012
		bcc blit3
		cmp #$03
		bcs next3
		lda #$03
next3		clc
		adc $d012
		sta $d012

		lda #<inter3
		sta $fffe
		lda #>inter3
		sta $ffff

		inc $d019
		lda $dc0d

		lda areg
		ldy yreg
		rti

inter3		sta areg
		sty yreg

		ldy vspr_counter

blit3		lda indextable,y
		tay

		lda ytable,y
		sta $d007
		sta $d00f
		lda xtablelo,y
		sta $d006
		sta $d00e
		lda frame,y
		sta spritepointer+3
		lda frame+16,y
		sta spritepointer+7
		lda color,y
		sta $d02a
		lda color+16,y
		sta $d02e

		lda xtablehi,y
		beq no3
		lda #$88
		ora $d010
		bne yes3
no3		lda #$77
		and $d010
yes3		sta $d010

		ldy vspr_counter
		iny
		sty vspr_counter

		cpy maxspr
		beq +
		jmp nextspr0
+
		jmp exitinter

		; Irq jump addresses depending on the number of sprites
t_jumplo
		!byte $00,$00,$00,$00,$00
t_jumphi
		!byte $00,$00,$00,$00,$00

		; Active sprites tab
activatetab	; !byte $00,$01,$03,$07,$0f,$1f,$3f,$7f,$ff
		!byte %00000000,%10001000,%11001100,%11101110,%11111111

		; for two-layer sprites, paired as [0+4, 1+5, 2+6, 3+7]
;--------------------------------------
; statusline
; destroys registers!
;--------------------------------------
statusline
		; reset scroll
		lda $d011
		and #$f8
		ora #4
		sta $d011
		lda $d016
		and #$f8
		;ora #0
		sta $d016
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop

	
		lda #0
		sta $d021
		ldx #126
-		dex
		bne -

		lda #9
		sta $d021

		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011

		lda scrollstate
		cmp #state_idle
		bne +
			lda #<maininter
			sta $fffe
			lda #>maininter
			sta $ffff
			jmp ++
+
			lda #<scrollirq
			sta $fffe
			lda #>scrollirq
			sta $ffff
++
		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		;inc $d019	; acknowledge raster irq.
		;lda $dc0d	; acknowledge pending irqs.

		rti

;--------------------------------------
exitinter
		stx xreg

		;; From this point and onward the sprites have been drawn. 
		;; There is plenty of raster time to trigger another interrupt just before the last bad line
		;; and use black background.

		lda $d012

		; if (raster line < 242 and 
		;     PlayerState != PlayerStateFades and 
		;     PlayerState != PlayerStateTransitInit and
		;     PlayerState != PlayerStateTransitDrawBack) ...
		cmp #$f2
		bcs +
		lda PlayerState
		cmp #PlayerStateFades
		beq +
		cmp #PlayerStateTransitInit
		beq +
		cmp #PlayerStateTransitDrawBack
		beq +
		; then {
			lda #$f2
			sta $d012

			lda #<statusline	; so, set raster interrupt at next sprite 0 y coordinate.
			sta $fffe
			lda #>statusline
			sta $ffff

			inc $d019	; acknowledge raster irq.
			lda $dc0d	; acknowledge pending irqs.
			;lda $dd0d
			jmp ++
+		; else

			lda #<maininter
			sta $fffe
			lda #>maininter
			sta $ffff

			lda #$00	; Set main interrupt to happen at line 32
			sta $d012
			inc $d019	; acknowledge raster irq.
			lda $dc0d	; acknowledge pending irqs.
			;lda $dd0d
++

		; Calculate pushback forces
		jsr calc_individual_forces

		; All AI logic
		jsr ctrl_enemy

		inc AnimCounter
		lda AnimCounter
		and #$1f	; 32 / 8 = 4 => range is [0-31] but always divided by 8 => [0-3]
		sta AnimCounter
		lsr
		lsr
		lsr
		sta AnimFrame	; This will create an animation stepper of 1 image per 8 frames, in range [0-3]
		

		; player movement here
		jsr ctrl_player
		bne +
			; abort this routine and start scrolling
			jmp ++++
+
		
		; Animate player
		lda PlayerAnimState
		asl
		asl
		clc
		adc AnimFrame	; Animate 1 image every 8 frames
		tax
		lda AnimTable,x
		sta frame+player+16 	; This is the sprite outline
		clc
		adc #4			; offset 4 blocks to get sprite color fill
		sta frame+player	; This is the color fill

		; Animate enemies
		; ---------------------------------------------------------------------------------

		; let enemy_qty = a;
		ldx MobsPresent
		beq +++	; if (enemy_qty != 0) {
			; 	for (x=enemy_qty-1; x>=0; x--); do { 
-			dex
			lda enemy_state,x
			cmp #EnemyLoot
			beq +
			cmp #EnemyDead
			bne ++
+
				; If in loot state, don't animate
				cpx #0
				bne -
				jmp +++
++
			lda enemy_anim_state,x
			clc
			asl
			asl
			clc
			adc AnimFrame	; reuse anim counter
			tay
			lda CurrentMobType,x
			cmp #$80
			bne +				; if (CurrentMobType == NPC(0))
				lda NpcImageList
				jmp ++
+			cmp #$81
			bne +				; if (CurrentMobType == NPC(1))
				lda NpcImageList+1
				jmp ++
+			and #$03			
			bne +				; if (CurrentMobType == slime(0))
				lda EnemyAnimTable,y
				jmp ++
+			cmp #$01
			bne +				; if (CurrentMobType == spider(1))
				lda EnemyAnimTable+52,y
				jmp ++
+			cmp #$02
			bne +				; if (CurrentMobType == skeleton(2))
				lda EnemyAnimTable+104,y
				jmp ++
+
							; else (CurrentMobType == knight(3))
				lda EnemyAnimTable+156,y

++		sta frame+enemy+16,x
		clc
		adc #4
		sta frame+enemy,x
		cpx #0
		bne -		; } // end for
+++
			; } // end if
		; ---------------------------------------------------------------------------------

		; From now on allow trigger on irq again (sacrifice in sprite accuracy)
		jsr sort	; sort sprites

		lda StatsUpdated
		beq +
			jsr draw_stats
			lda #0
			sta StatsUpdated
+

++++		;inc $d019
		;lda $dc0d
		;lda $dd0d
		lda areg
		ldx xreg
		ldy yreg

		rti		; ...aaand return from the multiplexing interrupt chain.


; The sorting routine initialization
;--------------------------------------
initsort
		ldx maxspr
		dex
-		txa
		sta indextable,x
		dex
		bpl -

		lda #<sortstart
		sta bal
		lda #>sortstart
		sta bah

		ldy #$00
-		lda bal
		sta sortlo,y	; create the sort table for low byte, set all to same address
		lda bah
		sta sorthi,y	; the sort table for high byte.

		lda bal
		clc
		adc #18
		sta bal
		bcc +
		inc bah
+		iny
		cpy #items-1
		bne -
		rts

; The sprite sorting routine
;--------------------------------------
sort
		lda maxspr
		cmp #$02	; if (maxspr < 2)
		bcc +		;     return;
		sbc #$02	; y = maxspr - 2;
		tay		;
		lda sortlo,y	; 			; reorder the indices of the virtual sprites.
		sta bal		; bal = sortlo[y];
		lda sorthi,y	;
		sta bah		; bah = sorthi[y];
		ldy #$00	; y = 0;
		lda #$60	; a = 96;
		sta (bal),y	; ba[y] = a;
		jsr over0	; over0();
		ldy #$00	; y = 0;
		lda #$a4	; a = 164;
		sta (bal),y	; ba[y] = a;
+		rts		; return;

over0		ldy indextable+1	; y = *(indextable+1);
back0		ldx indextable		; x = *(indextable);
		lda ytable,y		; a = ytable[y];
		cmp ytable,x		; if (ytable[x] >= a)
		bcs over1		;     goto over1;
		stx indextable+1	; *(indextable+1) = x;
		sty indextable		; *(indextable) = y;

sortstart
over1		ldy indextable+2	; y = *(indextable+2);
back1		ldx indextable+1	; x = *(indextable+1);
		lda ytable,y		; a = ytable[y];
		cmp ytable,x		; if (ytable[x] >= a)
		bcs over2		;     goto over2;
		stx indextable+2	; *(indextable+2) = x;
		sty indextable+1	; *(indextable+1) = y;
		bcc back0

over2		ldy indextable+3	; ...
back2		ldx indextable+2
		lda ytable,y
		cmp ytable,x
		bcs over3
		stx indextable+3
		sty indextable+2
		bcc back1

over3		ldy indextable+4
back3		ldx indextable+3
		lda ytable,y
		cmp ytable,x
		bcs over4
		stx indextable+4
		sty indextable+3
		bcc back2

over4		ldy indextable+5
back4		ldx indextable+4
		lda ytable,y
		cmp ytable,x
		bcs over5
		stx indextable+5
		sty indextable+4
		bcc back3

over5		ldy indextable+6
back5		ldx indextable+5
		lda ytable,y
		cmp ytable,x
		bcs over6
		stx indextable+6
		sty indextable+5
		bcc back4

over6		ldy indextable+7
back6		ldx indextable+6
		lda ytable,y
		cmp ytable,x
		bcs over7
		stx indextable+7
		sty indextable+6
		bcc back5

over7		ldy indextable
		rts

; Use pseudo op !fill to initialize sorter jump table with value 0:
sortlo	!fill items-1
sorthi	!fill items-1


; ------------------------------------------------------------------------------------
; setup_enemies
; Sets up the enemies in the current "room" and which loot they have.
; ------------------------------------------------------------------------------------
setup_enemies
		; clear old data
		ldx #0
		lda #0
-			sta ytable+enemy,x
			sta xtablelo+enemy,x
			sta xtablehi+enemy,x
			sta color+enemy,x
			sta color+enemy+16,x
			sta frame+enemy,x
			sta frame+enemy+16,x
			inx
			cpx #max_enemies
		bne -

		; get mobdata from the right place
		; All these rows mean: a = offy * 16 / 12
		lda offy
		jsr transform_a_mul_16_div_12
		sta tmp

		; This is a = offx / 20
		ldy #$ff
		ldx offx+1
		lda offx
-			iny
			sec
			sbc #20
			bcs -
			dex	; offx is 16 bits so check that high byte is also subtracted from
			bpl -
		tya

		clc
		adc tmp		; x = offy * 4 / 3 + offx / 20 == screen pos!
		tay
		sta CurrentRoomIdx


		; LOAD MOBS
		; prepare source address
		lda MobSrc
		sta tmp_addr
		lda MobSrc+1
		sta tmp_addr+1

		; get mob data from world / dungeons
		lda (tmp_addr),y
		tay
		lda mobs_entries_list,y			; get current mob entry in list 
		tay

		; set correct address for lda operation at store_mob
		lda #<CurrentMobType
		sta store_mob+1
		lda #>CurrentMobType
		sta store_mob+2
		lda #0
		sta MobsPresent				; set mob counter to 0

		; Store the mob data in a more manageable structure
		lda mobs_entries,y			; load the length of the current mob entry
		iny
		sta tmp					; store length in tmp
		cmp #0
		bne +
			rts			; exit if no mobs are present on the current screen
+
-		; do {
			lda mobs_entries,y		; load mob type
			ldx mobs_entries+1,y		; load mob qty
			sta tmp2

			; if (mob type == NPC) {

			and #$80
			beq +
				lda tmp2		; Set the NPC type
				sta CurrentMobType
					; x is screen position where NPC will stand
				stx CurrentMobType+1
				inc MobsPresent
				jmp ++

+			; } else {

				lda tmp2

				; Store x mob types in list
store_mob			sta $0000		; will be initialized with CurrentMobType list address
				inc store_mob+1		; will increment list entry each time
				inc MobsPresent		; increment total mobs by 1
				dex
				bne store_mob
			iny	; skip to next entry in mobs_entries
			iny
			dec tmp			; x++
			bne -

++			; } // end if

		; } while (x < num_mobs_entries);

		; Put all mobs on screen
		ldx MobsPresent
-
			dex		; get next enemy idx (going backwards)
			ldy CurrentMobType,x
			lda mobtable_hp,y	; get HP for the mobtype y
			sta enemy_hp,x
			lda mobtable_ap,y	; get AP for the mobtype y
			sta enemy_ap,x
			lda mobtable_gold,y	; get gold qty for drop for mobtype y
			sta enemy_gold,x
			lda mobtable_lootidx,y	; get mob loot table index
			sta enemy_lootidx,x
			tya
			and #$80
			bne +
				lda mob_fill_table,y
				sta color+enemy+16,x		; set mob fill color
				lda mob_contour_table,y
				sta color+enemy,x		; set mob contour color
				jmp ++
+
				lda npc_fill_table,y
				sta color+enemy+16,x		; set NPC fill color
				lda npc_contour_table,y
				sta color+enemy,x		; set NPC contour color
++
			lda #0
			sta enemy_pull_force_x,x
			sta enemy_pull_force_y,x

			lda #EnemyStopFacingSouth	; set animation state
			sta enemy_anim_state,x
			lda #EnemyIdle			; set AI state
			sta enemy_state,x
			tya
			cmp #$80
			bne +	; 80 = NPC 1
				lda #EnemyIsNpc
				sta enemy_state,x
				lda NpcImageList
				jmp ++
+			cmp #$81
			bne +	; 81 = NPC 2
				lda #EnemyIsNpc
				sta enemy_state,x
				lda NpcImageList
				jmp ++
+			and #$03
			bne +	; 0 = slime
				lda EnemyAnimTable
				jmp ++
+			cmp #1
			bne +	; 1 = spider
				lda EnemyAnimTable+48
				jmp ++
+			cmp #2
			bne +	; 2 = skeleton
				lda EnemyAnimTable+96
				jmp ++

+			; else	; 3 = knight
				lda EnemyAnimTable+144
++
			sta frame+enemy+16,x
			clc
			adc #4
			sta frame+enemy,x

			cpx #0
		beq +
		jmp -
+

		; Randomize mob positions

		ldx MobsPresent

		; for each mob do {
-			dex

			stx tmp3	; store mob index

			; Choose a random location
			jsr get_random
			lda RandomNumber
			+immediate_a_mod_n 240

			; tmp2 should be tileX and tmp should be tileY from random value here
			; If not done, enemies will spawn at top left.
			sta tmp2
			+immediate_a_div_by_n 20
			sty tmp			
			lda tmp2
			tay
			+immediate_a_mod_n 20
			sta tmp2

			; Check if position is free
			lda tilebuffer,y

			; if tile[x,y] >= 32 then try a new random position;
			cmp #20
			bcc +
				inx	; repeat random position for current mob index
				jmp -
+			; end if

			; Set x and y coordinates for current mob
			lda #0
			sta xtablehi+enemy,x
			lda tmp2
			clc
			asl
			asl
			asl
			asl		; carry might be set already here
			rol xtablehi+enemy,x
			adc #xoffset
			sta xtablelo+enemy,x
			bcc +
			inc xtablehi+enemy,x
+			
			lda tmp
			clc
			asl
			asl
			asl
			asl
			adc #yoffset
			sta ytable+enemy,x
			
			cpx #0	; more mobs to check?
		bne -
		; } next mob 

		rts
; ------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------
;  ctrl_enemy
;  This is some enemy AI code
; ------------------------------------------------------------------------------------
ctrl_enemy
		ldx MobsPresent
		bne +
		rts
+
-		dex

		; ---------------------------------
		; check state before doing anything
		; ---------------------------------
		lda enemy_state,x
		cmp #EnemyLoot
		bne +
			; ------------------
			; Loot state
			; ------------------
			jsr check_player_enemy_collision	; Did player try to pick up loot from
								; killed enemy?

			; ------------------
			; Heart
			; ------------------
			cmp #$80	; heart
			bne +++
				lda #1
				jsr increase_hp
				inc StatsUpdated
			jmp ++
			; ------------------
+++
			; ------------------
			; Gold
			; ------------------
			cmp #$81	; gold
			bne +++

				jsr get_random
				lda RandomNumber
				and #3
				clc
				adc enemy_gold,x
				jsr increase_gold
				inc StatsUpdated
				
			jmp ++
			; ------------------
+++
			; ------------------
			; Keys
			; ------------------
			cmp #$82	; keys
			bne +++
			; TODO: add keys
			; ------------------
+++
			; ------------------
			; TODO: More loot
			; ------------------
			; ------------------
			jmp +
++
			; Set enemy as dead (looted)
			lda #$40
			sta enemy+frame,x

			; Reset position
			lda #0
			sta enemy+xtablelo,x
			sta enemy+xtablehi,x
			sta enemy+ytable,x

			; Leave as dead
			lda #EnemyDead
			sta enemy_state,x
			jmp +++++
			; ------------------

+
		cmp #EnemyIsNpc
		bne +
			; ------------------
			; NPC state
			; ------------------
			jmp +++++
			; ------------------


+
		cmp #EnemyDead
		bne +
			; ------------------
			; Dead state
			; ------------------
			jmp +++++ 		; skip this enemy because it's dead
			; ------------------

+
	; ------------------------------------------------
	; If we get here, then we know that enemy is alive
	; ------------------------------------------------

		; ---------------------------------
		; Check enemy with player collision
		; ---------------------------------
		jsr check_player_enemy_collision
		cmp #0
		beq +
			ldy enemy_state,x
			cpy #EnemyHit
			bcs +
			ldy PlayerState
			cpy #PlayerStateHit
			bcs +

				ldy #50
				sty PlayerBusyTimer
				inc StatsUpdated

				lda enemy_ap,x
				jsr decrease_hp
				bne ++++
					ldy #48
					sty PlayerBusyTimer
					lda #PlayerDying
					sta PlayerAnimState
					lda #PlayerStateDying
					sta PlayerState
					jmp +
++++
				lda #PlayerStateHit
				sta PlayerState

				lda PlayerAnimState
				and #3
				cmp #PlayerStopFacingSouth
				bne +++
					ldy #$fa
					sty PlayerPullForceY
					jmp +
+++				cmp #PlayerStopFacingWest
				bne +++
					ldy #$06
					sty PlayerPullForceX
					jmp +
+++				cmp #PlayerStopFacingNorth
				bne +++
					ldy #$06
					sty PlayerPullForceY
					jmp +
+++				; else
					ldy #$fa
					sty PlayerPullForceX
+

		lda enemy_state,x
		cmp #EnemyHit	; enemy can only be hit if enemy is alive
		bcs +
		jsr check_weapon_enemy_collision
		beq +
		
			lda PlayerAnimState
			and #3
			cmp #PlayerStopFacingSouth
			bne ++				
				lda #$06
				sta enemy_pull_force_y,x
				jmp +
++			cmp #PlayerStopFacingWest
			bne ++
				lda #$fa
				sta enemy_pull_force_x,x
				jmp +
++			cmp #PlayerStopFacingNorth
			bne ++
				lda #$fa
				sta enemy_pull_force_y,x
				jmp +
++
				lda #$06
				sta enemy_pull_force_x,x
+
		lda enemy_state,x
		cmp #EnemyIdle
		bne +

			; ----------------
			; Idle State
			; ----------------
			; Choose a random location and start moving there
			jsr get_random
			lda RandomNumber
			+immediate_a_mod_n 240
			sta RandomPos

			; Separate nextpos into x (a) and y (y) locations
			+immediate_a_mod_n 20
			sta enemy_nextpos_x,x
			lda RandomPos
			+immediate_a_div_by_n 20
			tya
			sta enemy_nextpos_y,x
			lda #EnemyMoving
			sta enemy_state,x
			jmp +++++
			; ----------------
					
+		cmp #EnemyWaiting
		bne +

			; ----------------
			; Waiting State
			; ----------------
			; Wait until timeout
			lda enemy_timer,x
			beq enemy_timeout_jmp
			dec enemy_timer,x

			jsr check_player_proximity

			jmp +++++
enemy_timeout_jmp
			lda #EnemyIdle
			sta enemy_state,x
			jmp +++++
			; ----------------

+		cmp #EnemyMoving
		bne +
			; ----------------
			; Moving State
			; ----------------
			jsr move_enemy
			jmp +++++
			; ----------------

+		cmp #EnemyAttacking
		bne +
			; ----------------
			; Attacking State
			; ----------------
			jsr enemy_attack
			jmp +++++
			; ----------------

+		cmp #EnemyHit
		bne +
			; ----------------
			; Hit State
			; ----------------
			lda AnimCounter
			and #3
			tay
			lda damage_flash,y
			sta color+enemy,x
			lda enemy_timer,x
			beq +++
				dec enemy_timer,x
				jmp +++++
+++
			ldy CurrentMobType,x
			lda mob_contour_table,y
			sta color+enemy,x
			lda #EnemyMoving
			sta enemy_state,x
			jmp +++++
			; ----------------


+		cmp #EnemyDying
		bne +++++
			; ----------------
			; Dying State
			; ----------------
			sta enemy_anim_state,x
			lda enemy_timer,x
			beq +++
				dec enemy_timer,x
				lda #10
				sta color+enemy+16,x
				lda #7
				sta color+enemy,x
				jmp +++++
+++

			; ------------------------------
			; Time of death, changing state
			; ------------------------------
			jsr get_random
			lda RandomNumber
			and #3
			beq +++
				; Spawn some loot
				tay
				lda loot_list,y
				sta frame+enemy+16,x
				clc
				adc #4
				sta frame+enemy,x
				lda loot_colors_fill,y
				sta color+enemy+16,x
				lda loot_colors_contour,y
				sta color+enemy,x

				lda #EnemyLoot
				sta enemy_state,x
				sta enemy_anim_state,x
				jmp +++++
+++
			lda #0
			sta xtablelo+enemy,x
			sta xtablehi+enemy,x
			sta ytable+enemy,x
			lda #EnemyDead
			sta enemy_state,x

			; ----------------
+++++
		cpx #0
		beq +
		jmp -
+
		rts
; ------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------
; move_enemy
; ------------------------------------------------------------------------------------
move_enemy
		stx tmp4

		lda CurrentMobType,x
		tax

		; determine movement speed
		lda mobtable_speed,x
		lsr

		; assume that speed = 0 is forbidden.
		; if a == 0 then:
		bne +
			lda AnimCounter
			and #$01	; Achieve subpixel accuracy
		; end if
+		sta CurrentMobSpeed
		ldx tmp4

		; convert to sprite coordinate x
		lda enemy_nextpos_x,x
		clc
		asl
		asl
		asl
		asl
		adc #xoffset
		sta tmp2
		lda #0
		rol
		sta tmp3

		; convert to sprite coordinate y
		lda enemy_nextpos_y,x
		clc
		asl
		asl
		asl
		asl
		adc #yoffset

		; Check enemy y sprite coordinate
		; --------------------------------------------------------------------

		cmp ytable+enemy,x	; Check the y coordinate
		bne +
		jmp +++		; Go check also the x coordinates
+
		bcc +	; jump if next y < curr y

			; ******   next y > curr y   ******
			inx
			inx
			jsr get_tile_below_sprite
			cmp #16
			bcc ++

				; Enemy has tile below sprite => Go idle and wait to make a decision.
				ldx tmp4

				lda #EnemyWaiting
				sta enemy_state,x
				jsr get_random
				lda RandomNumber
				lsr
				sta enemy_timer,x
				rts			; return

++
				ldx tmp4

				lda ytable+enemy,x
				clc
				adc CurrentMobSpeed
				sta ytable+enemy,x
				lda #EnemyRunSouth
				sta enemy_anim_state,x
				rts
+
			; ******   next y < curr y   ******
			inx
			inx
			jsr get_tile_above_sprite
			cmp #16
			bcc ++
				; TODO: Keep this shortcut?
				ldx tmp4
				jmp +++	; Check also x sprite coordinates before taking a new course.

				; Enemy has tile above sprite => Go idle and wait to make a decision.
				ldx tmp4

				lda #EnemyWaiting
				sta enemy_state,x
				jsr get_random
				lda RandomNumber
				lsr
				sta enemy_timer,x
				rts			; return

++
				ldx tmp4

				lda ytable+enemy,x
				sec
				sbc CurrentMobSpeed
				sta ytable+enemy,x
				lda #EnemyRunNorth
				sta enemy_anim_state,x
				rts			; return

		; Check enemy x sprite coordinate
		; --------------------------------------------------------------------
+++

		lda tmp3
		cmp xtablehi+enemy,x
		bne +
		lda tmp2
		cmp xtablelo+enemy,x
		bne +
		
			; Enemy has reached destination
			lda #EnemyWaiting
			sta enemy_state,x
			jsr get_random
			lda RandomNumber
			lsr
			sta enemy_timer,x
			rts			; return
+
		bcc +	; jump if next x < curr x

			; ******   next x > curr x   ******
			inx
			inx
			jsr get_tile_right_of_sprite
			cmp #16
			bcc ++

				; Enemy has tile right of sprite => Go idle and wait to make a decision.
				ldx tmp4

				lda #EnemyWaiting
				sta enemy_state,x
				jsr get_random
				lda RandomNumber
				lsr
				sta enemy_timer,x
				rts		; return

++
				ldx tmp4

				lda xtablelo+enemy,x
				clc
				adc CurrentMobSpeed
				sta xtablelo+enemy,x
				lda xtablehi+enemy,x
				adc #0
				sta xtablehi+enemy,x
				lda #EnemyRunEast
				sta enemy_anim_state,x
				rts
+
			; ******   next x < curr x   ******
			inx
			inx
			jsr get_tile_left_of_sprite
			cmp #16
			bcc ++

				; Enemy has tile left of sprite => Go idle and wait to make a decision.
				ldx tmp4

				lda #EnemyWaiting
				sta enemy_state,x
				jsr get_random
				lda RandomNumber
				lsr
				sta enemy_timer,x
				rts			; return

++
				ldx tmp4

				lda xtablelo+enemy,x
				sec
				sbc CurrentMobSpeed
				sta xtablelo+enemy,x
				lda xtablehi+enemy,x
				sbc #0
				sta xtablehi+enemy,x
				lda #EnemyRunWest
				sta enemy_anim_state,x
				rts			; return

; ------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------
; enemy_attack
; ------------------------------------------------------------------------------------
enemy_attack
		lda #0
		sta tmp2		; result variable

		lda xtablehi+player
		lsr
		lda xtablelo+player
		ror
		lsr
		lsr
		lsr
		sta tmp

		lda xtablehi+enemy,x
		lsr
		lda xtablelo+enemy,x
		ror
		lsr
		lsr
		lsr
		cmp tmp			; is enemy on same X?
		bne +

		; player x == enemy x => found player X
		lda #1
		sta tmp2		; Arrived on X axis
		jmp ++
+
		bcc +

		; next x < cur x
		lda xtablelo+enemy,x
		sec
		sbc #2
		sta xtablelo+enemy,x
		lda xtablehi+enemy,x
		sbc #0
		sta xtablehi+enemy,x
		rts			; Walk X axis first
+
		; next x > cur x
		lda xtablelo+enemy,x
		clc
		adc #2
		sta xtablelo+enemy,x
		lda xtablehi+enemy,x
		adc #0
		sta xtablehi+enemy,x
		rts			; Walk X axis first
++
		lda ytable+player
		lsr
		lsr
		lsr
		lsr
		sta tmp

		lda ytable+enemy,x
		lsr
		lsr
		lsr
		lsr
		cmp tmp			; Is enemy on same Y
		bne +

		; next y == cur y => found player on Y!
		lda tmp2
		beq +
		lda #EnemyWaiting
		sta enemy_state,x
		lda RandomNumber
		lsr
		sta enemy_timer,x
		rts
+
		bcc +

		; next y < cur y
		lda ytable+enemy,x
		sec
		sbc #2
		sta ytable+enemy,x
		rts
+
		; next y > cur y
		lda ytable+enemy,x
		clc
		adc #2
		sta ytable+enemy,x
		rts
; ------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------
;  check_player_proximity
; ------------------------------------------------------------------------------------
check_player_proximity
		rts
; ------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------
;  player_start_attack
; ------------------------------------------------------------------------------------
player_start_attack
		; Initiate player attack animation and activate weapon sprite at
		; player location. If an enemy is in front of the player, apply
		; the corresponding damage to it.

		lda #PlayerStateAttack
		sta PlayerState

		lda PlayerAnimState
		and #3
		clc
		adc #8		; This is the attack state, now determine which direction
		sta PlayerAnimState
		cmp #PlayerAttackSouth
		bne +

		; Show weapon sprite
		lda xtablelo+player
		sta xtablelo+weapon
		lda xtablehi+player
		sta xtablehi+weapon
		lda ytable+player
		clc
		adc #16
		sta ytable+weapon
		lda #0
		sta color+weapon
		lda #8
		sta color+weapon+16
		lda #$6b
		sta frame+weapon
		lda #$70
		sta frame+weapon+16
		rts
+		cmp #PlayerAttackWest
		bne +

		; Show weapon sprite
		lda xtablelo+player
		sec
		sbc #16
		sta xtablelo+weapon
		lda xtablehi+player
		sbc #0
		sta xtablehi+weapon
		lda ytable+player
		sta ytable+weapon
		lda #0
		sta color+weapon
		lda #8
		sta color+weapon+16
		lda #$6b
		sta frame+weapon
		lda #$71
		sta frame+weapon+16
		rts
+		cmp #PlayerAttackNorth
		bne +

		; Show weapon sprite
		lda xtablelo+player
		sta xtablelo+weapon
		lda xtablehi+player
		sta xtablehi+weapon
		lda ytable+player
		sec
		sbc #16
		sta ytable+weapon
		lda #0
		sta color+weapon
		lda #8
		sta color+weapon+16
		lda #$6b
		sta frame+weapon
		lda #$72
		sta frame+weapon+16
		rts
+		cmp #PlayerAttackEast
		bne +

		; Show weapon sprite
		lda xtablelo+player
		clc
		adc #16
		sta xtablelo+weapon
		lda xtablehi+player
		adc #0
		sta xtablehi+weapon
		lda ytable+player
		sta ytable+weapon
		lda #0
		sta color+weapon
		lda #8
		sta color+weapon+16
		lda #$6b
		sta frame+weapon
		lda #$73
		sta frame+weapon+16
		rts
+
		rts


; Player's start location position arrays.
StartLocX	!byte 8,0,0,0
StartLocY	!byte 91,0,0,0

MapStartX	!byte 0,0,0,0
MapStartHiX	!byte 0,0,0,0
MapStartY	!byte 84,0,0,0

; --------------------------------
; Sprite pointers data
; --------------------------------
AnimTable
		; Standing facing south
		!byte $40,$40,$40,$40
		; Standing facing west
		!byte $48,$48,$48,$48
		; Standing facing north
		!byte $50,$50,$50,$50
		; Standing facing east
		!byte $58,$58,$58,$58
		; Walk south
		!byte $40,$41,$40,$42
		; Walk west
		!byte $48,$49,$48,$4a
		; Walk north
		!byte $50,$51,$50,$52
		; Walk east
		!byte $58,$59,$58,$5a
		; Attack south
		!byte $43,$43,$43,$43
		; Attack west
		!byte $4b,$4b,$4b,$4b
		; Attack north
		!byte $53,$53,$53,$53
		; Attack east
		!byte $5b,$5b,$5b,$5b
		; Dying
		!byte $40,$48,$50,$58
		; Death
		!byte $78,$79,$7a,$7b
EnemyAnimTable
		; SLIME
		; Standing facing south
		!byte $62,$62,$62,$62
		; Standing facing west
		!byte $62,$62,$62,$62
		; Standing facing north
		!byte $62,$62,$62,$62
		; Standing facing east
		!byte $62,$62,$62,$62
		; Run south
		!byte $62,$63,$62,$63
		; Run west
		!byte $62,$63,$62,$63
		; Run north
		!byte $62,$63,$62,$63
		; Run east
		!byte $62,$63,$62,$63
		; Attack south
		!byte $62,$63,$62,$63
		; Attack west
		!byte $62,$63,$62,$63
		; Attack north
		!byte $62,$63,$62,$63
		; Attack east
		!byte $62,$63,$62,$63
		; Death
		!byte $78,$79,$7a,$7b

		; SPIDER
		; Standing facing south
		!byte $90,$90,$90,$90
		; Standing facing west
		!byte $92,$92,$92,$92
		; Standing facing north
		!byte $98,$98,$98,$98
		; Standing facing east
		!byte $9a,$9a,$9a,$9a
		; Run south
		!byte $90,$91,$90,$91
		; Run west
		!byte $92,$93,$92,$93
		; Run north
		!byte $98,$99,$98,$99
		; Run east
		!byte $9a,$9b,$9a,$9b
		; Attack south
		!byte $90,$91,$90,$91
		; Attack west
		!byte $92,$93,$92,$93
		; Attack north
		!byte $98,$99,$98,$99
		; Attack east
		!byte $9a,$9b,$9a,$9b
		; Death
		!byte $78,$79,$7a,$7b

		; SKELETON
		; Standing facing south
		!byte $a0,$a1,$a0,$a2
		; Standing facing west
		!byte $a0,$a1,$a0,$a2
		; Standing facing north
		!byte $a0,$a1,$a0,$a2
		; Standing facing east
		!byte $a0,$a1,$a0,$a2
		; Run south
		!byte $a0,$a1,$a0,$a2
		; Run west
		!byte $a0,$a1,$a0,$a2
		; Run north
		!byte $a0,$a1,$a0,$a2
		; Run east
		!byte $a0,$a1,$a0,$a2
		; Attack south
		!byte $a3,$a3,$a3,$a0
		; Attack west
		!byte $a3,$a3,$a3,$a0
		; Attack north
		!byte $a3,$a3,$a3,$a0
		; Attack east
		!byte $a3,$a3,$a3,$a0
		; Death
		!byte $78,$79,$7a,$7b

		; KNIGHT
		; Standing facing south
		!byte $b0,$b0,$b1,$b1
		; Standing facing west
		!byte $b2,$b2,$b3,$b3
		; Standing facing north
		!byte $b8,$b8,$b9,$b9
		; Standing facing east
		!byte $ba,$ba,$bb,$bb
		; Run south
		!byte $b0,$b1,$b0,$b1
		; Run west
		!byte $b2,$b3,$b2,$b3
		; Run north
		!byte $b8,$b9,$b8,$b9
		; Run east
		!byte $ba,$bb,$ba,$bb
		; Attack south
		!byte $b0,$b1,$b0,$b1
		; Attack west
		!byte $b2,$b3,$b2,$b3
		; Attack north
		!byte $b8,$b9,$b8,$b9
		; Attack east
		!byte $ba,$bb,$ba,$bb
		; Death
		!byte $78,$79,$7a,$7b

NpcImageList	!byte $60,$61


; hp array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_hp
		!byte $02,$04,$0a,$14,$05,$08,$14,$1e
		!byte $0a,$0e,$1e,$28,$14,$1e,$32,$50

; ap array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_ap
		!byte $01,$01,$02,$04,$02,$02,$04,$08
		!byte $04,$04,$08,$16,$08,$08,$16,$32

; gold array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_gold
		!byte $01,$04,$10,$15,$12,$15,$20,$25
		!byte $15,$20,$25,$30,$25,$40,$75,$96

; loot index array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_lootidx
		!byte $00,$01,$02,$03,$00,$04,$05,$06
		!byte $07,$08,$09,$0a,$0b,$0c,$0d,$0e

; subpixel speed ratio is 1/2; 1 = 0.5, 2 = 1, etc...
mobtable_speed	!byte $01,$02,$01,$01,$01,$02,$02,$02
		!byte $02,$03,$02,$02,$02,$04,$02,$02

; mob colors
mob_fill_table
		!byte $05,$01,$00,$0f,$0e,$01,$00,$0e
		!byte $0a,$01,$00,$04,$07,$01,$00,$08
mob_contour_table
		!byte $0d,$00,$01,$00,$06,$06,$03,$00
		!byte $04,$04,$04,$00,$08,$08,$08,$00
npc_fill_table
		!byte $05,$0e
npc_contour_table
		!byte $00,$00

damage_flash
		!byte $07,$07,$02,$02
loot_list
		!byte $00,$80,$81,$82	; [nothing, heart, gold, bigkey]
loot_colors_fill
		!byte $00,$01,$07,$07
loot_colors_contour
		!byte $00,$02,$01,$01

fadeout_colors_bg_border
		!byte $00,$00,$00,$00,$09,$09,$09,$09
fadeout_colors_extra_color1
		!byte $09,$09,$0b,$0b,$0c,$0c,$0f,$0f
fadeout_colors_extra_color2
		!byte $09,$09,$09,$09,$0b,$0b,$0b,$0b
gradient_fader
		!byte $00,$07,$04,$06,$06,$06,$00,$05
		!byte $08,$0f,$0c,$0e,$0e,$0e,$08,$0d

		; 1 = door
		; 2 = blocking
		; 3 = tree
		; 4 = chest
		; 5 = locked door
		; 6 = runestone
		; 7 = infostone
		; 8 = crushable boulder
		; 9 = movable pillar
		; a = cenotaph
collision_map	!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$01,$01,$00
		!byte $00,$00,$00,$00,$02,$03,$04,$04
		!byte $02,$02,$02,$02,$05,$02,$02,$02
		!byte $02,$02,$02,$06,$07,$08,$09,$02
		!byte $02,$02,$02,$02,$00,$02,$02,$0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$02,$02

; SFX suite	
; 		format is: BYTE<8 bits>,BYTE<high 4 bits|low 4 bits>, ...

;		SFX format:
;		  <attack|decay>, <systain|release>, <1 byte pulse width (reversed high/low bytes)>,
;		  <wave form value = [$10,$11,$20,$21,$40,$41,$80,$81]> OR 
;		  <absolute note value n = [n >$81, n < $c0] >, ...
sword_swing
		!byte $67,$f8,$00,$b8,$81,$bf,$80,$b8,$b4,$b2,$00

; -----------------------------------------------------------------

end_code_c000


; ***** FREE SPACE: 489 bytes


; -----------------------------------------------------------------
; $d000
; $e000 - $efff ; sprites

; $f000 - player_max_hp
; .... see beginning of this file for content in this RAM area.

;		*=$fa00
;end_code_f000

