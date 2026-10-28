@echo off
setlocal

:: =============================================================================
:: flatten-patches.cmd
::
:: Frees disk space on C: for Windows 10 and Windows 11:
::   - repairs the component store if needed, then flattens Windows updates (DISM /ResetBase)
::   - empties Windows Update downloads, system temp and every user's temp folder
::   - removes Windows upgrade leftovers, including Windows.old (no rollback afterwards)
::   - deletes .msi/.msp files in C:\Windows\Installer that no installed app or patch uses
::   - reports how much space was saved
::
:: Must be run as Administrator.
::
:: Layout: the main flow below only calls functions. Each function ends with
:: "goto :EOF", which returns to the line after its "call".
:: =============================================================================

:: ---- main flow -------------------------------------------------------------

:: stop here if not elevated
call :check_admin
if errorlevel 1 goto :end

:: sets BUILD; stops here if the build can't be read or is older than Windows 10
call :detect_version
if errorlevel 1 goto :end

:: set the version-specific settings (Windows 11 = build 22000 and up)
if %BUILD% GEQ 22000 (call :win11) else (call :win10)

:: everything common to both versions
call :main

:end
pause
exit /b


:: =============================================================================
:: Version-specific settings
::   WU_SERVICES  services to stop before cleaning, restarted at the end
::   EXTRA_TEMP   extra temp folders to empty
::   EXTRA_PURGE  extra upgrade folders to remove
:: =============================================================================

:win10
echo Detected Windows 10 (build %BUILD%)
set "WU_SERVICES=wuauserv bits"
set "EXTRA_TEMP="
:: Windows 10 Update Assistant download folder
set "EXTRA_PURGE=C:\Windows10Upgrade"
goto :EOF

:win11
echo Detected Windows 11 (build %BUILD%)
:: the Update Orchestrator (UsoSvc) restarts wuauserv and Delivery Optimization (dosvc)
:: holds files open in the download folder, so stop them too
set "WU_SERVICES=UsoSvc wuauserv bits dosvc"
:: Windows 11 keeps SYSTEM's temp files here instead of C:\Windows\Temp
set "EXTRA_TEMP=C:\Windows\SystemTemp"
set "EXTRA_PURGE="
goto :EOF


:: =============================================================================
:: Common steps, in order
:: =============================================================================

:main
:: DISM needs a scratch folder
if not exist C:\Temp mkdir C:\Temp

call :record_free_space
call :disable_hibernation
call :delete_shadow_copies
call :repair_component_store
call :flatten_patches
call :analyze_component_store
call :stop_update_services
call :clean_update_downloads
call :clean_system_folders
call :clean_temp_folders
call :remove_upgrade_leftovers
call :remove_orphan_installers
call :start_update_services

echo:
set runextra=n
set /P runextra=Run extra cleanup (Defender definitions, WizTree, PatchCleaner, OneDrive removal)? [y/N]
if /I "%runextra%"=="y" call :extra_cleanup

call :report_space_saved
goto :EOF


:: =============================================================================
:: Functions
:: =============================================================================

:check_admin
:: "net session" only succeeds in an elevated prompt
net session >nul 2>&1
if errorlevel 1 (
    echo This script must be run as Administrator.
    exit /b 1
)
goto :EOF


:detect_version
:: Windows 11 still reports version 10.0, so use the build number from the registry
set BUILD=
for /f "tokens=3" %%b in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber ^| find "CurrentBuildNumber"') do set BUILD=%%b
if not defined BUILD (
    echo Could not detect the Windows build number.
    exit /b 1
)
:: 10240 is the first Windows 10 build
if %BUILD% LSS 10240 (
    echo Build %BUILD% is older than Windows 10; not supported.
    exit /b 1
)
goto :EOF


:record_free_space
:: free bytes on C: before cleaning; batch math is 32-bit, so PowerShell reads it
for /f %%f in ('powershell -NoProfile -Command "(Get-PSDrive C).Free"') do set FREE_BEFORE=%%f
goto :EOF


:repair_component_store
:: fix any corruption first, or flattening fails with error 14098 - The component store has been corrupted
sfc /scannow
:: sfc fixed errors and asks for a reboot? reboot and run this again
:: sfc could not fix errors? answer y to repair with DISM
echo:
set answer=n
set /P answer=Was there errors? [N/y]
if /I "%answer%"=="y" Dism.exe /Online /Cleanup-Image /RestoreHealth /ScratchDir:C:\Temp
goto :EOF


:flatten_patches
:: remove superseded update components; installed updates can no longer be uninstalled after this
Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase /ScratchDir:C:\Temp
goto :EOF


:stop_update_services
echo:
echo Stopping update services: %WU_SERVICES%
:: if a service is still running after the first try, wait 5 seconds and try once more
for %%s in (%WU_SERVICES%) do (
    net stop %%s /y >nul 2>&1
    sc query %%s | find "STOPPED" >nul || (timeout /t 5 /nobreak >nul & net stop %%s /y >nul 2>&1)
)
goto :EOF


:start_update_services
:: bring the services stopped above back up
for %%s in (%WU_SERVICES%) do net start %%s >nul 2>&1
goto :EOF


:clean_update_downloads
:: update files Windows Update already downloaded; it downloads them again if needed
echo Cleaning Windows Update downloads
call :purge_contents "C:\Windows\SoftwareDistribution\Download"
goto :EOF


:clean_temp_folders
echo Cleaning temp folders
:: system temp
call :purge_contents "C:\Windows\Temp"
:: every user profile's temp
for /d %%u in ("C:\Users\*") do if exist "%%u\AppData\Local\Temp" call :purge_contents "%%u\AppData\Local\Temp"
:: version-specific temp folders (see :win10 / :win11)
for %%t in (%EXTRA_TEMP%) do call :purge_contents "%%t"
goto :EOF


:remove_upgrade_leftovers
:: $WINDOWS.~BT / ~WS : feature upgrade staging
:: $GetCurrent / ESD  : Media Creation Tool and upgrade downloads
:: Windows.old        : previous Windows install; rollback is not possible after this
echo Removing upgrade leftovers and Windows.old
:: remove the OS uninstall (rollback) entry first
Dism /Online /Remove-OSUninstall
for %%d in ("C:\$WINDOWS.~BT" "C:\$WINDOWS.~WS" "C:\$GetCurrent" "C:\ESD" "C:\Windows.old" %EXTRA_PURGE%) do call :purge_dir "%%~d"
goto :EOF


:remove_orphan_installers
:: deletes .msi/.msp in C:\Windows\Installer that no installed product or patch references.
:: The PowerShell command is built piece by piece in PS, then run as a plain -Command.
:: No iex / -ExecutionPolicy Bypass: Sophos blocks those (Exec_12a, T1059.001).
:: Rules for editing the pieces: single quotes only (a " would break the cmd line),
:: no percent signs, and never put ";" between a try {} and its catch {}.
echo Removing orphaned installer packages

:: $keep = file names (lowercase) of every cached installer still in use.
:: A file is kept if EITHER source below knows it; the COM list alone misses some
:: machine-wide products, so deleting on it alone would break their repair/uninstall.

:: source 1, Windows Installer (COM): cached .msi of each installed product and cached
:: .msp of each patch, for all users ('s-1-1-0') and all install contexts (7)
set "PS=$keep=@{}; try { $msi=New-Object -ComObject WindowsInstaller.Installer;"
set "PS=%PS% foreach ($p in $msi.ProductsEx('','s-1-1-0',7)) { try { $keep[[IO.Path]::GetFileName($p.InstallProperty('LocalPackage')).ToLower()]=1 } catch {} };"
set "PS=%PS% foreach ($x in $msi.PatchesEx('','s-1-1-0',7,15)) { try { $keep[[IO.Path]::GetFileName($x.PatchProperty('LocalPackage')).ToLower()]=1 } catch {} }"
:: if the COM list can't be read, nothing is safe to delete
set "PS=%PS% } catch { Write-Host ('  Could not read the installed products list, skipping: ' + $_); exit };"

:: source 2, registry: LocalPackage recorded under every user SID (S-1-5-18 = machine-wide),
:: first for products, then for patches
set "PS=%PS% $ud='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData';"
set "PS=%PS% Get-ChildItem $ud -ErrorAction SilentlyContinue | ForEach-Object { Get-ChildItem ($_.PSPath + '\Products') -ErrorAction SilentlyContinue | ForEach-Object { $v=(Get-ItemProperty ($_.PSPath + '\InstallProperties') -ErrorAction SilentlyContinue).LocalPackage; if ($v) { $keep[[IO.Path]::GetFileName($v).ToLower()]=1 } } };"
set "PS=%PS% Get-ChildItem $ud -ErrorAction SilentlyContinue | ForEach-Object { Get-ChildItem ($_.PSPath + '\Patches') -ErrorAction SilentlyContinue | ForEach-Object { $v=(Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).LocalPackage; if ($v) { $keep[[IO.Path]::GetFileName($v).ToLower()]=1 } } };"

:: an empty list would mark every file as an orphan; skip instead
set "PS=%PS% if ($keep.Count -eq 0) { Write-Host '  No installed packages found, skipping to be safe.'; exit };"
:: find .msi/.msp in the top folder that are not in the list ($PatchCache$ subfolder is left alone)
set "PS=%PS% $count=0; $bytes=0;"
set "PS=%PS% $orphans = Get-ChildItem 'C:\Windows\Installer\*' -Include *.msi,*.msp -File -Force | Where-Object { -not $keep.ContainsKey($_.Name.ToLower()) };"
:: delete them, counting files and size for the summary line
set "PS=%PS% foreach ($o in $orphans) { $len=$o.Length; try { Remove-Item -LiteralPath $o.FullName -Force -ErrorAction Stop; $count++; $bytes+=$len } catch { Write-Host ('  Could not delete ' + $o.Name) } };"
set "PS=%PS% Write-Host ('  {0} orphaned packages removed ({1:N2} GB), {2} in use kept' -f $count, ($bytes/1GB), $keep.Count)"

powershell -NoProfile -Command "%PS%"
goto :EOF


:disable_hibernation
:: turn off hibernation to free hiberfil.sys space
powercfg /hibernate off >nul 2>&1
goto :EOF


:delete_shadow_copies
:: remove all shadow copies / restore points
vssadmin delete shadows /all /quiet >nul 2>&1
goto :EOF


:analyze_component_store
:: report component store size after flattening
Dism /Online /Cleanup-Image /AnalyzeComponentStore
goto :EOF


:clean_system_folders
echo Cleaning system folders
for %%f in (
  "C:\Windows\Logs\CBS"
  "C:\Windows\SoftwareDistribution\DeliveryOptimization"
  "C:\Windows\ServiceProfiles\LocalService\Downloads"
  "C:\Windows\ServiceProfiles\NetworkService\Downloads"
  "C:\Windows\ServiceProfiles\MSSQL$MICROSOFT##WID\Downloads"
) do call :purge_contents "%%~f"
goto :EOF


:report_space_saved
:: compare free space now with the value saved by :record_free_space
echo:
powershell -NoProfile -Command "$a=[int64]'%FREE_BEFORE%'; $b=(Get-PSDrive C).Free; 'Space saved on C: {0:N2} GB  (free now: {1:N2} GB)' -f (($b-$a)/1GB), ($b/1GB)"
goto :EOF


:extra_cleanup
:: optional: Defender definitions, helper tools, OneDrive removal, Office SolutionPackages
echo:
echo --- Windows Defender definitions ---
echo Disable Tamper Protection temporarily NOW: Virus and threat protection -> Manage settings -> Tamper Protection Off
pause
powershell -NoProfile -Command "Add-AppxPackage -Register -DisableDevelopmentMode 'C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\AppXManifest.xml' -ForceApplicationShutdown" >nul 2>&1
"C:\Program Files\Windows Defender\MpCmdRun.exe" -RemoveDefinitions -All >nul 2>&1
del /q /f /s "C:\ProgramData\Microsoft\Windows Defender\Definition Updates\Backup\*" >nul 2>&1
del /q /f /s "C:\ProgramData\Microsoft\Windows Defender\Scans\History\Service\*" >nul 2>&1
"C:\Program Files\Windows Defender\MpCmdRun.exe" -SignatureUpdate >nul 2>&1
echo Re-enable Tamper Protection NOW.
pause

echo:
echo --- Optional helper tools ---
winget install AntibodySoftware.WizTree
winget install HomeDev.PatchCleanerPortable
echo winget install NoFaff.InstallerClean (about 100MB) - run it, then uninstall
winget install NoFaff.InstallerClean
pause
winget uninstall NoFaff.InstallerClean
pause

echo:
echo --- OneDrive removal ---
winget uninstall "Microsoft OneDrive" >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDriveSetup" /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul 2>&1

echo:
echo --- Office SolutionPackages ---
rmdir /q /s "C:\Users\Administrator\AppData\Local\Microsoft\Office\SolutionPackages" >nul 2>&1
rmdir /q /s "%LOCALAPPDATA%\Microsoft\Office\SolutionPackages" >nul 2>&1
goto :EOF


:: ---- helpers ----------------------------------------------------------------

:purge_contents
:: empties folder %1 but keeps the folder itself; files in use are skipped
if not exist "%~1" goto :EOF
:: files in the folder and all subfolders
del /q /f /s "%~1\*" >nul 2>&1
:: then the subfolders themselves
for /d %%i in ("%~1\*") do rmdir /q /s "%%i" >nul 2>&1
goto :EOF


:purge_dir
:: removes folder %1 entirely, including folders owned by TrustedInstaller/SYSTEM
if not exist "%~1" goto :EOF
echo   %~1
:: take ownership ("/d y" answers the prompt; English Windows only)
takeown /f "%~1" /r /d y >nul 2>&1
:: give the Administrators group (S-1-5-32-544) full control
icacls "%~1" /grant *S-1-5-32-544:F /t /c /q >nul 2>&1
rd /s /q "%~1" >nul 2>&1
goto :EOF
