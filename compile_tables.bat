@echo off
acme coretables.asm
if %ERRORLEVEL% == 0 (
	REM start c:\windows\notepad.exe coretables_labels.a
) else (
	echo Error!
	pause
)

acme outdoortables.asm
if %ERRORLEVEL% == 0 (
	REM start c:\windows\notepad.exe outdoortables_labels.a
) else (
	echo Error!
	pause
)
