@echo off

mkdir C:\Temp

:: flatten out microsoft patches; first make sure to fix any corruption or you'll get an error 14098 - The component store has been corrupted
sfc /scannow
REM fixed errors and asking for reboot? reboot; if not, then move on
REM cannot fix errors? run:

echo:
set answer=n
set /P answer=Was there errors? [N/y] 
IF /I "%anserver%"=="y" Dism.exe /Online /Cleanup-Image /RestoreHealth /ScratchDir:C:\Temp

REM finally: flatten patches out
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase /ScratchDir:C:\Temp

:: purge and free up temporary updater files
net stop wuauserv & net stop bits
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" && for /d %i in ("C:\Windows\SoftwareDistribution\Download\*") do rmdir /q /s "%i"

pause

