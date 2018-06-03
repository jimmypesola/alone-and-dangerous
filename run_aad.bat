acme -l aad_symbols.txt aad.asm
if %ERRORLEVEL% == 0 (
	start c:\windows\notepad.exe aad_symbols.txt
	x64 aad.prg
) else (
	echo Error!
	pause
)
