!sl	"coretables_labels.a"
!to	"coretables.prg", cbm
!source "const.asm"



; game core specific data
		*=$f000

; ----------------------
; Player and HUD data
; ----------------------
player = 0 	; (in indexes 0-15)
weapon = 1
enemy = 2


AnimCounter = $5f

;------------------------------------------------------------------------------------
; Kernal area variables [$f000-$fffd], use this space to save on load memory
;------------------------------------------------------------------------------------

; STATIC DATA + TEMPORARY VARIABLE DATA - can be reloaded / initialized to memory for each new map!

;-----------------------------------------------------------
; tile-to-screen lookup tables (will be generated on setup)
; contains the relative positions for tiles on screen
;-----------------------------------------------------------
coretables_begin

tilepos_lo
		!fill 240,0
tilepos_hi
		!fill 240,0

;-----------------------------------------------------------
; sprites coordinates, color and frame tables
;-----------------------------------------------------------
ytable
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
xtablelo
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
xtablehi
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
color
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
frame
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

;-----------------------------------------------------------
; temporary color memory buffer used with screen transitions
;-----------------------------------------------------------
;colorbuffer	!fill 1024,$00

;-----------------------------------------------------------
; tile buffer for unpacking and storing current map room
;-----------------------------------------------------------
tilebuffer	!fill 240,$00

;------------------------------------------------------------------------------------

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


;-----------------------------------------------------------
; Generated sine table (gen_sine_table)
;-----------------------------------------------------------
sine
		!fill 256,0

; data used by ctrl_player routine and its
; subroutines:
tmp_doorexit	!byte $00
tmp_trans_xhi	!byte $00
tmp_trans_xlo	!byte $00
tmp_trans_y	!byte $00

; Aliases to same storage
tmp_chest_loc
tmp_tree_loc
sw_src_pos
		!byte $00
tmp_chest_idx
tmp_tree_idx
sw_src_tile
		!byte $00

sw_target_room	!byte $00
sw_target_pos	!byte $00
sw_target_tile	!byte $00
sw_state	!byte $00
sw_state_swa	!byte $00
sw_tmp_y	!byte $00
sw_tmp_x	!byte $00
sw_cond		!byte $00

; params: y = weapon # (InvSword, InvAxe, ...etc), must be > 0.
; returns: a = 1 if present, 0 if not.
check_weapon_presence
		cpy #InvArrows
		bne +
			lda ArrowQ
			sta item_value_adder
+		tya
		and Weapons
		bne +
			rts
+		lda #1
		clc
		adc item_value_adder
		rts

; params: y = weapon # (InvSword, InvAxe, ...etc), must be > 0.
; returns: a > 0 (1, 2 or 3 as power) if present, 0 if not present.
check_item_presence
		cpy #InvArmor
		bne +
			lda ArmorQ
			sta item_value_adder
+		cpy #InvNecklace
		bne +
			lda NecklaceQ
			sta item_value_adder
+		tya
		and Items
		bne +
			rts
+		lda #1
		clc
		adc item_value_adder
		rts
item_value_adder
		!byte $00

coretables_end
