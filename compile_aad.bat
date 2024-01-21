@echo off

acme aad.asm

if %ERRORLEVEL% == 0 (
	start c:\windows\notepad.exe aad_symbols.a
	echo aad.asm successfully compiled!
	pause
) else (
	echo Error!
	pause
)
