@echo OFF
pushd "%~dp0"
setlocal
REM setlocal enabledelayedexpansion

::   install-rkit-portable  Copyright (C) <2019>  <audioscavenger@it-cooking.com>
::   This program comes with ABSOLUTELY NO WARRANTY;
::   This is free software, and you are welcome to redistribute it
::   under certain conditions; https://www.gnu.org/licenses/gpl-3.0.html
:: ----------------------------------------------------------------------------------------------------------------------
:top
@set version=1.6.0
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
:: - [x] 7zip _latest_
:: - [x] apache benchmark _latest_ + openSSL _latest_
:: - [ ] blat mail _latest_
:: - [x] busybox _latest_
:: - [x] cmdow _latest_
:: - [x] curl _latest_
:: - [x] BIND9 + dig _latest_
:: - [x] msvcr110.dll  _as-needed_
:: - [x] dirhash _latest_
:: - [x] file _latest_
:: - [x] gawk _latest_
:: - [x] gitty _latest_
:: - [x] jq _latest_
:: - [ ] mailsend-go _latest_
:: - [x] netcat _latest_
:: - [x] NirSoft _latest_
:: - [x] NirCmd _latest_
:: - [x] Pdftk free _latest_
:: - [x] sqlite _latest_
:: - [x] SysinternalsSuite _latest_
:: - [x] tcpdump _latest_
:: - [x] trrntzip _latest_
:: - [x] UnxUtils _latest_
:: - [x] upx _latest_
:: - [x] wget _latest_
:: - [ ] Windows Server 2003 Resource Kit Tools
:: - [x] XMLStarlet _latest_
:: - [x] XpdfReader _latest_
:: + install 7zip 21.03
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
set VERBOSE=v
set RESTART=n
verify on
set COUNTER=0
set SUCCESS=0
set fullyInstalled=
title %0 %version% started %DATE% at %TIME%
REM MODE CON: COLS=150 LINES=50

IF DEFINED ProgramW6432 (set "PROGRAMS=%ProgramW6432%") ELSE set "PROGRAMS=%ProgramFiles%"

IF NOT DEFINED INSTALLDIR set INSTALLDIR="%~dp0"
IF NOT EXIST %INSTALLDIR% md %INSTALLDIR%
IF NOT EXIST %INSTALLDIR% call :error mkdir - cannot create %INSTALLDIR% & goto :end
pushd %INSTALLDIR%

call :detect_admin_mode
call :set_colors
call :pre_requisites
call :startup


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: MAIN :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main
REM call :UnxUtils
REM call :wget
REM call :curl
REM call :sevenZip
REM call :busybox
REM call :jq
REM call :cmdow
REM call :BIND9
REM call :xmllint
REM call :sqlite
REM call :SysinternalsSuite
REM call :UPX
REM call :tcpdump
REM call :trrntzip
REM call :DirHash
REM call :apache
REM call :file
REM call :Netcat
REM call :pdftk
REM call :gitty
call :tea
call :Xpdf
call :Nirsoft

call :post_install
goto :end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:UnxUtils
echo %c%%~0 %END%
:: UnxUtils are supposedly deprecated since the win32 port of busybox, however:
:: - busybox tail cannot process UNC paths
:: - you are using UNC path, cannot use mklink
call :power_download https://downloads.sourceforge.net/project/unxutils/unxutils/current/UnxUtils.zip %TMP%\UnxUtils.zip
call :power_unzip %TMP%\UnxUtils.zip *.exe
:: just noticed how slow is UnxUtils xargs compared to busybox's
del /f /q xargs.exe 2>NUL
:: recently noticed UnxUtils tee doesnt handle colors
del /f /q tee.exe 2>NUL
goto :EOF

:wget
echo %c%%~0 %END%
:: https://eternallybored.org/misc/wget/
:: wget is included in busybox but it's a very limited version
call :power_download https://eternallybored.org/misc/wget/1.21.3/%bits%/wget.exe .\wget.exe
goto :EOF

:curl
echo %c%%~0 %END%
:: https://curl.se/windows/
call :power_download https://curl.se/windows/dl-7.82.0_2/curl-7.82.0_2-win%bits%-mingw.zip %TMP%\curl-mingw.zip
call :power_unzip %TMP%\curl-mingw.zip curl-ca-bundle.crt keep
call :power_unzip %TMP%\curl-mingw.zip curl.exe keep
call :power_unzip %TMP%\curl-mingw.zip libcurl-x%bits%.dll
goto :EOF

:sevenZip
echo %c%%~0 %END%
:: https://sourceforge.net/projects/sevenzip/files/7-Zip/
:: 7zip first, in any case we need 7z.exe
set ver7zMaj=21
set ver7zMin=07
call :power_download https://downloads.sourceforge.net/project/sevenzip/7-Zip/%ver7zMaj%.%ver7zMin%/7z%ver7zMaj%%ver7zMin%%arch%.exe %TMP%\7z%ver7zMaj%%ver7zMin%%arch%.exe
call :install_7zip %TMP%\7z%ver7zMaj%%ver7zMin%%arch%.exe
call :setup_7zip_Extn
call :copy_7z
goto :EOF

:busybox
echo %c%%~0 %END%
call :power_download https://frippery.org/files/busybox/busybox%archbits%.exe .\busybox.exe
goto :EOF

:jq
echo %c%%~0 %END%
:: https://github.com/stedolan/jq/releases/
:: jq is a json parser
call :power_download https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win%bits%.exe .\jq.exe
goto :EOF

:cmdow
echo %c%%~0 %END%
:: cmdwow reposition/resize windows, may trigger dumb A/V
call :power_download https://github.com/ritchielawrence/cmdow/zipball/master %TMP%\cmdow.zip
call :power_unzip %TMP%\cmdow.zip cmdow.exe
goto :EOF

:gawk
echo %c%%~0 %END%
:: awk is included in busybox but it's a very limited version and not GNU
call :power_download https://downloads.sourceforge.net/project/gnuwin32/gawk/3.1.6-1/gawk-3.1.6-1-bin.zip %TMP%\gawk-3.1.6-1-bin.zip
call :power_unzip %TMP%\gawk-3.1.6-1-bin.zip gawk.exe
goto :EOF

:XMLStarlet
echo %c%%~0 %END%
:: XMLStarlet Command Line XML Toolkit
call :power_download https://sourceforge.net/projects/xmlstar/files/latest/download %TMP%\xmlstarlet-win32.zip
call :power_unzip %TMP%\xmlstarlet-win32.zip xml.exe
goto :EOF

:BIND9
echo %c%%~0 %END%
:: https://downloads.isc.org/isc/bind9/
:: BIND9 also contains dig
call :power_download https://downloads.isc.org/isc/bind9/9.18.1/BIND9.18.1.%bitx%.zip %TMP%\BIND9.zip
call :power_unzip %TMP%\BIND9.zip dig.exe keep
call :power_unzip %TMP%\BIND9.zip *.dll
:: BIND9 libxml2.dll is in conflict with the one from xmllint, but xmllint's works with both
:: BIND9 needs MSVC++ 2012 redistribuable
IF NOT DEFINED msvcr110 (
  call :power_download %msvc_url% %TMP%\msvcr110.zip
  call :power_unzip %TMP%\msvcr110.zip msvcr110.dll
)
goto :EOF

:xmllint
echo %c%%~0 %END%
:: https://sourceforge.net/projects/gnuwin32/files/libxml/
:: xmllint - needed to get latest curl version; couldn't extract Xpath with xmlstarlet coz curl html page is broken (too loose)
call :power_download https://sourceforge.net/projects/gnuwin32/files/libxml/2.4.12-1/libxml2-2.4.12-bin.zip/download %TMP%\libxml2-win32.zip
call :power_unzip %TMP%\libxml2-win32.zip libxml2.dll keep
call :power_unzip %TMP%\libxml2-win32.zip *.exe
goto :EOF

:sqlite
echo %c%%~0 %END%
:: https://sqlite.org/index.html
call :power_download https://sqlite.org/2022/sqlite-dll-win64-x64-3380200.zip %TMP%\sqlite-tools-win32-x86.zip
call :power_unzip %TMP%\sqlite-tools-win32-x86.zip *.exe
goto :EOF

:SysinternalsSuite
echo %c%%~0 %END%
:: SysinternalsSuite includes PsTools which will trigger exaggerated/mental AVs/services that easily shoot false positives.
call :power_download https://download.sysinternals.com/files/SysinternalsSuite.zip %TMP%\SysinternalsSuite.zip
call :7unzip %TMP%\SysinternalsSuite.zip .\
goto :EOF

:UPX
echo %c%%~0 %END%
:: https://github.com/upx/upx/releases
:: UPX is a free, portable, extendable, high-performance executable packer for several executable formats.
call :power_download https://github.com/upx/upx/releases/download/v3.96/upx-3.96-win%bits%.zip %TMP%\upx-win.zip
call :power_unzip %TMP%\upx-win.zip upx.exe
goto :EOF

:tcpdump
echo %c%%~0 %END%
:: http://chiselapp.com/user/rkeene/repository/tcpdump-windows-wrapper/index
:: tcpdump for windows
call :power_download "http://chiselapp.com/user/rkeene/repository/tcpdump-windows-wrapper/raw/tcpdump.exe?name=2e3d4d01fa597e1f50ba3ead8f18b8eeacb83812" .\tcpdump.exe
goto :EOF

:trrntzip
echo %c%%~0 %END%
:: trrntzip for windows: standardize CRC for romset zipfiles for MAME
call :power_download "https://cfhcable.dl.sourceforge.net/project/trrntzip/trrntzip/TorrentZip v0.2/trrntzip_v02_win.zip" .\trrntzip.exe
goto :EOF

:DirHash
echo %c%%~0 %END%
:: Directory checksum tool
call :power_download https://www.idrix.fr/Root/Samples/DirHash%arch%.zip %TMP%\DirHash%arch%.zip
call :power_unzip %TMP%\DirHash%arch%.zip dirhash.exe
goto :EOF

:apache
echo %c%%~0 %END%
:: https://www.apachelounge.com/download/
:: apache benchmark tool is very basic, and while it will give you a solid idea of some performance, it is a bad idea to only depend on it if you plan to have your site exposed to serious stress in production.
call :power_download https://www.apachelounge.com/download/VS16/binaries/httpd-2.4.53-win%bits%-VS16.zip %TMP%\httpd-win.zip
call :power_unzip %TMP%\httpd-win.zip ab.exe keep
call :power_unzip %TMP%\httpd-win.zip abs.exe keep
call :power_unzip %TMP%\httpd-win.zip libcrypto-1_1%arch%.dll keep
call :power_unzip %TMP%\httpd-win.zip libssl-1_1%arch%.dll keep
call :power_unzip %TMP%\httpd-win.zip openssl.exe
goto :EOF

:file
echo %c%%~0 %END%
:: https://sourceforge.net/projects/gnuwin32/files/file/
:: File for Windows
call :power_download https://sourceforge.net/projects/gnuwin32/files/file/5.03/file-5.03-bin.zip/download %TMP%\file-5.03-bin.zip
call :power_unzip %TMP%\file-5.03-bin.zip file.exe keep
call :power_unzip %TMP%\file-5.03-bin.zip magic1.dll keep
call :power_unzip %TMP%\file-5.03-bin.zip magic keep
call :power_unzip %TMP%\file-5.03-bin.zip magic.mgc
move /y file.exe filemagic.exe
call :power_download https://sourceforge.net/projects/gnuwin32/files/file/5.03/file-5.03-dep.zip/download %TMP%\file-5.03-dep.zip
call :power_unzip %TMP%\file-5.03-dep.zip regex2.dll keep
call :power_unzip %TMP%\file-5.03-dep.zip zlib1.dll
goto :EOF

:Netcat
echo %c%%~0 %END%
:: Netcat for NT is the tcp/ip "Swiss Army knife" that never made it into any of the resource kits
:: it's powerful enough to be included in some natsy malware packages so it may trigger your AV
:: https://github.com/diegocr/netcat
:: example use: nc -l -p 23 -t -e cmd.exe
call :power_download https://joncraton.org/files/nc111nt.zip %TMP%\nc111nt.zip
call :7unzip %TMP%\nc111nt.zip .\ nc nc.exe
goto :EOF

:pdftk
echo %c%%~0 %END%
:: unfortunately their installer cannot be unzipped, we will use the portable release instead
:: https://portableapps.com/apps/office/pdftk_builder_portable
call :power_download "https://download3.portableapps.com/portableapps/PDFTKBuilderPortable/PDFTKBuilderPortable_4.1.6_English.paf.exe?20190321" %TMP%\PDFTKBuilderPortable_English.paf.exe
call :7unzip %TMP%\PDFTKBuilderPortable_English.paf.exe .\ nopassword pdftkbuilder\
goto :EOF

:gitty
echo %c%%~0 %END%
:: https://github.com/muesli/gitty/releases/
:: gitty requires you to provide valid access tokens in an environment variable called GITTY_TOKENS=github.com=abc123;gitlab.com=xyz890;myhost.tld=...
call :power_download "https://github.com/muesli/gitty/releases/latest/download/gitty_0.7.0_Windows_x86_64.zip" %TMP%\gitty_Windows.zip
call :7unzip %TMP%\gitty_Windows.zip .\ nopassword gitty.exe
goto :EOF

:tea
echo %c%%~0 %END%
:: https://gitea.com/gitea/tea/releases
:: then run: tea login add; tea is a tool for gitea project
IF %bits% EQU 32 (
  call :power_download https://gitea.com/attachments/8fa5daac-e0b4-4d49-8304-8b7b0d8705be %TMP%\tea.exe.xz
) ELSE (
  call :power_download https://gitea.com/attachments/2d24cb59-a569-47c3-b941-1683649ece4f %TMP%\tea.exe.xz
)
call :7unzip %TMP%\tea.exe.xz .\ nopassword tea.exe
goto :EOF

:Xpdf
echo %c%%~0 %END%
:: http://www.xpdfreader.com/download.html
:: Xpdf open source project includes a PDF viewer along with a collection of command line tools which perform various functions on PDF files
call :power_download "https://dl.xpdfreader.com/xpdf-tools-win-4.03.zip" %TMP%\xpdf-tools-win.zip
call :7unzip %TMP%\xpdf-tools-win.zip .\ nopassword bin%bits%\
goto :EOF

:Nirsoft
echo %c%%~0 %END%
:: https://www.nirsoft.net/utils/
:: Nirsoft tools are not included by default but you can uncomment this section if you like.
:: Note that some tools such as password viewers will trigger exaggerated/mental AVs/services that easily shoot false positives.
REM call :wget_nirsoft http://nirsoft.net/packages/passrecenc.zip %TMP%\passrecenc.zip
:: warning: tons of false AV alarms for each exe in passreccommandline.zip
REM call :7unzip %TMP%\passrecenc.zip .\ nirsoft123!
REM call :wget_nirsoft http://www.nirsoft.net/protected_downloads/passreccommandline.zip %TMP%\passreccommandline.zip download nirsoft123!
REM call :7unzip %TMP%\passreccommandline.zip .\ nirsoft123!
REM call :wget_nirsoft http://nirsoft.net/packages/systools.zip %TMP%\systools.zip
REM call :7unzip %TMP%\systools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/brtools.zip %TMP%\brtools.zip
REM call :7unzip %TMP%\brtools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/progtools.zip %TMP%\progtools.zip
REM call :7unzip %TMP%\progtools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/networktools.zip %TMP%\networktools.zip
REM call :7unzip %TMP%\networktools.zip .\
REM call :wget_nirsoft http://nirsoft.net/packages/x64tools.zip %TMP%\x64tools.zip
REM call :7unzip %TMP%\x64tools.zip .\ nirsoft123!
call :wget_nirsoft https://nirsoft.net/utils/nircmd%arch%.zip %TMP%\nircmd%arch%.zip
call :7unzip %TMP%\nircmd%arch%.zip .\
goto :EOF

:rktools
echo %c%%~0 %END%
:: Windows Server 2003 Resource Kit Tools used to be a must have but I don't remember a time when I used any of their tools
REM call :power_download https://download.microsoft.com/download/8/e/c/8ec3a7d8-05b4-440a-a71e-ca3ee25fe057/rktools.exe %TMP%\rktools.exe
REM call :7unzip %TMP%\rktools.exe %TMP%\
REM call :7unzip %TMP%\rktools.msi .\
goto :EOF

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
:: call :power_download http://kpdus.com/jad/winnt/jadnt158.zip %TMP%\jadnt158.zip
:: call :power_unzip %TMP%\jadnt158.zip jad.exe

:: Blat - A Windows (32 & 64 bit) command line SMTP mailer. Use it to automatically eMail logs, the contents of a html FORM, or whatever else you need to send. 
:: TODO: handle the special case url for blat32
REM "https://downloads.sourceforge.net/project/blat/Blat Full Version/32 bit versions/Win2000 and newer/blat3219_32.full.zip"
REM call :power_download "https://downloads.sourceforge.net/project/blat/Blat Full Version/64 bit versions/blat3219_64.full.zip" %TMP%\blat3219_64.full.zip
REM call :power_unzip %TMP%\blat3219_64.full.zip blat.exe keep
REM call :power_unzip %TMP%\blat3219_64.full.zip blat.dll

:: mailsend-go is a multi-platform command line tool to send mail via SMTP protocol - StartTLS will be used if server supports it
:: https://github.com/muquit/mailsend-go
:: example: mailsend-go -info -smtp smtp.gmail.com -port 587
REM call :power_download https://github.com/muquit/mailsend-go/releases/download/v1.0.4/mailsend-go_1.0.4_windows-%bits%bit.zip %TMP%\mailsend-go_1.0.4_windows-%bits%bit.zip
REM call :power_unzip %TMP%\mailsend-go_1.0.4_windows-%bits%bit.zip mailsend-go.exe

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:post_install
echo %c%%~0 %END%

:: compress all DLL
echo:
IF EXIST .\upx.exe upx *.dll

:: create Ux missing binaries from busybox as the last step
echo:
call :install_busybox_symlink
:: timeout, date, time, expand, echo are all Windows command
del /f /q timeout.exe date.exe time.exe expand.exe echo.exe 2>NUL

:: update HKLM or HKCU
echo:
IF %ADMIN% EQU 0 (call :update_HKLM_path) ELSE (call :update_HKCU_path)

:: echo systempropertiesadvanced.exe
goto :EOF


:set_colors
IF DEFINED END goto :EOF
set colorCompatibleVersions=-8-8.1-10-2016-2019-
call set colorIncompatible=%%colorCompatibleVersions:-%WindowsVersion%-=COMPATIBLE%%
IF "%colorCompatibleVersions%"=="%colorIncompatible%" exit /b 1
call win10colors-set.cmd >NUL 2>NUL && goto :EOF

set END=[0m
set HIGH=[1m
set Underline=[4m
set REVERSE=[7m

set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m

goto :EOF
:: BUG: some space are needed after :set_colors


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
IF DEFINED DEBUG echo DEBUG: %m%%~n0 %~0 %HIGH%%*%END% 1>&2
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file

set req=%1
set arch=
set archbits=
set bits=32
set bitx=x86
IF DEFINED PROCESSOR_ARCHITEW6432 echo WARNING: running 32bit cmd on 64bit system 1>&2
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set arch=-x64
  set archbits=64
  set bits=64
  set bitx=x64
)
%SystemRoot%\system32\whoami /groups | findstr "12288" >NUL && set "ADMIN=0" || set "ADMIN=1"
IF %ADMIN% EQU 0 (
  echo Batch started with %HIGH%%y%ADMIN%END% rights 1>&2
) ELSE (
  echo Batch started with %y%USER%END% rights 1>&2
)

IF DEFINED req (
  IF NOT "%ADMIN%" EQU "%req%" (
    IF "%ADMIN%" GTR "%req%" (
      echo %y%Batch started with USER privileges, when ADMIN was needed.%END% 1>&2
      IF DEFINED AUTOMATED exit
      REM :UACPrompt
      net localgroup administrators | findstr "%USERNAME%" >NUL || call :error %~0: User %USERNAME% is NOT localadmin
      echo Set UAC = CreateObject^("Shell.Application"^) >"%TMP%\getadmin.vbs"
      REM :: WARNING: cannot use escaped parameters with this one:
      IF DEFINED params (
      echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params:"=""%", "", "runas", 1 >>"%TMP%\getadmin.vbs"
      ) ELSE echo UAC.ShellExecute "cmd.exe", "/c %~s0", "", "runas", 1 >>"%TMP%\getadmin.vbs"
      CScript //B "%TMP%\getadmin.vbs"
      del /q "%TMP%\getadmin.vbs"
    ) ELSE (
      echo %r%Batch started with ADMIN privileges, when USER was needed. EXIT%END% 1>&2
      IF NOT DEFINED AUTOMATED pause 1>&2
    )
    exit
  )
)

set osType=workstation
wmic os get Caption /value | findstr Server >%TMP%\wmic.tmp.txt && set "osType=server" || ver >%TMP%\ver.tmp.txt

:: https://www.lifewire.com/windows-version-numbers-2625171
:: Microsoft Windows [Version 10.0.17763.615]
IF "%osType%"=="workstation" (
  findstr /C:"Version 10.0" %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=10"    && exit /b 0
  findstr /C:"Version 6.3"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=8.1"   && exit /b 0
  findstr /C:"Version 6.2"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=8"     && exit /b 0
  findstr /C:"Version 6.1"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=7"     && exit /b 0
  findstr /C:"Version 6.0"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=Vista" && exit /b 0
  findstr /C:"Version 5.1"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=XP"    && exit /b 0
) ELSE (
  for /f "tokens=4" %%a in (%TMP%\wmic.tmp.txt) do    set "WindowsVersion=%%a"   && exit /b 0
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
echo:

:: timeout, date, time, expand, echo are all Windows command
del /f /q timeout.exe date.exe time.exe expand.exe echo.exe 2>NUL

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
echo:%END%
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
echo: %HIGH%%k%
IF EXIST %outputFile% del /q %outputFile% 2>NUL
REM IF DEFINED wget (
  REM echo wget --no-check-certificate %url% -O %outputFile% --user=%user% --password=%password% 2>&1 | findstr /C:saved
  REM wget --no-check-certificate %url% -O %outputFile% --user=%user% --password=%password% 2>&1 | findstr /C:saved
REM ) ELSE (
  IF DEFINED DEBUG echo powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile('%url%','%outputFile%')}"
  echo powershell "%url%"
  powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile('%url%','%outputFile%')}"
REM )
echo: %END%

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
powershell -executionPolicy bypass -Command "&{Add-Type -AssemblyName System.IO.Compression.FileSystem ; $Filter = '%filter%' ; $zip = [System.IO.Compression.ZipFile]::OpenRead('%archive%') ; $zip.Entries | Where-Object { $_.Name -like $Filter } | ForEach-Object { $FileName = $_.Name ; [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, """$FileName""", $true)} }"
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


:power_expand archive [folder]
IF NOT EXIST %1 goto :EOF
echo %c%%~0%END% %1 %2
powershell -executionPolicy bypass -Command Expand-Archive -Force -LiteralPath %1 -DestinationPath %2
goto :EOF


:7unzip archive targetDir [password] [filter] [keep]
:: 7unzip does overwrite extracted files
findstr /C:"%~0 %~n1 OK" %LOGFILE% >NUL 2>&1 && echo %g%%~0 %~n1 OK && goto :EOF
echo %c%%~0 %1 %END% %2 %3
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

echo:
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

echo:
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
    echo:
    echo %HIGH%%y%Please NOTE:%END% RKIT %installedDateVersion% with success. DO you want to %HIGH%re-install%END% version %version% anyway?
    echo %HIGH%%k%re-install will %w%purge everything%k% + re-download everything under %INSTALLDIR%%END%
    echo:
    set /p choice=choice? [N/y] 
  ) ELSE (
  :: if fullyInstalled previous version!=current, just indicate it's an update
    echo:
    echo %HIGH%%g%Please NOTE:%END% RKIT %installedDateVersion% with success. New version %version% will %HIGH%update%END% your folder.
    echo %HIGH%%k%update will just re-download + overwrite everything under %INSTALLDIR%%END% in 5 seconds...
    echo:
    ping -n 6 localhost >NUL 2>&1
  )
)

:: if potentially installed and log absent for some reason, just indicate it's an update
IF [%installedVersion%]==[unknown] (
  echo:
  echo %HIGH%%y%Please NOTE:%END% RKIT *seems* to be installed already. New version %version% will %HIGH%update%END% your folder.
  echo %HIGH%%k%update will just re-download + overwrite everything under %INSTALLDIR%%END% in 5 seconds...
  echo:
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
echo:%g%
echo            _ _    _____                 _     _____              _                 
echo      /\   ^| ^| ^|  / ____^|               ^| ^|   ^|  __ \            ^| ^|                
echo     /  \  ^| ^| ^| ^| ^|  __  ___   ___   __^| ^|   ^| ^|__) ^|_ _ _ __ __^| ^|_ __   ___ _ __ 
echo    / /\ \ ^| ^| ^| ^| ^| ^|_ ^|/ _ \ / _ \ / _` ^|   ^|  ___/ _` ^| '__/ _` ^| '_ \ / _ \ '__^|
echo   / ____ \^| ^| ^| ^| ^|__^| ^| (_) ^| (_) ^| (_^| ^|_  ^| ^|  ^| (_^| ^| ^| ^| (_^| ^| ^| ^| ^|  __/ ^|   
echo  /_/    \_\_^|_^|  \_____^|\___/ \___/ \__,_^( ^) ^|_^|   \__,_^|_^|  \__,_^|_^| ^|_^|\___^|_^|   
echo                                          ^|/                                        
echo:%END%
goto :EOF

:counterInc
set /A COUNTER=COUNTER+1
goto :EOF

:successInc
set /A SUCCESS=SUCCESS+1
REM pause
goto :EOF

:error
echo:%r%
echo ==============================================================
echo ERROR: %HIGH%%*%END%%r%
IF [%1]==[setx] echo %y%Consider installing Windows XP SP3 or Server 2003 SP2 %r%
IF [%1]==[powershell] echo %y%Consider install Management Framework at https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu [or download wget.exe manually] %r%
IF [%1]==[mkdir] echo %y%Consider installing in a folder you have Modifications permission %r%
echo ==============================================================
echo:%END%
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
  echo: %y%
  echo %HIGH%WARNING: %END%%y%something went wrong, please check and correct the script or just accept the fatality.%END%
  pause
)
del /q %TMPFILE%*
popd
exit /b %CR%
