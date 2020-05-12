@echo off
setlocal EnableDelayedExpansion

Rem Multithreading dispatcher
if NOT "%1"=="" goto %1
:: https://www.dostips.com/forum/viewtopic.php?t=5809

call :set_colors
Start "1 Timer coalescing" %0 :Do_work_1
REM Start "2 Normal" %0 :Do_work_flickering

exit /b


:logo_nQ-downloader
echo.
echo.
echo    %y%              .g8""8q.          __   __                  __        __   ___  __  tm
echo    %y%            .dP'    `YM.       ^|  \ /  \ ^|  ^| ^|\ ^| ^|    /  \  /\  ^|  \ ^|__  ^|__) 
echo    %y%            dM'      `MM       ^|__/ \__/ ^|/\^| ^| \^| ^|___ \__/ /~~\ ^|__/ ^|___ ^|  \ 
echo    %c%   ,;      %y% MM        MM 
echo    %c% `7MMpMMMb.%y% MM.      ,MP 
echo    %c%   MM    MM%y% `Mb.    ,dP' 
echo    %c%   MM    MM%y%   `"bmmd"'   
echo    %c%   MM    MM%y%       MMb    
echo    %c% .JMML  JMML.%y%      `boo__
echo.%END%
goto :EOF

:set_colors
set colorCompatibleVersions=-8-8.1-10-2016-2019-
IF DEFINED WindowsVersion IF "!colorCompatibleVersions:-%WindowsVersion%-=_!"=="%colorCompatibleVersions%" goto :EOF

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

goto :EOF
:: BUG: some space are needed after :set_colors



:Do_work_1
  REM mode 40,3
  mode 100,40
  REM call :Empty_Env
  For /L %%\ in (0,1,1000000) do (
  call :logo_nQ-downloader

      %= Antiflicker via timers coalescing (for win 7 to ...) =%
      %= For best visualize close any browser and multimedia player (these change/increase the timer resolution!) =%
      %= disable Aero (desktop compositing) on windows 7 =%
      if not "!OT!"=="!time:~-1!" (

         %= Fast write on screen =%
         cls & echo Flickering? & echo Flichering? %%\
         set OT=!time:~-1!
      )
  )
exit /b

:Do_work_flickering
  REM mode 40,3
  mode 100,40
  call :Empty_Env
  pause
  For /L %%\ in (0,1,1000000) do (

      %= Fast write on screen =%
      cls & echo Flickering? & echo Flichering? %%\
  )
exit /b

:Empty_Env
  set 
  rem For best SET performance. Dos is faster 2x .. 5x
  set "preserve= TMP COMSPEC preserve "
  for /f "delims==" %%v in ('set') do if "!preserve: %%v =!" equ "!preserve!" set "%%v="
  set "preserve="
  set
  pause
exit/b