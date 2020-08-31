@echo OFF
setlocal
:: http://serverfault.com/questions/98858/how-to-find-the-bottleneck-while-transferring-huge-files-between-2-hosts
:top

set version=2.0
set author=lderewonko

:: stress CPU:
REM busybox dd if=/dev/urandom bs=64k count=100000 | gzip -f >NUL

:: on linux :
:: time busybox dd if=/dev/zero of=tmp.tmp bs=1M count=2000 && rm tmp.tmp

:init
set DIRNAME=%~dp0
set CURRENTDRIVE=%~d0
set TITLE=%~n0 %version% by %author% - %COMPUTERNAME% - %USERNAME%@%USERDOMAIN_ROAMINGPROFILE%
title %TITLE%

:defaults
set nbGo=2
set block=64

:prechecks

for %%x in (get_timelapse.cmd) DO set "get_timelapse=%%~$PATH:x"
IF NOT DEFINED get_timelapse echo ERROR: get_timelapse.cmd not found & pause & exit

:: you must have admin rights to use dd
call :detect_admin_mode 0
call :set_colors


:main
del /q /f %DIRNAME%\????M.tmp 2>NUL

set /P drive=Drive ? [%CURRENTDRIVE%] 
set /P nbGo=Gigas ? [%nbGo%] 
echo test throughput: block= 100000 k
echo test latency   : block= 1      k
set /P block=block ? [%block%] 
echo.

rem INIT --------------------------------------------------
set testdrive=%drive%xx
if "%testdrive%" NEQ "xx" (
	if "%testdrive:~1,1%" NEQ ":" set drive=%CURRENTDRIVE%
	) ELSE (
	set drive=%CURRENTDRIVE%
)
rem INIT --------------------------------------------------

:: convert Go to %block%k clusters:
set /A nbBlocks=%nbGo%*1024*1024/%block%

echo GO for %nbGo%GB test on %drive%\ (%nbBlocks% * %block%k blocks)...
echo.

call :TEST_LOCAL
call :RESULTS

goto :END




:TEST_LOCAL
echo.
echo STARTING Write test of %nbGo%GB on %drive%
echo ------------------------------------------
echo   %END%1. Flushing disk cache:%HIGH%%k% 
sync %drive% 2>NUL
echo   %END%2. Generating %nbGo%000M.tmp out of /dev/zero...%HIGH%%k% 
call %get_timelapse% start >NUL 2>&1
busybox dd if=/dev/zero of=%DIRNAME%\%nbGo%000M.tmp bs=%block%k count=%nbBlocks% >NUL 2>&1 && sync %drive% 2>NUL
echo   %END%3. Flushing disk cache again:%HIGH%%k% 
sync %drive% 2>NUL
call %get_timelapse% %TIMESTART% %TIME% >NUL 2>&1
set totalWriteCs=%totalcs%

echo.
echo STARTING Read test of %nbGo%GB on %drive%
echo ------------------------------------------
echo   %END%1. Flushing disk cache:%HIGH%%k% 
sync %drive% 2>NUL
echo   %END%2. Reading %nbGo%GB from %DIRNAME%\%nbGo%000M.tmp...%HIGH%%k% 
call %get_timelapse% start >NUL 2>&1
busybox dd if=%DIRNAME%\%nbGo%000M.tmp of=/dev/null bs=8k >NUL 2>&1 && sync %drive% 2>NUL
call %get_timelapse% %TIMESTART% %TIME% >NUL 2>&1
set totalReadCs=%totalcs%
echo.%END%

del /q /f %DIRNAME%\????M.tmp
goto :EOF


:detect_admin_mode [num]
IF DEFINED DEBUG echo %m%DEBUG: %~0 %HIGH%%*%END% 1>&2
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file

set bits=32
set bitx=x86
IF DEFINED PROCESSOR_ARCHITEW6432 echo WARNING: 32bit cmd on 64bit system 1>&2
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
wmic os get Caption /value | findstr Server >%TMP%\wmic.tmp.txt
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
  for /f "tokens=4" %%a in (%TMP%\wmic.tmp.txt) do set WindowsVersion=%%a
)
goto :EOF


:set_colors
IF DEFINED END goto :EOF
set colorCompatibleVersions=-8-8.1-10-2016-2019-
call set colorIncompatible=%%colorCompatibleVersions:-%WindowsVersion%-=COMPATIBLE%%
IF "%colorCompatibleVersions%"=="%colorIncompatible%" exit /b 1
REM call win10colors-set.cmd >NUL 2>NUL && goto :EOF

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


:RESULTS
:: TIMESTART=16:50:41,12
set /A writeMBs=%nbGo%00000/%totalWriteCs%
set /A readMBs=%nbGo%00000/%totalReadCs%

for /F "tokens=*" %%a in ('wmic cpu get Name ^| findstr /R .') DO set cpuName=%%a

echo RESULTS: %c%Disk speed run on %DATE% %TIME% %END%
echo Session: %c%    %COMPUTERNAME% by %USERNAME%@%USERDOMAIN_ROAMINGPROFILE% %HIGH%%k%
wmic cpu get Manufacturer, Name, NumberOfCores | findstr /R .
echo %HIGH%%k% ----------------------------------------------------------------------------- %END%
echo write speed=%writeMBs% MB/s
echo read  speed=%readMBs% MB/s
echo %HIGH%%k% ----------------------------------------------------------------------------- %END%
goto :EOF


:END
pause
