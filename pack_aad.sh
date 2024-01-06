#!/bin/bash

./compile_tables.sh

function hex2dec {
	UCASE=$(echo $1 | tr a-z A-Z)
	echo $(printf "%d\n" $((16#$UCASE)))
}

DISKIMAGE_NAME=aad.d64
MAIN_PRG=aadangerous
MAIN_UNPACKED_PRG=aad_unpacked.prg
MUSIC_BIN=game_music.bin
CHARSET_BIN=aad_charset_big.bin
SPRITES_BIN=aad_sprites_outdoor.bin
OUTDOOR_RLE=aad_map_big.rle
CHARSET_ATTRS_BIN=aad_charset_attrs_big.bin
TILES_BIN=aad_tiles_big.bin
OUTDOOR_TABLES_PRG=outdoortables.prg
OUTDOOR_TEXT_PRG=outdoortext.prg
CORE_TABLES_PRG=coretables.prg

DUNGEON_0_CHARSET_BIN=aad_d0_charset.bin
DUNGEON_0_CHARSET_ATTRS_BIN=aad_d0_charset_attrs.bin
DUNGEON_0_TILES_BIN=aad_d0_tiles.bin
DUNGEON_0_RLE=aad_d0_map.rle
DUNGEON_0_SPRITES_BIN=aad_sprites_dungeon0.bin
DUNGEON_0_TABLES_PRG=d0tables.prg
DUNGEON_0_TEXT_PRG=d0text.prg

BASEADDR=2049                    # $0801
PARTONE_START=2049               # $0801
PARTTWO_START=12288              # $3000
PARTTHREE_START=49152            # $c000
MAPLOC=28672                     # $7000
TEXTLOC=48128                    # $bc00
MAPCOLSLOC=48640                 # $be00
MAPTILESLOC=$(($MAPCOLSLOC+256)) # $bf00
MUSICLOC=8192                    # $2000
SPRITELOC=20480                  # $5000
CHARSETLOC=18432                 # $4800
ODTABLESLOC=57344                # $e000
CORETABLESLOC=61440              # $f000


# -- Short file names for 1541 floppy --
CORE_TABLES_FILE=ct
OUTDOOR_FILE=od
OUTDOOR_SPRITES_FILE=ods
OUTDOOR_CHARSET_FILE=odc
OUTDOOR_TABLES_FILE=odt
OUTDOOR_TEXT_FILE=odx
DUNGEON_0_FILE=d0
DUNGEON_0_SPRITES_FILE=d0s
DUNGEON_0_CHARSET_FILE=d0c
DUNGEON_0_TABLES_FILE=d0t
DUNGEON_0_TEXT_FILE=d0x
DUNGEON_1_FILE=d1
DUNGEON_1_SPRITES_FILE=d1s
DUNGEON_2_FILE=d2
DUNGEON_2_SPRITES_FILE=d2s
DUNGEON_3_FILE=d3
DUNGEON_3_SPRITES_FILE=d3s
DUNGEON_4_FILE=d4
DUNGEON_4_SPRITES_FILE=d4s
DUNGEON_5_FILE=d5
DUNGEON_5_SPRITES_FILE=d5s
DUNGEON_6_FILE=d6
DUNGEON_6_SPRITES_FILE=d6s
DUNGEON_7_FILE=d7
DUNGEON_7_SPRITES_FILE=d7s

# This is the packer command which will pack all files into one single compressed binary + initial loader routine.
# TODO: Later, remove the map + charset attrs + tiles + sprites, replace with intro screen + code

CRUNCHED_LEN_INCFILE=file_lengths.a
truncate -s 0 $CRUNCHED_LEN_INCFILE

echo =======================================================================
echo ========================== Core Tables ================================
echo =======================================================================

# -- This command will crunch the core tables machine code file and use the specified load address $0400, decrunched file will be relocated to $f000
exomizer mem -l 0x0400 $CORE_TABLES_PRG -o $CORE_TABLES_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $CORE_TABLES_FILE | cut -d' ' -f 5)
	echo "ct_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing core tables file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Outdoor Tables ===============================
echo =======================================================================

# -- This command will crunch the main outdoor tables binary file and use the specified load address $0400, decrunched file will be relocated to $e000
exomizer mem -l 0x0400 $OUTDOOR_TABLES_PRG -o $OUTDOOR_TABLES_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $OUTDOOR_TABLES_FILE | cut -d' ' -f 5)
	echo "od_tables_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing outdoor tables file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Outdoor RLE Map ==============================
echo =======================================================================

# -- This command will crunch the main outdoor binary map (RLE packed) file and use the specified load address $5000, decrunched files will be relocated to $7000
exomizer mem -l 0x6ffa $OUTDOOR_RLE@0x7000 $OUTDOOR_TEXT_PRG $CHARSET_ATTRS_BIN@$MAPCOLSLOC $TILES_BIN@$MAPTILESLOC -o $OUTDOOR_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $OUTDOOR_FILE | cut -d' ' -f 5)
	echo "od_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing outdoor RLE map file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Outdoor Sprites ==============================
echo =======================================================================

# -- This command will crunch the main outdoor sprites binary file and use the specified load address $4ffe (using a small safety offset, unpacking requires it when data overlaps!), decrunched file will be relocated to $5000
exomizer mem -l 0x4ffe $SPRITES_BIN@0x5000 -o $OUTDOOR_SPRITES_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $OUTDOOR_SPRITES_FILE | cut -d' ' -f 5)
	echo "od_sprites_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing outdoor sprites file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Outdoor Charset ==============================
echo =======================================================================

# -- This command will crunch the main outdoor charset binary file and use the specified load address $0400, decrunched file will be relocated to $4800
exomizer mem -l 0x47fe $CHARSET_BIN@0x4800 -o $OUTDOOR_CHARSET_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $OUTDOOR_CHARSET_FILE | cut -d' ' -f 5)
	echo "od_charset_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing outdoor charset file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi


# --------------------------------------
# -- DUNGEON 0
# --------------------------------------

echo =======================================================================
echo ======================== Dungeon 0 Tables =============================
echo =======================================================================

# -- This command will crunch dungeon 0 tables binary file and use the specified load address $0400, decrunched file will be relocated to $e000
exomizer mem -l 0x0400 $DUNGEON_0_TABLES_PRG -o $DUNGEON_0_TABLES_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $DUNGEON_0_TABLES_FILE | cut -d' ' -f 5)
	echo "d0_tables_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing dungeon 0 tables file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Dungeon 0 RLE Map ============================
echo =======================================================================

# -- This command will crunch dungeon 0 binary map (RLE packed) file and use the specified load address $6ffa, decrunched files will be relocated to $7000
exomizer mem -l 0x6ffa $DUNGEON_0_RLE@0x7000 $DUNGEON_0_TEXT_PRG $DUNGEON_0_CHARSET_ATTRS_BIN@$MAPCOLSLOC $DUNGEON_0_TILES_BIN@$MAPTILESLOC -o $DUNGEON_0_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $DUNGEON_0_FILE | cut -d' ' -f 5)
	echo "d0_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing dungeon 0 map file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Dungeon 0 Sprites ============================
echo =======================================================================

# -- This command will crunch dungeon 0 sprites binary file and use the specified load address $4ffe (using a small safety offset), decrunched file will be relocated to $5000
exomizer mem -l 0x4ffe $DUNGEON_0_SPRITES_BIN@0x5000 -o $DUNGEON_0_SPRITES_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $DUNGEON_0_SPRITES_FILE | cut -d' ' -f 5)
	echo "d0_sprites_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing dungeon 0 sprites file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo ======================== Dungeon 0 Charset ============================
echo =======================================================================

# -- This command will crunch dungeon 0 charset binary file and use the specified load address $47fe, decrunched file will be relocated to $4800
exomizer mem -l 0x47fe $DUNGEON_0_CHARSET_BIN@0x4800 -o $DUNGEON_0_CHARSET_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	SIZE=$(ls -l $DUNGEON_0_CHARSET_FILE | cut -d' ' -f 5)
	echo "d0_charset_len=$SIZE" >> $CRUNCHED_LEN_INCFILE
	echo 'Packing dungeon 0 charset file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi



#
# -- TODO: Add more binary maps here
#
echo ''
echo =======================================================================
echo ======================== Compile aad.asm ==============================
echo =======================================================================


./compile_aad.sh

echo ''
echo =======================================================================
echo ================== Compute addresses and lengths  =====================
echo =======================================================================

PARTONE_END=$(grep end_code_800 aad_symbols.a | gawk '{print $3}')
PARTTWO_END=$(grep end_code_3k aad_symbols.a | gawk '{print $3}')
PARTTHREE_END=$(grep end_code_c000 aad_symbols.a | gawk '{print $3}')
MAP_END=$(grep end_mapdata aad_symbols.a | gawk '{print $3}')
TEXT_END=$(grep odtext_end odtext.a | gawk '{print $3}')
ODTABLES_END=$(grep outdoortables_end aad_symbols.a | gawk '{print $3}')
CORETABLES_END=$(grep coretables_end aad_symbols.a | gawk '{print $3}')

PARTONE_END_HEX=${PARTONE_END:1:4}
PARTTWO_END_HEX=${PARTTWO_END:1:4}
PARTTHREE_END_HEX=${PARTTHREE_END:1:4}
MAP_END_HEX=${MAP_END:1:4}
TEXT_END_HEX=${TEXT_END:1:4}
ODTABLES_END_HEX=${ODTABLES_END:1:4}
CORETABLES_END_HEX=${CORETABLES_END:1:4}

PARTONE_END=$(hex2dec $PARTONE_END_HEX)
PARTTWO_END=$(hex2dec $PARTTWO_END_HEX)
PARTTHREE_END=$(hex2dec $PARTTHREE_END_HEX)
MAP_END=$(hex2dec $MAP_END_HEX)
TEXT_END=$(hex2dec $TEXT_END_HEX)
ODTABLES_END=$(hex2dec $ODTABLES_END_HEX)
CORETABLES_END=$(hex2dec $CORETABLES_END_HEX)

PARTTWO_OFFSET=$(($PARTTWO_START-$BASEADDR))
PARTTHREE_OFFSET=$(($PARTTHREE_START-$BASEADDR))
MAPCOLS_OFFSET=$(($MAP_END-$BASEADDR))
MAPTILES_OFFSET=$(($MAPCOLS_OFFSET+256))
SPRITE_OFFSET=$(($SPRITELOC-$BASEADDR))
CHARSET_OFFSET=$(($CHARSETLOC-$BASEADDR))
TEXT_OFFSET=$(($TEXTLOC-$BASEADDR))
ODTABLES_OFFSET=$(($ODTABLESLOC-$BASEADDR))
CORETABLES_OFFSET=$(($CORETABLESLOC-$BASEADDR))

PARTONE_LEN=$(($PARTONE_END-$PARTONE_START))
PARTTWO_LEN=$(($PARTTWO_END-$PARTTWO_START))
PARTTHREE_LEN=$(($PARTTHREE_END-$PARTTHREE_START))
MAP_LEN=$(($MAP_END-$MAPLOC))
TEXT_LEN=$(($TEXT_END-$TEXTLOC))
MAPCOLS_LEN=256
MAPTILES_LEN=256
SPRITES_LEN=8192
CHARSET_LEN=2048
ODTABLES_LEN=$(($ODTABLES_END-$ODTABLESLOC))
CORETABLES_LEN=$(($CORETABLES_END-$CORETABLESLOC))

echo ''
echo '----------------------------------------------'
echo '       Start and end addresses of data'
echo '----------------------------------------------'
echo 'BASEADDR        ($0801) = '$BASEADDR
echo 'PARTONE_START   ($0801) = '$PARTONE_START
echo 'PARTONE_END     ($'$PARTONE_END_HEX') = '$PARTONE_END
echo 'MUSICLOC        ($2000) = '$MUSICLOC
echo 'MUSICLOC_END    ($3000) = 12288'
echo 'PARTTWO_START   ($3000) = '$PARTTWO_START
echo 'PARTTWO_END     ($'$PARTTWO_END_HEX') = '$PARTTWO_END
echo 'CHARSETLOC      ($4800) = '$CHARSETLOC
echo 'CHARSETLOC_END  ($5000) = 20480'
echo 'SPRITELOC       ($5000) = '$SPRITELOC
echo 'SPRITELOC_END   ($7000) = 28672'
echo 'MAPLOC          ($7000) = '$MAPLOC
echo 'MAPLOC_END      ($'$MAP_END_HEX') = '$MAP_END
echo 'TEXTLOC         ($bc00) = '$TEXTLOC
echo 'TEXTLOC_END     ($'$TEXT_END_HEX') = '$TEXT_END
echo 'MAPCOLSLOC      ($be00) = '$MAPCOLSLOC
echo 'MAPCOLSLOC_END  ($bf00) = 48896'
echo 'MAPTILESLOC     ($bf00) = '$MAPTILESLOC
echo 'MAPTILESLOC_END ($c000) = 49152'
echo 'PARTTHREE_START ($c000) = '$PARTTHREE_START
echo 'PARTTHREE_END   ($'$PARTTHREE_END_HEX') = '$PARTTHREE_END
echo 'ODTABLESLOC     ($e000) = '$ODTABLESLOC
echo 'ODTABLESLOC_END ($'$ODTABLES_END_HEX')'
echo 'CORETABLESLOC   ($f000) = '$CORETABLESLOC
echo 'CORETABLESLOC_EN($'$CORETABLES_END_HEX')'

echo '----------------------------------------------'

echo PARTTWO_OFFSET = $PARTTWO_OFFSET
echo PARTTHREE_OFFSET = $PARTTHREE_OFFSET
echo MAPCOLS_OFFSET = $MAPCOLS_OFFSET
echo MAPTILES_OFFSET = $MAPTILES_OFFSET
echo TEXT_OFFSET = $TEXT_OFFSET
echo SPRITE_OFFSET = $SPRITE_OFFSET
echo CHARSET_OFFSET = $CHARSET_OFFSET
echo CORETABLES_OFFSET = $CORETABLES_OFFSET

echo '----------------------------------------------'
echo ''


echo =======================================================================
echo ======================== Main PRG =====================================
echo =======================================================================

exomizer sfx basic,$BASEADDR -s 'lda #0 sta $d020' -x 'inc $d020 dec $d020' $MAIN_UNPACKED_PRG,$BASEADDR,,$PARTONE_LEN $MUSIC_BIN@$MUSICLOC $MAIN_UNPACKED_PRG,$PARTTWO_START,$PARTTWO_OFFSET,$PARTTWO_LEN $CHARSET_BIN@$CHARSETLOC $SPRITES_BIN@$SPRITELOC $OUTDOOR_RLE@$MAPLOC $OUTDOOR_TEXT_PRG,$TEXTLOC,,$TEXT_LEN $CHARSET_ATTRS_BIN@$MAPCOLSLOC $TILES_BIN@$MAPTILESLOC $MAIN_UNPACKED_PRG,$PARTTHREE_START,$PARTTHREE_OFFSET,$PARTTHREE_LEN $OUTDOOR_TABLES_PRG,$ODTABLESLOC,,$ODTABLES_LEN $CORE_TABLES_PRG,$CORETABLESLOC,,$CORETABLES_LEN -o $MAIN_PRG
RESULT=$?
if [ $RESULT -eq 0 ]; then
	echo 'Packing main file was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

echo =======================================================================
echo =======================================================================
echo =======================================================================


c1541 -format "aad,1a" d64 $DISKIMAGE_NAME
RESULT=$?
if [ $RESULT -eq 0 ]; then
	echo 'Creating and formatting disk aad.d64 was successful!'
else
	echo 'Error!'
	read
	exit $RESULT
fi

c1541 -attach $DISKIMAGE_NAME -write $MAIN_PRG -write $CORE_TABLES_FILE -write $OUTDOOR_TABLES_FILE -write $OUTDOOR_FILE -write $OUTDOOR_SPRITES_FILE -write $OUTDOOR_CHARSET_FILE -write $DUNGEON_0_TABLES_FILE -write $DUNGEON_0_FILE -write $DUNGEON_0_SPRITES_FILE -write $DUNGEON_0_CHARSET_FILE
RESULT=$?
if [ $RESULT -eq 0 ]; then
	echo 'Writing files to disk was successful!'
	#read
else
	echo 'Error!'
	#read
	exit $RESULT
fi
