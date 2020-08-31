set osType=workstation
wmic os get Caption /value | findstr Server >%TMP%\wmic.tmp.txt && set osType=server

:: https://www.lifewire.com/windows-version-numbers-2625171
IF [%osType%]==[workstation] (
  for /f "tokens=4,5 delims=. " %%a in ('ver') do echo %%a.%%b | findstr "6.2 6.3 10.0" >NUL || exit /b 0
) ELSE (
  for /f "tokens=4" %%a in (%TMP%\wmic.tmp.txt) do echo %%a | findstr "2016 2019" >NUL || exit /b 0
)
REM echo %WindowsVersion% | findstr "6.2 6.3 10.0 2016 2019" >NUL || exit /b 0

REM ver | findstr /C:"Version 10.0" && set "WindowsVersion=10"    && goto :EOF
REM ver | findstr /C:"Version 6.3"  && set "WindowsVersion=8.1"   && goto :EOF
REM ver | findstr /C:"Version 6.2"  && set "WindowsVersion=8"     && goto :EOF
REM ver | findstr /C:"Version 6.1"  && set "WindowsVersion=7"     && exit /b 0
REM ver | findstr /C:"Version 6.0"  && set "WindowsVersion=Vista" && exit /b 0
REM ver | findstr /C:"Version 5.1"  && set "WindowsVersion=XP"    && exit /b 0

REM set colorCompatibleVersions=-8-8.1-10-2016-2019-
REM IF "!colorCompatibleVersions:-%WindowsVersion%-=_!"=="%colorCompatibleVersions%" exit /b 0

set END=[0m
set HIGH=[1m
set Underline=[4m
set REVERSE=[7m

REM echo [101;93m NORMAL FOREGROUND COLORS [0m
set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m

REM echo [101;93m NORMAL BACKGROUND COLORS [0m
set RK=[40m
set RR=[41m
set RG=[42m
set RY=[43m
set RB=[44m
set RM=[45m
set RC=[46m
set RW=[47m

REM echo [101;93m STRONG FOREGROUND COLORS [0m
set hK=[90m
set hR=[91m
set hG=[92m
set hY=[93m
set hB=[94m
set hM=[95m
set hC=[96m
set hW=[97m

REM echo [101;93m STRONG BACKGROUND COLORS [0m
set hRK=[100m
set hRR=[101m
set hRG=[102m
set hRY=[103m
set hRB=[104m
set hRM=[105m
set hRC=[106m
set hRW=[107m
