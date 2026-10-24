@echo off

:: Hibernation file
powercfg /hibernate off
:: Shadow copies / restore points
vssadmin delete shadows /all /quiet

IF EXIST "C:\$WINDOWS.~BT" call :recursive_delete "C:\$WINDOWS.~BT"
IF EXIST "C:\$WINDOWS.~WS" call :recursive_delete "C:\$WINDOWS.~WS"
Dism /Online /Remove-OSUninstall
IF EXIST C:\Windows.old call :recursive_delete C:\Windows.old

:: purge and free up temporary updater files
echo net stop wuauserv
net stop wuauserv 2>nul
echo net stop bits
net stop bits 2>nul

for %%f in (
  C:\Windows\Temp
  C:\Windows\Logs\CBS
  C:\Windows\SoftwareDistribution\DeliveryOptimization
  C:\Windows\SoftwareDistribution\Download
  C:\Windows\ServiceProfiles\LocalService\Downloads
  C:\Windows\ServiceProfiles\MSSQL$MICROSOFT##WID\Downloads
  C:\Windows\ServiceProfiles\NetworkService\Downloads
) DO call :delete_content %%f


echo net start bits
net start bits
echo net start wuauserv
net start wuauserv

md C:\Temp 2>NUL

:: flatten out microsoft patches; first make sure to fix any corruption or you'll get an error 14098 - The component store has been corrupted
sfc /scannow
:: fixed errors and asking for reboot? reboot; if not, then move on
:: cannot fix errors? run:

echo:
set answer=n
set /P answer=Did sfc complete without errors? [N/y] 
IF /I "%answer%"=="y" (
  echo Dism.exe /Online /Cleanup-Image /RestoreHealth /ScratchDir:C:\Temp
  Dism.exe /Online /Cleanup-Image /RestoreHealth /ScratchDir:C:\Temp
)

:: finally: flatten patches out
echo Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase /ScratchDir:C:\Temp
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase /ScratchDir:C:\Temp

Dism /Online /Cleanup-Image /AnalyzeComponentStore

goto :end

:delete_content folder
IF NOT EXIST "%~1\" exit /b 0

echo del /a /q /f /s "%~1\*"
del /a /q /f /s "%~1\*"

for /d %%d in ("%~1\*") do rd /s /q "%%d"

goto :EOF

:recursive_delete folder
IF NOT EXIST "%~1\" exit /b 0

echo rd /q /s %1
rd /q /s %1
goto :EOF


:end
echo:
echo ------------------------ all done ---------------------------
pause
exit /b


REM # need an app to open this app windows defender link?
powershell  Add-AppxPackage -Register -DisableDevelopmentMode "C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\AppXManifest.xml" -ForceApplicationShutdown

echo DISABLE Tamper Protection Temporarily NOW: Virus + threat protection ) Manage settings. ) Tamper Protection and toggle it Off
pause

REM # 1. This should now complete successfully without the 0x80070005 error
"C:\Program Files\Windows Defender\MpCmdRun.exe" -RemoveDefinitions -All
del /q /f /s "C:\ProgramData\Microsoft\Windows Defender\Definition Updates\Backup\*"
del /q /f /s "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service\*"

REM force defender update:
"C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate

echo:
echo RE-Enable Tamper Protection Temporarily NOW: Virus + threat protection ) Manage settings. ) Tamper Protection and toggle it ON
pause

winget install AntibodySoftware.WizTree
winget install HomeDev.PatchCleanerPortable

echo winget install NoFaff.InstallerClean (100MB) - execute and uninstall it after the job is done
winget install NoFaff.InstallerClean
pause
winget uninstall NoFaff.InstallerClean

pause

winget uninstall "Microsoft OneDrive"
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f
REM never triggers that fallback file to reinstall OneDrive during a future system update:
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f

rmdir /q /s "C:\Users\Administrator\AppData\Local\Microsoft\Office\SolutionPackages"
rmdir /q /s "%LOCALAPPDATA%\Microsoft\Office\SolutionPackages"

echo THE END

pause

