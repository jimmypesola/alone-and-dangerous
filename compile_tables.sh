#!/bin/bash

echo '### RLE compress all maps'
python3 rle_encode.py aad_map_big.bin aad_map_big.rle
python3 rle_encode.py aad_d0_map.bin aad_d0_map.rle

acme coretables.asm
if [ $? -eq 0 ]; then
	gvim coretables_labels.a
	echo 'coretables.asm successfully compiled!'
else
	echo 'Error!'
	read
fi

acme outdoortables.asm
if [ $? -eq 0 ]; then
	gvim outdoortables_labels.a
	echo 'outdoortables.asm successfully compiled!'
else
	echo 'Error!'
	read
fi

acme outdoortext.asm
if [ $? -eq 0 ]; then
	echo 'outdoortext.asm successfully compiled!'
else
	echo 'Error!'
	read
fi

acme d0tables.asm
if [ $? -eq 0 ]; then
	gvim d0tables_labels.a
	echo 'd0tables.asm successfully compiled!'
else
	echo 'Error!'
	read
fi

acme d0text.asm
if [ $? -eq 0 ]; then
	echo 'd0text.asm successfully compiled!'
else
	echo 'Error!'
	read
fi
