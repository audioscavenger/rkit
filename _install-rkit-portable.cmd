@echo OFF
::   install-rkit-portable  Copyright (C) <2019>  <audioscavenger@it-cooking.com>
::   This program comes with ABSOLUTELY NO WARRANTY;
::   This is free software, and you are welcome to redistribute it
::   under certain conditions; https://www.gnu.org/licenses/gpl-3.0.html
:: ----------------------------------------------------------------------------------------------------------------------
:top
@set version=1.5.1
:: ----------------------------------------------------------------------------------------------------------------------
:: This batch purpose is to create a portable Resource Kit folder with UNIX-like commands for your convenience.
:: It features mostly command line tools including busybox, SysinternalsSuite, Rkit2003 and 7zip among many.
:: Nirsoft tools are mostly GUI and therefore not included but you can easily modify this batch to include them.
:: Note: Many tools included (such as password recovery/sniffer and even Pskill.exe from Microsoft) are considered 
::  harmful/unwanted by exaggerated/mental AVs/services such as Sophos, and will shoot false positives.
::  Prepare yourself to explain these alerts to your IT bff.
:: ----------------------------------------------------------------------------------------------------------------------
:: This batch will operate in the folder it is placed in, or the folder passed as parameter.
:: This batch *should* be compatible from Windows XP SP3 Pro and beyond.
:: Requisites: setx, powershell, mklink (will be circumvented at disk cost)
:: /!\ Warning: starting this batch with ADMIN rights will alter SYSTEM settings. Read carefully what it does.
:: /!\ Warning: there may be a bug in :setup_7zip_Extn when PROGRAMS=C:\Program Files (x86) because of the parenthesis
:: ----------------------------------------------------------------------------------------------------------------------
:: - [x] 7zip _19.00_
:: - [x] apache benchmark _2.4.43_
:: - [ ] blat mail _3.2.19_
:: - [x] busybox _latest_
:: - [x] curl _7.65_
:: - [x] dig  _9.15.0_
:: - [x] msvcr110.dll  _as needed_
:: - [x] dirhash _latest_
:: - [x] file _5.03_
:: - [x] gawk _3.1.6-1_
:: - [x] jq _1.6_
:: - [ ] mailsend-go _1.0.4_
:: - [x] netcat _1.1.1_
:: - [ ] NirSoft _latest_
:: - [x] NirCmd _latest_
:: - [x] openSSL _1.1.1c_
:: - [x] Pdftk free _1.41_
:: - [x] sqlite _33.10.100_
:: - [x] SysinternalsSuite _latest_
:: - [x] tcpdump _latest_
:: - [x] UnxUtils _latest_
:: - [x] upx _3.95w_
:: - [x] wget _1.20.3_
:: - [ ] Windows Server 2003 Resource Kit Tools
:: - [x] XMLStarlet _latest_
:: + install 7zip 19.00
:: + add/update 7zip file associations for local user  (/!\ ==> or ALL USERS   if started as ADMIN!)
:: + update PATH variable for local user (prepend)     (/!\ ==> or SYSTEM PATH if started as ADMIN! (append))
:: + compress every DLL with UPX
:: ----------------------------------------------------------------------------------------------------------------------
:: TODO:
:: [ ] make lin2xml and dig compatible because of lib2xml.dll used for both but different 
:: [x] download wget first to get rid of powershell asap
:: [ ] use 7zip portable instead
:: [ ] detect UNC path because mklink won't work
:: [ ] https://www.dostips.com/forum/viewtopic.php?f=3&t=3428
:: [ ] git push -f --set-upstream origin master
:: ----------------------------------------------------------------------------------------------------------------------

:init
set DEBUG=
set INSTALLDIR=%1
set TMPFILE=%TMP%\%~n0.tmp
set LOGFILE=.\%~n0.log
set VERBOSE=
set RESTART=n
verify on
set COUNTER=0
set SUCCESS=0
set fullyInstalled=
title %0 %version% started %DATE% at %TIME%
MODE CON: COLS=150 LINES=50

IF DEFINED ProgramW6432 (set "PROGRAMS=%ProgramW6432%") ELSE set "PROGRAMS=%ProgramFiles%"

IF NOT DEFINED INSTALLDIR set INSTALLDIR="%~dp0"
IF NOT EXIST %INSTALLDIR% md %INSTALLDIR%
IF NOT EXIST %INSTALLDIR% call :error mkdir - cannot create %INSTALLDIR% & goto :end
pushd %INSTALLDIR%

call :set_colors
call :detect_admin_mode
call :pre_requisites
call :startup

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: STANDARD ZONE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main

:: UnxUtils are supposedly deprecated since the win32 port of busybox, however:
:: - busybox tail cannot process UNC paths
:: - you are using UNC path, cannot use mklink
call :power_download https://downloads.sourceforge.net/project/unxutils/unxutils/current/UnxUtils.zip %TEMP%\UnxUtils.zip
call :power_unzip %TEMP%\UnxUtils.zip *.exe
:: just noticed how slow is UnxUtils xargs
del /f /q xargs.exe
:: recently noticed UnxUtils tee doesnt handle colors
del /f /q tee.exe

:: wget is included in busybox but it's a limited version
call :power_download https://eternallybored.org/misc/wget/1.20.3/%bits%/wget.exe .\wget.exe

:: 7zip first, in any case we need 7z.exe
set ver7zMaj=19
set ver7zMin=00
call :power_download https://downloads.sourceforge.net/project/sevenzip/7-Zip/%ver7zMaj%.%ver7zMin%/7z%ver7zMaj%%ver7zMin%%arch%.exe %TEMP%\7z%ver7zMaj%%ver7zMin%%arch%.exe
call :install_7zip %TEMP%\7z%ver7zMaj%%ver7zMin%%arch%.exe
call :setup_7zip_Extn
call :copy_7z

call :power_download https://frippery.org/files/busybox/busybox.exe .\busybox.exe

:: jq is a json parser
call :power_download https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win%bits%.exe .\jq.exe

:: awk is included in busybox but it's a limited version
call :power_download https://downloads.sourceforge.net/project/gnuwin32/gawk/3.1.6-1/gawk-3.1.6-1-bin.zip %TEMP%\gawk-3.1.6-1-bin.zip
call :power_unzip %TEMP%\gawk-3.1.6-1-bin.zip gawk.exe

:: XMLStarlet Command Line XML Toolkit
call :power_download https://sourceforge.net/projects/xmlstar/files/latest/download %TEMP%\xmlstarlet-win32.zip
call :power_unzip %TEMP%\xmlstarlet-win32.zip xml.exe

:: BIND9 contains dig
call :power_download https://downloads.isc.org/isc/bind9/9.14.3/BIND9.14.3.%bitx%.zip %TEMP%\BIND9.zip
call :power_unzip %TEMP%\BIND9.zip dig.exe keep
call :power_unzip %TEMP%\BIND9.zip *.dll
:: BIND9 libxml2.dll is in conflict with the one from xmllint, but xmllint's works with both
:: BIND9 needs MSVC++ 2012 redistribuable
IF NOT DEFINED msvcr110 (
  call :power_download %msvc_url% %TEMP%\msvcr110.zip
  call :power_unzip %TEMP%\msvcr110.zip msvcr110.dll
)

:: xmllint - needed to get latest curl version; couldn't extract Xpath with xmlstarlet coz curl html page is broken (too loose)
call :power_download https://sourceforge.net/projects/gnuwin32/files/libxml/2.4.12-1/libxml2-2.4.12-bin.zip/download %TEMP%\libxml2-win32.zip
call :power_unzip %TEMP%\libxml2-win32.zip libxml2.dll keep
call :power_unzip %TEMP%\libxml2-win32.zip *.exe

:: curl guys simply remove the link after each new version, thanks
REM call :power_download https://curl.haxx.se/windows/dl-7.65.0_1/curl-7.65.0_1-win%bits%-mingw.zip %TEMP%\curl-7.65.0_1-win%bits%-mingw.zip
REM call :power_download https://curl.haxx.se/windows/dl-7.65.1_3/curl-7.65.1_3-win%bits%-mingw.zip %TEMP%\curl-7.65.0_1-win%bits%-mingw.zip

:: auto-detection of curl version
curl https://curl.haxx.se/windows/ >%TMPFILE% 2>NUL
REM echo cat //*[@class="windl"][1]/a[1]/@href | xmllint --shell --nowarning --noblanks --html --recover %TMPFILE%
:: <href>dl-7.65.1_3/curl-7.65.1_3-win64-mingw.zip</href>
echo cat //*[@class="windl"]/a[1]/@href | xmllint --shell --nowarning --noblanks --html --recover %TMPFILE% | gawk -F[^<^>] "{print $3}" >%TMPFILE%.2
:: dl-7.65.1_3/curl-7.65.1_3-win64-mingw.zip
:: dl-7.65.1_3/curl-7.65.1_3-win32-mingw.zip
for /f %%a in ('findstr win%bits% %TMPFILE%.2') do set url=%%a


call :power_download https://curl.haxx.se/windows/%url% %TEMP%\curl-mingw.zip
call :power_unzip %TEMP%\curl-mingw.zip curl-ca-bundle.crt keep
call :power_unzip %TEMP%\curl-mingw.zip curl.exe keep
call :power_unzip %TEMP%\curl-mingw.zip libcurl-x%bits%.dll

:: SysinternalsSuite includes PsTools which will trigger exaggerated/mental AVs/services that easily shoot false positives.
call :power_download https://sqlite.org/2020/sqlite-tools-win32-x86-3310100.zip %TEMP%\sqlite-tools-win32-x86.zip
call :power_unzip %TEMP%\sqlite-tools-win32-x86.zip *.exe

:: SysinternalsSuite includes PsTools which will trigger exaggerated/mental AVs/services that easily shoot false positives.
call :power_download https://download.sysinternals.com/files/SysinternalsSuite.zip %TEMP%\SysinternalsSuite.zip
call :7unzip %TEMP%\SysinternalsSuite.zip .\

:: UPX is a free, portable, extendable, high-performance executable packer for several executable formats.
call :power_download https://github.com/upx/upx/releases/download/v3.95/upx-3.95-win%bits%.zip %TEMP%\upx-3.95-win%bits%.zip
call :power_unzip %TEMP%\upx-3.95-win%bits%.zip upx.exe

:: tcpdump for windows
call :power_download "http://chiselapp.com/user/rkeene/repository/tcpdump-windows-wrapper/raw/tcpdump.exe?name=2e3d4d01fa597e1f50ba3ead8f18b8eeacb83812" .\tcpdump.exe

:: Directory checksum tool
call :power_download https://www.idrix.fr/Root/Samples/DirHash%arch%.zip %TEMP%\DirHash%arch%.zip
call :power_unzip %TEMP%\DirHash%arch%.zip dirhash.exe

:: apache benchmark tool is very basic, and while it will give you a solid idea of some performance, it is a bad idea to only depend on it if you plan to have your site exposed to serious stress in production.
REM call :power_download https://home.apache.org/~steffenal/VC15/binaries/httpd-2.4.39-win%bits%-VC15.zip %TEMP%\httpd-2.4.39-win%bits%-VC15.zip
call :power_download https://www.apachelounge.com/download/VS16/binaries/httpd-2.4.43-win%bits%-VS16.zip %TEMP%\httpd-win%bits%.zip
call :power_unzip %TEMP%\httpd-win%bits%.zip ab.exe keep
call :power_unzip %TEMP%\httpd-win%bits%.zip abs.exe keep
call :power_unzip %TEMP%\httpd-win%bits%.zip libcrypto-1_1%arch%.dll keep
call :power_unzip %TEMP%\httpd-win%bits%.zip libssl-1_1%arch%.dll keep
call :power_unzip %TEMP%\httpd-win%bits%.zip openssl.exe

:: File for Windows
call :power_download https://sourceforge.net/projects/gnuwin32/files/file/5.03/file-5.03-bin.zip/download %TEMP%\file-5.03-bin.zip
call :power_unzip %TEMP%\file-5.03-bin.zip file.exe keep
call :power_unzip %TEMP%\file-5.03-bin.zip magic1.dll keep
call :power_unzip %TEMP%\file-5.03-bin.zip magic keep
call :power_unzip %TEMP%\file-5.03-bin.zip magic.mgc
move /y file.exe filemagic.exe
call :power_download https://sourceforge.net/projects/gnuwin32/files/file/5.03/file-5.03-dep.zip/download %TEMP%\file-5.03-dep.zip
call :power_unzip %TEMP%\file-5.03-dep.zip regex2.dll keep
call :power_unzip %TEMP%\file-5.03-dep.zip zlib1.dll

:: Netcat for NT is the tcp/ip "Swiss Army knife" that never made it into any of the resource kits
:: it's powerful enough to be included in some natsy malware packages so it may trigger your AV
:: https://github.com/diegocr/netcat
:: example use: nc -l -p 23 -t -e cmd.exe
call :power_download https://joncraton.org/files/nc111nt.zip %TEMP%\nc111nt.zip
call :7unzip %TEMP%\nc111nt.zip .\ nc nc.exe

:: pdftk 2.02 = https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-2.02-win-setup.exe
:: unfortunately this installer cannot be unzipped
call :power_download "https://portableapps.com/redirect/?a=PDFTKBuilderPortable&s=s&d=pa&f=PDFTKBuilderPortable_3.10.0_English.paf.exe" %TEMP%\PDFTKBuilderPortable_3.10.0_English.paf.exe
call :7unzip %TEMP%\PDFTKBuilderPortable_3.10.0_English.paf.exe .\ nopassword pdftkbuilder\

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: OPTIONAL ZONE ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Nirsoft tools are not included by default but you can uncomment this section if you like.
:: Note that some tools such as password viewers will trigger exaggerated/mental AVs/services that easily shoot false positives.
REM call :wget_nirsoft http://nirsoft.net/packages/passrecenc.zip %TEMP%\passrecenc.zip
:: warning: tons of false AV alarms for each exe in passreccommandline.zip
REM call :7unzip %TEMP%\passrecenc.zip .\ nirsoft123!
REM call :wget_nirsoft http://www.nirsoft.net/protected_downloads/passreccommandline.zip %TEMP%\passreccommandline.zip download nirsoft123!
REM call :7unzip %TEMP%\passreccommandline.zip .\ nirsoft123!
REM call :wget_nirsoft http://nirsoft.net/packages/systools.zip %TEMP%\systools.zip
REM call :7unzip %TEMP%\systools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/brtools.zip %TEMP%\brtools.zip
REM call :7unzip %TEMP%\brtools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/progtools.zip %TEMP%\progtools.zip
REM call :7unzip %TEMP%\progtools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/networktools.zip %TEMP%\networktools.zip
REM call :7unzip %TEMP%\networktools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/x64tools.zip %TEMP%\x64tools.zip
REM call :7unzip %TEMP%\x64tools.zip .\ nirsoft123!
call :wget_nirsoft https://nirsoft.net/utils/nircmd%arch%.zip %TEMP%\nircmd%arch%.zip
call :7unzip %TEMP%\nircmd%arch%.zip .\

:: Windows Server 2003 Resource Kit Tools used to be a must have but I don't remember a time when I used any of their tools
REM call :power_download https://download.microsoft.com/download/8/e/c/8ec3a7d8-05b4-440a-a71e-ca3ee25fe057/rktools.exe %TEMP%\rktools.exe
REM call :7unzip %TEMP%\rktools.exe %TEMP%\
REM call :7unzip %TEMP%\rktools.msi .\

:: TODO: activestate perl v5.8.4 built for MSWin32-x86-multi-thread - I use just 2 files to get it work (without modules or cpan etc indeed) - total = 824KB
:: TODO: it seems to be possible with strawberry perl 5.30 but the zipfile is 144MB, and the files needed total 5MB, down to 1.7MB with upx *.dll
:: http://strawberryperl.com/download/5.30.0.1/strawberry-perl-5.30.0.1-%bits%bit.zip
:: perl.exe
:: libgcc_s_dw2-1.dll
:: perl530.dll
:: libwinpthread-1.dll
:: libstdc++-6.dll

:: Jad - the fast Java Decompiler - http://kpdus.com/jad.html - example: jad -p example1.class >myexm1.java
:: TODO: download link file is corrupt
:: call :power_download http://kpdus.com/jad/winnt/jadnt158.zip %TEMP%\jadnt158.zip
:: call :power_unzip %TEMP%\jadnt158.zip jad.exe

:: Blat - A Windows (32 & 64 bit) command line SMTP mailer. Use it to automatically eMail logs, the contents of a html FORM, or whatever else you need to send. 
:: TODO: handle the special case url for blat32
REM "https://downloads.sourceforge.net/project/blat/Blat Full Version/32 bit versions/Win2000 and newer/blat3219_32.full.zip"
REM call :power_download "https://downloads.sourceforge.net/project/blat/Blat Full Version/64 bit versions/blat3219_64.full.zip" %TEMP%\blat3219_64.full.zip
REM call :power_unzip %TEMP%\blat3219_64.full.zip blat.exe keep
REM call :power_unzip %TEMP%\blat3219_64.full.zip blat.dll

:: mailsend-go is a multi-platform command line tool to send mail via SMTP protocol - StartTLS will be used if server supports it
:: https://github.com/muquit/mailsend-go
:: example: mailsend-go -info -smtp smtp.gmail.com -port 587
REM call :power_download https://github.com/muquit/mailsend-go/releases/download/v1.0.4/mailsend-go_1.0.4_windows-%bits%bit.zip %TEMP%\mailsend-go_1.0.4_windows-%bits%bit.zip
REM call :power_unzip %TEMP%\mailsend-go_1.0.4_windows-%bits%bit.zip mailsend-go.exe

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: compress all DLL
echo.
IF EXIST .\upx.exe upx *.dll

:: create Ux missing binaries from busybox
echo.
call :install_busybox_symlink

:: update HKLM or HKCU
echo.
IF %ADMIN% EQU 0 (call :update_HKLM_path) ELSE (call :update_HKCU_path)

:: echo systempropertiesadvanced.exe
goto :end


:set_colors
set colorCompatibleVersions=-8-8.1-10-2016-2019-
IF DEFINED WindowsVersion IF "!colorCompatibleVersions:-%WindowsVersion%-=_!"=="%colorCompatibleVersions%" goto :EOF

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
REM IF %ERRORLEVEL% NEQ 0 call :error powershell NOT FOUND & goto :end
for %%x in (powershell.exe) do (set powershell=%%~$PATH:x)
IF NOT DEFINED powershell call :error powershell NOT FOUND & goto :end

for %%x in (setx.exe) do (set setx=%%~$PATH:x)
IF NOT DEFINED setx call :error setx NOT FOUND & goto :end

for %%x in (msvcr110.dll) do (set msvcr110=%%~$PATH:x)
IF NOT DEFINED msvcr110 echo WARNING: MSVC 2012 redistributable is not installed
IF NOT DEFINED msvcr110 call :set_msvc_url

for %%x in (wget.exe) do (set wget=%%~$PATH:x)
goto :EOF

:set_msvc_url
:: http://www.dlldownloader.com/msvcr110-dll/#Method-2-Copying-the-Msvcr110dll-File-to-the-Software-File-Folder
IF %bits% EQU 32 (
set msvc_url=http://www.dlldownloader.com/msvcr110-dll/download/e225e0eb1de90f5aa3efb1fb9b3e5e51/
) ELSE (
set msvc_url=http://www.dlldownloader.com/msvcr110-dll/download/e481de48e6b9658e8c761b2447591a1f/
)
goto :EOF

:detect_admin_mode [num]
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file

IF DEFINED DEBUG echo %HIGH%%b%%~0%END%%c% %* %END%
set bits=32
set bitx=x86
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set arch=-x64
  set bits=64
  set bitx=x64
)
set req=%1
%SystemRoot%\system32\whoami /groups | findstr "12288" >NUL && set "ADMIN=0" || set "ADMIN=1"

IF %ADMIN% EQU 0 (
  echo Batch started with %HIGH%%y%ADMIN%END% rights
) ELSE (
  echo Batch started with %y%USER%END% rights
)

IF DEFINED req (
  IF NOT [%ADMIN%]==[%req%] (
    echo %r%Batch NOT started with the right privileges, EXIT%END% 1>&2
    pause
    exit
  )
)

set osType=workstation
wmic os get Caption /value | findstr Server >%LOGS%\wmic.tmp.txt
IF %ERRORLEVEL% EQU 0 set osType=server

:: https://www.lifewire.com/windows-version-numbers-2625171
:: Microsoft Windows [Version 10.0.17763.615]
IF [%osType%]==[workstation] (
  REM for /F "tokens=4 delims=. " %%v in ('ver') DO set WindowsVersion=%%v
  ver | findstr /C:"Version 10.0" && set WindowsVersion=10& goto :EOF
  ver | findstr /C:"Version 6.3" && set WindowsVersion=8.1& goto :EOF
  ver | findstr /C:"Version 6.2" && set WindowsVersion=8& goto :EOF
  ver | findstr /C:"Version 6.1" && set WindowsVersion=7& goto :EOF
  ver | findstr /C:"Version 6.0" && set WindowsVersion=Vista& goto :EOF
  ver | findstr /C:"Version 5.1" && set WindowsVersion=XP& goto :EOF
) ELSE (
  for /f "tokens=4" %%a in (%LOGS%\wmic.tmp.txt) do set WindowsVersion=%%a
)
goto :EOF

:install_busybox_symlink
:: you need ADMIN privileges to create links... depends on DOMAIN settings maybe?
findstr /C:"%~0 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 OK && goto :EOF
echo %c%%~0%END%
call :counterInc

set choice=n
:: no mklink for XP so busybox will unfortunately create hardlinks for a total of 88MB
IF [%WindowsVersion%]==[XP] (
  busybox --install %INSTALLDIR%
) ELSE (
  IF %ADMIN% EQU 0 (
    :: mklink won't overwrite existing files
    FOR /f "usebackq" %%a IN (`busybox.exe --list`) DO 2>NUL (
      mklink %%a.exe busybox.exe 2>NUL
    )
  ) ELSE (
    echo Sorry: you need ADMIN privileges to create links.
    echo Do you want to create hard links instead? Cost = 80MB
    set /p choice=your choice: [N/y] 
  )
)

IF [%choice%]==[y] busybox --install %INSTALLDIR%
echo.

echo %~0 OK>>%LOGFILE%
call :successInc
goto :EOF

:install_7zip 7z0000.exe
findstr /C:"%~0 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 OK && goto :EOF
echo %c%%~0 %1%END%
call :counterInc

IF NOT EXIST %1 goto :EOF

echo start /wait %1 /S
start /wait %1 /S
del /q %1 2>NUL
echo Installing 7zip - %HIGH%%g%DONE%END%

echo %~0 OK>>%LOGFILE%
goto :EOF

:setup_7zip_Extn
findstr /C:"%~0 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 OK && goto :EOF
echo %c%%~0 %1%END%
call :counterInc

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
  FOR /f "tokens=1,2 delims=-" %%a in ("%%x") DO (
    REG ADD %SC%\.%%a /VE /D "7-Zip.%%a" /F >NUL
    REG ADD %SC%\7-Zip.%%a /VE /D "%%a Archive" /F >NUL
    REG ADD %SC%\7-Zip.%%a\DefaultIcon /VE /D "%PROGRAMS%\7-Zip\7z.dll,%%b" /F >NUL
    REG ADD %SC%\7-Zip.%%a\shell\open\command /VE /D "\"%PROGRAMS%\7-Zip\7zFM.exe\" \"%%1\"" /F >NUL
    <nul set /p =%%a 
  )
)
echo.%END%
echo Setup 7zip file extensions: %HIGH%%g%DONE%END%

echo %~0 OK>>%LOGFILE%
call :successInc
goto :EOF

:copy_7z
findstr /C:"%~0 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 OK && goto :EOF
echo %c%%~0%END%
call :counterInc

copy /y "%PROGRAMS%\7-Zip\7z.exe" .\
copy /y "%PROGRAMS%\7-Zip\7z.dll" .\

echo %~0 OK>>%LOGFILE%
call :successInc
goto :EOF

:wget_nirsoft url output [user pass]
findstr /C:"%~0 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 OK && goto :EOF
echo %c%%~0 %1%END%
call :counterInc

IF DEFINED VERBOSE echo wget --referer=http://nirsoft.net %1 -O %2 --user=%3 --password=%4
wget --referer=http://nirsoft.net %1 -O %2 --user=%3 --password=%4 2>&1 | findstr/C:saved

echo %~0 OK>>%LOGFILE%
call :successInc
goto :EOF

:power_download url outputFile [user pass]
findstr /C:"%~0 %~n2 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 %~n2 OK && goto :EOF
echo %c%%~0%END% %y%%1 %HIGH%%2%END% %3 %4
set "url=%~1"
set "outputFile=%~2"
set user=%3
set password=%4

call :counterInc

IF NOT DEFINED outputFile echo USAGE: %~nx0 url output [user pass]& exit /b
echo.%HIGH%%k%
IF EXIST %outputFile% del /q %outputFile% 2>NUL
REM IF DEFINED wget (
  REM echo wget --no-check-certificate %url% -O %outputFile% --user=%user% --password=%password% 2>&1 | findstr /C:saved
  REM wget --no-check-certificate %url% -O %outputFile% --user=%user% --password=%password% 2>&1 | findstr /C:saved
REM ) ELSE (
  IF DEFINED DEBUG echo powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile('%url%','%outputFile%')}"
  echo powershell "%url%"
  powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile('%url%','%outputFile%')}"
REM )
echo.%END%

echo %~0 %~n2 OK>>%LOGFILE%
call :successInc
goto :EOF

:power_unzip archive filter [keep]
:: power_unzip does overwrite extracted files
findstr /L /C:"%~0 %~n1 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 %~n1 OK && goto :EOF
findstr /L /C:"%~0 %~n1 %2 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 %~n1 %2 OK && goto :EOF
echo %HIGH%%c%%~0%END%%c% %1 %2
IF NOT EXIST %1 goto :EOF
set archive=%1
set filter=%2
set keep=%3

call :counterInc

IF NOT DEFINED filter echo USAGE: %~0 archive filter [keep]& exit /b
IF NOT EXIST %archive% echo USAGE: %~0 archive filter [keep]& exit /b
powershell -executionPolicy bypass -Command "&{Add-Type -AssemblyName System.IO.Compression.FileSystem ; $Filter = '%filter%' ; $zip = [System.IO.Compression.ZipFile]::OpenRead('%archive%') ; $zip.Entries | Where-Object { $_.Name -like $Filter } | ForEach-Object { $FileName = $_.Name ; [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$FileName", $true)} }"
IF %ERRORLEVEL% NEQ 0 (
  set keep=keep
) ELSE (
  echo %~0 %~n1 %2 OK>>%LOGFILE%
)

IF NOT [%keep%]==[keep] (
  del /q %archive% 2>NUL
  echo %~0 %~n1 OK>>%LOGFILE%
)
call :successInc
goto :EOF

:7unzip archive targetDir [password] [filter] [keep]
:: 7unzip does overwrite extracted files
findstr /C:"%~0 %~n1 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 %~n1 OK && goto :EOF
echo %c%%~0 %1%END% %2 %3
set archive=%1
set targetDir=%2
set password=%3
set filter=%4
set keep=%5
IF DEFINED password set password=-p%~3
IF /I [%password%]==[nopassword] set password=
IF DEFINED filter set filter=%4 -r

call :counterInc

echo %g%
IF DEFINED VERBOSE echo 7z.exe e -y -o%targetDir% %password% %archive% %filter%
7z.exe e -y -o%targetDir% %password% %archive% %filter% | findstr /C:Extracting
echo %END%

IF /I NOT [%keep%]==[keep] (
  del /q %archive% 2>NUL
  echo %~0 %~n1 OK>>%LOGFILE%
)
call :successInc
goto :EOF

:update_HKLM_path
echo %c%%~0%END%
set RKIT_PATH=%CD%

reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH | findstr /C:"%RKIT_PATH%" >NUL 2>&1
IF %ERRORLEVEL% EQU 0 (
  echo %g%No need to update PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
  goto :EOF
)

echo.
echo UPDATE %HIGH%%y%HKLM%END%_PATH with %RKIT_PATH%...

:: prepend
REM for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do if [%%b]==[] ( setx /m PATH "%RKIT_PATH%;%%~a" ) else ( setx /m PATH "%RKIT_PATH%;%%~a %%~b" )

::append
for /f "skip=2 tokens=3*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH') do if [%%b]==[] ( setx /m PATH "%%~a;%RKIT_PATH%" ) else ( setx /m PATH "%%~a %%~b;%RKIT_PATH%" )

echo UPDATE %HIGH%%y%HKLM%END%_PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
goto :EOF

:update_HKCU_path
echo %c%%~0%END%
set RKIT_PATH=%CD%

reg query HKCU\Environment /v PATH | findstr /C:"%RKIT_PATH%" >NUL 2>&1
IF %ERRORLEVEL% EQU 0 (
  echo %g%No need to update PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
  goto :EOF
)

echo.
echo UPDATE %y%HKCU%END%_PATH with %RKIT_PATH%...

:: prepend
for /f "skip=2 tokens=3*" %%a in ('reg query HKCU\Environment /v PATH') do if [%%b]==[] ( setx PATH "%RKIT_PATH%;%%~a" ) else ( setx PATH "%RKIT_PATH%;%%~a %%~b" )

::append
REM for /f "skip=2 tokens=3*" %%a in ('reg query HKCU\Environment /v PATH') do if [%%b]==[] ( setx PATH "%%~a;%RKIT_PATH%" ) else ( setx PATH "%%~a %%~b;%RKIT_PATH%" )

echo UPDATE %y%HKCU%END%_PATH with %RKIT_PATH%... %HIGH%%g%OK%END%
goto :EOF

:startup
setlocal enabledelayedexpansion
IF EXIST %LOGFILE% (
  :: get version installed if any:
  set /p installedDateVersion= <%LOGFILE%
  for /f "tokens=1" %%a in ("!installedDateVersion!") do set installedVersion=%%a
  findstr /C:"ALL GOOD, PARDNER" %LOGFILE% 2>NUL
  IF !ERRORLEVEL! EQU 0 set fullyInstalled=true
) ELSE (
  :: we don't know which version was installed:
  IF EXIST wc.exe set installedVersion=unknown
)
setlocal disabledelayedexpansion

:: debug
REM echo installedDateVersion=%installedDateVersion%
REM echo installedVersion=%installedVersion%
REM echo fullyInstalled=%fullyInstalled%
set choice=n
IF DEFINED fullyInstalled (
  :: if fullyInstalled previous version==current, prompt for re-install
  IF [%installedVersion%]==[%version%] (
    echo.
    echo %HIGH%%y%Please NOTE:%END% RKIT %installedDateVersion% with success. DO you want to %HIGH%re-install%END% version %version% anyway?
    echo %HIGH%%k%re-install will %w%purge everything%k% + re-download everything under %INSTALLDIR%%END%
    echo.
    set /p choice=choice? [N/y] 
  ) ELSE (
  :: if fullyInstalled previous version!=current, just indicate it's an update
    echo.
    echo %HIGH%%g%Please NOTE:%END% RKIT %installedDateVersion% with success. New version %version% will %HIGH%update%END% your folder.
    echo %HIGH%%k%update will just re-download + overwrite everything under %INSTALLDIR%%END% in 5 seconds...
    echo.
    ping -n 6 localhost >NUL 2>&1
  )
)

:: if potentially installed and log absent for some reason, just indicate it's an update
IF [%installedVersion%]==[unknown] (
  echo.
  echo %HIGH%%y%Please NOTE:%END% RKIT *seems* to be installed already. New version %version% will %HIGH%update%END% your folder.
  echo %HIGH%%k%update will just re-download + overwrite everything under %INSTALLDIR%%END% in 5 seconds...
  echo.
  ping -n 6 localhost >NUL 2>&1
)

:: purge everything + log: will run only if user is prompted to re-install and they accept
:: in the future, new versions may also do it silentely but i'm not a fan since users may add their own stuff in that folder
:: that would mean I would have to delete files selectively or make sure downloads actually overwrite old ones
:: the actual issue stands with mklink and busybox. 
IF /I [%choice%]==[y] (
  del *.log *.cab *.upx *.exe *.dll *.cfg *.scr *.msi *.vbs *.ocx *.ini *.inf *.sys *.chm *.hlp *.txt *.adm *.doc *.htm *.lmk *.msc *.cnt *.reg *.xsl *.bat *.config *.7z *.zip
) ELSE (
  IF DEFINED fullyInstalled exit
)
IF NOT EXIST %LOGFILE% echo %version% has been installed on %DATE% >%LOGFILE%
goto :EOF

:allgood
echo.%g%
echo            _ _    _____                 _     _____              _                 
echo      /\   ^| ^| ^|  / ____^|               ^| ^|   ^|  __ \            ^| ^|                
echo     /  \  ^| ^| ^| ^| ^|  __  ___   ___   __^| ^|   ^| ^|__) ^|_ _ _ __ __^| ^|_ __   ___ _ __ 
echo    / /\ \ ^| ^| ^| ^| ^| ^|_ ^|/ _ \ / _ \ / _` ^|   ^|  ___/ _` ^| '__/ _` ^| '_ \ / _ \ '__^|
echo   / ____ \^| ^| ^| ^| ^|__^| ^| (_) ^| (_) ^| (_^| ^|_  ^| ^|  ^| (_^| ^| ^| ^| (_^| ^| ^| ^| ^|  __/ ^|   
echo  /_/    \_\_^|_^|  \_____^|\___/ \___/ \__,_^( ^) ^|_^|   \__,_^|_^|  \__,_^|_^| ^|_^|\___^|_^|   
echo                                          ^|/                                        
echo.%END%
goto :EOF

:counterInc
set /A COUNTER=COUNTER+1
goto :EOF

:successInc
set /A SUCCESS=SUCCESS+1
REM pause
goto :EOF

:error
echo.%r%
echo ==============================================================
echo ERROR: %HIGH%%*%END%%r%
IF [%1]==[setx] echo %y%Consider installing Windows XP SP3 or Server 2003 SP2 %r%
IF [%1]==[powershell] echo %y%Consider install Management Framework at https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu [or download wget.exe manually] %r%
IF [%1]==[mkdir] echo %y%Consider installing in a folder you have Modifications permission %r%
echo ==============================================================
echo.%END%
pause
exit /b 1
goto :EOF

:end
set /A CR=%COUNTER%-%SUCCESS%
IF %CR% GTR 0 (
  call :allgood
  echo ALL GOOD, PARDNER | tee -a %LOGFILE%
  echo exit in 10 seconds...
  ping -n 11 localhost >NUL 2>&1
) ELSE (
  echo.%r%
  echo WARNING: something went wrong, please check and correct the script or just accept the fatality.%END%
  pause
)
del /q %TMPFILE%*
popd
exit /b %CR%
