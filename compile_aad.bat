@echo off

call compile_tables.bat

acme aad.asm

if %ERRORLEVEL% == 0 (
	start c:\windows\notepad.exe aad_symbols.a
	echo Compilation successful!
	pause
) else (
	echo Error!
	pause
)
