!sl	"d0tables_labels.a"
!to	"d0tables.prg", cbm
!source "coretables_labels.a"



f_base = 64

; ----------------------
;  Enemy frame constants
; ----------------------
f_death 	= f_base + 32
f_bat 		= f_base + 96
f_rat		= f_base + 104
f_rat_boss	= f_base + 80
f_rat_boss_claw = f_base + 99
f_blob		= f_base + 122

; ----------------------
;  NPC frame constants
; ----------------------
f_man 		= f_base + 120
f_woman		= f_base + 120
f_boy		= f_base + 121
f_girl		= f_base + 121

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

;  Common constants
;
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
; For multiple doors in one room
doortablemulti
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff

doorexits	; Exit tile position on *target* screen if door exists on that screen.
		; f0-ff indicates offset in "doorexitsmulti".
		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00
		!byte $00,$00,$8e,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $10
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
; Exits for multiple doors in one room
doorexitsmulti
		!byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		!byte $ff,$ff,$ff,$ff,$ff,$ff

; extensions
;		$00-$3f = locked doors/chests (if tile #1 then must magically be revealed) (position) (if tile #2 then reference to loot_trigger table instead)
;		$40-$bf = destroyable blocks (not stones! they are all breakable.) (position, content)
;		$c0-$ef = runestones (spells) (spell number) or triggers when looting an item
;		$f0-$fe = switches (refers to two-state switchlist table 'switch_lists', max 14 entries) (position ref list ending with $ff)
;		$ff     = nothing

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

; chest items
chests		; $00 - $3f
		!byte item_axe-item_base
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
;                  If AND condition has the MSB set then it becomes an XOR switch with the switch indicated by its offset value after
;                    it is AND'ed with $7f.
; switch	(state, position, AND condition, targets)
swbase		; Each switch is 8 bytes, 4th to 8th byte are the targets. The targets are basically a tile in a room that can be changed.
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
;          c - bat      (black - easy)	(moves in 8 directions)
;          d - spider   (orange - extreme)
;          e - skeleton (orange - extreme)
;          f - knight   (orange - extreme)
;         10 - bat	(free moving all directions)
;         40 - Boss     (rat boss)
;         41 - Boss     (Knight boss)
;         80 - NPC 0    (A NPC, salesman?)
grp_nothing
		; $00	<= offset
		!byte $00		; empty room
grp_4x_blueknights
		; $01
		!byte $01,$07,$04	; # of groups; type (up to 256); qty in group x; type; qty in group x+1; ...
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
grp_6x_greenspiders
		; $1c
		!byte $01,$01,$06
grp_2x_greenslime
		; $1f
		!byte $01,$00,$02
grp_2x_rat
		; $22
		!byte $01,$01,$02
grp_6x_bats
		; $25
		!byte $01,$0c,$06
grp_0e_not_used
		; $28
		!byte $00,$00,$00
grp_1x_ratboss
		; $2b
		!byte $01,$0f,$01

;-----------------------------------------------------------
; Level data constants (occupies $d0 bytes = 208 bytes)
;-----------------------------------------------------------
world
		; mobs_entries references, see mobs_entries table above. (not mob_entries_list)

		;      0   1   2   3   4   5   6   7   8   9   a   b   c   d   e   f
		!byte $00,$00,$2b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $00
		!byte $25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $01
		!byte $22,$00,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $02
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
		; BAT
		; Run south
		!byte f_bat,f_bat+1,f_bat,f_bat+1
		; Run west
		!byte f_bat,f_bat+1,f_bat,f_bat+1
		; Run north
		!byte f_bat,f_bat+1,f_bat,f_bat+1
		; Run east
		!byte f_bat,f_bat+1,f_bat,f_bat+1
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

		; RAT
		; Run south
		!byte f_rat,f_rat+1,f_rat,f_rat+1
		; Run west
		!byte f_rat+2,f_rat+3,f_rat+2,f_rat+3
		; Run north
		!byte f_rat+8,f_rat+9,f_rat+8,f_rat+9
		; Run east
		!byte f_rat+10,f_rat+11,f_rat+10,f_rat+11
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

		; RAT BOSS CLAW
		; Run south
		!byte f_rat_boss+18,f_rat_boss+18,f_rat_boss+18,f_rat_boss+18
		; Run west
		!byte f_rat_boss_claw,f_rat_boss_claw,f_rat_boss_claw,f_rat_boss_claw
		; Run north
		!byte f_rat_boss+18,f_rat_boss+18,f_rat_boss+18,f_rat_boss+18
		; Run east
		!byte f_rat_boss+18,f_rat_boss+18,f_rat_boss+18,f_rat_boss+18
		; Death
		!byte f_death,f_death+1,f_death+2,f_death+3

		; No enemy, padding 20 bytes
		!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BossAnimTable
		; Tile set animations (20 frames) (add 8 to frame number for next boss in table)

		; RAT BOSS
		; Idle frames
		!byte 0, 1, 0, 1
		; Attack frames
		!byte 0, 1, 0, 1
		; Move frames
		!byte 0, 1, 0, 1
		; Hide frames
		!byte 0, 1, 0, 1
		; Death frames
		!byte 4, 5, 6, 7

		; No boss, padding 20 bytes
		!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

BossFrames2x2
		; BOSS 2x2 frame sprite sets (8 x 2x2 sprites), 32 bytes

		; Frame 0 tile set
		!byte f_rat_boss,f_rat_boss+1,f_rat_boss+8,f_rat_boss+9

		; Frame 1 tile set
		!byte f_rat_boss+2,f_rat_boss+1,f_rat_boss+8,f_rat_boss+9

		; Frame 2 tile set
		!byte f_rat_boss+2,f_rat_boss+3,f_rat_boss+10,f_rat_boss+11

		; Frame 3 tile set
		!byte f_rat_boss+18,f_rat_boss+18,f_rat_boss+18,f_rat_boss+18

		; Frame 4 tiles set
		!byte f_death,f_death,f_death,f_death

		; Frame 5 tiles set
		!byte f_death+1,f_death+1,f_death+1,f_death+1

		; Frame 6 tiles set
		!byte f_death+2,f_death+2,f_death+2,f_death+2

		; Frame 7 tiles set
		!byte f_death+3,f_death+3,f_death+3,f_death+3

BossFrames2x3
		; BOSS 2x3 frame sprites (2 extra sprites per frame, lowest row) (8 x 2x3 sprites), 16 bytes

		; Padding 16 bytes (no boss frames)
		!byte f_rat_boss+18,f_rat_boss+18	; frame 0
		!byte f_rat_boss+18,f_rat_boss+18	; frame 1
		!byte f_rat_boss+18,f_rat_boss_claw	; frame 2
		!byte f_rat_boss+18,f_rat_boss+18	; frame 3
		!byte f_death,f_death			; frame 4
		!byte f_death+1,f_death+1		; frame 5
		!byte f_death+2,f_death+2		; frame 6
		!byte f_death+3,f_death+3		; frame 7

		; man, boy, woman, girl
NpcImageList	!byte f_man,f_boy,f_woman,f_girl


; hp array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_hp
		!byte $02,$04,$0a,$14,$05,$08,$14,$1e
		!byte $0a,$0e,$1e,$28,$02,$02,$02,$32

; ap array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_ap
		!byte $01,$01,$02,$04,$02,$02,$04,$08
		!byte $04,$04,$08,$16,$01,$08,$16,$32

; gold array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_gold
		!byte $01,$04,$10,$15,$12,$15,$20,$25
		!byte $15,$20,$25,$30,$00,$40,$75,$96

; loot index array of mobtypes [slime1, spider1, skel1, knight1, slime2, spider2, ... etc]
mobtable_lootidx
		!byte $00,$01,$02,$03,$00,$04,$05,$06
		!byte $07,$08,$09,$0a,$00,$0c,$0d,$0e

; subpixel speed ratio is 1/2; 1 = 0.5, 2 = 1, etc...
mobtable_speed	!byte $01,$02,$01,$01,$01,$02,$02,$02
		!byte $02,$03,$02,$02,$01,$04,$02,$02

; mob colors
mob_fill_table
		!byte $06,$0b,$00,$0f,$0e,$01,$00,$0e
		!byte $0a,$01,$00,$04,$02,$01,$00,$0f
mob_contour_table
		!byte $00,$00,$01,$00,$0a,$06,$03,$00
		!byte $04,$04,$00,$04,$00,$08,$00,$00
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
collision_map	!byte $02,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$02,$02,$02,$02,$02
		!byte $01,$01,$02,$02,$02,$02,$04,$04
		!byte $02,$02,$02,$02,$02,$02,$02,$02
		!byte $02,$02,$02,$02,$02,$0b,$0b,$06
		!byte $01,$02,$02,$02,$02,$02,$02,$0a
		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$00,$00,$00,$00,$00,$02,$02

; Everything below is static data
; ------------------------------------------------
; Player's start location position arrays per map
; ------------------------------------------------
; player's starting pos in tiles
;
StartLocX	!byte 30,30,0,0,0,0,0,0
StartLocY	!byte 34,34,0,0,0,0,0,0

; screen starting pos (left corner) in tiles
MapStartX	!byte 20,20,0,0,0,0,0,0
MapStartHiX	!byte 0,0,0,0,0,0,0,0
MapStartY	!byte 24,24,0,0,0,0,0,0


; screen graphics colors per map
BorderColor	!byte 0
BGColor		!byte 0
MultiColor1	!byte 12
MultiColor2	!byte 9

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
		rts
d0tables_end
