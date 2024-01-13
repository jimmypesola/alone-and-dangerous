; -----------------------------------------------------------
;  Constants
; -----------------------------------------------------------

offx=$bc	; map x screen offset (from top left corner) (rough scroll, 16 pixels)
offy=$be	; map y screen offset (from top left corner)
screen_id=$b8	; indicates the currently active screen (0=$4000,1=$4400)
scroll_x=$b9	; variables for scrolling the screen (fine scroll 1 pixel)
scroll_x2=$ba
scroll_y=$bb

tmp=$06
tmp_addr=$07 ; and $08
tmp_addr2=$09 ; and $0a

tmp2=$0b

scrollstate=$0c
transferstate=$0c

tmp3=$0d
tmp4=$0e

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

put_tile_tmp = $19
tmpy = $1a

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

PlayerWeaponPower = $29	; bits 0-2 - sword type 0-7 (can do up to 7pts damage)
			; bits 3-7 - other obtained weapons bitmask

indextable=$30	; sprite multiplexer indices: must have at least 16 entries, but reserve 32

DictLen = 288	; Room dictionary length (back reference to rooms "already seen", i.e.
		; compression for rooms which data are identical.)

; Keyscanner ZERO PAGE Variables
ScanResult = $50

; Reserved temporary zero page vars
StatsUpdated = $51

; Used temporarily onpy within stats calculation scope
tmp_hp_digits = $52 ; ...and $53,$54,$55 !
tmp_gold_incr = $52 ; ...and $53,$54,$55 !
tmp_gold_value = $53

; Used globally within collision detection scope
enemy_negx_size = $c5
enemy_posx_size = $c6
enemy_negy_size = $c7
enemy_posy_size = $c8

; tmp vars that should be used outside interrupt code
safe_tmp=$56
safe_tmp2=$57
safe_tmp3=$58
safe_tmp4=$59

MapID = $5a

MapOverworld = 0
MapDungeon1 = 1
MapDungeon2 = 2
MapDungeon3 = 3
MapDungeon4 = 4
MapDungeon5 = 5
MapDungeon6 = 6
MapDungeon7 = 7
MapRatDungeon = 8

PlayerPowerState = $5b
PrevMapID = $5c

; Animation counter (defined in coretables.asm!)
;AnimCounter = $5f	; For each sprite

KeyStopper = $60	; KeyStopper, when a key is held down to prevent repetition.
RandomDir = $61

; Player animation state variable and values
PlayerAnimState = $62 ; NOTE: used with above AnimCounter (index 2 in sprite anim table)

BossesLooted = $64 ; $64 - $6b

; Inventory weapons
InvSword = $01			; Sword (damage added by weapon power)
InvAxe = $02			; Just an axe, to cut trees
InvBow = $04			; Bow is required to shoot arrows
InvArrows = $08			; Normal arrows (white)
; Modifiers
InvFireArrows = $01		; Fire arrows (red/yellow flashing)
InvMagicalArrows = $02		; Magically powered arrows (blue/white flashing)

; Inventory items
InvShield = $01			; Shield, blocks stronger attacks
InvGauntlet = $02		; Gauntlet allows heavy lifting
InvUnknown1 = $04
InvArmor = $08			; Armor 1/2
InvRaft = $10			; Raft allows lake traversal in some spots
InvRope = $20			; Rope to traverse gaps / cliffs
InvMasterKey = $40		; Opens one big locked door
InvNecklace = $80		; Yellow (Spellpower level 1)
; Modifiers:
InvImprovedArmor = $01		; Improved armor 1/4 (modifier)
InvMagicalArmor = $02		; Magical armor 1/6 (modifier)
InvNecklaceJade = $01		; Green (Spellpower level 2) (modifier)
InvNecklacePower = $02		; Aquamarine (Spellpower level 5) (modifier)

Arrows = $82			; Number of arrows, 1 byte.

Weapons = $83			; 
SelWeapon = $84			; Selected weapon idx: 0=None, 1=Sword, 2=Axe, 4=Bow
; Selecting weapon by bit shift 1, 2, 4, 1, 2, 4... and(Weapons, SelWeapon) != 0 => Weapon present.
Items = $85

ArrowQ = $86
ArmorQ = $87
NecklaceQ = $88

; Free bytes here!

linebuffer=$90 ; 40 bytes, ends in $b7

;FrameStarted=$c0
ForcesPresent=$c0


CurrentMobType=$c1
CurrentEnemyDir=$c2
FinalEnemyAnimState=$c3

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
txt_raft = 136
txt_rope = 137
txt_key2 = 138
txt_necklace = 139
txt_sword = 40
txt_axe = 41
txt_bow = 42
txt_arrow = 43
txt_shield = 44
txt_gauntlet = 45
txt_unknown1 = 46
txt_armor = 47

; -------------------------------

; ---------------------------------
; Scroll and transfer state values
; ---------------------------------

state_idle = 0
state_scroll_up = 1
state_scroll_down = 2
state_scroll_left = 3
state_scroll_right = 4
state_transfer_unpack = 5
state_transfer_draw_back = 6
state_transfer_draw_front = 7
state_transfer_end = 8

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
PlayerStateDying = 7
PlayerStateDead = 8
PlayerStateFades = 9
PlayerStateStartLootChest = 10
PlayerStateLootChest = 11
PlayerStateSwitchMap = 12
PlayerStatePullSwitch = 13
PlayerStateDestroyTile = 14
PlayerStateBusy = 15
PlayerStateDialog = 16
PlayerStateDialogEnd = 17

; ----------------------
; Enemy animation state values
; ----------------------
EnemyRunSouth = 0
EnemyRunWest = 1
EnemyRunNorth = 2
EnemyRunEast = 3
EnemyRunSouthWest = 4
EnemyRunNorthWest = 5
EnemyRunNorthEast = 6
EnemyRunSouthEast = 7
EnemyDyingAnim = 4

; ----------------------
; Enemy behavior
; state values
; ----------------------
EnemyIdle = 0
EnemyWaiting = 1
EnemyMoving = 2
EnemyAttacking = 3
EnemyHit = 4
EnemyDying = 5
EnemyDead = 6
EnemyLoot = 7
ChestLootRise = 8
ChestLootHover = 9
EnemyIsNpc = 11


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
ct_passable = 0
ct_door = 1
ct_block = 2
ct_tree = 3
ct_chest = 4
ct_locked = 5
ct_runestone = 6
ct_infostone = 7
ct_crushable = 8
ct_movable = 9
ct_cenotaph = 10
ct_switch = 11

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
;player_max_hp 	=	$f000	;!byte $00,$06	; store as strings, for efficiency
;player_hp 	=	$f002	;!byte $00,$06			; bcd string
;player_level 	=	$f004	;!byte $00,$01			; bcd string
;player_gold	=	$f006	;!byte $00,$00,$00,$00,$00	; bcd string
;enemy_hp	=	$f00b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15dc
;enemy_ap	=	$f013	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15e4
;enemy_gold	=	$f01b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15ec
;enemy_state	=	$f023	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15f4
;enemy_anim_state=	$f02b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $15fc
;enemy_lootidx	=	$f033	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $1604
;enemy_nextpos_x=	$f03b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $160c
;enemy_nextpos_y=	$f043	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $1614
;enemy_timer	=	$f04b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $161c
;enemy_pull_force_x =	$f053	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $1624
;enemy_pull_force_y =	$f05b	;!byte $00,$00,$00,$00,$00,$00,$00,$00 ; $162c
;
;CurrentRoomIdx =	$f063	; 1-byte room index on map
;
;; 16-bit mob data currently on screen
;CurrentMobTypes = 	$f064	; list of up to 9 bytes
;
;-----------------------------------------------------------
; tile-to-screen lookup tables
; contains the relative positions for tiles on screen
;-----------------------------------------------------------
;tilepos_lo 	=	$f100
;tilepos_hi	=	$f200

;-----------------------------------------------------------
; Sprite tables (160 bytes)
;-----------------------------------------------------------
; y-coordinate table for virtual sprites
;ytable		=	$f500	; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;
; x-coordinate table for virtual sprites
;xtablelo	=	$f520	; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;
; x-coordinate table for virtual sprites (high byte)
;xtablehi	=	$f540	; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;
; color table for virtual sprites
;color		=	$f560	; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;
; frame index for virtual sprites
;frame		=	$f580	; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;				; !byte $00,$00,$00,$00,$00,$00,$00,$00
;
; tile buffer for temporarily storing current map room
;tilebuffer	=	$fa00

; color memory buffer
colorbuffer	=	$0400
colormem_diff	=	(>colorbuffer + $2c) & $ff

;------------------------------------------------------------------------------------

; keyboard internal keycodes
kb_none = 0
kb_space = 1
kb_a = 2
kb_d = 4
kb_w = 8
kb_s = 16
kb_n = 32
kb_h = 64
kb_return = 128

