@echo off
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

acme d0tables.asm
if %ERRORLEVEL% == 0 (
	REM start c:\windows\notepad.exe d0tables_labels.a
	echo d0tables.asm successfully compiled!
) else (
	echo Error!
	pause
)
