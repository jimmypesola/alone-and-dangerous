@echo off

call compile_aad.bat

for /f "usebackq tokens=3" %%a in (`findstr /RC:"end_code_800" aad_symbols.a`) do set PARTONE_END=%%a
for /f "usebackq tokens=3" %%a in (`findstr /RC:"end_code_3k" aad_symbols.a`) do set PARTTWO_END=%%a
for /f "usebackq tokens=3" %%a in (`findstr /RC:"end_code_c000" aad_symbols.a`) do set PARTTHREE_END=%%a
for /f "usebackq tokens=3" %%a in (`findstr /RC:"end_mapdata" aad_symbols.a`) do set MAP_END=%%a
for /f "usebackq tokens=3" %%a in (`findstr /RC:"outdoortables_end" aad_symbols.a`) do set ODTABLES_END=%%a
for /f "usebackq tokens=3" %%a in (`findstr /RC:"coretables_end" aad_symbols.a`) do set CORETABLES_END=%%a

set /A PARTONE_END=0x%PARTONE_END:~1,4%
set /A PARTTWO_END=0x%PARTTWO_END:~1,4%
set /A PARTTHREE_END=0x%PARTTHREE_END:~1,4%
set /A MAP_END=0x%MAP_END:~1,4%
set /A ODTABLES_END=0x%ODTABLES_END:~1,4%
set /A CORETABLES_END=0x%CORETABLES_END:~1,4%

set BASEADDR=2049
set PARTONE_START=2049
set PARTTWO_START=12288
set PARTTHREE_START=49152
set MAPLOC=28672
set MAPCOLSLOC=%MAP_END%
set /A MAPTILESLOC=%MAP_END%+256
set MUSICLOC=8192
set SPRITELOC=20480
set CHARSETLOC=18432
set ODTABLESLOC=57344
set CORETABLESLOC=61440

set /A PARTTWO_OFFSET=%PARTTWO_START%-%BASEADDR%
set /A PARTTHREE_OFFSET=%PARTTHREE_START%-%BASEADDR%
set /A MAPCOLS_OFFSET=%MAPEND%-%BASEADDR%
set /A MAPTILES_OFFSET=%MAPCOLS_OFFSET%+256
set /A SPRITE_OFFSET=%SPRITELOC%-%BASEADDR%
set /A CHARSET_OFFSET=%CHARSETLOC%-%BASEADDR%
set /A ODTABLES_OFFSET=%ODTABLESLOC%-%BASEADDR%
set /A CORETABLES_OFFSET=%CORETABLESLOC%-%BASEADDR%

set /A PARTONE_LEN=%PARTONE_END%-%PARTONE_START%
set /A PARTTWO_LEN=%PARTTWO_END%-%PARTTWO_START%
set /A PARTTHREE_LEN=%PARTTHREE_END%-%PARTTHREE_START%
set /A MAP_LEN=%MAP_END%-%MAPLOC%
set MAPCOLS_LEN=256
set MAPTILES_LEN=256
set SPRITES_LEN=8192
set CHARSET_LEN=2048
set /A ODTABLES_LEN=%ODTABLES_END%-%ODTABLESLOC%
set /A CORETABLES_LEN=%CORETABLES_END%-%CORETABLESLOC%

set DISKIMAGE_NAME=aad.d64
set MAIN_PRG=aadangerous
set MAIN_UNPACKED_PRG=aad_unpacked.prg
set MUSIC_BIN=game_music.bin
set CHARSET_BIN=aad_charset_big.bin
set SPRITES_BIN=aad_sprites_outdoor.bin
set OUTDOOR_RLE=aad_map_big.rle
set CHARSET_ATTRS_BIN=aad_charset_attrs_big.bin
set TILES_BIN=aad_tiles_big.bin
set OUTDOOR_TABLES_PRG=outdoortables.prg
set CORE_TABLES_PRG=coretables.prg

set DUNGEON_0_CHARSET_BIN=aad_d0_charset.bin
set DUNGEON_0_CHARSET_ATTRS_BIN=aad_d0_charset_attrs.bin
set DUNGEON_0_TILES_BIN=aad_d0_tiles.bin
set DUNGEON_0_RLE=aad_d0_map.rle
set DUNGEON_0_SPRITES_BIN=aad_sprites_dungeon0.bin
set DUNGEON_0_TABLES_PRG=d0tables.prg


REM -- Short file names for 1541 floppy --
set OUTDOOR_FILE=od
set OUTDOOR_SPRITES_FILE=ods
set OUTDOOR_CHARSET_FILE=odc
set OUTDOOR_TABLES_FILE=odt
set DUNGEON_0_FILE=d0
set DUNGEON_0_SPRITES_FILE=d0s
set DUNGEON_0_CHARSET_FILE=d0c
set DUNGEON_0_TABLES_FILE=d0t
set DUNGEON_1_FILE=d1
set DUNGEON_1_SPRITES_FILE=d1s
set DUNGEON_2_FILE=d2
set DUNGEON_2_SPRITES_FILE=d2s
set DUNGEON_3_FILE=d3
set DUNGEON_3_SPRITES_FILE=d3s
set DUNGEON_4_FILE=d4
set DUNGEON_4_SPRITES_FILE=d4s
set DUNGEON_5_FILE=d5
set DUNGEON_5_SPRITES_FILE=d5s
set DUNGEON_6_FILE=d6
set DUNGEON_6_SPRITES_FILE=d6s
set DUNGEON_7_FILE=d7
set DUNGEON_7_SPRITES_FILE=d7s

REM -- This is the packer command which will pack all files into one single compressed binary + initial loader routine.
REM -- TODO: Later, remove the map + charset attrs + tiles + sprites, replace with intro screen + code

echo =======================================================================
echo ======================== Main PRG =====================================
echo =======================================================================

exomizer sfx basic,%BASEADDR% -s "lda #0 sta $d020" -x "inc $d020 dec $d020" %MAIN_UNPACKED_PRG%,%BASEADDR%,,%PARTONE_LEN% %MUSIC_BIN%@%MUSICLOC% %MAIN_UNPACKED_PRG%,%PARTTWO_START%,%PARTTWO_OFFSET%,%PARTTWO_LEN% %CHARSET_BIN%@%CHARSETLOC% %SPRITES_BIN%@%SPRITELOC% %OUTDOOR_RLE%@%MAPLOC% %CHARSET_ATTRS_BIN%@%MAPCOLSLOC% %TILES_BIN%@%MAPTILESLOC% %MAIN_UNPACKED_PRG%,%PARTTHREE_START%,%PARTTHREE_OFFSET%,%PARTTHREE_LEN% %OUTDOOR_TABLES_PRG%,%ODTABLESLOC%,,%ODTABLES_LEN% %CORE_TABLES_PRG%,%CORETABLESLOC%,,%CORETABLES_LEN% -o %MAIN_PRG%
if %ERRORLEVEL% == 0 (
	echo Packing main file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Outdoor Tables ===============================
echo =======================================================================

REM -- This command will crunch the main outdoor tables binary file and use the specified load address $a000, decrunched file will be relocated to $e000
exomizer mem -l 0xa000 %OUTDOOR_TABLES_PRG% -o %OUTDOOR_TABLES_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing main charset file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Outdoor RLE Map ==============================
echo =======================================================================

REM -- This command will crunch the main outdoor binary map (RLE packed) file and use the specified load address $5000, decrunched files will be relocated to $7000
exomizer mem -l 0x5000 %OUTDOOR_RLE%@0x7000 %CHARSET_ATTRS_BIN%@%MAPCOLSLOC% %TILES_BIN%@%MAPTILESLOC% -o %OUTDOOR_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing main file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Outdoor Sprites ==============================
echo =======================================================================

REM -- This command will crunch the main outdoor sprites binary file and use the specified load address $4ffe (using a small safety offset), decrunched file will be relocated to $5000
exomizer mem -l 0x4ffe %SPRITES_BIN%@0x5000 -o %OUTDOOR_SPRITES_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing main sprites file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Outdoor Charset ==============================
echo =======================================================================

REM -- This command will crunch the main outdoor charset binary file and use the specified load address $0400, decrunched file will be relocated to $4800
exomizer mem -l 0x47fe %CHARSET_BIN%@0x4800 -o %OUTDOOR_CHARSET_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing main charset file was successful!
) else (
	echo Error!
	pause
	exit /b
)


REM --------------------------------------
REM -- DUNGEON 0
REM --------------------------------------

echo =======================================================================
echo ======================== Dungeon 0 Tables =============================
echo =======================================================================

REM -- This command will crunch dungeon 0 tables binary file and use the specified load address $a000, decrunched file will be relocated to $e000
exomizer mem -l 0xa000 %DUNGEON_0_TABLES_PRG% -o %DUNGEON_0_TABLES_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing main charset file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Dungeon 0 RLE Map ============================
echo =======================================================================

REM -- This command will crunch dungeon 0 binary map (RLE packed) file and use the specified load address $5000, decrunched files will be relocated to $7000
exomizer mem -l 0x5000 %DUNGEON_0_RLE%@0x7000 %DUNGEON_0_CHARSET_ATTRS_BIN%@%MAPCOLSLOC% %DUNGEON_0_TILES_BIN%@%MAPTILESLOC% -o %DUNGEON_0_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing main file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Dungeon 0 Sprites ============================
echo =======================================================================

REM -- This command will crunch dungeon 0 sprites binary file and use the specified load address $4ffe (using a small safety offset), decrunched file will be relocated to $5000
exomizer mem -l 0x4ffe %DUNGEON_0_SPRITES_BIN%@0x5000 -o %DUNGEON_0_SPRITES_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing dungeon 0 sprites file was successful!
) else (
	echo Error!
	pause
	exit /b
)

echo =======================================================================
echo ======================== Dungeon 0 Charset ============================
echo =======================================================================

REM -- This command will crunch dungeon 0 charset binary file and use the specified load address $0400, decrunched file will be relocated to $4800
exomizer mem -l 0x47fe %DUNGEON_0_CHARSET_BIN%@0x4800 -o %DUNGEON_0_CHARSET_FILE%
if %ERRORLEVEL% == 0 (
	echo Packing dungeon 0 charset file was successful!
) else (
	echo Error!
	pause
	exit /b
)



REM
REM -- TODO: Add more binary maps here
REM



c1541 -format "aad,1a" d64 %DISKIMAGE_NAME%
if %ERRORLEVEL% == 0 (
	echo Creating and formatting disk aad.d64 was successful!
) else (
	echo Error!
	pause
	exit /b
)

c1541 -attach %DISKIMAGE_NAME% -write %MAIN_PRG% -write %OUTDOOR_TABLES_FILE% -write %OUTDOOR_FILE% -write %OUTDOOR_SPRITES_FILE% -write %OUTDOOR_CHARSET_FILE% -write %DUNGEON_0_TABLES_FILE% -write %DUNGEON_0_FILE% -write %DUNGEON_0_SPRITES_FILE% -write %DUNGEON_0_CHARSET_FILE%
if %ERRORLEVEL% == 0 (
	echo Writing files to disk was successful!
	pause
) else (
	echo Error!
	pause
	exit /b
)
