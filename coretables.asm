!sl	"coretables_labels.a"
!to	"coretables.prg", cbm

; game core specific data
		*=$f000

;------------------------------------------------------------------------------------
; Kernal area variables [$f000-$fffd], use this space to save on load memory
;------------------------------------------------------------------------------------

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
MobSrc		!word $0000	; 2-byte address where mob data is fetched

;-----------------------------------------------------------
; tile-to-screen lookup tables
; contains the relative positions for tiles on screen
;-----------------------------------------------------------

tilepos_lo
		!byte $00,$02,$04,$06,$08,$0a,$0c,$0e,$10,$12,$14,$16,$18,$1a,$1c,$1e
		!byte $20,$22,$24,$26,$50,$52,$54,$56,$58,$5a,$5c,$5e,$60,$62,$64,$66
		!byte $68,$6a,$6c,$6e,$70,$72,$74,$76,$a0,$a2,$a4,$a6,$a8,$aa,$ac,$ae
		!byte $b0,$b2,$b4,$b6,$b8,$ba,$bc,$be,$c0,$c2,$c4,$c6,$f0,$f2,$f4,$f6
		!byte $f8,$fa,$fc,$fe,$00,$02,$04,$06,$08,$0a,$0c,$0e,$10,$12,$14,$16
		!byte $40,$42,$44,$46,$48,$4a,$4c,$4e,$50,$52,$54,$56,$58,$5a,$5c,$5e
		!byte $60,$62,$64,$66,$90,$92,$94,$96,$98,$9a,$9c,$9e,$a0,$a2,$a4,$a6
		!byte $a8,$aa,$ac,$ae,$b0,$b2,$b4,$b6,$e0,$e2,$e4,$e6,$e8,$ea,$ec,$ee
		!byte $f0,$f2,$f4,$f6,$f8,$fa,$fc,$fe,$00,$02,$04,$06,$30,$32,$34,$36
		!byte $38,$3a,$3c,$3e,$40,$42,$44,$46,$48,$4a,$4c,$4e,$50,$52,$54,$56
		!byte $80,$82,$84,$86,$88,$8a,$8c,$8e,$90,$92,$94,$96,$98,$9a,$9c,$9e
		!byte $a0,$a2,$a4,$a6,$d0,$d2,$d4,$d6,$d8,$da,$dc,$de,$e0,$e2,$e4,$e6
		!byte $e8,$ea,$ec,$ee,$f0,$f2,$f4,$f6,$20,$22,$24,$26,$28,$2a,$2c,$2e
		!byte $30,$32,$34,$36,$38,$3a,$3c,$3e,$40,$42,$44,$46,$70,$72,$74,$76
		!byte $78,$7a,$7c,$7e,$80,$82,$84,$86,$88,$8a,$8c,$8e,$90,$92,$94,$96
tilepos_hi_a
		!byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
		!byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
		!byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
		!byte $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
		!byte $40,$40,$40,$40,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
		!byte $41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
		!byte $41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
		!byte $41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41,$41
		!byte $41,$41,$41,$41,$41,$41,$41,$41,$42,$42,$42,$42,$42,$42,$42,$42
		!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42
		!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42
		!byte $42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42,$42
		!byte $42,$42,$42,$42,$42,$42,$42,$42,$43,$43,$43,$43,$43,$43,$43,$43
		!byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43
		!byte $43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43,$43

tilepos_hi_b
		!byte $44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44
		!byte $44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44
		!byte $44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44
		!byte $44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44,$44
		!byte $44,$44,$44,$44,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
		!byte $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
		!byte $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
		!byte $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
		!byte $45,$45,$45,$45,$45,$45,$45,$45,$46,$46,$46,$46,$46,$46,$46,$46
		!byte $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
		!byte $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
		!byte $46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46,$46
		!byte $46,$46,$46,$46,$46,$46,$46,$46,$47,$47,$47,$47,$47,$47,$47,$47
		!byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47
		!byte $47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47,$47

colormem_hi
		!byte $d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8
		!byte $d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8
		!byte $d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8
		!byte $d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8,$d8
		!byte $d8,$d8,$d8,$d8,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
		!byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
		!byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
		!byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9
		!byte $d9,$d9,$d9,$d9,$d9,$d9,$d9,$d9,$da,$da,$da,$da,$da,$da,$da,$da
		!byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da
		!byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da
		!byte $da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da,$da
		!byte $da,$da,$da,$da,$da,$da,$da,$da,$db,$db,$db,$db,$db,$db,$db,$db
		!byte $db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db
		!byte $db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db,$db

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

		; More tables :-)

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
; Player's start location position arrays per map
; --------------------------------------------
; player's starting pos in tiles
StartLocX	!byte 8,30,0,0,0,0,0,0
StartLocY	!byte 91,34,0,0,0,0,0,0

; screen starting pos (left corner) in tiles
MapStartX	!byte 0,20,0,0,0,0,0,0
MapStartHiX	!byte 0,0,0,0,0,0,0,0
MapStartY	!byte 84,24,0,0,0,0,0,0

; screen graphics colors per map
BorderColor	!byte 0,0,0,0,0,0,0,0
BGColor		!byte 9,0,0,0,0,0,0,0
MultiColor1	!byte 15,12,0,0,0,0,0,0
MultiColor2	!byte 11,9,0,0,0,0,0,0

; --------------------------------------------
;  Persistent changes (introduced by switches)
;  allows up to 7 tiles per map
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
		!byte pc_target_list_d7-pc_target_list_base

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
pc_target_list_d7
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff

; These tables below are for animating loot "jumping" out of a chest when opened.
; - Formula for this is: let f = frame index; sprite_y = sprite_y + move_table[f] - sine_table[f]
; - Sine table can have more uses, like rotating movement simulation, or bouncing effect. Max offsets are exactly 1 tile vertically or horizontally, in both arrays.

sine_table	; 50 bytes sine table
		!byte $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$09,$0a,$0b,$0c,$0c,$0d
		!byte $0e,$0e,$0e,$0f,$0f,$0f,$10,$10,$10,$10,$10,$10,$10,$0f,$0f,$0f
		!byte $0e,$0e,$0e,$0d,$0c,$0c,$0b,$0a,$09,$09,$08,$07,$06,$05,$04,$03
		!byte $02,$01

move_table	; 50 bytes move south table
		!byte $00,$00,$00,$00,$00,$01,$01,$01,$02,$02,$02,$03,$03,$03,$04,$04
		!byte $04,$05,$05,$05,$06,$06,$06,$07,$07,$07,$08,$08,$08,$09,$09,$09
		!byte $0a,$0a,$0a,$0b,$0b,$0c,$0c,$0c,$0d,$0d,$0d,$0e,$0e,$0e,$0f,$0f
		!byte $0f,$0f

num_dirs_table	!byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
		!byte $03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03,$03
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
		!byte $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07

fadeout_colors_bg_border
		!byte $00,$00,$00,$00,$09,$09,$09,$09
fadeout_colors_extra_color1
		!byte $09,$09,$0b,$0b,$0c,$0c,$0f,$0f
fadeout_colors_extra_color2
		!byte $09,$09,$09,$09,$0b,$0b,$0b,$0b
gradient_fader
		!byte $00,$07,$04,$06,$06,$06,$00,$05
		!byte $08,$0f,$0c,$0e,$0e,$0e,$08,$0d
damage_flash
		!byte $07,$07,$02,$02

boss_loc_array	; Each world/dungeon has up to two bosses. This array defines room and tile position of each boss.
		; It is checked each time a room is entered, and the location matches the room position and position within the room (2nd byte).
		; When a boss is defeated, its position shall be set to $ff permanently so it won't appear again.
		;    Room,Tile		  Map
		!byte $ff,$ff,$ff,$ff	; outdoor world
		!byte $02,$30,$ff,$ff	; dungeon 0
		!byte $ff,$ff,$ff,$ff	; dungeon 1
		!byte $ff,$ff,$ff,$ff	; dungeon 2
		!byte $ff,$ff,$ff,$ff	; dungeon 3
		!byte $ff,$ff,$ff,$ff	; dungeon 4
		!byte $ff,$ff,$ff,$ff	; dungeon 5
		!byte $ff,$ff,$ff,$ff	; dungeon 6
		!byte $ff,$ff,$ff,$ff	; dungeon 7


; -------------------------------
;  Text characters locations + 
;  symbol codes per map
; -------------------------------
txt_sp = 32
txt_start = 1
num_start = 48
txt_heart = 36
txt_key = 37
txt_coin = 38
txt_slash = 39
; -------------------------------



; --------------------------------------------
; SFX suite	
; 		format is: BYTE<8 bits>,BYTE<high 4 bits|low 4 bits>, ...

;		SFX format:
;		  <attack|decay>, <systain|release>, <1 byte pulse width (reversed high/low bytes)>,
;		  <wave form value = [$10,$11,$20,$21,$40,$41,$80,$81]> OR 
;		  <absolute note value n = [n >$81, n < $c0] >, ...
sword_swing
		!byte $67,$f8,$00,$b8,$81,$bf,$80,$b8,$b4,$b2,$00

; -----------------------------------------------------------------

coretables_end
