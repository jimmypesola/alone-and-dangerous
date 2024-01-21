@echo off

REM -- RLE compress all maps
python rle_encode.py aad_map_big.bin aad_map_big.rle
python rle_encode.py aad_d0_map.bin aad_d0_map.rle

acme coretables.asm
if %ERRORLEVEL% == 0 (
	REM start c:\windows\notepad.exe coretables_labels.a
	echo coretables.asm successfully compiled!
) else (
	echo Error!
	pause
)

acme outdoortables.asm
if %ERRORLEVEL% == 0 (
	REM start c:\windows\notepad.exe outdoortables_labels.a
	echo outdoortables.asm successfully compiled!
) else (
	echo Error!
	pause
)

acme outdoortext.asm
if %ERRORLEVEL% == 0 (
	echo outdoortext.asm successfully compiled!
) else (
	echo Error!
	pause
)

acme d0tables.asm
if %ERRORLEVEL% == 0 (
	REM start c:\windows\notepad.exe d0tables_labels.a
	echo d0tables.asm successfully compiled!
) else (
	echo Error!
	pause
)

acme d0text.asm
if %ERRORLEVEL% == 0 (
	echo d0text.asm successfully compiled!
) else (
	echo Error!
	pause
)
