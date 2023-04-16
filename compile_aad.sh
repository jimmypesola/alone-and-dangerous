#!/bin/bash

echo '### RLE compress all maps'
python3 rle_encode.py aad_map_big.bin aad_map_big.rle
python3 rle_encode.py aad_d0_map.bin aad_d0_map.rle

./compile_tables.sh

acme aad.asm

if [ $? -eq 0 ]; then
  gvim aad_symbols.a &
  echo 'aad.asm successfully compiled!'
else
  echo 'Compile error!! Press ENTER to continue'
  read
fi
