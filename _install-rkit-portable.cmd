:: author=audioscavenger @ it-cooking.com
:: version=1.2
:: /!\ Warning: starting this batch with ADMIN rights will alter SYSTEM settings. Read carefully what it does.
:: ----------------------------------------------------------------------------------------------------------------------
:: This batch purpose is to create a portable Resource Kit folder containing UNIX-like commands for your convenience.
:: It features mostly command line tools including busybox, SysinternalsSuite, Rkit2003 and 7zip.
:: Nirsoft tools are mostly GUI and therefore not included but you can easily modify this batch to include them.
:: Note: Many tools included (such as password recovery/sniffer and even Pskill.exe from Microsoft) are considered 
::  harmful/unwanted by exaggerated/mental AVs/services such as Sophos, and will shoot false positives.
::  Prepare yourself to explain these alerts to your IT bff.
:: ----------------------------------------------------------------------------------------------------------------------
:: This batch will operate in the folder it is placed in, or the folder passed as parameter.
:: This batch *should* be compatible from Windows XP SP3 Pro and beyond.
:: Requisites: setx, powershell, mklink (will be circumvented at disk cost)
:: ----------------------------------------------------------------------------------------------------------------------
:: - download 7zip 19.00
:: - download gawk
:: - download wget
:: - download busybox
:: - download SysinternalsSuite
:: - download Windows Server 2003 Resource Kit Tools
:: + install 7zip 19.00
:: + add 7zip file associations for local user  (/!\ ==> or ALL USERS   if started as ADMIN!)
:: + update PATH variable for local user        (/!\ ==> or SYSTEM PATH if started as ADMIN!)
:: ----------------------------------------------------------------------------------------------------------------------
:: TODO:
:: [ ] use 7zip portable instead
:: [ ] detect UNC path because symlink won't work
:: [ ] ?
:: ----------------------------------------------------------------------------------------------------------------------

@echo OFF
set INSTALLDIR=%1
set TMPFILE=%TMP%\%~n0.txt
set TMPDIR=%TMP%
set VERBOSE=
verify on

IF NOT DEFINED INSTALLDIR set INSTALLDIR="%~dp0"
IF NOT EXIST %INSTALLDIR%\ md %INSTALLDIR%
pushd %INSTALLDIR%

call :set_colors
call :pre_requisites

:: 7zip first, in any case we need 7z.exe
set ver7zMaj=19
set ver7zMin=00
call :power_download https://downloads.sourceforge.net/project/sevenzip/7-Zip/%ver7zMaj%.%ver7zMin%/7z%ver7zMaj%%ver7zMin%%arch%.exe %TMPDIR%\7z%ver7zMaj%%ver7zMin%%arch%.exe
call :install_7zip %TMPDIR%\7z%ver7zMaj%%ver7zMin%%arch%.exe
call :setup_7zip_Extn
call :copy_7z

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: UnxUtils are deprecated since the win32 port of busybox
REM call :power_download https://downloads.sourceforge.net/project/unxutils/unxutils/current/UnxUtils.zip %TMPDIR%\UnxUtils.zip
REM call :power_unzip %TMPDIR%\UnxUtils.zip *.exe

:: Nirsoft tools are not included by default but you can uncomment this section if you like.
:: Note that some tools such as password viewers will trigger exaggerated/mental AVs/services that easily shoot false positives.
REM call :wget_nirsoft http://nirsoft.net/packages/passrecenc.zip %TMPDIR%\passrecenc.zip
REM call :7unzip %TMPDIR%\passrecenc.zip .\ nirsoft123!
REM call :wget_nirsoft http://www.nirsoft.net/protected_downloads/passreccommandline.zip %TMPDIR%\passreccommandline.zip download nirsoft123!
REM call :7unzip %TMPDIR%\passreccommandline.zip .\ nirsoft123!
REM call :wget_nirsoft http://nirsoft.net/packages/systools.zip %TMPDIR%\systools.zip
REM call :7unzip %TMPDIR%\systools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/brtools.zip %TMPDIR%\brtools.zip
REM call :7unzip %TMPDIR%\brtools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/progtools.zip %TMPDIR%\progtools.zip
REM call :7unzip %TMPDIR%\progtools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/networktools.zip %TMPDIR%\networktools.zip
REM call :7unzip %TMPDIR%\networktools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/x64tools.zip %TMPDIR%\x64tools.zip
REM call :7unzip %TMPDIR%\x64tools.zip .\ nirsoft123!
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: awk is included in busybox but it's a limited version
call :power_download https://downloads.sourceforge.net/project/gnuwin32/gawk/3.1.6-1/gawk-3.1.6-1-bin.zip %TMPDIR%\gawk-3.1.6-1-bin.zip
del /q .\awk.exe 2>NUL
call :power_unzip %TMPDIR%\gawk-3.1.6-1-bin.zip awk.exe

:: wget is included in busybox but it's a limited version
call :power_download https://eternallybored.org/misc/wget/1.20.3/%bits%/wget.exe .\wget.exe

call :power_download https://frippery.org/files/busybox/busybox.exe .\busybox.exe
call :install_busybox_symlink

:: SysinternalsSuite includes PsTools which will trigger exaggerated/mental AVs/services that easily shoot false positives.
call :power_download https://download.sysinternals.com/files/SysinternalsSuite.zip %TMPDIR%\SysinternalsSuite.zip
call :7unzip %TMPDIR%\SysinternalsSuite.zip .\

:: Windows Server 2003 Resource Kit Tools used to be a must have but I don't remember a time when I used any of their tools
call :power_download https://download.microsoft.com/download/8/e/c/8ec3a7d8-05b4-440a-a71e-ca3ee25fe057/rktools.exe %TMPDIR%\rktools.exe
call :7unzip %TMPDIR%\rktools.exe %TMPDIR%\
call :7unzip %TMPDIR%\rktools.msi .\

IF %ADMIN% EQU 0 (call :update_HKLM_path) ELSE (call :update_HKCU_path)

:: echo systempropertiesadvanced.exe
goto :end


:set_colors
set END=[0m
set HIGH=[1m
set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m
goto :EOF

:pre_requisites
echo %c%%~0%END%
:: Cannot use where on Windows XP
:: where powershell >NUL 2>&1
REM IF %ERRORLEVEL% NEQ 0 call :error powershell NOT FOUND& goto :end
for %%x in (powershell.exe) do (set powershell=%%~$PATH:x)
IF NOT DEFINED powershell call :error powershell NOT FOUND& goto :end

for %%x in (setx.exe) do (set setx=%%~$PATH:x)
IF NOT DEFINED setx call :error setx NOT FOUND& goto :end

for %%x in (wget.exe) do (set wget=%%~$PATH:x)

set bits=32
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set arch=-x64
  set bits=64
)

:: check current user is local admin
net localgroup administrators | findstr /B /C:%USERNAME% >NUL
set ADMIN=%ERRORLEVEL%

:: check batch is started with admin rights
NET SESSION >NUL 2>&1
set /a ADMIN=ADMIN+%ERRORLEVEL%

IF %ADMIN% EQU 0 (
  echo Batch started with %HIGH%%y%ADMIN%END% rights
) ELSE (
  echo Batch started with %y%USER%END% rights
)

ver | findstr /C:"Version 5.1" && set WindowsVersion=XP
ver | findstr /C:"Version 6.1" && set WindowsVersion=7
ver | findstr /C:"Version 10.0" && set WindowsVersion=10

goto :EOF

:install_busybox_symlink
echo %c%%~0%END%
:: no mklink for XP so busybox will unfortunately create hardlinks for a total of 88MB
IF [%WindowsVersion%]==[XP] busybox --install %INSTALLDIR% && goto :EOF

:: mklink won't overwrite existing files
FOR /f "usebackq" %%l IN (`busybox.exe --list`) DO 2>NUL (
  mklink %%l.exe busybox.exe >NUL 2>&1
)
goto :EOF

:install_7zip 7z0000.exe
echo %c%%~0 %1%END%
IF NOT EXIST %1 goto :EOF
echo start /wait %1 /S
start /wait %1 /S
del /q %1 2>NUL
echo Installing 7zip - %HIGH%%g%DONE%END%
goto :EOF

:setup_7zip_Extn
:: setup 7zip association for all users if batch executed by local admin

IF %ADMIN% EQU 0 (
  SET SC=HKLM\SOFTWARE\Classes
  echo Setup 7zip file extensions: %HIGH%%y%ALL USERS%END%
) ELSE (
  SET SC=HKCU\Software\Classes
  echo Setup 7zip file extensions: %y%current user only%END%
)

REM SET Extn=001 7z arj bz2 bzip2 cab cpio deb dmg fat gz gzip hfs iso lha lzh lzma rar rpm squashfs swm tar taz tbz tbz2 tgz tpz txz wim xar xz z zip
REM FOR %a IN (%Extn%) DO @REG QUERY HKCU\SOFTWARE\Classes\7-Zip.%a\DefaultIcon | @awk -F\\ "/Classes/ {gsub("""7-Zip.""",""""""); printf $4}; /dll/ {gsub("""7z.dll,""","""-"""); printf $4""" """}" 
:: BUG: cannot use , comma as separator because shitty FOR loop would use it as separator

SET Extn=001-9 7z-0 arj-4 bz2-2 bzip2-2 cab-7 cpio-12 deb-11 dmg-17 fat-21 gz-14 gzip-14 hfs-18 iso-8 lha-6 lzh-6 lzma-16 rar-3 rpm-10 squashfs-24 swm-15 tar-13 taz-5 tbz-2 tbz2-2 tgz-14 tpz-14 txz-23 wim-15 xar-19 xz-23 z-5 zip-1
:: echo without CR:
<nul set /p =Setup 7zip file extensions:%g% 
FOR %%x IN (%Extn%) DO (
  FOR /f "tokens=1,2 delims=-" %%a in ('@echo %%x') DO (
    REG ADD %SC%\.%%a /VE /D "7-Zip.%%a" /F >NUL
    REG ADD %SC%\7-Zip.%%a /VE /D "%%a Archive" /F >NUL
    REG ADD %SC%\7-Zip.%%a\DefaultIcon /VE /D "%PROGRAMFILES%\7-Zip\7z.dll,%%b" /F >NUL
    REG ADD %SC%\7-Zip.%%a\shell\open\command /VE /D "\"%PROGRAMFILES%\7-Zip\7zFM.exe\" \"%%1\"" /F >NUL
    <nul set /p =%%a 
  )
)
echo.%END%
echo Setup 7zip file extensions: %HIGH%%g%DONE%END%
goto :EOF

:copy_7z
echo %c%%~0%END%
copy /y "%ProgramFiles%\7-Zip\7z.exe" .\
copy /y "%ProgramFiles%\7-Zip\7z.dll" .\
goto :EOF

:wget_nirsoft url output [user pass]
echo %c%%~0 %1%END%
IF DEFINED VERBOSE echo wget --referer=http://nirsoft.net %1 -O %2 --user=%3 --password=%4
wget --referer=http://nirsoft.net %1 -O %2 --user=%3 --password=%4 2>&1 | grep saved
goto :EOF

:power_download url output [user pass]
echo %c%%~0%END% %y%%1 %HIGH%%2%END%
del /q %2 2>NUL
IF DEFINED wget (
  wget %1 -O %2 --user=%3 --password=%4 2>&1 | grep saved
) ELSE (
  powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile("""%1""","""%2""")}"
)
goto :EOF

:power_unzip archive filter
IF NOT EXIST %1 goto :EOF
echo %c%%~0%END% %1 %2
powershell -executionPolicy bypass -Command "&{Add-Type -AssemblyName System.IO.Compression.FileSystem ; $Filter = '%2' ; $zip = [System.IO.Compression.ZipFile]::OpenRead("""%1""") ; $zip.Entries | Where-Object { $_.FullName -like $Filter } | ForEach-Object { $FileName = $_.Name ; [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$FileName", $true)} }"
del /q %1 2>NUL
goto :EOF

:7unzip archive target [password]
echo %c%%~0 %1%END% %2 %3
set password=
set pass=%3
IF DEFINED pass set password=-p%3

echo %g%
IF DEFINED VERBOSE echo 7z.exe e -y -o%2 %password% %1
7z.exe e -y -o%2 %password% %1 | grep Extracting
echo %END%
del /q %1 2>NUL
goto :EOF

:update_HKLM_path
echo %c%%~0%END%
set RKIT_PATH=%CD%

path | findstr /C:"%RKIT_PATH%" >NUL 2>&1
IF ERRORLEVEL 0 (
  echo %g%No need to update PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
  goto :EOF
)

echo.
echo UPDATE HKLM_PATH with %RKIT_PATH%...

:: prepend
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do if [%%b]==[] ( setx /m PATH "%RKIT_PATH%;%%~a" ) else ( setx /m PATH "%RKIT_PATH%;%%~a %%~b" )

::append
REM for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do if [%%b]==[] ( setx /m PATH "%%~a;%RKIT_PATH%" ) else ( setx /m PATH "%%~a %%~b;%RKIT_PATH%" )

echo UPDATE %HIGH%%y%HKLM%END%_PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
goto :EOF

:update_HKCU_path
echo %c%%~0%END%
set RKIT_PATH=%CD%

path | findstr /C:"%RKIT_PATH%" >NUL 2>&1
IF ERRORLEVEL 0 (
  echo %g%No need to update PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
  goto :EOF
)

echo.
echo UPDATE HKCU_PATH with %RKIT_PATH%...

:: prepend
for /f "skip=2 tokens=3*" %%a in ('reg query HKCU\Environment /v PATH') do if [%%b]==[] ( setx PATH "%RKIT_PATH%;%%~a" ) else ( setx PATH "%RKIT_PATH%;%%~a %%~b" )

::append
REM for /f "skip=2 tokens=3*" %%a in ('reg query HKCU\Environment /v PATH') do if [%%b]==[] ( setx PATH "%%~a;%RKIT_PATH%" ) else ( setx PATH "%%~a %%~b;%RKIT_PATH%" )

echo UPDATE %y%HKCU%END%_PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
goto :EOF

:error
echo.%r%
echo ==============================================================
echo ERROR: %HIGH%%*%END%%r%
IF %1 == setx echo %y%Consider installing Windows XP Service Pack 2 Support Tools at https://www.microsoft.com/en-us/download/details.aspx?id=18546 %r%
IF %1 == powershell echo %y%Consider upgrading to Windows XP SP3 or Server 2003 SP2 (or download wget.exe manually) %r%
echo ==============================================================
echo.%END%
pause
exit
goto :EOF

:end
echo %c%END%END%
echo exit in 5 seconds...
sleep 5
popd
exit