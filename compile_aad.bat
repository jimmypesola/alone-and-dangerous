@echo off

REM -- RLE compress all maps
python rle_encode.py aad_map_big.bin aad_map_big.rle
python rle_encode.py aad_d0_map.bin aad_d0_map.rle


call compile_tables.bat

acme aad.asm

if %ERRORLEVEL% == 0 (
	start c:\windows\notepad.exe aad_symbols.a
	echo aad.asm successfully compiled!
	pause
) else (
	echo Error!
	pause
)
