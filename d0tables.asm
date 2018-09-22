!sl	"d0tables_labels.a"
!to	"d0tables.prg", cbm


; ----------------------
;  Enemy frame constants
; ----------------------
f_death 	= $60
f_blob 		= $92
f_spider	= $98
f_skeleton	= $a8
f_knight	= $b8
f_bat 		= $92
f_rat		= $98

; ----------------------
;  Item frame constants
; ----------------------
f_bow		= $8b
f_necklace	= $81
f_shield	= $89
f_masterkey	= $71
f_torch		= $72
f_gauntlet	= $73
f_raft		= $82
f_armor		= $83

; ----------------------
;  Loot frame constants
; ----------------------
f_nothing	= $00
f_heart		= $78
f_gold		= $79
f_potion	= $7a
f_arrows	= $7b
f_sword		= $8a

; ----------------------
;  Loot color constants
; ----------------------
col_f_nothing	= $00	; fill colors
col_f_heart	= $01
col_f_gold	= $07
col_f_potion	= $06
col_f_arrows	= $07
col_f_sword	= $01

col_c_nothing	= $00	; contour colors
col_c_heart	= $02
col_c_gold	= $01
col_c_potion	= $00
col_c_arrows	= $01
col_c_sword	= $03

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


; Dungeon 0 map specific data
		*=$e000		; will be loaded here

;---------------------------------------------------------------------------------------------------------
; DUNGEON 0 DOORS  - Each cell here is a reference to another cell.
;                    These tables can be loaded from disk (they will not change.)
;---------------------------------------------------------------------------------------------------------
doortable	; e0-ef indicates offset in "doortablemulti". $f0-$fe are dungeons 1-15, $ff means no door
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $00
		!byte $ff,$ff,$20,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $10
		!byte $12,$f0,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $20
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $30
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $40
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $50
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $60
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $70
		; --------------------------------------------------------------------------
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $80
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $90
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $a0
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; $b0
		!byte $ff,$ff,$ff                                                     ; $c0

doortablemulti
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff

doorexits	; Exit tile position on *target* screen if door exists on that screen.
		; f0-ff indicates offset in "doorexitsmulti".
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00
		!byte $00,$00,$8d,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $10
		!byte $5f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $20
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $30
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $40
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $50
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $60
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $70
		; -------------------------------------------------------------------
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $80
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $90
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $a0
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $b0
		!byte $00,$00,$00                                                     ; $c0

doorexitsmulti
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff

; extensions
;		$00-$3f = locked doors (if tile #1 then must magically be revealed) (position) (if tile #2 then reference to loot_trigger table instead)
;		$40-$7f = chests (position, content)
;		$80-$bf = destroyable blocks (not stones! they are all breakable.) (position, content)
;		$c0-$ef = runestones (spells) (spell number) or triggers when looting an item
;		$f0-$fe = switches (refers to two-state switchlist table 'switch_lists', max 15 entries) (position ref list ending with $ff)

; notes:        - If $00-$3f but no door nor grass, then reveal a life container instead.
extensions
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $ff,$ff,$00,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$f2,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $f0,$ff,$f1,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		; -------------------------------------------------------------------
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff

; screen tile positions for:
locked_doors		; $00 - $3f
		!byte loot_trig0-loot_triggers
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; screen tile positions and content for:
chests			; $40 - $7f
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
; screen tile positions and content for:
destroyable_blocks	; $80 - $bf
		!byte $ff
; content for:
runestones		; $c0 - $ef
		!byte $ff

switch_sets	; indices $f0 - $fe, values are offsets in switch_lists
		!byte $00,$02,$05,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

; switches
switch_lists
		!byte switch_0-swbase,$ff, switch_1-swbase, switch_2-swbase, $ff, switch_3-swbase, switch_4-swbase, $ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff	; padding bytes (32 bytes in total for switch_lists)
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
switch_0	!byte $00, $11, $ff, swtarget0-swtargetbase, swtarget1-swtargetbase,$ff,$ff,$ff
switch_1	!byte $00, $16, switch_2-swbase, swtarget2-swtargetbase,$ff,$ff,$ff,$ff
switch_2	!byte $00, $23, switch_1-swbase, swtarget2-swtargetbase,$ff,$ff,$ff,$ff
switch_3	!byte $00, $90, switch_4-swbase+$80, swtarget3-swtargetbase, swtarget4-swtargetbase,$ff,$ff,$ff
switch_4	!byte $00, $92, switch_3-swbase+$80, swtarget3-swtargetbase, swtarget4-swtargetbase,$ff,$ff,$ff
switch_5	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_6	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
switch_7	!byte $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

; switch target (room, position, tile_off, tile_on)
swtargetbase
swtarget0	!byte $21, $c2, 19, 2
swtarget1	!byte $21, $d6, 19, 2
swtarget2	!byte $22, $5c, 19, 2
swtarget3	!byte $12, $5a, 2, 20
swtarget4	!byte $12, $a5, 19, 2
swtarget5	!byte $ff, $ff, 0, 0
swtarget6	!byte $ff, $ff, 0, 0
swtarget7	!byte $ff, $ff, 0, 0

loot_triggers
		; (screen pos, sprite frame)
loot_trig0	!byte $48,f_sword,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff


; -------------------------------------------------
; MOB DATA
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

; $0e
grp_2x_rat	!byte $01,$01,$02



mobs_entries_list	; room for enemy configurations
		!byte $00,$01,$04,$07,$0a,$0d,$10,$13,$16,$19,$1c,$1f,$22,$25,$28,$2b
		!byte $2e,$31,$34,$37,$3a,$3d,$40,$43,$46,$49,$4c,$4f,$52,$55,$58,$5b
		!byte $5e,$61,$64,$67,$6a,$6d,$70,$73,$76,$79,$7c,$7f,$82,$85,$88,$8b
		!byte $8e,$91,$94,$97,$9a,$9d,$a0,$a3,$a6,$a9,$ac,$af,$b2,$b5,$b8,$bb
		!byte $be,$c1,$c4,$c7,$ca,$cd,$d0,$d3,$d6,$d9,$dc,$df,$e2,$e5,$e8,$eb

;-----------------------------------------------------------
; Level data constants (occupies $d0 bytes = 208 bytes)
;-----------------------------------------------------------
world
		; mobs_entries references

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00
		!byte $0e,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $01
		!byte $0e,$00,$0a,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $02
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $03
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $04
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $05
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $06
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $07

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $08
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $09
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0d,$00,$00,$00 ; $0b
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
		!byte f_nothing,f_heart,f_gold,f_potion
loot_colors_fill
		!byte col_f_nothing,col_f_heart,col_f_gold,col_f_potion
loot_colors_contour
		!byte col_c_nothing,col_c_heart,col_c_gold,col_c_potion

fadeout_colors_bg_border
		!byte $00,$00,$00,$00,$09,$09,$09,$09
fadeout_colors_extra_color1
		!byte $09,$09,$0b,$0b,$0c,$0c,$0f,$0f
fadeout_colors_extra_color2
		!byte $09,$09,$09,$09,$0b,$0b,$0b,$0b
gradient_fader
		!byte $00,$07,$04,$06,$06,$06,$00,$05
		!byte $08,$0f,$0c,$0e,$0e,$0e,$08,$0d

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
collision_map	!byte $02,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$02,$02,$02,$02,$02
		!byte $01,$01,$02,$02,$02,$02,$04,$04
		!byte $02,$02,$02,$02,$02,$02,$02,$02
		!byte $02,$02,$02,$02,$02,$0b,$0b,$06
		!byte $01,$02,$02,$02,$02,$02,$02,$0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$02,$02

d0tables_end
