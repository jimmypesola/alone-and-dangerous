		!sl "aad_symbols.a"
		!to "aad_unpacked.prg", cbm
		!source "coretables_labels.a"
		!source "outdoortables_labels.a"
		!source "file_lengths.a"
		!source "odtext.a"
; Memory (VIC Bank at $4000, character set at $4800, sprite blocks at $5000-$6fff)
;
;	CODE #1:
;       $0400-$07ff -> 1024 bytes --- Color buffer (if used). This area is not good for much else.
;	$0810-$1fff -> -- Routines and tables
;
;	MUSIC:
; 	$2000-$2fff -> 4096 bytes --- SID player routine
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
;	$5000-$5fff -> 4096 bytes --- Sprite bank of 64 sprites here.
;
;	GAME DATA:
;	$7000-$bdff -> 19968 bytes --- RLE compressed map data (interior + outdoor).
;	                               Outdoor map is 16x13 (=208) "rooms" with interiors included, 16x8 with interiors excluded.
;         $be00-$beff -> 256 bytes --- Map columns location
;         $bf00-$bfff -> 256 bytes --- Map tiles location
;
;	$e000-$ebff -> 3072 bytes --- World related table data (odt, d0t, ...)
;       $ec00-$efff -> 1024 bytes --- Free space for something... but this space is occupied by Kernal routines.
;
;	CODE #3:
;	$c000-$cfff -> 4096 bytes --- code routines
;	$e000-$efff -> 4096 bytes --- Keep clear from $e600-$efff, kernal ROM is banked in at loading and messes up data here.
;	$f000-$f5ff -> 1536 bytes --- Core tables and game data (prel.)
;	$f600-$f9e7 -> -- Color buffer, 1000 bytes
;	$fa00-$faf0 -> -- Tile Buffer
;

; TODO: Fix choppable tree / crushable rock / unlockable door (can be mixed in?) / table
; TODO: If all enemies are killed in some room, spawn item / door.
; TODO: Make shops
; TODO: Make more enemies
; TODO: Make more bosses


; Features:
; 1. Uses a loader, rle compressed map data. Also compressed (lzw?) with Exomizer. Runtime dungeon loading / map swapping works now as well.
; 2. Configure memory, switch in RAM at BASIC ROM ($a000-$bfff).
; 3. Load compressed map data to $7000-$bfff, as near the end ($bfff) as possible.
; 4. Unpack new map specific tables to $e000-$e5ff. Not further, as loader will be bugged if more than $e5ff 
; 5. Unpack new map to beginning of $7000 in place (overwrites own data). Supports bigger maps :-)
; 6. Unpack new set of sprites to $5000-$6fff
; 7. Unpack new charset to $4800-$4fff
; 8. Unpack new tune to $2000-$2fff?
; 9. Storing data beyond $e5ff seems bad for kernal operations.

; More features:
; - Improved map to screen
;      - Each screen is stored as RLE packed data
;      - Pointer tables (high and low bytes) to addresses where each screen's RLE data starts.
;      - Uses indexed table of rooms/screens where each room can be re-referenced if identical in map.
;      - Saves even more space allowing larger maps! Max size is 20k, allowing a map of max 320x144 tiles 
;        (uncompressed map can have a logical size up to 62kbyte without any dynamic disk loading of that data).

; shift in RAM at Kernal ROM ($e000-$ffff), except in loading of new maps.
;

; -----------------------------------------------------------
;  Welcome to the constant section
; -----------------------------------------------------------
!source "const.asm"
;------------------------------------------------------------------------------------
!source "macros.asm"
;------------------------------------------------------------------------------------



; RUN command

		*=$0801
begin_code_801
		!byte $0d,$08,$0a,$00,$9e
		!byte $20,$31,$32,$32,$38,$38

		*=$0810

; --------------------------------------------
; dungeon / overworld names + file names
; --------------------------------------------
coretables		!pet "ct"
coretables_len
outdoorworld		!pet "od"
outdoorworld_len
outdoorsprites		!pet "ods"
outdoorsprites_len
outdoorcharset		!pet "odc"
outdoorcharset_len
outdoortables		!pet "odt"
outdoortables_len
dungeon_0		!pet "d0"
dungeon_0_len
dungeon_0_sprites	!pet "d0s"
dungeon_0_sprites_len
dungeon_0_charset	!pet "d0c"
dungeon_0_charset_len
dungeon_0_tables	!pet "d0t"
dungeon_0_tables_len
dungeon_1		!pet "d1"
dungeon_1_len
dungeon_1_sprites	!pet "d1s"
dungeon_1_sprites_len
dungeon_1_charset	!pet "d1c"
dungeon_1_charset_len
dungeon_1_tables	!pet "d1t"
dungeon_1_tables_len
dungeon_2		!pet "d2"
dungeon_2_len
dungeon_2_sprites	!pet "d2s"
dungeon_2_sprites_len
dungeon_2_charset	!pet "d2c"
dungeon_2_charset_len
dungeon_2_tables	!pet "d2t"
dungeon_2_tables_len
dungeon_3		!pet "d3"
dungeon_3_len
dungeon_3_sprites	!pet "d3s"
dungeon_3_sprites_len
dungeon_3_charset	!pet "d3c"
dungeon_3_charset_len
dungeon_3_tables	!pet "d3t"
dungeon_3_tables_len
dungeon_4		!pet "d4"
dungeon_4_len
dungeon_4_sprites	!pet "d4s"
dungeon_4_sprites_len
dungeon_4_charset	!pet "d4c"
dungeon_4_charset_len
dungeon_4_tables	!pet "d4t"
dungeon_4_tables_len
dungeon_5		!pet "d5"
dungeon_5_len
dungeon_5_sprites	!pet "d5s"
dungeon_5_sprites_len
dungeon_5_charset	!pet "d5c"
dungeon_5_charset_len
dungeon_5_tables	!pet "d5t"
dungeon_5_tables_len
dungeon_6		!pet "d6"
dungeon_6_len
dungeon_6_sprites	!pet "d6s"
dungeon_6_sprites_len
dungeon_6_charset	!pet "d6c"
dungeon_6_charset_len
dungeon_6_tables	!pet "d6t"
dungeon_6_tables_len
dungeon_7		!pet "d7"
dungeon_7_len
dungeon_7_sprites	!pet "d7s"
dungeon_7_sprites_len
dungeon_7_charset	!pet "d7c"
dungeon_7_charset_len
dungeon_7_tables	!pet "d7t"
dungeon_7_tables_len

od_tables_lb_end	= <($0400 + od_tables_len - 2)
od_tables_hb_end	= >($0400 + od_tables_len - 2)
od_lb_end		= <($6ffa + od_len - 2)
od_hb_end		= >($6ffa + od_len - 2)
od_sprites_lb_end	= <($4ffe + od_sprites_len - 2)
od_sprites_hb_end	= >($4ffe + od_sprites_len - 2)
od_charset_lb_end	= <($47fe + od_charset_len - 2)
od_charset_hb_end	= >($47fe + od_charset_len - 2)
d0_tables_lb_end	= <($0400 + d0_tables_len - 2)
d0_tables_hb_end	= >($0400 + d0_tables_len - 2)
d0_lb_end		= <($6ffa + d0_len - 2)
d0_hb_end		= >($6ffa + d0_len - 2)
d0_sprites_lb_end	= <($4ffe + d0_sprites_len - 2)
d0_sprites_hb_end	= >($4ffe + d0_sprites_len - 2)
d0_charset_lb_end	= <($47fe + d0_charset_len - 2)
d0_charset_hb_end	= >($47fe + d0_charset_len - 2)


tables_name_lb_idx	!byte <outdoortables, <dungeon_0_tables, <dungeon_1_tables
			!byte <dungeon_2_tables, <dungeon_3_tables, <dungeon_4_tables
			!byte <dungeon_5_tables, <dungeon_6_tables, <dungeon_7_tables

tables_name_hb_idx	!byte >outdoortables, >dungeon_0_tables, >dungeon_1_tables
			!byte >dungeon_2_tables, >dungeon_3_tables, >dungeon_4_tables
			!byte >dungeon_5_tables, >dungeon_6_tables, >dungeon_7_tables

tables_name_len_idx	!byte outdoortables_len-outdoortables, dungeon_0_tables_len-dungeon_0_tables
			!byte dungeon_1_tables_len-dungeon_1_tables, dungeon_2_tables_len-dungeon_2_tables
			!byte dungeon_3_tables_len-dungeon_3_tables, dungeon_4_tables_len-dungeon_4_tables
			!byte dungeon_5_tables_len-dungeon_5_tables, dungeon_6_tables_len-dungeon_6_tables
			!byte dungeon_7_tables_len-dungeon_7_tables

; EXOMIZER PACKER END ADDRESSES, FIND THEM IN PACKER OUTPUT LIKE:
; "Phase 3: Generating output file" section, at "Writing "..." as prg, saving from $A000 to $A32C"
; IN THIS EXAMPLE: tables_file_end_lb = $2c, tables_file_end_hb = $a3
tables_file_end_lb	!byte od_tables_lb_end, d0_tables_lb_end, $e1, $e1, $e1, $e1, $e1, $e1, $e1
tables_file_end_hb	!byte od_tables_hb_end, d0_tables_hb_end, $4c, $4c, $4c, $4c, $4c, $4c, $4c

map_name_lb_idx		!byte <outdoorworld,<dungeon_0,<dungeon_1,<dungeon_2,<dungeon_3
			!byte <dungeon_4,<dungeon_5,<dungeon_6,<dungeon_7

map_name_hb_idx		!byte >outdoorworld,>dungeon_0,>dungeon_1,>dungeon_2,>dungeon_3
			!byte >dungeon_4,>dungeon_5,>dungeon_6,>dungeon_7

map_name_len_idx	!byte outdoorworld_len-outdoorworld
			!byte dungeon_0_len-dungeon_0, dungeon_1_len-dungeon_1
			!byte dungeon_2_len-dungeon_2, dungeon_3_len-dungeon_3
			!byte dungeon_4_len-dungeon_4, dungeon_5_len-dungeon_5
			!byte dungeon_6_len-dungeon_6, dungeon_7_len-dungeon_7

; EXOMIZER PACKER END ADDRESSES, FIND THEM IN PACKER OUTPUT LIKE:
; "Phase 3: Generating output file" section, at "Writing "..." as prg, saving from $A000 to $A32C"
; IN THIS EXAMPLE: tables_file_end_lb = $2c, tables_file_end_hb = $a3
map_file_end_lb		!byte od_lb_end, d0_lb_end, $ec, $ec, $ec, $ec, $ec, $ec, $ec
map_file_end_hb		!byte od_hb_end, d0_hb_end, $6c, $6c, $6c, $6c, $6c, $6c, $6c

sprite_name_lb_idx	!byte <outdoorsprites, <dungeon_0_sprites, <dungeon_1_sprites
			!byte <dungeon_2_sprites, <dungeon_3_sprites, <dungeon_4_sprites
			!byte <dungeon_5_sprites, <dungeon_6_sprites, <dungeon_7_sprites

sprite_name_hb_idx	!byte >outdoorsprites, >dungeon_0_sprites, >dungeon_1_sprites
			!byte >dungeon_2_sprites, >dungeon_3_sprites, >dungeon_4_sprites
			!byte >dungeon_5_sprites, >dungeon_6_sprites, >dungeon_7_sprites

sprite_name_len_idx	!byte outdoorsprites_len-outdoorsprites, dungeon_0_sprites_len-dungeon_0_sprites
			!byte dungeon_1_sprites_len-dungeon_1_sprites, dungeon_2_sprites_len-dungeon_2_sprites
			!byte dungeon_3_sprites_len-dungeon_3_sprites, dungeon_4_sprites_len-dungeon_4_sprites
			!byte dungeon_5_sprites_len-dungeon_5_sprites, dungeon_6_sprites_len-dungeon_6_sprites
			!byte dungeon_7_sprites_len-dungeon_7_sprites

; EXOMIZER PACKER END ADDRESSES, FIND THEM IN PACKER OUTPUT LIKE:
; "Phase 3: Generating output file" section, at "Writing "..." as prg, saving from $A000 to $A32C"
; IN THIS EXAMPLE: tables_file_end_lb = $2c, tables_file_end_hb = $a3
sprite_file_end_lb	!byte od_sprites_lb_end, d0_sprites_lb_end, $85, $85, $85, $85, $85, $85, $85
sprite_file_end_hb	!byte od_sprites_hb_end, d0_sprites_hb_end, $59, $59, $59, $59, $59, $59, $59


charset_name_lb_idx	!byte <outdoorcharset, <dungeon_0_charset, <dungeon_1_charset
			!byte <dungeon_2_charset, <dungeon_3_charset, <dungeon_4_charset
			!byte <dungeon_5_charset, <dungeon_6_charset, <dungeon_7_charset

charset_name_hb_idx	!byte >outdoorcharset, >dungeon_0_charset, >dungeon_1_charset
			!byte >dungeon_2_charset, >dungeon_3_charset, >dungeon_4_charset
			!byte >dungeon_5_charset, >dungeon_6_charset, >dungeon_7_charset

charset_name_len_idx	!byte outdoorcharset_len-outdoorcharset, dungeon_0_charset_len-dungeon_0_charset
			!byte dungeon_1_charset_len-dungeon_1_charset, dungeon_2_charset_len-dungeon_2_charset
			!byte dungeon_3_charset_len-dungeon_3_charset, dungeon_4_charset_len-dungeon_4_charset
			!byte dungeon_5_charset_len-dungeon_5_charset, dungeon_6_charset_len-dungeon_6_charset
			!byte dungeon_7_charset_len-dungeon_7_charset

; EXOMIZER PACKER END ADDRESSES, FIND THEM IN PACKER OUTPUT LIKE:
; "Phase 3: Generating output file" section, at "Writing "..." as prg, saving from $A000 to $A32C"
; IN THIS EXAMPLE: tables_file_end_lb = $2c, tables_file_end_hb = $a3
charset_file_end_lb	!byte od_charset_lb_end, d0_charset_lb_end, $e1, $e1, $e1, $e1, $e1, $e1, $e1
charset_file_end_hb	!byte od_charset_hb_end, d0_charset_hb_end, $4c, $4c, $4c, $4c, $4c, $4c, $4c

dungeon_name		!scr "  dungeon @  "
rat_dungeon_name	!scr "   sewers    "
overworld_name		!scr "  overworld  "

dungeon_names_lo	!byte <overworld_name, <rat_dungeon_name, <dungeon_name, <dungeon_name, <dungeon_name, <dungeon_name
			!byte <dungeon_name, <dungeon_name, <dungeon_name
dungeon_names_hi	!byte >overworld_name, >rat_dungeon_name, >dungeon_name, >dungeon_name, >dungeon_name, >dungeon_name
			!byte >dungeon_name, >dungeon_name, >dungeon_name

;-----------------------------------------------------------
; raster routine - scroll rendering
; parameters:
;-----------------------------------------------------------
scrollirq
		sta areg
		stx xreg
		sty yreg
		jsr $2003	; TODO: Create overlapping IRQ to play music always at raster 0,
				; then rti again back to scrollirq after finishing music player processing.

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

+		sei
		jsr set_music_sprites_irq
		jsr initsort
		cli

		jsr draw_stats
		jmp scrollAndTransferCommonReturn


;-----------------------------------------------------------
; raster routine - room transfer
; parameters:
;-----------------------------------------------------------
transfer_irq
		sta areg
		stx xreg
		sty yreg
		jsr $2003	; TODO: Create overlapping IRQ to play music always at raster 0,
				; then rti again back to scrollirq after finishing music player processing.


		; Scroll state jump table
		lda transferstate
		cmp #state_transfer_unpack
		bne +
		jmp transferStateUnpack

+		cmp #state_transfer_draw_back
		bne +
		jmp transferStateDrawBack

+		cmp #state_transfer_draw_front
		bne +
		jmp transferStateDrawFront

+		cmp #state_transfer_end
		bne +
		jmp transferStateEnd

		;----------------------------------------------------------------
		; Transfer state exit, don't enter here unless transfer is done
		;----------------------------------------------------------------

+		sei
		jsr set_music_sprites_irq
		jsr initsort
		cli

		jsr draw_stats
		jmp scrollAndTransferCommonReturn

;-----------------------------------------------------------
; raster routine - Switch processing
; - Needed for the heavy processing it implies
; parameters:
;-----------------------------------------------------------
;switch_irq
;		sei
;		sta areg
;		stx xreg
;		sty yreg

;		jsr $2003

;		jsr change_switch_state

;		lda #PlayerStateInControl
;		sta PlayerState

;		jsr set_music_sprites_irq

;		ldy yreg
;		ldx xreg
;		lda areg
;		cli
;		rti

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
			sei
			lda #state_idle
			sta scrollstate
			lda #(62)
			sta xtablelo+player
			lda #1
			sta xtablehi+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			jmp scrollAndTransferCommonReturn

+
		jsr move_screen_left
		jmp scrollAndTransferCommonReturn

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
			sei
			lda #state_idle
			sta scrollstate
			lda #(26)
			sta xtablelo+player
			lda #0
			sta xtablehi+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			cli
+
		jmp scrollAndTransferCommonReturn

;---------------------------------------
; Scroll up
;---------------------------------------
scrollStateUp

		lda scroll_y
		cmp #192
		bne +
			; scroll finished
			sei
			lda #state_idle
			sta scrollstate
			lda #(216)
			sta ytable+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			cli
			jmp scrollAndTransferCommonReturn

+		jsr move_screen_up
		jmp scrollAndTransferCommonReturn

;---------------------------------------
; Scroll down
;---------------------------------------
scrollStateDown
		jsr move_screen_down
		lda scroll_y
		cmp #4
		bne +
			; scroll finished
			sei
			lda #state_idle
			sta scrollstate
			lda #(54)
			sta ytable+player
			jsr copy_screen
			jsr setup_enemies
			jsr draw_stats
			cli
+
		jmp scrollAndTransferCommonReturn


;---------------------------------------
; Transfer state init
;---------------------------------------
transferStateUnpack

		jsr unpack_next_screen
		lda #state_transfer_draw_back
		sta transferstate
		jsr handle_persistent_changes
		jmp scrollAndTransferCommonReturn


;---------------------------------------
; Transfer state draw background
;---------------------------------------
transferStateDrawBack
		lda #0
		ldx #0
-			sta xtablelo,x
			sta xtablehi,x
			sta ytable,x
			inx
			cpx #15
			bne -

		jsr draw_screen
		jsr swap_screen

		lda #state_transfer_draw_front
		sta transferstate
		jmp scrollAndTransferCommonReturn


;---------------------------------------
; Transfer state draw foreground
;---------------------------------------
transferStateDrawFront
		jsr draw_stats
		jsr copy_screen
		jsr swap_screen

		lda #state_transfer_end
		sta transferstate
		jmp scrollAndTransferCommonReturn


;---------------------------------------
; Transfer state end
;---------------------------------------
transferStateEnd
		; Check dialogs
		ldy CurrentRoomIdx
		lda extensions,y
		; if ((a % $20) != 0) {
		cmp #$f0
		bcs +
		cmp #$80
		bcs +
		and #$20
		beq +
			lda extensions,y
			and #$1f
			sta capt_ptr
			lda #PlayerStateDialog
			jmp ++

+		; } else {
			lda #0
		; }
++		sta PlayerState
		jsr setup_enemies

		; set new player pos
		lda tmp_trans_xhi
		sta xtablehi+player
		lda tmp_trans_xlo
		sta xtablelo+player
		lda tmp_trans_y
		sta ytable+player

		lda #state_idle
		sta transferstate
		jmp scrollAndTransferCommonReturn


;---------------------------------------
; Scroll and transfer end
;---------------------------------------
scrollAndTransferCommonReturn

		lda $d011
		and #$1f
		sta $d011

		inc $d019	; acknowledge raster irq.
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

			lda PlayerAnimState
			and #3 ; Get direction no matter which state
			sta PlayerAnimState
			jmp +++	; Release all pressed keys
+
		and #kb_space ; Check for space key (see status screen)
		beq +
			lda KeyStopper
			and #$10
			bne +
			ora #$10
			sta KeyStopper

			lda #32
			sta PlayerBusyTimer
			lda #PlayerStateBusy
			sta PlayerState

			jsr draw_inventory
			jmp +++

+		lda ScanResult
		and #kb_a ; Check for A key (left)
		beq +
			ldx #1
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #player
			jsr get_tile_left_of_sprite
			stx plr_r_last_tilepos
			sta plr_r_last_tileidx

			ldx #PlayerRunWest
			stx PlayerAnimState

			; Check collision for tile in a
			jsr check_tile_collision
			cmp #ct_block
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_left player,1

			jmp +++

+		lda ScanResult
		and #kb_d ; Check for D key (right)
		beq +
			ldx #2
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #player
			jsr get_tile_right_of_sprite
			stx plr_r_last_tilepos
			sta plr_r_last_tileidx

			ldx #PlayerRunEast
			stx PlayerAnimState

			; Check collision for tile in a
			jsr check_tile_collision
			cmp #ct_block
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_right player,1

			jmp +++

+		lda ScanResult
		and #kb_w ; Check for W key (up)
		beq +
			ldx #3
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #player
			jsr get_tile_above_sprite
			stx plr_r_last_tilepos
			sta plr_r_last_tileidx

			ldx #PlayerRunNorth
			stx PlayerAnimState

			; Check collision for tile in a
			jsr check_tile_collision
			cmp #ct_block
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_up player,1

			jmp +++

+		lda ScanResult
		and #kb_s ; Check for S key (down)
		beq +
			ldx #4
			stx plr_r_ctrl_dir

			; Check if possible to move
			ldx #0
			ldx #player
			jsr get_tile_below_sprite
			stx plr_r_last_tilepos
			sta plr_r_last_tileidx

			ldx #PlayerRunSouth
			stx PlayerAnimState

			; Check collision for tile in a
			jsr check_tile_collision
			cmp #ct_block
			bcc ++	; branch if found a blocking tile
				jmp +++
++
			; Found a passable tile, move player
			+move_sprite_down player,1

			jmp +++

+		lda ScanResult
		and #kb_n ; Check for 'n' key (select next weapon)
		beq +

			; Select next weapon
			jsr select_next_weapon
			jmp +++

+		lda ScanResult
		and #kb_h ; Check for 'h' key (give a weapon)
		beq +

			lda #InvAxe
			sta SelWeapon
			ora Weapons
			sta Weapons
			inc StatsUpdated
			jmp +++

+		lda ScanResult
		and #kb_return ; Check for Return key (attack)
		bne +
		jmp +++
+			lda KeyStopper
			and #$20
			beq +
				rts
+				lda KeyStopper	; filter "Return" key for next repeat
				ora #$20
				sta KeyStopper
				jsr interact
				beq +++
				cmp #2
				beq +
					rts
+
				; At this point we can assume it is an attack
				+get_selected_weapon
				bne +
					lda #0
					rts	; reset keys if no sword
+				lda #10
				sta PlayerBusyTimer

				lda #<sword_swing
				ldy #>sword_swing
				ldx #14
				jsr $2006

				jsr player_start_attack
				rts
+++
		; Reset keystopper (both space and return)
		lda KeyStopper
		and #$cf
		sta KeyStopper
		rts


; --------------------------------------------
; --------------------------------------------
; SHORT UTILITY ROUTINES
; --------------------------------------------
; --------------------------------------------
interact
		jmp ($e000)
boss_behavior
		jmp ($e002)

; --------------------------------------------
; select_next_weapon
; Parameters: 	none
; Destroys:	a
; Returns:	a - selected weapon index
; --------------------------------------------
select_next_weapon
		lda SelWeapon
		asl
		cmp Weapons
		bcc +
		beq +
			lda #InvSword
			sta SelWeapon
			rts
+		sta SelWeapon
		rts
; --------------------------------------------



; --------------------------------------------
; get_tile_left_of_sprite (spriteX-1)/16
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
;               x - Tile pos
; --------------------------------------------
get_tile_left_of_sprite

		lda xtablelo,x
		sec
		sbc #xoffset+1	; remove the xoffset: spriteX = (spriteX - offx - 1)
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
		sbc #yoffset-8	; remove the yoffset, but compensate for the sprite center
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
		rts

; --------------------------------------------
; get_tile_right_of_sprite
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
;               x - Tile pos
; --------------------------------------------
get_tile_right_of_sprite

		lda xtablelo,x
		sec
		sbc #xoffset-16	; first remove the xoffset-16
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
		sbc #yoffset-8	; remove the yoffset, but compensate for sprite center
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
		rts

; --------------------------------------------
; get_tile_above_sprite
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
;               x - Tile pos
; --------------------------------------------
get_tile_above_sprite

		lda xtablelo,x
		sec
		sbc #xoffset-8	; remove the xoffset, center the sprite
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

		lda ytable,x
		sec
		sbc #yoffset+1	; remove the yoffset
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
		rts

; --------------------------------------------
; get_tile_below_sprite
; Destroys:	x, y, a
; Parameters: 	x - sprite index
; Return value: a - Tile ID
;               x - Tile pos
; --------------------------------------------
get_tile_below_sprite

		lda xtablelo,x
		sec
		sbc #xoffset-8	; remove the xoffset, center the sprite
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

		lda ytable,x
		sec
		sbc #yoffset-16	; remove the yoffset
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
		rts
; --------------------------------------------

;-----------------------------------------------------------
; check_tile_collision
; destroys registers a,x
; parameters: a - tile type
; 
;-----------------------------------------------------------
check_tile_collision
		tax
		lda collision_map,x
		sta plr_r_ctrl_coll
		rts


;-----------------------------------------------------------
; calc_individual_forces
; destroys registers a,x,y
; postcondition: if tmp != 0 then forces were calculated
;-----------------------------------------------------------
calc_individual_forces	; $1229


		lda #0
		sta tmp
		ldx #0

		; Take a backup of player's coordinates
		ldy xtablehi+player
		sty tmp_preforce_x_hi
		ldy xtablelo+player
		sty tmp_preforce_x_lo
		ldy ytable+player
		sty tmp_preforce_y

		; Check player's forces
		lda PlayerPullForceX
		beq +++	; if it's zero, skip this
		bpl +
			; it's negative ($fa), so the value must be inverted and carry must be set (two's complement)
			ldy #1
			sty tmp
			inc PlayerPullForceX
			ldy xtablehi+player
			sty tmp_preforce_x_hi
			dec xtablehi+player	; borrow 1, carry will compensate it
			sec
			jmp ++

+			; it's positive, just add it
			ldy #2
			sty tmp
			ldy xtablehi+player
			sty tmp_preforce_x_hi
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
		ldx #player
		cmp #1
		bne +	; x force was negative

			jsr get_tile_left_of_sprite
			jsr check_tile_collision
			cmp #ct_block
			bcc +++
				jsr reset_plr_x_coords
+++				jmp ++
+		cmp #2 ; x force was positive
		bne +

			jsr get_tile_right_of_sprite
			jsr check_tile_collision
			cmp #ct_block
			bcc +++
				jsr reset_plr_x_coords
+++				jmp ++
+		cmp #3 ; y force was negative
		bne +

			jsr get_tile_above_sprite
			jsr check_tile_collision
			cmp #ct_block
			bcc +++
				jsr reset_plr_y_coords
+++				jmp ++
+
		; y force was positive

			jsr get_tile_below_sprite
			jsr check_tile_collision
			cmp #ct_block
			bcc ++
				jsr reset_plr_y_coords
++

; ------------------------------------------

		rts ; TODO: Skip mob forces for now, seems to not be working so well with frame skipping
		lda MobsPresent
		bne +
		rts
+		sta tmp
		tax

		; do {
-			dex
			lda enemy_pull_force_x,x
			beq +++ ; skip if zero
			inc ForcesPresent
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
			inc ForcesPresent
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

reset_plr_x_coords
		lda tmp_preforce_x_lo
		sta xtablelo+player
		lda tmp_preforce_x_hi
		sta xtablehi+player
		lda #0
		sta PlayerPullForceX
		rts

reset_plr_y_coords
		lda tmp_preforce_y
		sta ytable+player
		lda #0
		sta PlayerPullForceY
		rts

tmp_preforce_x_lo
		!byte $00
tmp_preforce_x_hi
		!byte $00
tmp_preforce_y
		!byte $00

;-----------------------------------------------------------
; check_player_enemy_collision
; parameters (addresses):
; - xtablelo_a+1
; - xtablehi_a+1
; - ytable_a+1
; returns: a=1 if collision with enemy, a=>2 if collision with loot, 0 if no collision
;-----------------------------------------------------------
check_player_enemy_collision

		lda xtablelo+player
		sec
		sbc xtablelo+enemy,x
		tay
		lda xtablehi+player
		sbc xtablehi+enemy,x
		bpl +
		; difference is negative, how far?

			; if (a >= -11) then {
			cmp #$ff
			bne ++
			cpy enemy_negx_size	; check hitbox size
			bcs +++
				jmp ++	; exit a=0
+++				; else
				; collision in X, check also Y
				jmp +++
			; }

+			; difference is positive, how far?

			; if (a <= 12) then {
			cmp #$00
			bne ++
			cpy enemy_posx_size	; check hitbox size
			bcc +++
				jmp ++	; exit a=0
+++				; else
				; collision in X, check also Y
			; }
		lda ytable+player
		sec
		sbc ytable+enemy,x	; a = object_a - enemy_y[x];
		bcs +
		; difference is negative, how far?

			; if (a >= -11) then {
			cmp enemy_negy_size	; check hitbox size
			bcs +++
				jmp ++	; exit a=0
+++				; else
				; collision in Y too, return with 1 or higher (depending on loot type)
				lda frame+enemy+16,x     ; contains loot type (80 is heart, 81 is coins, 82 is key)
				;lda #1
				rts
			; }

+			; difference is positive, how far?

			; if (a <= 12) then {
			cmp enemy_posy_size	; check hitbox size
			bcc +++
				jmp ++	; exit a=0
+++				; else
				; collision in Y too, return with success
				lda frame+enemy+16,x     ; contains loot type (if applicable)
				;lda #1
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
++++			cpy enemy_negx_size
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
++++			cpy enemy_posx_size
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
			cmp enemy_negy_size
			bcs +++
				jmp ++	; exit with a=0
+++				; else
				; collision in Y too, return with success
				jmp check_enemy
			; }

+			; difference is positive, how far?

			; if (a < 16) then {
			cmp enemy_posy_size
			bcc +++
				jmp ++	; exit with a=0
+++				; else
				; collision in Y too, return with success
				jmp check_enemy
			; }
++

		lda #$00
		rts
check_enemy
		lda enemy_state,x	; check if enemy is alredy being hurt or is dying
		cmp #EnemyHit
		beq +			; and if so, don't hurt anymore, exit with a=0
		cmp #EnemyDying
		beq +
			lda #EnemyHit
			sta enemy_state,x
			lda #32
			sta enemy_timer,x
			lda enemy_hp,x
			sec
			sbc PlayerWeaponPower
			sta enemy_hp,x
			bcs ++
				lda #0
				sta enemy_hp,x
				lda #EnemyDying			; Player has slain the enemy
				sta enemy_state,x
				lda #EnemyDyingAnim
				sta enemy_anim_state,x
				lda #24
				sta enemy_timer,x
++
		inx
		txa
		dex
		rts
+		lda #0
		rts

;-----------------------------------------------------------
; decrease_hp
; Removes 'a' units from player's HP stat (damage)
; NOTE: a shall contain a BCD value
; If result is negative, then carry will be cleared
; params: a (hp increase value)
; destroys registers: a
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
; params: a (hp increase value)
; destroys registers: a
;-----------------------------------------------------------
increase_hp
		sta tmp_hp_digits

		; OR high and low BCD bytes of HP together
		lda player_hp
		asl
		asl
		asl
		asl
		ora player_hp+1

		clc
		sed
		adc tmp_hp_digits
		cld

		bcs +	; if no overflow and player_max_hp - tmp_hp_digits >= 0:
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

+		; else:
		rts
		; end if

;-----------------------------------------------------------
; increase_max_hp
; Adds "a" units to player's maximum HP stat
; NOTE: a shall contain a BCD value
; params: a (max HP increase value)
; destroys registers: a
;-----------------------------------------------------------
increase_max_hp
		; OR high and low byte values together
		sta tmp_hp_digits
		lda player_max_hp
		asl
		asl
		asl
		asl
		ora player_max_hp+1

		clc
		sed
		adc tmp_hp_digits
		cld

		; if carry clear:
		bcs +
			sta tmp_hp_digits
			and #$f0
			lsr
			lsr
			lsr
			lsr
			sta player_max_hp
			lda tmp_hp_digits
			and #$0f
			sta player_max_hp+1
+		; else:
			rts
		; end if

;-----------------------------------------------------------
; decrease_gold
; Pay 'a' coins from player's gold
; NOTE: a shall contain a BCD value (2 digits)
; If result is negative (<0), then carry will be cleared
;-----------------------------------------------------------
decrease_gold
		sta tmp_gold_incr	; store a

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

		; subtract from digits 4 and 3, as in joining $0a and $0b into $ab.
		lda player_gold+3
		asl
		asl
		asl
		asl
		ora player_gold+4	; joined digit positions 4 and 3

		sed			; set decimal mode

		sec
		sbc tmp_gold_incr	; subtract 
		bcs +
			lda #0		; avoid number becoming negative when sbc overflows
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
			lda #9		; maxed out gold? :-)
			sta player_gold
			sta player_gold+1
			sta player_gold+2
			sta player_gold+3
			sta player_gold+4
			cld
			rts
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

; -----------------------------------------------
; Mini table for indexing tile rows (20 per row)
; -----------------------------------------------
get_index_from_map_coords
		!byte $00,$14,$28,$3c,$50,$64,$78,$8c
		!byte $a0,$b4,$c8,$dc



; --------------------------------------------
; LOOKUP TABLES END
; --------------------------------------------


; --------------------------------------------
; get_random
; gets a random byte value in register a.
; destroys registers: a
; parameters: x1 - seed (optional)
; returns: a - random number
; --------------------------------------------
get_random
		inc x1
		clc

x1		= * + 1
		lda #$00	;x1

c1		= * + 1
		eor #$c2	;c1

a1		= * + 1
		eor #$11	;a1
		sta a1

b1		= * + 1
		adc #$37	;b1
		sta b1
		lsr
		eor a1
		adc c1
		sta c1
		rts

; --------------------------------------------
; get_door_target_location
; - Returns:    a - door target location on map
;               x - screen pos
;               y - doortablemulti offset index if applicable
; --------------------------------------------
get_door_target_location

		; Get screens array location!
		;-----------------------------

		; store direction
		stx tmp3

		; All these rows mean: a = offy * 16 / 12 => transform map coordinate to screen tile pos/index (when seen as continuous array)
;		lda offy
;		jsr transform_a_mul_16_div_12
;		sta tmp

		; This is a = offx / 20
;		ldy #$ff
;		ldx offx+1
;		lda offx
;-			iny
;			sec
;			sbc #20
;			bcs -
;			dex	; offx is 16 bits so check that bit 8 is also subtracted from
;			bpl -
;		tya
;		clc
;		adc tmp		; x = offy * 4 / 3 + offx / 20 == screen pos!
;		tax		; -------------------------------------------
;		sta tmp

		ldx CurrentRoomIdx
		stx tmp

		; x = screen pos of door

		; Use x now to fetch current screen location in door table
doorcheck
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

			; As we iterate x=x+1 and while x < 0, y is incremented to the memory offset 
			; as soon as x hits 0. Then y has the correct offset.
			ldy #$ff
			cpx #0
			beq ++
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
					bne -
				; }
				iny
				sty tmp2	; store doortablemulti byte offset calculated from "door set" offset
			;}
++
			jsr get_entered_door_index	; returns y as correct offset to doortablemulti
			tax
			lda doortablemulti,y
			rts

+		; } else {
       			; (a >= $f0)
			; target location is a dungeon or just another room
			; return a
		; }
		rts

doorbuf		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	; 8 doors max


;-----------------------------------------------------------
; get_entered_door_index
; - destroys all registers
; - parameters:
;       tmp2    - 
; - returns:
;	a	- screen tile location where door was found
;	y	- index in doortablemulti where door was found
; ---------------------------------------------------------------
get_entered_door_index
		; Prepare list of door positions, "doorbuf", to map with doortablemulti
		ldx #0
		ldy #0
-			lda tilebuffer,x
			cmp #TileHatch
			beq +
			cmp #TileDoor
			beq +
--			inx
			cpx #240
			bne -

		; end loop
		lda #$ff
		sta doorbuf,y
		jmp ++

+				; Store position
				txa
				sta doorbuf,y
				iny
				jmp --

++		ldx #0
		ldy tmp2
-			lda doorbuf,x
			cmp #$ff
			beq +
			cmp plr_r_last_tilepos
			beq +
			inx
			iny
			bne -
+		rts

;get_entered_door_index
;               old code:
;		ldx #0
;		ldy #0
;-			lda tilebuffer,x
;			cmp #13 ; type = a; index = x;
;			beq save_door_type ;   save_door_type(pos);
;			cmp #14
;			beq save_door_type
;--			inx
;			cpx #240
;			bne -
;		jmp ++
;		; -------------------------------------------------------------------------
;save_door_type
;				txa
;				sta doorbuf,y	; fill in positions where doors were found.
;				iny
;				jmp --
;		; -------------------------------------------------------------------------
;++
;		ldx #$ff
;		ldy tmp3	; check direction
;		cpy #1		; west
;		bne ++
;			dec tmp
;++		cpy #2		; east
;		bne ++
;			inc tmp
;++		cpy #3		; north
;		bne ++
;			lda tmp
;			sec
;			sbc #20
;			sta tmp
;++		cpy #4		; south
;		bne +
;			lda tmp
;			sec
;			sbc #20
;			sta tmp
;++
;-		; do {
;			inx
;			cpx #$08
;			bne +
;				rts
;+			lda doorbuf,x
;			cmp tmp		; compare with current position
;			beq ++		; if found, return a, x
;			lda #$ff
;			cmp tmp
;			bne -
;		; while (a != #$ff);
;
;		ldx #$ff
;++		rts
; --------------------------------------------



; --------------------------------------------
; transform_a_div_16_mul_12
; - Used to convert a 240 element room index
;   starting at each row: 0, 16, 32, 48, 64, 80, 96, 128, 144, 160, 176, 192
;   to a 16 pixel stepped map y coordinate.
; Destroys y
; Returns a = a / 16 * 12
; --------------------------------------------
transform_a_div_16_mul_12

		; All these rows mean: a = a / 16 * 12
		tay
		lda #0
		cpy #$10
		bcc +		; if offy < 12 goto +
		adc #11		; adding actually 12 here, carry is always set!
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
; - Used to convert map offset y coordinate to a 240 element room index
;   starting at each row: 0, 16, 32, 48, 64, 80, 96, 128, 144, 160, 176, 192
; Destroys y,a
; Returns a = a * 16 / 12
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


;-----------------------------------------------------------
; swap_screen
;  - Hides visible screen and makes it back buffer
;  - Shows back buffer and makes it the visible screen
;  - screen_id=0 => screen @ $4400
;  - screen_id=1 => screen @ $4000
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
	lda #txt_sp
-	sta $43bf,x
	sta $47bf,x
	dex
	bne -
	rts


;-----------------------------------------------------------
; loader
;  disk load and unpack routine
; preconditions:
;    - kernal rom must be visible ($36 in address $01)
; parameters: fname 	- byte sequence of 40 chars
;           : fname_len - file name length
;           : zp_dest_lo- decrunch destination address
;           : zp_dest_hi- decrunch destination address
; destroys registers: a, x, y
;-----------------------------------------------------------
;-------------------------------
fname		= tmp_addr
fname_len	!byte $00
;-------------------------------

;-------------------------------
; just return from interrupt asap
loadirq
		inc $d019
		pla
		tay
		pla
		tax
		pla
		rti
flashload
		inc $d020
		dec $d020
		jmp $f6ed
;-------------------------------

load_file
		lda #<flashload
		sta $0328
		lda #>flashload
		sta $0329
		lda fname_len
		ldx fname
		ldy fname+1
		jsr $ffbd     ; call setnam

		lda #$01      ; file number 1
		ldx last_device; last used device number
		stx $ba
		bne +
		ldx #$08      ; default to device 8
+		ldy #$01      ; load to address stored in file
		jsr $ffba     ; call setlfs

		lda #$00
		jsr $ffd5     ; call LOAD
check_error	bcs load_error    ; if carry set, the file could not be opened

		; check drive error channel here to test for
		; file not found error etc.

		rts
;-------------------------------
load_error
		; A = $05 (DEVICE NOT PRESENT)
		; A = $04 (FILE NOT FOUND)
		; A = $1D (LOAD ERROR)
		; A = $00 (BREAK, RUN/STOP has been pressed during loading)
		jsr hex_error
		lda #$02
		sta $d020	; red color will indicate error
		jmp *
		rts
;-------------------------------


; -----------------
; -- exodecrunch --
; -----------------

; -------------------------------------------------------------------
; zero page addresses used
; -------------------------------------------------------------------
zp_len_lo = $a7
zp_len_hi = $a8

zp_src_lo  = $ae
zp_src_hi  = zp_src_lo + 1

zp_bits_hi = $fc

zp_bitbuf  = $fd
zp_dest_lo = zp_bitbuf + 1      ; dest addr lo
zp_dest_hi = zp_bitbuf + 2      ; dest addr hi

tabl_bi = decrunch_table
tabl_lo = decrunch_table + 52
tabl_hi = decrunch_table + 104
loading_text	!scr "   loading   "
decr_text	!scr "  depacking  "

destination_lo	= *
destination_hi  = * + 1
		!word $0000

;LITERAL_SEQUENCES_NOT_USED = 0

; -------------------------------------------------------------------
; disable interrupts, disable decimal mode, init disk loader
loader
		sei
		lda #$7f
		sta $dc0d
		sta $dd0d
		cld
		lda #0
		sta $d015	; disable sprites, they can hang loading...
				; ...serial data reception from disk drive in desync?

		; As we play with kernal, we need to short circuit the interrupt
		lda #<loadirq
		sta $0314
		lda #>loadirq
		sta $0315

		lda #$36	; enable kernal
		sta $01

		lda $dd0d
		inc $d019
		cli

		jsr load_file

		sei		; stop all interrupts now
		lda #$35	; disable kernal again
		sta $01

		lda #$7f
		sta $dc0d
		sta $dd0d

		rts

; --------------------------------------
; load_text - prints loading status
; x - text low byte
; y - text high byte
; destination_lo, destination_hi -
;   Chosen dungeon from dungeon_names_lo
;   and dungeon_names_hi.
; --------------------------------------
load_text
		stx load_txt+1
		sty load_txt+2
		lda destination_lo
		sta dest_txt+1
		lda destination_hi
		sta dest_txt+2
		ldy #0
-			lda #32
			sta $41c6,y
			sta $423e,y
load_txt		lda $0000,y
			sta $41ee,y
dest_txt		lda $0000,y
			cmp #0
			bne +
			lda MapID
			clc
			adc #num_start
+			sta $4216,y
			lda #1
			sta $d9ee,y
			sta $da16,y
			iny
			cpy #13
			bne -
		rts

; --------------------------------------
; caption_text - prints message
; a - text len
; x - text low byte
; y - text high byte
; --------------------------------------
caption_text

		stx capt_txt+1
		sty capt_txt+2
		tax
		dex

		; calculate text start
		lsr	; a = text len / 2

		; a = 20 + a
		clc
		adc #19
		tay
-			lda #32
			sta $41b8,y
			sta $4208,y
capt_txt		lda $0000,x
			sta $41e0,y
			lda #1
			sta $d9e0,y
			dey
			dex
			bpl -
		rts
capt_ptr	!byte $00


; --------------------------------------
; hex output in corner
; --------------------------------------
hex_error
		pha
		and #$0f
		tay
		lda hextable,y
		sta $4001
		pla
		and #$f0
		tay
		lda hextable,y
		sta $4000
		lda #1
		sta $d800
		rts
hextable
		!byte 48,49,50,51,52,53,54,55
		!byte 56,57,1,2,3,4,5,6
; --------------------------------------
; get crunched byte routine
; --------------------------------------
get_crunched_byte
	lda _byte_lo
	bne _byte_skip_hi
	dec _byte_hi
_byte_skip_hi
	dec _byte_lo
_byte_lo = * + 1
_byte_hi = * + 2
	lda $ffff		; needs to be set correctly before
	inc $d020
	dec $d020
	rts			; decrunch_file is called.
; end_of_data needs to point to the address just after the address
; of the last byte of crunched data.
; -------------------------------------------------------------------

; exodecrunch starts here
; --------------------------------------
        ;; refill bits is always inlined
!macro mac_refill_bits {
        pha
        jsr get_crunched_byte
        rol
        sta zp_bitbuf
        pla
}

!macro mac_get_bits {
        jsr get_bits
}

get_bits
        adc #$80                ; needs c=0, affects v
        asl
        bpl gb_skip
gb_next
        asl zp_bitbuf
        bne gb_ok
        +mac_refill_bits
gb_ok
        rol
        bmi gb_next
gb_skip
        bvs gb_get_hi
        rts
gb_get_hi
        sec
        sta zp_bits_hi
        jmp get_crunched_byte
; -------------------------------------------------------------------
; no code below this comment has to be modified in order to generate
; a working decruncher of this source file.
; However, you may want to relocate the tables last in the file to a
; more suitable address.
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; jsr this label to decrunch, it will in turn init the tables and
; call the decruncher
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
decrunch
; -------------------------------------------------------------------
; init zeropage, x and y regs. (12 bytes)
;
        ldy #0
        ldx #3
init_zp
        jsr get_crunched_byte
        sta zp_bitbuf - 1,x
        dex
        bne init_zp
; -------------------------------------------------------------------
; calculate tables (62 bytes) + get_bits macro
; x and y must be #0 when entering
;
        clc
table_gen
        tax
        tya
        and #$0f
        sta tabl_lo,y
        beq shortcut            ; start a new sequence
; -------------------------------------------------------------------
        txa
        adc tabl_lo - 1,y
        sta tabl_lo,y
        lda zp_len_hi
        adc tabl_hi - 1,y
shortcut
        sta tabl_hi,y
; -------------------------------------------------------------------
        lda #$01
        sta <zp_len_hi
        lda #$78                ; %01111000
        +mac_get_bits
; -------------------------------------------------------------------
        lsr
        tax
        beq rolled
        php
rolle
        asl zp_len_hi
        sec
        ror
        dex
        bne rolle
        plp
rolled
        ror
        sta tabl_bi,y
        bmi no_fixup_lohi
        lda zp_len_hi
        stx zp_len_hi
        !byte $24
no_fixup_lohi
        txa
; -------------------------------------------------------------------
        iny
        cpy #52
        bne table_gen
; -------------------------------------------------------------------
; prepare for main decruncher
        ldy zp_dest_lo
        stx zp_dest_lo
        stx zp_bits_hi
; -------------------------------------------------------------------
; copy one literal byte to destination (11 bytes)
;
literal_start1
        tya
        bne no_hi_decr
        dec zp_dest_hi
no_hi_decr
        dey
        jsr get_crunched_byte
        sta (zp_dest_lo),y
; -------------------------------------------------------------------
; fetch sequence length index (15 bytes)
; x must be #0 when entering and contains the length index + 1
; when exiting or 0 for literal byte
next_round
        dex
        lda zp_bitbuf
no_literal1
        asl
        bne nofetch8
        jsr get_crunched_byte
        rol
nofetch8
        inx
        bcc no_literal1
        sta zp_bitbuf
; -------------------------------------------------------------------
; check for literal byte (2 bytes)
;
        beq literal_start1
; -------------------------------------------------------------------
; check for decrunch done and literal sequences (4 bytes)
;
        cpx #$11
        bcs exit_or_lit_seq
; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (18(11) bytes) + get_bits macro
;
        lda tabl_bi - 1,x
        +mac_get_bits
        adc tabl_lo - 1,x       ; we have now calculated zp_len_lo
        sta zp_len_lo
        lda zp_bits_hi
        adc tabl_hi - 1,x       ; c = 0 after this.
        sta zp_len_hi
; -------------------------------------------------------------------
; here we decide what offset table to use (27(26) bytes) + get_bits_nc macro
; z-flag reflects zp_len_hi here
;
        ldx zp_len_lo
        lda #$e1
        cpx #$03
        bcs gbnc2_next
        lda tabl_bit,x
gbnc2_next
        asl zp_bitbuf
        bne gbnc2_ok
        tax
        jsr get_crunched_byte
        rol
        sta zp_bitbuf
        txa
gbnc2_ok
        rol
        bcs gbnc2_next
        tax
; -------------------------------------------------------------------
; calulate absolute offset (zp_src) (21 bytes) + get_bits macro
;
        lda #0
        sta zp_bits_hi
        lda tabl_bi,x
        +mac_get_bits
        adc tabl_lo,x
        sta zp_src_lo
        lda zp_bits_hi
        adc tabl_hi,x
        adc zp_dest_hi
        sta zp_src_hi
; -------------------------------------------------------------------
; prepare for copy loop (2 bytes)
;
pre_copy
        ldx zp_len_lo
; -------------------------------------------------------------------
; main copy loop (30 bytes)
;
copy_next
        tya
        bne copy_skip_hi
        dec zp_dest_hi
        dec zp_src_hi
copy_skip_hi
        dey
!ifndef LITERAL_SEQUENCES_NOT_USED {
        bcs get_literal_byte
}
        lda (zp_src_lo),y
literal_byte_gotten
        sta (zp_dest_lo),y
        dex
        bne copy_next
        lda zp_len_hi
begin_stx
        stx zp_bits_hi
        beq next_round
copy_next_hi
        dec zp_len_hi
        jmp copy_next
!ifndef LITERAL_SEQUENCES_NOT_USED {
get_literal_byte
        jsr get_crunched_byte
        bcs literal_byte_gotten
}
; -------------------------------------------------------------------
; exit or literal sequence handling (16(12) bytes)
;
exit_or_lit_seq
!ifndef LITERAL_SEQUENCES_NOT_USED {
        beq decr_exit
        jsr get_crunched_byte
        sta zp_len_hi
        jsr get_crunched_byte
        tax
        bcs copy_next
decr_exit
}
        rts
; -------------------------------------------------------------------
; the static stable used for bits+offset for lengths 3, 1 and 2 (3 bytes)
; bits 4, 2, 4 and offsets 16, 48, 32
tabl_bit
	!byte %11100001, %10001100, %11100010
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; this 156 byte table area may be relocated. It may also be clobbered
; by other data between decrunches.
; -------------------------------------------------------------------
decrunch_table
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        !byte 0,0,0,0,0,0,0,0,0,0,0,0
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------

;-----------------------------------------------------------
; setup - set custom character set and border colors
;
;-----------------------------------------------------------
setup
		; Set player inventory data
		lda #0
		ldx #0
		sta SelWeapon
		sta Weapons
		sta Items
		sta ArrowQ
		sta ArmorQ
		sta NecklaceQ
-		sta BossesLooted,x
		inx
		cpx #8
		bne -

		; Set Player sprite color (indicates armor or special power)
		lda #PlayerPowerNormal
		sta PlayerPowerState

		lda #1
		sta PlayerWeaponPower
softsetup
		jsr gen_tilepos_tables
		jsr clear_coretable_vars
		jsr gen_sine_table

		; set charset at $4800, screen at $4000
		lda #$02
		sta $d018

		; set multicolor mode
		lda $d016
		ora #$10
		and #$17
		sta $d016

		; reset sprite positions
		lda #0
		ldx #15
-			sta xtablelo,x
			sta xtablehi,x
			sta ytable,x
			dex
			bpl -

		; set screen offset on map [ x = map ID]
		; Check from which map we came. PrevMapID multiplied by 8 and added to MapID
		; as index to MapStartX, MapStartHiX, MapStartY, StartPosX, StartPosY, etc as they are fetched.
		clc
		ldx PrevMapID
		
		lda MapID
		sta PrevMapID	; Now that we've used PrevMapID, we can store the new MapID there.

		lda MapStartX,x
		sta offx
		lda MapStartHiX,x
		sta offx+1
		lda MapStartY,x
		sta offy

		; set background colors
		lda BorderColor
		sta $d020
		lda BGColor
		sta $d021
		lda MultiColor1
		sta $d022
		lda MultiColor2
		sta $d023

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
		sta ForcesPresent

		jsr unpack_next_screen
		jsr handle_persistent_changes

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

		lda #<maininter
		sta $fffe
		lda #>maininter
		sta $ffff

		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011
		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.
		;lda $dd0d	; acknowledge pending irqs.

		rts

;-----------------------------------------------------------

;-----------------------------------------------------------
; set_transfer_irq - set transfer raster interrupt
;
;-----------------------------------------------------------
set_transfer_irq
		sei

		lda #<transfer_irq
		sta $fffe
		lda #>transfer_irq
		sta $ffff

		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011
		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.
		lda $dd0d	; acknowledge pending irqs.

		jsr initsort
		cli

		rts

;-----------------------------------------------------------

;-----------------------------------------------------------
; set_switch_irq - set switch processing raster interrupt
;
;-----------------------------------------------------------
;set_switch_irq
;		sei

;		lda #<switch_irq
;		sta $fffe
;		lda #>switch_irq
;		sta $ffff

;		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
;		sta $d011
;		lda #$00	; Set main interrupt to happen at line 32
;		sta $d012

;		inc $d019	; acknowledge raster irq.
;		lda $dc0d	; acknowledge pending irqs.
		;lda $dd0d	; acknowledge pending irqs.

;		cli

;		rts

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
++			jmp +++	; Unpack RLE encoded screen data from offx and offy

+		cmp #state_scroll_right
		bne +
			lda offx+1
			pha
			lda offx
			pha
			clc
			adc #20
			sta offx
			bcc +++
			inc offx+1
+++			jsr unpack_next_screen
			pla
			sta offx
			pla
			sta offx+1
			jmp ++

+		cmp #state_scroll_up
		bne +
			lda offy
			pha
			sec
			sbc #12
			jmp +++

+		cmp #state_scroll_down
		bne ++
			lda offy
			pha
			clc
			adc #12
+++			sta offy
			jsr unpack_next_screen
			pla
			sta offy
++
		; apply changes to the tilebuffer originating from switches
		jsr handle_persistent_changes

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
		lda $dd0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		cli

		rts

;-----------------------------------------------------------


;-----------------------------------------------------------
; handle_persistent_changes - changes any tiles on screen
;                             which where earlier triggered
;                             by a switch.
; destroys registers: yes!
;-----------------------------------------------------------
handle_persistent_changes
		; Handle persistent changes to tiles on each map here
		ldy MapID
		lda pc_map_idx,y
		clc
		adc #<pc_target_list_base
		sta tmp_addr
		lda #>pc_target_list_base
		adc #0
		sta tmp_addr+1

		; Update any tiles triggered from switches, etc...
		ldy #0
target_list_loop	lda (tmp_addr),y	; Load target room position
			iny
			cmp #$ff		; Was last position?
			bne +
			jmp ds_exit_target_loop

+			cmp CurrentRoomIdx	; Is target room position the current room?
			beq continue_target
				iny
				iny
				jmp target_list_loop	; No, check next items in target list

continue_target		lda (tmp_addr),y	; Load tile position
			iny
			tax			; Store tile position in x
			lda (tmp_addr),y	; Load tile index
			iny
			sta tilebuffer,x

			jmp target_list_loop	; Check if more tiles need update
ds_exit_target_loop
		rts

;-----------------------------------------------------------
; -------------------------------------------------
spawn_loot
		ldx MobsPresent
		inc MobsPresent	; Allocate next free enemy slot for loot sprite.
		lda #0
		sta xtablehi+enemy,x
		sta xtablehi+enemy+16,x
		lda tmp_chest_loc
		+immediate_a_mod_n 20
		clc
		asl
		asl
		asl
		asl
		bcc +
			inc xtablehi+enemy,x
+		adc #xoffset
		sta xtablelo+enemy,x
		sta xtablelo+enemy+16,x
		bcc +
			inc xtablehi+enemy,x
+		lda xtablehi+enemy,x
		sta xtablehi+enemy+16,x
		lda tmp_chest_loc
		+immediate_a_div_by_n 20
		tya
		clc
		asl
		asl
		asl
		asl
		adc #yoffset
		sta ytable+enemy,x
		sta ytable+enemy+16,x
check_chests
		ldy CurrentRoomIdx
		lda extensions,y
		and #$1f		; filter out chest idx
		tay
		lda chests,y
		tay
		lda item_base,y		; load item frame fill data
		sta frame+enemy+16,x
		clc
		adc #4			; step to item frame contour data
		sta frame+enemy,x	
		lda item_base+1,y	; load item frame fill color
		sta color+enemy,x
		lda item_base+2,y	; load item frame contour color
		sta color+enemy+16,x

		lda #0
		sta loot_swap_pos

		lda #ChestLootRise
		sta enemy_state,x
		lda #EnemyRunSouth
		sta enemy_anim_state,x
		lda #32
		sta enemy_timer,x
		rts

;-----------------------------------------------------------
; draw_stats - show a stats bar on the top - use chars
; parameters: -
; return value: -
; destroys: a, x, y, C, Z, N
;-----------------------------------------------------------
draw_stats
		clc
		lda #1
		ldx #39	; set status text to white color
-		sta $dbc0,x
		dex
		bne -
		sta $dbc0

		lda #txt_sp	; set whitespace (clear) status bar
		ldx #39
-		sta $43c0,x
		dex
		bne -
		sta $43c0

		lda #txt_heart
		sta $43c2
		lda #2
		sta $dbc2

		ldx #0
		clc
		lda player_hp
		beq +
			adc #num_start
			sta $43c4,x
			inx
+
		lda player_hp+1
		clc
		adc #num_start
		sta $43c4,x
		inx

		lda #txt_slash
		sta $43c4,x
		inx

		lda player_max_hp
		beq +
			clc
			adc #num_start
			sta $43c4,x
			inx
+
		lda player_max_hp+1
		clc
		adc #num_start
		sta $43c4,x

		lda #txt_key
		sta $43ca
		lda #7
		sta $dbca

		lda #num_start
		sta $43cc

		lda #15
		sta $dbd0
		lda #txt_coin
		sta $43d0

		ldx #0
		lda player_gold
		beq +
			clc
			adc #num_start
			sta $43d2,x
			inx
+		lda player_gold+1
		bne ++
		cpx #0
		beq +
++			clc
			adc #num_start
			sta $43d2,x
			inx
+		lda player_gold+2
		bne ++
		cpx #0
		beq +
++			clc
			adc #num_start
			sta $43d2,x
			inx
+		lda player_gold+3
		bne ++
		cpx #0
		beq +
++			clc
			adc #num_start
			sta $43d2,x
			inx
+		lda player_gold+4
		clc
		adc #num_start
		sta $43d2,x

set_weapon_icons
		; Set weapon icons
		ldx #0
-			lda txt_weapons,x
			sta $43d8,x
			ldy weapon_idx,x
			jsr check_weapon_presence
			tay
			lda presence_colors,y
			sta $dbd8,x
			inx
			cpx #4
			bne -

set_inventory_icons
		; Set inventory icons
		ldx #0
-			lda txt_items,x
			sta $43dc,x
			ldy inv_idx,x
			jsr check_item_presence
			tay
			lda presence_colors,y
			sta $dbdc,x
			inx
			cpx #8
			bne -

		rts
weapon_idx
		!byte InvSword, InvAxe, InvBow, InvArrows
inv_idx
		!byte InvShield, InvGauntlet, InvUnknown1, InvArmor
		!byte InvRaft, InvRope, InvMasterKey, InvNecklace
txt_weapons
		!byte txt_sword, txt_axe, txt_bow, txt_arrow
txt_items
		!byte txt_shield, txt_gauntlet, txt_unknown1, txt_armor
		!byte txt_raft, txt_rope, txt_key2, txt_necklace

presence_colors
		!byte 6, 1, 5, 4

;-----------------------------------------------------------
; draw_inventory
;-----------------------------------------------------------
draw_inventory
		sei

		lda #<inventory_interrupt
		sta $fffe
		lda #>inventory_interrupt
		sta $ffff

		lda screen_id
		beq +
			jsr swap_screen
+
		ldx #0
		lda #$20
-			sta $4000,x
			sta $4400,x
			sta $4100,x
			sta $4500,x
			sta $4200,x
			sta $4600,x
			sta $42f8,x
			sta $46f8,x
			dex
			bne -

		; Text "Inventory"
		ldx #0
-			lda text_inv,x
			sta $4038,x
			lda #1
			sta $d838,x
			inx
			cpx #9
		bne -

		; Text "Items"
		ldx #0
-			lda text_items,x
			sta $40b1,x
			lda #1
			sta $d8b1,x
			inx
			cpx #7
		bne -

		; Text "Weapons"
		ldx #0
-			lda text_weapons,x
			sta $4240,x
			lda #1
			sta $da40,x
			inx
			cpx #9
		bne -

		lda #6
		sta $d021

		lda #52
		sta $d012

		; Set arrow looks
		;lda player_inv
		;and #InvMagicalArrows
		;asl
		;asl
		;asl
		;tax
		;lda arrow_color,x
		;sta inv_item_color0
		;sta inv_item_color1

		; Set necklace looks
		;lda player_inv
		;and #InvNecklacePower
		;asl
		;asl
		;asl
		;asl
		;asl
		;tax
		;lda necklace_color,x
		;sta inv_item_color0+1

		; Set armor looks
		;lda player_inv+1
		;and #InvMagicalArmor
		;asl
		;asl
		;asl
		;asl
		;asl
		;tax
		;lda armor_color,x
		;sta inv_item_color0+7

		; Turn off sprites and initialize their positions
		lda #0
		sta $d015
		ldx #0
		ldy #0
-			lda inv_sprite_pos,y
			sta $d000,x
			sta $d008,x
			inx
			inx
			iny
			cpy #4
			bne -

		;TODO: Testing
		lda #$ff
		sta player_inv
		lda #$ff
		sta player_inv+1


		; Check what items player has found (upper and lower inventory rows)
		ldx #0
		stx items_mask
		stx items_mask+1
-			lda player_inv
			bne +
				jmp ++
+			and inv_items,x
			beq +
				lda items_mask
				ora inv_masks,x
				sta items_mask
+			lda player_inv
			bne +
				jmp ++
+			and inv_items+4,x
			beq +
				lda items_mask+1
				ora inv_masks,x
				sta items_mask+1
+			inx
			cpx #4
			bne -
++
		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		cli

		jmp *
		rts



; -------------------------------------------------
; Inventory interrupt
;
; -------------------------------------------------
inventory_interrupt
		sta areg
		stx xreg
		sty yreg

		jsr $2003

		lda #120
		sta $d012

		lda #<inventory_interrupt0
		sta $fffe
		lda #>inventory_interrupt0
		sta $ffff

		; Turn off sprites but initialize their positions
		lda #0
		sta $d015
		lda #104
		ldx #$0f
-		sta $d000,x
		dex
		dex
		bpl -


		; Set color and image on upper half of inventory sprites
		ldx #0
-			lda inv_item_color0,x
			sta $d02b,x
			lda inv_item_color1,x
			sta $d027,x
			lda inv_sprites0,x
			sta $43fc,x
			lda inv_sprites1,x
			sta $43f8,x
			inx
			cpx #4
			bne -

		lda items_mask
		sta $d015

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		lda areg
		ldx xreg
		ldy yreg
		rti

inventory_interrupt0

		sta areg
		sty yreg
		stx xreg

		lda #52
		sta $d012

		lda #<inventory_interrupt
		sta $fffe
		lda #>inventory_interrupt
		sta $ffff

		; Turn off sprites but initialize their positions
		lda #0
		sta $d015
		lda #128
		ldx #$0f
-		sta $d000,x
		dex
		dex
		bpl -

		; Set color and image on upper half of inventory sprites
		ldx #0
-			lda inv_item_color0+4,x
			sta $d02b,x
			lda inv_item_color1+4,x
			sta $d027,x
			lda inv_sprites0+4,x
			sta $43fc,x
			lda inv_sprites1+4,x
			sta $43f8,x
			inx
			cpx #4
			bne -

		lda items_mask+1
		sta $d015

		lda PlayerState
		cmp #PlayerStateBusy
		bne +
			jsr player_busy
			jmp ++
+
		jsr read_keyboard
		lda ScanResult
		beq ++
			lda KeyStopper
			and #$10
			bne ++
				ora #$10
				sta KeyStopper

			lda #$1b	; Default settings, normal text mode, set raster high bit to 0
			sta $d011
			lda #$00	; Set main interrupt to happen at line 32
			sta $d012

			; Redraw screen
			jsr swap_screen
			jsr draw_screen
			jsr swap_screen

			; Reset sprites
			ldx #8
-				lda frame,x
				sta spritepointer,x
				lda frame+16,x
				sta spritepointer+4,x
				lda color,x
				sta $d027
				lda color+16,x
				sta $d02b
				dex
				bpl -
			sei
			lda #10
			sta PlayerBusyTimer
			lda #PlayerStateBusy
			sta PlayerState
			ldx #$ff
			txs
			jmp main_routine
++
		lda KeyStopper
		and #$ef
		sta KeyStopper

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.	; acknowledge pending irqs.

		lda areg
		ldx xreg
		ldy yreg
		rti

inventory_interrupt1
		sta areg
		sty yreg
		stx xreg
		lda areg
		ldx xreg
		ldy yreg
		rti

inventory_interrupt2
		sta areg
		sty yreg
		stx xreg
		lda areg
		ldx xreg
		ldy yreg
		rti

inv_sprite_pos	!byte $80,$a0,$c0,$e0
inv_items	!byte $18,$60,$01,$04,$08,$10,$20,$c0
inv_masks	!byte $11,$22,$44,$88
inv_item_color0	!byte $09,$07,$07,$01,$02,$02,$08,$05
inv_item_color1	!byte $0e,$09,$0c,$09,$07,$09,$0b,$0b
arrow_color	!byte $01,$08,$03
necklace_color	!byte $07,$05,$03
armor_color	!byte $0c,$07,$02
inv_sprites0	!byte f_bow,f_necklace,f_shield,f_masterkey,f_torch,f_gauntlet,f_raft,f_armor
inv_sprites1	!byte f_bow+4,f_necklace+4,f_shield+4,f_masterkey+4,f_torch+4,f_gauntlet+4,f_raft+4,f_armor+4
		!byte $00
		!byte $00

scroll_tile
		lda $4cd7
		sta scroll_tile_tmp
		lda $4cd6
		sta $4cd7
		lda $4cd5
		sta $4cd6
		lda $4cd4
		sta $4cd5
		lda $4cd3
		sta $4cd4
		lda $4cd2
		sta $4cd3
		lda $4cd1
		sta $4cd2
		lda $4cd0
		sta $4cd1
		lda $4cc7
		sta $4cd0

		lda $4cc6
		sta $4cc7
		lda $4cc5
		sta $4cc6
		lda $4cc4
		sta $4cc5
		lda $4cc3
		sta $4cc4
		lda $4cc2
		sta $4cc3
		lda $4cc1
		sta $4cc2
		lda $4cc0
		sta $4cc1
		lda scroll_tile_tmp
		sta $4cc0

		lda $4cdf
		sta scroll_tile_tmp
		lda $4cde
		sta $4cdf
		lda $4cdd
		sta $4cde
		lda $4cdc
		sta $4cdd
		lda $4cdb
		sta $4cdc
		lda $4cda
		sta $4cdb
		lda $4cd9
		sta $4cda
		lda $4cd8
		sta $4cd9
		lda $4ccf
		sta $4cd8

		lda $4cce
		sta $4ccf
		lda $4ccd
		sta $4cce
		lda $4ccc
		sta $4ccd
		lda $4ccb
		sta $4ccc
		lda $4cca
		sta $4ccb
		lda $4cc9
		sta $4cca
		lda $4cc8
		sta $4cc9
		lda scroll_tile_tmp
		sta $4cc8
		rts
scroll_tile_tmp
		!byte $00


; -------------------------------------------------
;  Generates the tilepos_lo and tilepos_hi tables
; -------------------------------------------------
gen_tilepos_tables
		; initialize vars
		ldx #0
		ldy #0
		lda #$40
		sty gen_tilepos_lo
		sta gen_tilepos_hi

		; loop through all columns in a row
-		lda gen_tilepos_lo
		sta $f000,x
		clc
		adc #2
		sta gen_tilepos_lo
		lda gen_tilepos_hi
		sta $f0f0,x
		adc #0
		sta gen_tilepos_hi
		inx
		cpx #240
		bne +
		rts

+		iny
		cpy #20
		bne -

		; jump to next row
		lda gen_tilepos_lo
		clc
		adc #$28
		sta gen_tilepos_lo
		lda gen_tilepos_hi
		adc #0
		sta gen_tilepos_hi
		ldy #0
		jmp -

gen_tilepos_lo	!byte $00
gen_tilepos_hi	!byte $00

; -------------------------------------------------
;  Clear the coretable variables
; -------------------------------------------------
clear_coretable_vars
		ldx #0
		lda #0
-		sta ytable,x
		sta ytable+256,x
		inx
		bne -
		rts

; -------------------------------------------------
;  Generate an approximate sine table
; -------------------------------------------------
gen_sine_table
		ldy #$3f
		ldx #$00

-		lda value
		clc
		adc delta
		sta value
		lda value+1
		adc delta+1
		sta value+1

		sta sine+$c0,x
		sta sine+$80,y
		eor #$ff
		sta sine+$40,x
		sta sine+$00,y

		lda delta
		adc #$10
		sta delta
		bcc +
			inc delta+1

+		inx
		dey
		bpl -

		rts

value		!word $00
delta		!word $00

;-----------------------------------------------------------
end_code_800
;-----------------------------------------------------------



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

		lda $ba
		sta last_device

		sei

		lda #$7f
		sta $dc0d	; Turn off CIA interrupts
		sta $dd0d

		cld		; clear decimal flag

		lda #$35	; Turn off kernal and basic
		sta $01
		;jsr generate_tables

		ldx #$ff
		txs		; reset stack pointer
		;ldx #0		; x = 0
		;stx $dc0e

		lda $dd00	; Set VIC bank to $4000-$7fff	; We want more sprites!
		and #$fe
		sta $dd00

		ldx #$02	; Fill zero page variable space with value $80 (128)
		lda #$80
-		sta $00,x
		inx
		bne -

		lda #12		; Set max multiplexed sprites to 12
		sta maxspr

		;lda #$ff
		;sta xspeed	; init x speed for sprites to $ff

		;lda #$01	; init y speed for sprites to $01
		;sta yspeed

		lda #$10	; init x difference to 10
		sta xdif
		lda #$f8	; init y difference to 9
		sta ydif

		; set initial map #
		lda #0
		sta MapID
		sta PrevMapID

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
;		ldy #0

;--		lda #80
;		ldx #8

;-		adc random_table,x
;		dex
;		adc $dc08
;		sta random_table,x
;		cpx #0
;		bne -

;		iny
;		bne --

main_routine
		ldx #1
		stx $d01a	; Enable raster interrupts

		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011

		lda #$00	; Set main interrupt to happen at line 32
		sta $d012

		; set main interrupt (sprite multiplexer)
		lda #<maininter
		sta $fffe
		lda #>maininter
		sta $ffff

		asl $d019	; ack IRQs
		lda $dc0d
		lda $dd0d

		cli
--
		jmp -- ; replacing below with this jmp --
; old code below (bad place to process data!)
;		lda StatsUpdated
;		beq +
;			jsr draw_stats ; moved to exitinter
;			lda #0
;			sta StatsUpdated
;+
;		lda FrameStarted	;Removed
;		beq --

;		lda #0
;		sta FrameStarted

		; Scroll a tile to give nice impression
		;jsr scroll_tile	; Not used any longer

		; Calculate pushback forces
;		jsr calc_individual_forces	;TODO: Move

		; Perform parallel tasks here
;		lda TaskPointer
;		beq +
;TaskPointer=Task+1
;Task			jsr $0000
;		lda #$00
;		sta TaskPointer
;+		jmp --

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
; player_busy
;
;-----------------------------------------------------------
player_busy
		ldx PlayerBusyTimer
		beq +
			dex			; Player is busy and cannot move, either swinging sword or
			stx PlayerBusyTimer	; taking damage.
			rts
+
		lda next_state
		sta PlayerState
		lda #PlayerStateInControl
		sta next_state
		rts

next_state	!byte PlayerStateInControl

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
		ldx #8
		lda #0
-			dex
			sta xtablelo,x
			sta xtablehi,x
			sta ytable,x
			bne -
		sta MobsPresent
		lda #PlayerStateFades
		sta PlayerState
		lda #32
		sta PlayerBusyTimer
		rts

;-----------------------------------------------------------
; player_fades
; TODO: Rewrite this, many wasted bytes here for a
;       too fancy color fade effect. Just transition
;       out the screen by filling it with some nice looking
;       char instead, one line per frame until 24 rows 
;       filled. Then write "game over" in center of screen.
;       
;-----------------------------------------------------------
player_fades
		ldx #0
		lda player_fades_counter
		cmp #4
		bcc ++
		lda #$d8
		sta fader_srcaddr+2
		lda #$44
		sta fader_dstaddr+2
		jmp +++	; #4
++
		; fill color buffer steps 1-4
fader_srcaddr	lda $d800,x
		and #$0f
		tay
		lda gradient_fader,y
fader_dstaddr	sta $4400,x
		dex
		bne fader_srcaddr
		inc player_fades_counter
		inc fader_srcaddr+2
		inc fader_dstaddr+2
		rts

+++
		; step 5 - color buffer is now complete, fill color ram:
		ldx #0
-		lda $4400,x
		sta $d800,x
		lda $4500,x
		sta $d900,x
		lda $4600,x
		sta $da00,x
		lda $4700,x
		sta $db00,x
		inx
		bne -
		stx player_fades_counter	; reset fade counter

;		ldx #0
;-		lda $4400,x
;		sta $d800,x
;		inx
;		bne -
;-		lda $4500,x
;		sta $d900,x
;		inx
;		bne -
;-		lda $4600,x
;		sta $da00,x
;		inx
;		bne -
;-		lda $4700,x
;		sta $db00,x
;		inx
;		bne -
;		stx player_fades_counter	; reset fade counter

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
		ldx #0
-		lda text_game_over,x
		sta $41ef,x
		lda #1
		sta $d9ef,x
		inx
		cpx #9
		bne -

		rts

text_game_over	!scr "game over"
player_fades_counter
		!byte $00


;-----------------------------------------------------------
; prepare_new_map - loads the new map into place
; parameters: MapID (which map to load)
; returns: nothing
;-----------------------------------------------------------
prepare_new_map
		; Load the correct map and set things up

		; Set up map name, display loading text
		ldy MapID
		lda dungeon_names_lo,y
		sta destination_lo
		lda dungeon_names_hi,y
		sta destination_hi
		jsr swap_screen
		ldx #<loading_text
		ldy #>loading_text
		jsr load_text
		jsr swap_screen

		; Set tables file load data
		ldy MapID
		lda tables_name_lb_idx,y
		sta fname
		lda tables_name_hb_idx,y
		sta fname+1
		lda tables_name_len_idx,y
		sta fname_len
		jsr loader

		; load RLE compressed map content data
		; Set tables file load data
		ldy MapID
		lda map_name_lb_idx,y
		sta fname
		lda map_name_hb_idx,y
		sta fname+1
		lda map_name_len_idx,y
		sta fname_len
		jsr loader

		; load sprites
		ldy MapID
		lda sprite_name_lb_idx,y
		sta fname
		lda sprite_name_hb_idx,y
		sta fname+1
		lda sprite_name_len_idx,y
		sta fname_len
		jsr loader

		; (blank out screen here, chars look ugly
		;  when new charset is loaded and unpacked)
check_blank_on	lda $d011
		and #$ef
		sta $d011

		; load character set
		ldy MapID
		lda charset_name_lb_idx,y
		sta fname
		lda charset_name_hb_idx,y
		sta fname+1
		lda charset_name_len_idx,y
		sta fname_len
		jsr loader

;---------------------------------------------------------------------
		; decrunch tables
		ldy MapID
		lda tables_file_end_lb,y
		sta _byte_lo
		lda tables_file_end_hb,y
		sta _byte_hi
		jsr decrunch
check_tables
		; decrunch map
		ldy MapID
		lda map_file_end_lb,y
		sta _byte_lo
		lda map_file_end_hb,y
		sta _byte_hi
		jsr decrunch
check_map
		; decrunch sprites
		ldy MapID
		lda sprite_file_end_lb,y
		sta _byte_lo
		lda sprite_file_end_hb,y
		sta _byte_hi
		jsr decrunch
check_sprites
		; decrunch charset
		ldy MapID
		lda charset_file_end_lb,y
		sta _byte_lo
		lda charset_file_end_hb,y
		sta _byte_hi
		jsr decrunch
check_charset
check_blank_off
		lda $d011
		ora #$10
		sta $d011

		rts
;-----------------------------------------------------------
; ctrl_player - read keyboard + move player + check map collision
; returns: a
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
			jsr player_busy
			jmp ctrl_player_check_edges

+		cmp #PlayerStateTransitInit
		bne +

			; Turn off sprites
			lda #0
			sta $d015
			jsr set_transfer_irq
			lda #state_transfer_unpack
			sta transferstate
			lda #1
			jmp ctrl_player_end	; don't check edges!

+		cmp #PlayerStateStartLootChest
		bne +
			; should be chest!
			ldx tmp_chest_loc
			ldy tmp_chest_idx

			jsr open_chest

			lda #PlayerStateLootChest
			sta PlayerState

			lda #1
			jmp ctrl_player_end	; don't check edges!
+		cmp #PlayerStateLootChest
		bne +
			lda #0
			sta PlayerBusyTimer
			jsr spawn_loot

			lda #PlayerStateInControl
			sta PlayerState
			jmp ctrl_player_check_edges
+		cmp #PlayerStateDestroyTile
		bne +
			ldx tmp_tree_loc
			ldy tmp_tree_idx

			jsr destroy_tile

			lda #PlayerStateInControl
			sta PlayerState
			jmp ctrl_player_check_edges
+		cmp #PlayerStatePullSwitch
		bne +
			; Do nothing here, everything will be done on next interrupt
			lda #1
			jmp ctrl_player_end	; don't check edges!

+		cmp #PlayerStateBusy
		bne +
			; Pulling switches is heavy work!
			jsr player_busy
			lda #1
			jmp ctrl_player_end	; don't check edges!

+               cmp #PlayerStateDialog
		bne +
			; Display the dialog
check_caption
			ldy capt_ptr		; set y as index to txt_offsets
			ldx txt_lb,y		; get low byte text address
			lda txt_lengths,y	; get text length
			ldy #>txt_base		; get high byte text address
			jsr caption_text
			lda #PlayerStateDialogEnd
			sta next_state
			lda #100
			sta PlayerBusyTimer
			lda #PlayerStateBusy
			sta PlayerState
			lda #1
			jmp ctrl_player_end	; don't check edges!
+		cmp #PlayerStateDialogEnd
		bne +
			lda #PlayerStateInControl
			sta PlayerState
			jsr swap_screen
			jsr draw_screen
			jsr swap_screen
			lda #1
			jmp ctrl_player_end	; don't check edges!
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
			jsr prepare_new_map
			jsr softsetup

			ldx #$ff
			txs		; reset stack pointer
			;ldx #0		; x = 0
			;stx $dc0e
	
			jmp main_routine
			;lda #1	; set a to 1 to not scroll screen
			;rts

+		; else	;cmp #PlayerStateFades

			jsr player_fades

			jsr read_keyboard
			lda ScanResult
			and #kb_return
			beq *+5
				jsr softsetup
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
;-----------------------------------------------------------


destroy_tile
		; First check if block is destructible
		ldx CurrentRoomIdx
		lda extensions,x
		and #$c0
		cmp #$80
		beq +
			rts

+		; Get destructible block index, should match with the block which was attacked.
		ldx CurrentRoomIdx
		lda extensions,x
		and #$3f
		tay
		lda destructible_block_pos,y
		cmp tmp_tree_loc
		beq +
			rts
+		; Get tile or loot to spawn after tile is destroyed.
		lda destructible_block_cont,y
		sta tmp_tree_idx
		cmp #$f0 ; if idx == $f*
		bcc +
			jsr spawn_loot
			lda #0
			sta tmp_tree_idx
+		; endif

		; Do a local tile update
		ldx tmp_tree_loc
		lda tmp_tree_idx
		tay
		sta tilebuffer,x	; update tile buffer
		lda screen_id
		eor #1
		sta screen_id
		jsr put_tile		; then draw the new tile
		lda screen_id
		eor #1
		sta screen_id
		rts

;-----------------------------------------------------------
; ctrl_player_check_collisions
; check which tiles the player collided with.
;-----------------------------------------------------------
ctrl_player_check_collisions
		cpx #ct_door
		beq +
		jmp ++
+		; ------------------Found Door---------------------

			ldx plr_r_ctrl_dir
			jsr get_door_target_location ; uses direction variable x
			sta tmp3 ; target screen position
			cmp #$f0
			bcc +
				; Load new map
				and #$0f
				sta MapID
				ldx #PlayerStateSwitchMap
				stx PlayerState
				rts
+
			ldx tmp  ; get source screen position (set by "get_door_target_location" subroutine)
			lda doorexits,x ; fetch doorexit for target screen at source screen.

+			cmp #$e0
			bcc +
				; get the current multi door exit
				lda doorexitsmulti,y
+
			sta tmp_doorexit ; keep door exit here

			lda tmp3 ; fetch target screen position again
			jsr transform_a_div_16_mul_12
			sta offy ; extract y tile offset

			lda #0
			sta offx+1 ; reset high byte to ensure correct transitions

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
			lda #0
			sta tmp_trans_xhi
			lda tmp_doorexit
			+immediate_a_mod_n 20
			clc
			asl
			asl
			asl
			asl			; divides by 16
			rol tmp_trans_xhi	; transfer carry if set
			adc #xoffset
			sta tmp_trans_xlo
			bcc +
				inc tmp_trans_xhi	; apply carry if set (should not happen twice with earlier rol)
+
			lda #1
			rts
++
		cmp #ct_chest
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
;               0 = No chest found at specified position!
;-----------------------------------------------------------
open_chest
		lda screen_id
		eor #01
		sta screen_id

		lda #0
		cpy #TileChestClosedLeft
		bne +
			ldy #TileChestOpenLeft
			jsr put_tile
			inx
			iny
			jsr put_tile
			jmp ++

+		cpy #TileChestClosedRight
		bne +
			ldy #TileChestOpenRight
			jsr put_tile
			dex
			dey
			jsr put_tile

++
+		pha
		lda screen_id
		eor #01
		sta screen_id
		pla
		rts
;-----------------------------------------------------------

;-----------------------------------------------------------
; change_switch_state
; change switch state indicated by tile position and
; tile index.
;
; parameters:
; (in) CurrentRoomIdx : screen position (0-239)
;
; returns:
; a : result:
;               1 = Switch state changed.
;               2 = No switch found at specified position!
;-----------------------------------------------------------
change_switch_state

		sei
		inc $d021

		; First the intelligence...
		ldx CurrentRoomIdx
		lda extensions,x
		cmp #$f0
		bcs +
			rts	; exit if no switches present in this room

+		and #$0f
		tax	; move switch set index to x
		lda switch_sets,x
		tax	; move switch_lists index to x

		; loop to process all switches in this room

next_switch		lda switch_lists,x	; get switch list x
			cmp #$ff
			bne +
				jmp exit_switch_loop	; exit loop, no more switches

+			stx sw_tmp_x		; save switch index (x=$05)

			tay
			sty sw_tmp_y		; save switch y (y=$18)

			lda swbase+1,y		; get position
			cmp plr_r_last_tilepos	; check with last collided tile (should be a switch)
			beq +
				inx		; if this position was not correct, check next switch
				jmp next_switch

+			lda swbase,y		; get state of switch (0 or 1)
			eor #1			; toggle state of switch y
			sta swbase,y
			sta sw_state_swa	; save the state

			lda swbase+2,y		; get condition value (indicate another switch on
						; which this switch depends), or $fe that makes it a toggle switch
			sta sw_cond

			; loop all switch targets
next_sw_target
				lda swbase+3,y	; get next switch target tile
				sta sw_target_pos	; save target, we need register a
				cmp #$ff
				bne +
					jmp exit_target_loop		; no more targets, exit

+				lda sw_cond

				; if (A == $ff)
				cmp #$ff	; no condition?
				beq exit_switch_condition	; exit, no condition was set

				; else if (A and $80 != 0)
				and #$80	; XOR/toggle condition?
				beq +
					; XOR/toggle condition!
					lda sw_cond
					and #$7f
					tay			; switch B index
					lda sw_state_swa	; switch A index
					eor swbase,y
					sta sw_state	; save XORed state

					jmp check_if_local_update
+				; else
					; Normal AND condition
					ldy sw_cond		; switch B index
					lda sw_state_swa	; switch A index
					and swbase,y
					sta sw_state	; save ANDed state

					jmp check_if_local_update
				; endif
exit_switch_condition
				lda sw_state_swa
				sta sw_state
check_if_local_update
				; Check in which room the switch target is located
				ldx sw_target_pos
				lda swtargetbase,x	; Get room idx for target x
				sta sw_target_room	; save the target room

				txa
				clc
				adc sw_state		; add state
				tax
				ldy swtargetbase+2,x	; first get the tile based on state (pos 2 or 3 in swtargetX)
				sty sw_target_tile	; save target tile

				lda sw_target_room
				cmp CurrentRoomIdx	; Is it the current room?
				bne skip_local_target_update	; Nope, so skip local room update

				; Do a local tile update
				ldx sw_target_pos
				lda swtargetbase+1,x	; next get the position of tile to modify
				tax
				tya
				sta tilebuffer,x	; update tile buffer
				lda screen_id
				eor #1
				sta screen_id
				jsr put_tile		; then draw the new tile
				lda screen_id
				eor #1
				sta screen_id

skip_local_target_update
				; Do a remote tile update
				ldy MapID
				lda pc_map_idx,y	; Find which pc_target_list it is (pc_map_idx entries refer to 
							; one of pc_target_list_* address offsets.)
				tay
check_next_pc_target			lda pc_target_list_base,y	; get first empty target in list [0]
				cmp #$ff			; is it empty?
				beq +				; if yes, jump ahead and then store it at the corresponding target list position.
				cmp sw_target_room	; otherwise it is the target room the same as this position, we need to check if next
							; position is free:
				beq check_target_pc_pos

step_ahead_pc			iny
				iny
				iny
				jmp check_next_pc_target	; loop back and skip to next "persistent change" target

check_target_pc_pos			ldx sw_target_pos		; Get switch target pos index
					lda swtargetbase+1,x		; Get switch target position (second index in entry)
					cmp pc_target_list_base+1,y	; Is the tile position also the same? (Only a single
									;   switch set can be connected to a tile position.)
					bne step_ahead_pc		; If not, check next persistent change index.

				; Otherwise we have found the correct index,
				; or it is unused since earlier.

				; Save the remote tile update
+				lda sw_target_room
				sta pc_target_list_base,y
				ldx sw_target_pos
				lda swtargetbase+1,x
				sta pc_target_list_base+1,y
				lda sw_target_tile
				sta pc_target_list_base+2,y

				ldy sw_tmp_y		; get back the switch index
				ldx sw_tmp_x		; get back the switch list index
				iny	; --> get next switch target
				sty sw_tmp_y
				jmp next_sw_target

exit_target_loop
			ldx sw_tmp_x
			inx
			jmp next_switch	; go and process next switch

exit_switch_loop
		ldx sw_src_pos
		ldy sw_src_tile
		cpy #TileSwitchInactive
		bne +
			ldy #TileSwitchActive
			jmp ++

+		cpy #TileSwitchActive
		bne +
			ldy #TileSwitchInactive

++		tya
		sta tilebuffer,x	; update tile buffer

		lda screen_id
		eor #1
		sta screen_id

		jsr put_tile

		lda screen_id
		eor #1
		sta screen_id

		; Clear pending interrupts just in case (causes frame skips)
		asl $d019
		lda $dc0d
		lda $dd0d
		dec $d021
		cli

+		rts

;-----------------------------------------------------------



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
; destroys registers: a
;-----------------------------------------------------------
put_tile
		tya
		pha
		txa
		pha

		; find the backbuffer, then draw to it,
		lda screen_id
		beq tile_to_back
; tile_to_front
		lda #0
		jmp end_tile
tile_to_back
		lda #4
end_tile
		ora tilepos_hi,x

		; begin storing pointer to first row of tile data in tmp_addr
		sta tmp_addr+1

		; finish storing pointer to first row of tile data in tmp_addr
		lda tilepos_lo,x
		sta tmp_addr

		; push the screen position onto stack used to get the indirect address
		stx put_tile_tmp

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
		ldx put_tile_tmp

		; Get high byte for tile color data and store in tmp_addr
		lda put_tile_attr
		bne +
			lda tilepos_hi,x
			clc
			adc #$98
			jmp ++
+
			lda tilepos_hi,x	; => $40 + $98 + $2c = $d8 + $2c = $04 ($0400) color buffer
			clc
			adc #$c4
++
		sta tmp_addr+1

		; get low byte for first row of color data and store in tmp_addr
		lda tilepos_lo,x
		sta tmp_addr

		; Recover the tile index
		ldx tmp2

		ldy tiledata,x
		lda colordata,y
		ldy #0
		sta (tmp_addr),y
		ldy tiledata+1,x
		lda colordata,y
		ldy #1
		sta (tmp_addr),y
		ldy tiledata+2,x
		lda colordata,y
		ldy #40
		sta (tmp_addr),y
		ldy tiledata+3,x
		lda colordata,y
		ldy #41
		sta (tmp_addr),y

		pla
		tax
		pla
		tay
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

			jsr prepare_tile_idx_and_screen_pos_for_sides

			pha ; <<< TILE IDX

			; find the backbuffer, then draw to it,
			lda screen_id
			beq +
			; if backbuffer is a
				lda #0
				jmp ++

+			; else backbuffer is b
				lda #4

++			; endif
			ora tilepos_hi,x

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

				jmp ++

+			; else right part of tile

				; draw right part of tile only
				ldy #0
				lda tiledata+1,x
				sta (tmp_addr2),y
				ldy #40
				lda tiledata+3,x

++			; endif

			sta (tmp_addr2),y

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

			jsr prepare_tile_idx_and_screen_pos_for_sides

			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda tilepos_hi,x
			clc
			adc #$98
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
				ldy tiledata,x
				lda colordata,y
				ldy #0
				sta (tmp_addr2),y
				ldy tiledata+2,x
				lda colordata,y
				ldy #40
				sta (tmp_addr2),y

				jmp ++
+			; else right side of tile

				; color right part of tile only
				ldy tiledata+1,x
				lda colordata,y
				ldy #0
				sta (tmp_addr2),y
				ldy tiledata+3,x
				lda colordata,y
				ldy #40
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
		lda offx
		;dey	; these three lines below equals: x = (x+1) % 20
		+immediate_a_mod_n 20

-		; while (x < 12)

			tay ; keep column counter in y
			pha ; <<< COLUMN COUNTER

			; calculate offset where to get tiles (in tilebuffer area)
			; multiply row with 20
			txa
			pha ; <<< ROW COUNTER

			jsr prepare_tile_idx_and_screen_pos_for_sides

			pha ; <<< TILE IDX

			; find the backbuffer, then draw to it,
			lda screen_id
			beq +
			; if backbuffer a
				lda #0	; backbuffer a
				jmp ++

+			; else backbuffer b
				lda #4	; backbuffer b

++			; endif
			ora tilepos_hi,x

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

			jsr prepare_tile_idx_and_screen_pos_for_sides

			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda tilepos_hi,x
			clc
			adc #$98
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
				ldy tiledata,x
				lda colordata,y
				ldy #39
				sta (tmp_addr2),y
				ldy tiledata+2,x
				lda colordata,y
				ldy #79
				sta (tmp_addr2),y
				jmp ++
+			; else right part of tile

				; color right part of tile only
				ldy tiledata+1,x
				lda colordata,y
				ldy #39
				sta (tmp_addr2),y
				ldy tiledata+3,x
				lda colordata,y
				ldy #79
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

			jsr prepare_tile_idx_and_screen_pos_for_top_and_bottom

			pha	; <<< TILE IDX

			; find the backbuffer, then draw to it,
			lda screen_id
			beq +
			; if backbuffer is a
				lda #0
				jmp ++

+			; else backbuffer is b
				lda #4
++			; endif
			ora tilepos_hi,x

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

			jsr prepare_tile_idx_and_screen_pos_for_top_and_bottom

			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda tilepos_hi,x
			clc
			adc #$98
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
				ldy tiledata,x
				lda colordata,y
				ldy #0
				sta (tmp_addr2),y
				ldy tiledata+1,x
				lda colordata,y
				ldy #1
				sta (tmp_addr2),y
				jmp ++

+			; else bottom part of tile

				; color bottom part of tile only
				ldy tiledata+2,x
				lda colordata,y
				ldy #0
				sta (tmp_addr2),y
				ldy tiledata+3,x
				lda colordata,y
				ldy #1
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

			jsr prepare_tile_idx_and_screen_pos_for_top_and_bottom

			pha	; <<< TILE IDX

			; find the backbuffer, then draw to it,
			lda screen_id
			beq +
			; if backbuffer a
				lda #0
				jmp ++

+			; else backbuffer b
				lda #4

++			; endif
			ora tilepos_hi+220,x

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

			jsr prepare_tile_idx_and_screen_pos_for_top_and_bottom

			pha ; <<< TILE IDX

			; Get high byte for tile color data and store in tmp_addr
			lda tilepos_hi+220,x
			clc
			adc #$98
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
				ldy tiledata,x
				lda colordata,y
				ldy #40
				sta (tmp_addr2),y
				ldy tiledata+1,x
				lda colordata,y
				ldy #41
				sta (tmp_addr2),y
				jmp ++

+			; else bottom part of tile
				; color bottom part of tile only
				ldy tiledata+2,x
				lda colordata,y
				ldy #40
				sta (tmp_addr2),y
				ldy tiledata+3,x
				lda colordata,y
				ldy #41
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
		; Each screen is RLE compressed (all map data also compressed with LZW on disk)
		; so uncompress the next screen data to the tile buffer here, so it can be 
		; drawn to screen directly from there later.
		; Find room data via dictionary, fetch 16-bit dictionary entry by offx and offy
		; coordinates.

		; tmp_addr pointer stores the base address of the dictionary data. The dictionary
		; only holds 16 bit addresses to the compressed data of each room/screen. 

		; tmp_addr2 pointer stores the source address of the actual compressed data of a screen.
		;    It will be pointed to from the address of tmp_addr.
		;
		;    Each unit of data is a 16 bit word with tile ID and how many tiles with this
		;    ID were found while stepping ahead on x..

		; Initialize working pointer to zero, so we can calculate.
		lda #0
		sta tmp_addr
		sta tmp_addr+1

		lda offx+1
		sta tmp
		lda offx

		; First divide offx by 20 and offy by 12 to get coordinates in tile space.
		; divide offx by 20 to get screen x:
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

		; divide offy by 12 to get screen y:
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
			lda #>tilebuffer
			sta buffer+2
			lda #<tilebuffer
			sta buffer+1

			; uncompressed data now at tilebuffer
			jmp +

++		; } else {
			; data already uncompressed, copy directly to tilebuffer
			tax
-				iny
				lda (tmp_addr2),y
				sta tilebuffer-1,y
				dex
			bne -
			; uncompressed data now at tilebuffer


			; Update CurrentRoomIdx

			; All these rows mean: a = offy * 16 / 12
+			lda offy
			jsr transform_a_mul_16_div_12
			sta tmp

			; This is a = offx / 20
			ldy #$ff
			ldx offx+1
			lda offx
-				iny
				sec
				sbc #20
				bcs -
				dex	; offx is 16 bits so check that high byte is also subtracted from
				bpl -
			tya

			clc
			adc tmp		; x = offy * 4 / 3 + offx / 20 == screen pos!
			sta CurrentRoomIdx

			rts
		; }

; ---------------------------------------------------------
; prepare_tile_idx_and_screen_pos_for_sides
; params:
;  y	- screen tile column counter (map_x - 1) % 20
;  a	- screen tile row counter, the tile row at which
;  	  the tile idx and screen row pos is prepared,
;         (0-11).
;
; returns:
;  x		- screen tile row position (0,20,40,...,200,220)
;  a		- tile index
; ---------------------------------------------------------
prepare_tile_idx_and_screen_pos_for_sides
		sta tmp ; keep 1y
		asl	; 2y
		asl	; 4y
		clc
		adc tmp	; 5y	(4y + y = 5y)
		asl	; 10y	
		asl	; 20y
		sta tmp	;	tmp = 20y
		tax	; keep 20y in x
		tya
		clc
		adc tmp	; screenpos = 20y + (x+1) % 20
		tay	; transfer final offset to y again, but we still have column count on stack

		; get the tile index from map (for drawing)
		; Find the tile at the final offset
		lda tilebuffer,y	; fetch tile here
		asl
		asl ; multiply by 4

		rts

; ---------------------------------------------------------
; prepare_tile_idx_and_screen_pos_for_top_and_bottom
; params:
;  y	- screen tile column counter (map_x - 1) % 20
;  a	- screen tile row counter, the tile row at which
;  	  the tile idx and screen row pos is prepared,
;         (0-11).
;
; returns:
;  x		- screen tile row position (0,20,40,...,200,220)
;  a		- tile index
; ---------------------------------------------------------
prepare_tile_idx_and_screen_pos_for_top_and_bottom
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

		rts


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
		lda #kb_space
		ora ScanResult
		sta ScanResult
check_a
		lda #%11111101  ; select row 2
		sta $dc00
		lda $dc01       ; load column information
		and #%00000100  ; test 'a' key
		bne check_d
		lda #kb_a
		ora ScanResult
		sta ScanResult
check_d
		lda #%11111011  ; select row 3
		sta $dc00
		lda $dc01       ; load column information
		and #%00000100  ; test 'd' key
		bne check_w
		lda #kb_d
		ora ScanResult
		sta ScanResult
check_w
		lda #%11111101  ; select row 2
		sta $dc00
		lda $dc01       ; load column information
		and #%00000010  ; test 'w' key
		bne check_s
		lda #kb_w
		ora ScanResult
		sta ScanResult
check_s
		lda #%11111101  ; select row 2
		sta $dc00
		lda $dc01       ; load column information
		and #%00100000  ; test 's' key
		bne check_n
		lda #kb_s
		ora ScanResult
		sta ScanResult
check_n
		lda #%11101111	; select row 5
		sta $dc00
		lda $dc01	; load column information
		and #%10000000	; test 'n' key
		bne check_h
		lda #kb_n
		ora ScanResult
		sta ScanResult
check_h
		lda #%11110111	; select row 4
		sta $dc00
		lda $dc01	; load column information
		and #%00100000	; test 'h' key
		bne check_return
		lda #kb_h
		ora ScanResult
		sta ScanResult
check_return
		lda #%11111110	; select row 1
		sta $dc00	; load column information
		lda $dc01	; test 'return' key
		and #%00000010
		bne skip
		lda #kb_return
		ora ScanResult
		sta ScanResult
skip
		rts


;-----------------------------------------------------------

end_code_3k

; ***** FREE SPACE: 134 bytes




;-----------------------------------------------------------
; graphix data for tiles, sprites and the map
;
;-----------------------------------------------------------

		; Color buffer			@ $0400 - $07e7 (There's no use of this address range?)
		; Tables and routines		@ $0810 - $1eff
		; Screen unpack buffer		@ $1f00 - $1fef
		; Music				@ $2000 - $2fff
		; Initial game code		@ $3000 - $3fff
		; Primary screen data 		@ $4000 - $43ff
		; Secondary screen data		@ $4400 - $47ff
		; Character data 		@ $4800 - $4fff
		; Sprite data			@ $5000 - $6fff
		; Game tile map			@ $7000 - $bdff
		; Tile color table		@ $be00 - $beff
		; Tile data			@ $bf00 - $bfff
		; More game code		@ $c000 - $cfff
		; World tables (dynamic)	@ $e000 - $efff (outdoor, dungeon1, dungeon2...)
		; Core tables (static)		@ $f000 - $f5ff (coretables)

		; Map data, max 20480 bytes
		*=$7000
mapdata
		!binary "aad_map_big.rle"
end_mapdata
		; Map color data 256 bytes
		*=$be00
colordata
		!binary "aad_charset_attrs_big.bin"

		; Map tile data 256 bytes
		*=$bf00
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
		!binary "aad_sprites_outdoor.bin"	; 128 unpacked sprite entries, will add up to 128 packed sprite entries (32 bytes * 128 = 4096 = 4k) at $e000-$efff

		; Ends at $6fff

		*=$c000
begin_code_c000

;-----------------------------------------------------------
; Sprite multiplexer interrupt
;
;-----------------------------------------------------------
maininter

		sta areg	; save registers to zero page
		stx xreg
		sty yreg
		inc $d020
		jsr $2003
		dec $d020	; set cycle measuring indicator color in the border

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

		lda #$4c		;jmp $0000	; self-modifying code, sets the jmp opcode at "switch label"
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
		sta vspr_counter	; multiplexing is done for sprites 4-12

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
		sta areg
		stx xreg
		sty yreg

		; reset scroll
		lda #$1c
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

		lda BGColor
		sta $d021


		lda #<maininter
		sta $fffe
		lda #>maininter
		sta $ffff
		lda #$00	; Set main interrupt to happen at line 32
		sta $d012
		lda #$1b	; Default settings, normal text mode, set raster high bit to 0
		sta $d011

		inc $d019	; acknowledge raster irq.
		lda $dc0d	; acknowledge pending irqs.

		ldy yreg
		ldx xreg
		lda areg
		rti

;--------------------------------------
exitinter
		;; From this point and onward the sprites have been drawn.
		;; There is plenty of raster time to trigger another interrupt just before the last bad line
		;; and use black background.
		sei

		lda #$80
		bit $d011
		bmi +
		lda $d012

		; if (raster line < 242 and
		;     PlayerState != PlayerStateFades and
		;     PlayerState != PlayerStateTransitInit and
		;     PlayerState != ) ...
		cmp #$f2
		bcs skip_status

		jsr calc_individual_forces
		lda PlayerState
		cmp #PlayerStateFades
		beq +
		cmp #PlayerStateTransitInit
		beq +
		cmp #PlayerStatePullSwitch
		bne +
			; Process switches separately, since logic is heavy on CPU,
			; make it run in its own IRQ
			;jsr set_switch_irq
			lda #0
			sta $d015
			jsr change_switch_state

			lda #PlayerStateBusy
			sta PlayerState

			jmp +++++

+		; then {
			lda #$1b
			sta $d011
			lda #$f2
			sta $d012

			lda #<statusline	; so, set raster interrupt at next sprite 0 y coordinate.
			sta $fffe
			lda #>statusline
			sta $ffff

			;inc $d019	; acknowledge raster irq.
			;lda $dc0d	; acknowledge pending irqs.
			;lda $dd0d
			jmp ++
skip_status	; else

			lda #<maininter
			sta $fffe
			lda #>maininter
			sta $ffff

			lda #$1b
			sta $d011
			lda #$00	; Set main interrupt to happen at line 32
			sta $d012
			inc $d019	; acknowledge raster irq.
			lda $dc0d	; acknowledge pending irqs.
			;lda $dd0d
++
		lda StatsUpdated
		beq +
			jsr draw_stats
			lda #0
			sta StatsUpdated
			jmp +++++

+		inc AnimCounter
		lda AnimCounter
		and #$1f	; 32 / 8 = 4 => range is [0-31] but always divided by 8 => [0-3]
		sta AnimCounter
		lsr
		lsr
		lsr
		sta AnimFrame	; This will create an animation stepper of 1 image per 8 frames, in range [0-3]

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
		bne +	; if (enemy_qty != 0) {
		jmp +++
+
			; 	for (x=enemy_qty-1; x>=0; x--); do {
-			dex
			lda enemy_state,x
			cmp #EnemyLoot
			beq +
			cmp #ChestLootRise
			beq +
			cmp #ChestLootHover
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
			tay		; Store animation frame and state index in y (animates enemies, bosses and NPCs)
			lda CurrentMobTypes,x
			cmp #$80
			bne +				; if (CurrentMobTypes == NPC(0))
				lda NpcImageList
				jmp ++
+			cmp #$81
			bne +				; if (CurrentMobTypes == NPC(1))
				lda NpcImageList+1
				jmp ++
+			cmp #$0e
			bne +	; 0e = Boss type 1
				lda BossAnimTable,y
				asl
				asl
				tay	; y = BossAnimTable[y] * 4
				jsr set_boss_sprite_frames_2x2
				jmp ++++
+			cmp #$0f
			bne +	; 0f = Boss type 2
				lda BossAnimTable,y
				asl
				tay	; y = BossAnimTable[y] * 4
				jsr set_boss_sprite_frames_2x3
				jmp ++++
+			and #$03
			cmp #$00
			bne +				; if (CurrentMobTypes == enemy type 0)
				lda EnemyAnimTable,y
				jmp ++
+			cmp #$01
			bne +				; if (CurrentMobTypes == enemy type 1)
				lda EnemyAnimTable+20,y
				jmp ++
+			cmp #$02
			bne +				; if (CurrentMobTypes == enemy type 2)
				lda EnemyAnimTable+40,y
				jmp ++
+				lda EnemyAnimTable+60,y	; else (CurrentMobTypes == enemy type 3)

++		sta frame+enemy+16,x
		clc
		adc #4
		sta frame+enemy,x
++++		cpx #0
		beq +++		; } // end for
		jmp -
+++
			; } // end if
		; ---------------------------------------------------------------------------------


		; All AI logic
		jsr ctrl_enemy

		; player movement here
		jsr ctrl_player
		bne +++++
			; abort this routine and start scrolling
			jmp ++
+++++
		; From now on allow trigger on irq again (sacrifice in sprite accuracy)
		jsr sort	; sort sprites

		; Check if it's not too late to scroll some tiles :)
		lda $d011
		cmp #$80
		bcs ++
		lda MapID	; Scroll only if not main map, no scrollable tiles there.
		beq ++
			jsr scroll_tile
++
		inc $d019
		lda $dc0d
		lda $dd0d
		lda areg
		ldx xreg
		ldy yreg
		cli
		rti		; ...aaand return from the multiplexing interrupt chain.




; Set up boss frames
;--------------------------------------
set_boss_sprite_frames_2x3
		lda BossFrames2x3+1,y
		sta frame+enemy+16+10,x
		clc
		adc #4
		sta frame+enemy+10,x
		lda BossFrames2x3,y
		sta frame+enemy+16+9,x
		clc
		adc #4
		sta frame+enemy+9,x
		tya
		asl
		tay

set_boss_sprite_frames_2x2
		lda BossFrames2x2+3,y
		sta frame+enemy+16+8,x
		clc
		adc #4
		sta frame+enemy+8,x
		lda BossFrames2x2+2,y
		sta frame+enemy+16+7,x
		clc
		adc #4
		sta frame+enemy+7,x
		lda BossFrames2x2+1,y
		sta frame+enemy+16+6,x
		clc
		adc #4
		sta frame+enemy+6,x
		lda BossFrames2x2,y
		sta frame+enemy+16,x
		clc
		adc #4
		sta frame+enemy,x

		rts

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

over7		ldy indextable+8
back7		ldx indextable+7
		lda ytable,y
		cmp ytable,x
		bcs over8
		stx indextable+8
		sty indextable+7
		bcc back6

over8		ldy indextable+9
back8		ldx indextable+8
		lda ytable,y
		cmp ytable,x
		bcs over9
		stx indextable+9
		sty indextable+8
		bcc back7

over9		ldy indextable+10
back9		ldx indextable+9
		lda ytable,y
		cmp ytable,x
		bcs over10
		stx indextable+10
		sty indextable+9
		bcc back8

over10		ldy indextable+11
back10		ldx indextable+10
		lda ytable,y
		cmp ytable,x
		bcs over11
		stx indextable+11
		sty indextable+10
		bcc back9

over11		ldy indextable+12
back11		ldx indextable+11
		lda ytable,y
		cmp ytable,x
		bcs over12
		stx indextable+12
		sty indextable+11
		bcc back10

over12		ldy indextable+13
back12		ldx indextable+12
		lda ytable,y
		cmp ytable,x
		bcs over13
		stx indextable+13
		sty indextable+12
		bcc back11

over13		ldy indextable
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
			cpx #14	; (all sprites excluding player(0) + weapon(1))
		bne -


		; LOAD MOBS ; TODO: Can be simplified. Get rid of mobs_entries_list
		; prepare source address
		lda #<world
		sta tmp_addr
		lda #>world
		sta tmp_addr+1

		; Get mobdata from the right place
		ldy CurrentRoomIdx

		; get mob data from world / dungeons
		lda (tmp_addr),y
		tay

		; set correct address for lda operation at store_mob
		lda #<CurrentMobTypes
		sta store_mob+1
		lda #>CurrentMobTypes
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

			; if (mob type == NPC) {
			cmp #$80
			bcc +
				; NPC is a special case of mob, uses two positions in CurrentMobTypes list;
				; - first position for the type value
				; - second position for the NPC tile position on screen

				; Set the NPC type (first byte in CurrentMobTypes list)
				sta CurrentMobTypes
					; x is screen position where NPC will stand
				stx CurrentMobTypes+1 ; Use second position in list to set its position
				inc MobsPresent
				jmp ++

+			; } else {

				; Store x mob types in list
store_mob			sta $0000		; will be initialized with CurrentMobTypes list address
				inc store_mob+1		; will increment list entry each time
				inc MobsPresent		; increment total mobs by 1
				dex
				bne store_mob
			iny	; skip to next entry in mobs_entries
			iny
			dec tmp			; x++
			bne -

++			; } // end if

		; } while (tmp < num_mobs_entries);

		; -----------------------
		; Randomize mob positions
		; -----------------------

		ldx MobsPresent

		; for each mob do {
-			dex

			stx tmp3	; store mob index

			; Check if there's a boss in this room
			lda MapID
			asl
			asl	; x = MapID * 4
			tay
			lda boss_loc_array,y	; get boss 1 room
			cmp CurrentRoomIdx	; is it this room?
			bne +
				; Set collision detection size for boss type 1
				lda #$f2	; difference of 14 pixels (1 sprite blocks)
				sta enemy_negx_size
				lda #$f2	; difference of 14 pixels (1 sprite blocks)
				sta enemy_negy_size
				lda #$2c	; difference of 44 pixels (2 sprite blocks)
				sta enemy_posx_size
				lda #$28	; difference of 40 pixels (2 sprite blocks)
				sta enemy_posy_size
				lda boss_loc_array+1,y	; get boss 1 position
				jmp ++
+			lda boss_loc_array+2,y	; get boss 2 room
			cmp CurrentRoomIdx	; is it this room?
			bne +
				; Set collision detection size for boss type 2
				lda #$f2	; difference of 14 pixels (1 sprite blocks)
				sta enemy_negx_size
				lda #$f2	; difference of 14 pixels (1 sprite blocks)
				sta enemy_negy_size
				lda #$2c	; difference of 44 pixels (3 sprite blocks)
				sta enemy_posx_size
				lda #$3d	; difference of 61 pixels (3 sprite blocks)
				sta enemy_posy_size
				lda boss_loc_array+3,y	; get boss 2 position
				jmp ++
+			; Set collision detection size for normal mobs
			lda #$f2
			sta enemy_negx_size
			lda #$f2
			sta enemy_negy_size
			lda #$0e
			sta enemy_posx_size
			lda #$0e
			sta enemy_posy_size

			; Choose a random location
			jsr get_random
			+immediate_a_mod_n 240
++
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
			tay
			lda collision_map,y
			; if tile[x,y] >= 32 then try a new random position;
			cmp #2
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
			beq +
			jmp -
		; } next mob
+

		; -----------------------
		; Put all mobs on screen
		; -----------------------

		ldx MobsPresent
-
			dex		; get next enemy idx (going backwards)
			ldy CurrentMobTypes,x
			sty CurrentMobType
			lda mobtable_hp,y	; get HP for the mobtype y
			sta enemy_hp,x
			lda mobtable_ap,y	; get AP for the mobtype y
			sta enemy_ap,x
			lda mobtable_gold,y	; get gold qty for drop for mobtype y
			sta enemy_gold,x
			lda mobtable_lootidx,y	; get mob loot table index
			sta enemy_lootidx,x
			cpy #$80
			bcs +	; branch if it's an NPC
				lda mob_fill_table,y
				sta color+enemy+16,x		; set mob fill color
				cpy #$0e
				bcc _skip_boss_fill
					sta color+enemy+16+6,x
					sta color+enemy+16+7,x
					sta color+enemy+16+8,x
					sta color+enemy+16+9,x
					sta color+enemy+16+10,x
_skip_boss_fill			lda mob_contour_table,y
				sta color+enemy,x		; set mob contour color
				cpy #$0e
				bcc _skip_boss_contours
					sta color+enemy+6,x
					sta color+enemy+7,x
					sta color+enemy+8,x
					sta color+enemy+9,x
					sta color+enemy+10,x
_skip_boss_contours		jmp ++
+			; It's an NPC, set the correct sprite
			tya
			and #$0f	; Slice off MSB
			tay

			lda npc_fill_table,y
			sta color+enemy+16,x		; set NPC fill color
			lda npc_contour_table,y
			sta color+enemy,x		; set NPC contour color

++			; Common stuff
			lda #0
			sta enemy_pull_force_x,x
			sta enemy_pull_force_y,x

			lda #EnemyRunSouth	; set animation state
			sta enemy_anim_state,x
			lda #EnemyIdle			; set AI state
			sta enemy_state,x
			lda CurrentMobType
			cmp #$80				; if (CurrentMobTypes == NPC(0))
			bne +	; 80 = NPC 1
				lda #EnemyIsNpc
				sta enemy_state,x
				lda NpcImageList
				jmp ++
+			cmp #$81				; if (CurrentMobTypes == NPC(1))
			bne +	; 81 = NPC 2
				lda #EnemyIsNpc
				sta enemy_state,x
				lda NpcImageList
				jmp ++
+			cmp #$0e	; 0e = Boss type 1
			bne +
				lda BossAnimTable,y
				asl
				asl
				tay	; y = BossAnimTable[y] * 4
				jsr set_boss_sprite_frames_2x2
				cpx #0
				beq +++
				jmp -
+			cmp #$0f	; 0f = Boss type 2
			bne +
				lda BossAnimTable,y
				asl
				tay	; y = BossAnimTable[y] * 4
				jsr set_boss_sprite_frames_2x3
				cpx #0
				beq +++
				jmp -
+			and #$03
			cmp #$00
			bne +				; if (CurrentMobTypes == enemy type 0)
				lda EnemyAnimTable,y
				jmp ++
+			cmp #$01
			bne +				; if (CurrentMobTypes == enemy type 1)
				lda EnemyAnimTable+20,y
				jmp ++
+			cmp #$02
			bne +				; if (CurrentMobTypes == enemy type 2)
				lda EnemyAnimTable+40,y
				jmp ++
+				lda EnemyAnimTable+60,y	; else (CurrentMobTypes == enemy type 3)

++
			sta frame+enemy+16,x
			clc
			adc #4
			sta frame+enemy,x

			cpx #0
			beq +++
			jmp -
+++		rts
; ------------------------------------------------------------------------------------

; ------------------------------------------------------------------------------------
;  ctrl_enemy
;  This is some enemy AI code
;  Destroys registers: a, x, y
;  x = number of mobs, mob index
;  a = working register, calculation & comparison
;  y = used in subroutines for various tasks
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
			jsr check_player_looting_enemy
			jmp +++++
+
		cmp #ChestLootRise
		bne +
			; -----------------------
			; Chest Loot Rise state
			; -----------------------
			dec enemy_timer,x
			bne ++
				lda #50
				sta enemy_timer,x
				lda #ChestLootHover
				sta enemy_state,x
				jmp +++++
++			lda ytable+enemy,x
			sec
			sbc #1
			sta ytable+enemy,x
			sta ytable+enemy+16,x
			jmp +++++
+
		cmp #ChestLootHover
		bne +
			; ------------------------
			; Chest Loot Hover state
			; ------------------------
			dec enemy_timer,x
			bne ++
				lda #0
				sta loot_swap_pos
				lda frame+enemy+16,x
				jsr check_player_looting_enemy
				jmp +++++
++			lda ytable+enemy,x
			sta loot_tmp_pos
			lda loot_swap_pos
			sta ytable+enemy,x
			sta ytable+enemy+16,x
			lda loot_tmp_pos
			sta loot_swap_pos
			jmp +++++
loot_tmp_pos		!byte $00
loot_swap_pos		!byte $00
			; ------------------
+
		cmp #EnemyIsNpc
		bne +
			; ------------------
			; NPC state
			; ------------------
			jmp +++++
			; ------------------


+		cmp #EnemyDead
		bne +
			; ------------------
			; Dead state
			; ------------------
			jmp +++++ 		; skip this enemy because it's dead
			; ------------------

	; ------------------------------------------------
	; If we get here, then we know that enemy is alive
	; ------------------------------------------------

		; ---------------------------------
		; Check enemy with player collision
		; ---------------------------------

+		jsr check_player_enemy_collision
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
				tay
				lda player_y_force_by_dir,y
				sta PlayerPullForceY
				lda player_x_force_by_dir,y
				sta PlayerPullForceX
+

		lda enemy_state,x
		cmp #EnemyHit	; enemy can only be hit if enemy is alive
		bcs +
		jsr check_weapon_enemy_collision
		beq +

			lda PlayerAnimState
			and #3
			tay
			lda enemy_y_force_by_dir,y
			sta enemy_pull_force_y,x
			lda enemy_x_force_by_dir,y
			sta enemy_pull_force_x,x

+		lda enemy_state,x
		cmp #EnemyIdle
		bne +

			; ----------------
			; Idle State
			; ----------------
			; Choose a random location and start moving there
			jsr get_random
			sta enemy_timer,x
			ldy CurrentMobTypes,x
			and num_dirs_table,y	; limit to 4 or 8 directions
			sta enemy_dir,x
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
			lda CurrentMobTypes,x
			cmp #$0e
			bcc _is_normal_enemy
			; if (_is_normal_enemy) {
				jsr move_boss_2x2
				jmp _enemy_moved
			; } else {
_is_normal_enemy
				jsr move_enemy
			; }
_enemy_moved
			lda enemy_timer,x
			beq +++
				dec enemy_timer,x
			jmp +++++
+++			lda #EnemyWaiting
			sta enemy_state,x
			jsr get_random
			sta enemy_timer,x
			jmp +++++
			; ----------------

+		cmp #EnemyAttacking
		bne +
			; ----------------
			; Attacking State
			; ----------------
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
			ldy CurrentMobTypes,x	; check if boss
			cpy #$0e
			bcc ++ ; jump if y < $0e
				sta color+enemy+6,x
				sta color+enemy+7,x
				sta color+enemy+8,x
				sta color+enemy+9,x
				sta color+enemy+10,x
++			lda enemy_timer,x
			beq +++
				dec enemy_timer,x
				jmp +++++
+++
			ldy CurrentMobTypes,x
			lda mob_contour_table,y
			sta color+enemy,x
			ldy CurrentMobTypes,x	; check if boss
			cpy #$0e
			bcc ++ ; jump if y < $0e
				sta color+enemy+6,x
				sta color+enemy+7,x
				sta color+enemy+8,x
				sta color+enemy+9,x
				sta color+enemy+10,x
++			jsr get_random
			sta enemy_timer,x
			lda #EnemyMoving
			sta enemy_state,x
			ldy CurrentMobTypes,x
			and num_dirs_table,y	; limit to 4 or 8 directions
			sta enemy_dir,x
			jmp +++++
			; ----------------


+		cmp #EnemyDying
		beq +
			jmp +++++
+
			; ----------------
			; Dying State
			; ----------------
			;lda #EnemyDyingAnim
			;sta enemy_anim_state,x
			lda enemy_timer,x
			beq +++
				dec enemy_timer,x
				lda #10
				sta color+enemy+16,x
				lda #7
				sta color+enemy,x
				jmp +++++
+++
			; --------------------------------------------
			; Time of death, spawn loot and change state
			; --------------------------------------------
			jsr spawn_mob_loot

			; ----------------
+++++
		cpx #0
		beq +
		jmp -
+
		rts
; ------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------
; spawn_mob_loot
;   Spawns loot in a free enemy sprite slot. If it's a boss, spawn heart container
;   ony once per game.
; params: x = current mob index
; returns: Nothing
; destroys registers: a, y
; ------------------------------------------------------------------------------------
spawn_mob_loot
		; Spawn some loot
		lda CurrentMobTypes,x
		cmp #$0e
		bcc else_mob_loot	; jump if mob type < $0e, i.e. not a boss

			; Boss loot!
			ldy MapID
			lda BossesLooted,y
			beq +
				; Boss cannot drop super loot twice!
				jmp else_mob_loot
+
			; Set boss as looted here.
			lda #1
			sta BossesLooted,y

			lda #f_extra_heart
			sta frame+enemy+16,x
			clc
			adc #4
			sta frame+enemy,x
			lda #col_f_extra_heart
			sta color+enemy+16,x
			lda #col_c_extra_heart
			sta color+enemy,x

			lda #0
			ldy #6
-				sta xtablelo+enemy+6,y
				sta xtablehi+enemy+6,y
				sta ytable+enemy+6,y
				dey
				bpl -

			lda #0
			sta CurrentMobTypes,x	; Change mobtype to non-boss
						; so that loot hitbox becomes small.

			lda #EnemyLoot
			sta enemy_state,x
			lda #EnemyRunSouth
			sta enemy_anim_state,x
			rts

else_mob_loot
			; Normal mob loot
			jsr get_random
			and #3
			beq end_mob_loot	; Skip if no loot this time

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
				lda #EnemyRunSouth
				sta enemy_anim_state,x
				rts
end_mob_loot
		lda #0
		sta xtablelo+enemy,x
		sta xtablehi+enemy,x
		sta ytable+enemy,x

		ldy CurrentMobTypes,x	; check if boss
		cpy #$0e
		bcc +	; jump if y < $0e
			; reset the extra boss sprites
			ldy #6
-			sta xtablelo+enemy+6,y
			sta xtablehi+enemy+6,y
			sta ytable+enemy+6,y
			dey
			bpl -
	
+		lda #EnemyDead
		sta enemy_state,x
		rts

; ------------------------------------------------------------------------------------
check_player_looting_enemy

		; ------------------
		; Heart
		; ------------------
		cmp #f_heart	; heart
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
		cmp #f_gold	; gold
		bne +++

			jsr get_random
			and #3
			clc
			adc enemy_gold,x
			jsr increase_gold
			inc StatsUpdated

		jmp ++
		; ------------------
+++
		; ------------------
		; Potions
		; ------------------
		cmp #f_potion
		bne +++
			; TODO: add potions
			jmp ++
		; ------------------
+++
		; ------------------
		; Arrows
		; ------------------
		cmp #f_arrows
		bne +++
			; TODO: add arrows
			jmp ++
		; ------------------
+++
		; ------------------
		; Sword
		; ------------------
		cmp #f_sword
		bne +++
			lda #InvSword
			sta SelWeapon
			ora Weapons
			sta Weapons
			inc StatsUpdated
			jmp ++
		; ------------------
+++
		; ------------------
		; Axe
		; ------------------
		cmp #f_axe
		bne +++
			lda #InvAxe
			sta SelWeapon
			ora Weapons
			sta Weapons
			inc StatsUpdated
			jmp ++
		; ------------------
+++
		; ------------------
		; Heart container
		; ------------------
		cmp #f_extra_heart
		bne +++
			lda #2
			jsr increase_max_hp
			inc StatsUpdated
			jmp ++
		; ------------------
+++
		rts
		; ------------------
		; TODO: More loot
		; ------------------
		; ------------------
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
		; ------------------

+		rts


; ------------------------------------------------------------------------------------
move_enemy
		ldy CurrentMobTypes,x
		sty CurrentMobType

		; determine movement speed
		lda mobtable_speed,y
		lsr

		; assume that speed = 0 is forbidden.
		; if a == 0 then:
		bne +
			lda AnimCounter
			and #$01	; Achieve subpixel accuracy by counting on every second frame :-)
		; end if
+		sta CurrentMobSpeed

		; Move in the stored direction
		stx tmp4		; store enemy (sprite) index
		ldy enemy_dir,x
		sty CurrentEnemyDir
		lda move_enemy_dir_x,y
		beq ++
		bpl +
			ldy CurrentMobType	; fetch mob type
			cpy #12			; if type >= 12 then no tile checks will be made
			bcs me__skip_lt_chk
			inx
			inx
			jsr get_tile_left_of_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving
me__skip_lt_chk		ldx tmp4
			lda xtablehi+enemy,x
			bne +++
				lda xtablelo+enemy,x
				cmp #xoffset+24
				bcc _enemy_stop_moving
+++			jsr move_enemy_left
			lda #EnemyRunWest
			sta FinalEnemyAnimState
			jmp ++

+			ldy CurrentMobType	; fetch mob type
			cpy #12			; if type >= 12 then no tile checks will be made
			bcs me__skip_rt_chk
			inx
			inx
			jsr get_tile_right_of_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving
me__skip_rt_chk		ldx tmp4
			lda xtablehi+enemy,x
			beq ++++
				lda xtablelo+enemy,x
				cmp #xoffset+16
				bcs _enemy_stop_moving
++++			jsr move_enemy_right
			lda #EnemyRunEast
			sta FinalEnemyAnimState
			jmp ++
; ---------------
check_enemy_blocking_tile
		; Check if enemy ran into a blocking tile.
		tay
		lda collision_map,y
		cmp #ct_block	; if carry is set, then enemy has run into a blocking tile.
		bcs +
		lda #0
		rts
+		lda #1
		rts
; ---------------
_enemy_stop_moving
		; Enemy ran into a tile => Go idle and wait to make a decision.
		ldx tmp4

		lda #EnemyIdle
		sta enemy_state,x
		;jsr get_random
		;lsr
		;sta enemy_timer,x
		rts			; return
; ---------------
++		ldy CurrentEnemyDir
		lda move_enemy_dir_y,y
		; if (enemy_dir_y[current_enemy] != 0) {
		beq +++ 
		bpl +
			; if (enemy_dir_y[current_enemy] < 0) {
			ldy CurrentMobType
			cpy #12			; if type >= 12 then no tile checks will be made
			bcs me__skip_up_chk
			inx
			inx
			jsr get_tile_above_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving
me__skip_up_chk		ldx tmp4
			lda ytable+enemy,x
			cmp #yoffset+16
			bcc _enemy_stop_moving
			jsr move_enemy_up
			lda #EnemyRunNorth
			sta FinalEnemyAnimState
			jmp +++
			; } else {
+			ldy CurrentMobType
			cpy #12			; if type >= 12 then no tile checks will be made
			bcs me__skip_dn_chk
			inx
			inx
			jsr get_tile_below_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving
me__skip_dn_chk		ldx tmp4
			lda ytable+enemy,x
			cmp #yoffset+160
			bcs _enemy_stop_moving
			jsr move_enemy_down
			lda #EnemyRunSouth
			sta enemy_anim_state,x
			rts
+++			; }
		; }
		lda FinalEnemyAnimState
		sta enemy_anim_state,x
		rts

move_enemy_dir_x
		; 8 values for x; south, west, north, east, southeast, southwest, northwest, northeast
		!byte 0, -1, 0, 1, 1, -1, -1, 1
move_enemy_dir_y
		; 8 values for y; south, west, north, east, southeast, southwest, northwest, northeast
		!byte 1, 0, -1, 0, 1, 1, -1, -1
; ------------------------------------------------------------------------------------


; ------------------------------------------------------------------------------------
; move_boss_2x2 - move a 2x2 grid of sprites (the boss)
; ------------------------------------------------------------------------------------
move_boss_2x2
		ldy CurrentMobTypes,x

		; determine movement speed
		lda mobtable_speed,y
		lsr

		; assume that speed = 0 is forbidden.
		; if a == 0 then:
		bne +
			lda AnimCounter
			and #$01	; Achieve subpixel accuracy by counting on every second frame :-)
		; end if
+		sta CurrentMobSpeed

		; Move in the stored direction
		stx tmp4		; store enemy (sprite) index
		ldy enemy_dir,x
		sty CurrentEnemyDir
		lda move_enemy_dir_x,y
		beq ++
		bpl +
			inx
			inx
			jsr get_tile_left_of_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving_b1
			ldx tmp4	; load enemy (sprite) index
			lda xtablehi+enemy,x
			bne +++
				lda xtablelo+enemy,x
				cmp #xoffset+24
				bcc _enemy_stop_moving_b1
+++			jsr move_enemy_left
			lda #EnemyRunWest
			sta FinalEnemyAnimState
			jmp ++

+			inx
			inx			
			jsr get_tile_right_of_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving_b1
			ldx tmp4	; load enemy (sprite) index
			lda xtablehi+enemy,x
			beq ++++
				lda xtablelo+enemy,x
				cmp #xoffset+16
				bcs _enemy_stop_moving_b1
++++			jsr move_enemy_right
			lda #EnemyRunEast
			sta FinalEnemyAnimState
			jmp ++
; ---------------
_enemy_stop_moving_b1
		; Enemy ran into a tile => Go idle and wait to make a decision.
		ldx tmp4

		lda #EnemyIdle
		sta enemy_state,x
		jsr clone_coordinates_for_boss
		rts			; return
; ---------------
++		ldx tmp4	; load enemy (sprite) index
		ldy CurrentEnemyDir
		lda move_enemy_dir_y,y
		beq +++
		bpl +
			inx
			inx
			jsr get_tile_above_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving_b1
			ldx tmp4
			lda ytable+enemy,x
			cmp #yoffset+16
			bcc _enemy_stop_moving_b1
			jsr move_enemy_up
			jsr boss_behavior
			lda #EnemyRunNorth
			jmp ++++

+			inx
			inx
			jsr get_tile_below_sprite
			jsr check_enemy_blocking_tile
			bne _enemy_stop_moving_b1
			ldx tmp4
			lda ytable+enemy,x
			cmp #yoffset+137
			bcs _enemy_stop_moving_b1
			jsr move_enemy_down
			jsr boss_behavior
			lda #EnemyRunSouth
			jmp ++++
+++		lda FinalEnemyAnimState
++++		sta enemy_anim_state,x
		jsr clone_coordinates_for_boss
		rts

;
;  Clones the coordinates of one sprite into a grid
;  of sprites (making up the big boss sprite)
;
; params:
;  x - current enemy idx
;
; post:
;  enemies x+6 to x+10 have same coordinates as enemy x but spread out in 2x3 grid of 24x21 sized sprites
clone_coordinates_for_boss
		; copy boss coordinates to its adjacent sprites 6, 7, 8, 9, 10
		clc
		lda xtablelo+enemy,x
		sta xtablelo+enemy+7,x
		sta xtablelo+enemy+9,x
		adc #24				; +24 pixels offset for right side sprites
		sta xtablelo+enemy+6,x
		sta xtablelo+enemy+8,x
		sta xtablelo+enemy+10,x
		lda xtablehi+enemy,x
		sta xtablehi+enemy+6,x
		sta xtablehi+enemy+7,x
		sta xtablehi+enemy+8,x
		sta xtablehi+enemy+9,x
		sta xtablehi+enemy+10,x
		bcc +				; if carry was set from "adc #24" above...
			inc xtablehi+enemy+6,x	; set bit 9 for sprites 6,8,10
			inc xtablehi+enemy+8,x
			inc xtablehi+enemy+10,x
+		clc
		lda ytable+enemy,x
		sta ytable+enemy+6,x
		adc #21				; +21 pixels offset for second row of sprites
		sta ytable+enemy+7,x
		sta ytable+enemy+8,x
		adc #21				; +21 pixels offset for third row of sprites
		sta ytable+enemy+9,x
		sta ytable+enemy+10,x
		rts

; ------------------------------------------------------------------------------------
move_enemy_left
		lda xtablelo+enemy,x		; Subtract move speed from enemy sprite X coordinate {
		sec
		sbc CurrentMobSpeed
		sta xtablelo+enemy,x
		lda xtablehi+enemy,x
		sbc #0
		sta xtablehi+enemy,x		; }
		rts
move_enemy_right
		lda xtablelo+enemy,x
		clc
		adc CurrentMobSpeed		; Add move speed to enemy sprite X coordinate {
		sta xtablelo+enemy,x
		lda xtablehi+enemy,x
		adc #0
		sta xtablehi+enemy,x		; }
		rts
move_enemy_up
		lda ytable+enemy,x		; Subtract move speed from enemy sprite Y coordinate {
		sec
		sbc CurrentMobSpeed
		sta ytable+enemy,x		; }
		rts
move_enemy_down
		lda ytable+enemy,x		; Add move speed to enemy sprite Y coordinate {
		clc
		adc CurrentMobSpeed
		sta ytable+enemy,x		; }
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
		tax
		clc
		adc #8		; This is the attack state, now determine which direction
		sta PlayerAnimState

		; Show weapon sprite
		lda xtablehi+player
		sta xtablehi+weapon
		lda xtablelo+player
		sta xtablelo+weapon
		cpx #1
		bne +
			sec
			sbc #16
			sta xtablelo+weapon
			bcs ++
				dec xtablehi+weapon
				jmp ++
+		cpx #3
		bne ++
			clc
			adc #16
			sta xtablelo+weapon
			bcc ++
				inc xtablehi+weapon
++		lda ytable+player
		sta ytable+weapon
		cpx #0
		bne +
			clc
			adc #16
			sta ytable+weapon
			jmp ++
+		cpx #2
		bne ++
			sec
			sbc #16
			sta ytable+weapon
++
		lda #0
		sta color+weapon
		lda #8
		sta color+weapon+16
		lda #$63
		sta frame+weapon
		lda player_weapon_frames,x
		sta frame+weapon+16
		rts


		;     I   N   V   E   N   T   O   R   Y
text_inv	!byte $09,$0e,$16,$05,$0e,$14,$0f,$12,$19
		;         I   T   E   M   S
text_items	!byte $20,$09,$14,$05,$0d,$13,$20
		;         W   E   A   P   O   N   S
text_weapons	!byte $20,$17,$05,$01,$10,$0f,$0e,$13,$20
		;     -   S   P   A   C   E   -
text_space	!byte $1b,$13,$10,$01,$03,$05,$1b

fire_color	!byte $02,$0a,$07,$01,$01,$07,$0a,$02
magical_color	!byte $01,$15,$14,$06,$06,$14,$15,$01
item_color_idx	!byte $00

;		Items in the mask:
;		1 - Arrows
;		2 - Necklace
;		4 - Shield
;		8 - Master key
;		16 - Torch
;		32 - Gauntlet
;		64 - Raft
;		128 - Armor
items_mask	!byte $00,$00
;-----------------------------------------------------------

; ----------------------------------------------------------
; safekeeping area for system variables
; ----------------------------------------------------------
safekeeping
last_device	!byte $00	;	$ba
; ----------------------------------------------------------

; LONG TERM VARIABLE DATA (must be kept uncorrupted!)
persistent_vars_begin

; PLAYER/ENEMY DATA TABLES
player_max_hp
		!byte $00,$06	; store as strings, for efficiency 
player_hp
		!byte $00,$06			; bcd string
player_level
		!byte $00,$01			; bcd string
player_gold
		!byte $00,$00,$00,$00,$00	; bcd string
enemy_hp
		!byte $00,$00,$00,$00,$00,$00,$00,$00 
enemy_ap
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_gold
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_state
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_anim_state
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_lootidx
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_nextpos_x
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_nextpos_y
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_timer
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_pull_force_x
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_pull_force_y
		!byte $00,$00,$00,$00,$00,$00,$00,$00
enemy_dir
		!byte $00,$00,$00,$00,$00,$00,$00,$00

CurrentRoomIdx	!byte $00	; 1-byte room index on map

; 16-bit mob data currently on screen
CurrentMobTypes	!byte $00,$00,$00,$00,$00,$00,$00,$00,$00	; list of up to 9 bytes

; Each world/dungeon has up to two bosses. This array defines room and tile position of each boss.
; It is checked each time a room is entered, and the location matches the room position and position within the room (2nd byte).
; When a boss is defeated, its position shall be set to $ff permanently so it won't appear again.
boss_loc_array	;    Room,Tile		  Map
		!byte $ff,$ff,$ff,$ff	; outdoor world
		!byte $02,$30,$ff,$ff	; dungeon 0
		!byte $ff,$ff,$ff,$ff	; dungeon 1
		!byte $ff,$ff,$ff,$ff	; dungeon 2
		!byte $ff,$ff,$ff,$ff	; dungeon 3
		!byte $ff,$ff,$ff,$ff	; dungeon 4
		!byte $ff,$ff,$ff,$ff	; dungeon 5
		!byte $ff,$ff,$ff,$ff	; dungeon 6
		!byte $ff,$ff,$ff,$ff	; dungeon 7



; --------------------------------------------
;  Persistent changes (introduced by switches)
;  labels start with "pc_" and allow up to 7
;  tiles per map to change persistently (between loads.) 
;  This index refers to offsets in the target
;  lists below it, depending on which map
;  we're currently playing in.
; --------------------------------------------
pc_map_idx	; Do not modify this table!
		!byte $00
		!byte pc_target_list_d0-pc_target_list_base
		!byte pc_target_list_d1-pc_target_list_base
		!byte pc_target_list_d2-pc_target_list_base
		!byte pc_target_list_d3-pc_target_list_base
		!byte pc_target_list_d4-pc_target_list_base
		!byte pc_target_list_d5-pc_target_list_base
		!byte pc_target_list_d6-pc_target_list_base

; byte sequences of room pos, tile pos, and tile idx.
; Do not modify these tables! They are used as storage for switch effects.
pc_target_list_base
pc_target_list_outdoor
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d0
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d1
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d2
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d3
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d4
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d5
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
pc_target_list_d6
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff

persistent_vars_end
end_code_c000


; ***** FREE SPACE: 489 bytes


; -----------------------------------------------------------------
; $d000

; $f000 - player_max_hp
; .... see beginning of this file for content in this RAM area.

;		*=$fa00
; -------------------------------------------------
;
;		TILE BUFFER AREA
;		; $fa00 - $faff
;		; do not allocate anything else here
;
; -------------------------------------------------

;end_code_f000

