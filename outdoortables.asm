!sl	"outdoortables_labels.a"
!to	"outdoortables.prg", cbm
!source "coretables_labels.a"

; ----------------------
;  Enemy frame constants
; ----------------------
f_base		= 64
f_death 	= f_base + 32
f_blob 		= f_base + 82
f_spider	= f_base + 88
f_skeleton	= f_base + 104
f_knight	= f_base + 112

; ----------------------
;  NPC frame constants
; ----------------------
f_man 		= f_base + 80
f_woman		= f_base + 80
f_boy		= f_base + 81
f_girl		= f_base + 81

; ----------------------
;  Item frame constants
; ----------------------
f_axe		= f_base + 72
f_sword		= f_base + 73
f_shield	= f_base + 74
f_bow		= f_base + 75
f_extra_heart	= f_base + 64
f_necklace	= f_base + 65
f_raft		= f_base + 66
f_armor		= f_base + 67
f_key		= f_base + 48
f_masterkey	= f_base + 49
f_torch		= f_base + 50
f_gauntlet	= f_base + 51

; ----------------------
;  Loot frame constants
; ----------------------
f_nothing	= f_base + 35
f_heart		= f_base + 56
f_gold		= f_base + 57
f_potion	= f_base + 58
f_arrows	= f_base + 59
f_sword		= f_base + 73

; ----------------------
;  Loot color constants
; ----------------------
col_f_nothing	= $00	; fill colors
col_f_heart	= $01
col_f_gold	= $07
col_f_potion	= $06
col_f_arrows	= $07
col_f_sword	= $01
col_f_axe	= $01

col_c_nothing	= $00	; contour colors
col_c_heart	= $02
col_c_gold	= $01
col_c_potion	= $00
col_c_arrows	= $01
col_c_sword	= $03
col_c_axe	= $0f

; ----------------------
; Tile indices
; ----------------------
TileChestClosedLeft = 22
TileChestClosedRight = 23
TileChestOpenLeft = 62
TileChestOpenRight = 63
TileSwitchInactive = 37
TileSwitchActive = 38

; ----------------------
;  Collision tiles
; ----------------------
; Collision type for each tile type
ct_passable	= 0	; passable  - tile that can be walked over, enemies can spawn on it.
ct_door		= 1	; door      - tile transports player to some destination on current or a different map.
ct_block	= 2	; block     - unpassable block, enemies won't spawn on it.
ct_tree		= 3	; tree      - as "ct_block" but can be removed with an axe.
ct_chest	= 4	; chest     - interactive tile which can be opened and reveals an item.
ct_locked	= 5	; locked    - a locked tile, usually a door.
ct_runestone	= 6	; runestone - a tile, when interacted with, can teach a spell.
ct_infostone	= 7	; infostone - a tile that can be read when interacted with.
ct_crushable	= 8	; crushable - a tile that can be crushed with a (hammer).
ct_movable	= 9	; movable   - a tile that can be moved by pushing it.
ct_cenotaph	= 10	; cenotaph  - a grave, can spawn zombies/skeletons or other monsters if disturbed.
ct_switch	= 11	; switch    - when interacted with it toggles its state, and can change other tiles.



;---------------------------------------------------------------------------------------------------------
; Outdoor map specific data
		*=$e000		; will be loaded here

;---------------------------------------------------------------------------------------------------------
; MAIN WORLD DOORS - Each cell here is a reference to another cell. Store on disk with world.
;                    These tables can be loaded from disk (they will not change.)
;---------------------------------------------------------------------------------------------------------
doortable	; e0-ef indicates offset in "doortablemulti". $f0-$fe are dungeons 1-15, $ff means no door
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $ff,$83,$83,$80,$ff,$87,$ff,$88,$ff,$89,$8a,$ff,$8b,$ff,$ff,$8f ; $00
		!byte $ff,$85,$86,$ff,$81,$ff,$ff,$ff,$ff,$ff,$ff,$8d,$ff,$8e,$ff,$ff ; $10
		!byte $ff,$84,$92,$82,$8c,$ff,$93,$96,$e0,$ff,$97,$ff,$99,$ff,$91,$9a ; $20
		!byte $9b,$9f,$ff,$ff,$ff,$9d,$9c,$ff,$95,$ff,$ff,$98,$ff,$ff,$ff,$ff ; $30
		!byte $ff,$9e,$c0,$ff,$ff,$ff,$a1,$a2,$ff,$a3,$ff,$a6,$a5,$a7,$aa,$a8 ; $40
		!byte $a9,$f0,$a0,$ab,$ff,$ac,$ad,$b4,$ff,$e1,$e2,$ff,$ff,$ff,$ff,$b5 ; $50
		!byte $f1,$ff,$b6,$b8,$ff,$ff,$ff,$b9,$ff,$ba,$ff,$ff,$bb,$bf,$ff,$ff ; $60
		!byte $bc,$bd,$be,$ff,$ff,$ff,$a4,$c1,$c2,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $70
		; --------------------------------------------------------------------------
		!byte $03,$14,$23,$e3,$21,$11,$12,$05,$07,$09,$0a,$0c,$24,$1b,$1d,$0f ; $80
		!byte $28,$2e,$22,$26,$28,$38,$27,$2a,$3b,$2c,$2f,$30,$36,$35,$41,$31 ; $90
		!byte $52,$46,$47,$49,$76,$4c,$4b,$4d,$4f,$50,$4e,$53,$55,$56,$59,$59 ; $a0
		!byte $59,$5a,$5a,$5a,$57,$5f,$62,$60,$63,$67,$69,$6c,$70,$71,$72,$6d ; $b0 ; $b7 can be freed, referenced from $60 earlier
		!byte $42,$77,$78                                                     ; $c0

doortablemulti
		!byte $94,$90,$ff
		!byte $ae,$af,$b0,$ff
		!byte $b1,$b2,$b3,$ff
		!byte $01,$02,$ff

doorexits	; Exit tile position on *target* screen if door exists on that screen.
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

; extensions
;		$00-$3f = locked doors (if tile #1 then must magically be revealed) (position) (if tile #2 then reference to loot_trigger table instead)
;		$40-$7f = chests (position, content)
;		$80-$bf = destroyable blocks (not stones! they are all breakable.) (position, content)
;		$c0-$ef = runestones (spells) (spell number) or triggers when looting an item
;		$f0-$fe = switches (refers to two-state switchlist table 'switch_lists', max 14 entries) (position ref list ending with $ff)

; notes:        - If $00-$3f but no door nor grass, then reveal a life container instead.
extensions
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$80,$81,$ff,$c0,$82,$ff,$83,$ff,$84,$85,$ff,$86,$ff,$ff,$c1	; $00
		!byte $ff,$ff,$ff,$87,$c2,$ff,$ff,$ff,$ff,$88,$c3,$40,$ff,$89,$ff,$ff	; $10
		!byte $ff,$01,$8a,$ff,$ff,$ff,$8b,$8c,$02,$ff,$03,$ff,$8d,$ff,$04,$8e	; $20
		!byte $8f,$90,$91,$ff,$ff,$ff,$92,$ff,$05,$ff,$ff,$ff,$ff,$93,$ff,$ff	; $30
		!byte $ff,$c4,$94,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$95,$06,$96,$97,$98	; $40
		!byte $ff,$ff,$ff,$99,$41,$ff,$07,$9a,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	; $50
		!byte $9b,$ff,$ff,$9c,$ff,$ff,$ff,$9d,$ff,$9e,$ff,$ff,$9f,$a0,$ff,$a1	; $60
		!byte $ff,$ff,$a2,$ff,$08,$ff,$a3,$ff,$a4,$ff,$ff,$ff,$ff,$ff,$ff,$09	; $70
		; -------------------------------------------------------------------
		!byte $42,$43,$ff,$44,$45,$ff,$ff,$44,$45,$45,$45,$45,$46,$ff,$47,$c5	; $80
		!byte $48,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	; $90
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	; $a0
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$00,$ff,$ff,$ff	; $b0
		!byte $ff,$ff,$ff							; $c0

; pairs of (screen tile position, item) for:
chests		; $00 - $3f
		!byte item_sword-item_base
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; screen tile positions and content for:
destroyable_blocks	; $80 - $bf
		!byte $ff
; content for:
runestones		; $c0 - $ef
		!byte $ff

switch_sets	; indices $f0 - $fe, values are offsets in switch_lists
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; switches
switch_lists	; padding bytes (32 bytes in total for switch_lists)
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; switch	(state, position, AND condition, targets)
;               -  tile will be incremented by 1 when switched on and decremented by 1 when switched off
;		-  position is tile position of switch on screen
;               -  targets is a list of switch target tiles affected by this switch, for example:
;		   !byte .. , swtarget0-swtargetbase, swtarget1-swtargetbase, $ff,$ff,$ff
;		      - will contain two target tiles and ends list with $ff
;		-  AND condition indicates a dependency on an extra switch to activate, for example:
;
;                  switch_0	!byte $26, $40, swtarget_0-swtargetbase, $ff, switch_1-swbase =>
;
;			        Here "switch_1" needs to be ON for "switch_0" to activate its target.
;
;		   If AND condition is set to $fe, it will be a toggle switch instead
;		   If AND condition is set to $ff, then there is no condition.
swbase
switch_0	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_1	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_2	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_3	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_4	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_5	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_6	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_7	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

; switch target (room, position, tile_on, tile_off)
swtargetbase
swtarget0	!byte $ff, $ff, 0, 0
swtarget1	!byte $ff, $ff, 0, 0
swtarget2	!byte $ff, $ff, 0, 0
swtarget3	!byte $ff, $ff, 0, 0
swtarget4	!byte $ff, $ff, 0, 0
swtarget5	!byte $ff, $ff, 0, 0
swtarget6	!byte $ff, $ff, 0, 0
swtarget7	!byte $ff, $ff, 0, 0

; weapon frames + colors
item_base
item_axe	!byte f_axe, col_f_axe, col_c_axe, $ff
item_sword	!byte f_sword, col_f_sword, col_c_sword, $ff

; -------------------------------------------------
; MOB DATA
; -------------------------------------------------

mobs_entries
;          each label here is a list (until next label) with 1 header byte:
;           - header byte:  number of groups
;           - group 0 byte #0:  enemy type (0-255)
;           - group 0 byte #1:  quantity in group 0
;           - group 1 byte #0:  enemy type (0-255)
;           - group 1 byte #1:  quantity in group 1
;           - ... etc
;
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
grp_nothing
		; $00
		!byte $00		; empty room
grp_4x_blueknights
		; $01
		!byte $01,$07,$04	; # of groups; type[0]; qty in group[0]; type[1]; qty in group[1]; ...
grp_4x_blueskellies
		; $04
		!byte $01,$06,$04
grp_4x_greenknights
		; $07
		!byte $01,$03,$04
grp_4x_bluespiders
		; $0a
		!byte $01,$05,$04
grp_4x_greenskellies
		; $0d
		!byte $01,$02,$04
grp_4x_greenspiders
		; $10
		!byte $01,$01,$04
grp_4x_greenslimes
		; $13
		!byte $01,$00,$04
grp_1x_greenskelly
		; $16
		!byte $01,$02,$01
grp_1x_greenslime
		; $19
		!byte $01,$00,$01
grp_6x_greenslime
		; $1c
		!byte $01,$00,$06
grp_6x_greenspiders
		; $1f
		!byte $01,$01,$06
grp_2x_greenslime
		; $22
		!byte $01,$00,$02
grp_1x_npc_0
		; $25
		!byte $01,$80,$01
grp_0e_not_used			; use this for NPC?
		; $28
		!byte $00,$00,$00
grp_0f_not_used			; use this for NPC?
		; $2b
		!byte $00,$00,$00

;-----------------------------------------------------------
; Level data constants (occupies $d0 bytes = 208 bytes)
;-----------------------------------------------------------
world
		; mobs_entries references

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $01,$04,$04,$04,$07,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00
		!byte $0a,$0a,$0d,$0d,$0d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $01
		!byte $0a,$10,$10,$0d,$0d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $02
		!byte $0a,$10,$10,$13,$13,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $03
		!byte $0a,$0a,$10,$13,$13,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $04
		!byte $1c,$13,$10,$13,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $05
		!byte $19,$1f,$00,$10,$13,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $06
		!byte $00,$13,$16,$13,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $07

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $08
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $09
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$25,$00,$00,$00 ; $0b
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $0c

		; Attack states [south, west, north, east]
player_weapon_frames
		!byte $68,$69,$6a,$6b

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
		!byte f_death,f_death+1,f_death+2,f_death+3
EnemyAnimTable
		; SLIME
		; Run south
		!byte f_blob,f_blob+1,f_blob,f_blob+1
		; Run west
		!byte f_blob,f_blob+1,f_blob,f_blob+1
		; Run north
		!byte f_blob,f_blob+1,f_blob,f_blob+1
		; Run east
		!byte f_blob,f_blob+1,f_blob,f_blob+1
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

		; SPIDER
		; Run south
		!byte f_spider,f_spider+1,f_spider,f_spider+1
		; Run west
		!byte f_spider+2,f_spider+3,f_spider+2,f_spider+3
		; Run north
		!byte f_spider+8,f_spider+9,f_spider+8,f_spider+9
		; Run east
		!byte f_spider+10,f_spider+11,f_spider+10,f_spider+11
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

		; SKELETON
		; Run south
		!byte f_skeleton,f_skeleton+1,f_skeleton,f_skeleton+2
		; Run west
		!byte f_skeleton,f_skeleton+1,f_skeleton,f_skeleton+2
		; Run north
		!byte f_skeleton,f_skeleton+1,f_skeleton,f_skeleton+2
		; Run east
		!byte f_skeleton,f_skeleton+1,f_skeleton,f_skeleton+2
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

		; KNIGHT
		; Run south
		!byte f_knight,f_knight+1,f_knight,f_knight+1
		; Run west
		!byte f_knight+2,f_knight+3,f_knight+2,f_knight+3
		; Run north
		!byte f_knight+8,f_knight+9,f_knight+8,f_knight+9
		; Run east
		!byte f_knight+10,f_knight+11,f_knight+10,f_knight+11
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

BossAnimTable
		; Sprite tile set animations (20 frames) (add 8 to frame number for next boss in table)

		; Idle frames
		!byte 0, 0, 0, 0
		; Attack frames
		!byte 0, 0, 0, 0
		; Move frames
		!byte 0, 0, 0, 0
		; Hide frames
		!byte 0, 0, 0, 0
		; Death frames
		!byte 0, 0, 0, 0

		; No boss, padding 20 bytes
		!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BossFrames2x2
		; BOSS 2x2 frame sprite sets (8 x 2x2 sprites), 32 bytes

		; Padding 32 bytes (no boss frames)
		!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
		!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BossFrames2x3
		; BOSS 2x3 frame sprite sets (8 x 2x3 sprites), 48 bytes

		; Padding 16 bytes (no boss frames)
		!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

		; man, boy, woman, girl
NpcImageList	!byte f_man,f_boy,f_woman,f_girl


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
loot_list
		!byte f_nothing,f_heart,f_gold,f_potion
loot_colors_fill
		!byte col_f_nothing,col_f_heart,col_f_gold,col_f_potion
loot_colors_contour
		!byte col_c_nothing,col_c_heart,col_c_gold,col_c_potion

		; Collision type for each tile type
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
		; b = switch
collision_map	!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$01,$01,$00
		!byte $00,$00,$00,$00,$02,$03,$04,$04
		!byte $02,$02,$02,$02,$05,$02,$02,$02
		!byte $02,$02,$02,$06,$07,$08,$09,$02
		!byte $02,$02,$02,$02,$00,$02,$02,$0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$02,$02

; Everything below is static data
; ------------------------------------------------
; Player's start location position arrays per map
; ------------------------------------------------
; player's starting pos in tiles
;
StartLocX	!byte 8,4,0,0,0,0,0,0
StartLocY	!byte 91,76,0,0,0,0,0,0

; screen starting pos (left corner) in tiles
MapStartX	!byte 0,0,0,0,0,0,0,0
MapStartHiX	!byte 0,0,0,0,0,0,0,0
MapStartY	!byte 84,72,0,0,0,0,0,0


; screen graphics colors per map
BorderColor	!byte 0
BGColor		!byte 9
MultiColor1	!byte 15
MultiColor2	!byte 11

num_dirs_table	!byte $03,$03,$03,$03,$03,$03,$03,$03,$07,$07,$07,$07,$07,$07,$03,$03

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


; Tables indexed by this direction list: 0=south, 1=west, 2=north, 3=east
player_x_force_by_dir
		!byte $00,$06,$00,$fa	; push force affecting player will be opposite of his/her direction
player_y_force_by_dir
		!byte $fa,$00,$06,$00
enemy_x_force_by_dir
		!byte $00,$fa,$00,$06	; push force affecting enemy will be opposite of his/her direction
enemy_y_force_by_dir
		!byte $06,$00,$fa,$00



; --------------------------------------------
; SFX suite	
; 		format is: BYTE<8 bits>,BYTE<high 4 bits|low 4 bits>, ...
;		SFX format:
;		  <attack|decay>, <systain|release>, <1 byte pulse width (reversed high/low bytes)>,
;		  <wave form value = [$10,$11,$20,$21,$40,$41,$80,$81]> OR 
;		  <absolute note value n = [n >$81, n < $c0] >, ...
sword_swing
		!byte $67,$f8,$00,$b8,$81,$bf,$80,$b8,$b4,$b2,$00

boss_behavior
		clc
		lda AnimCounter
		asl
		tay
		lda sine,y
		adc ytable+enemy,x
		sta ytable+enemy,x
		rts

outdoortables_end
