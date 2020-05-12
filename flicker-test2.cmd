@echo off
setlocal EnableDelayedExpansion
:: https://www.dostips.com/forum/viewtopic.php?t=5809


:: define a nbsp (Non-breaking space or no-break space) ALT+0255
set nbsp=ÿ


:main
  call :set_colors
  call :draw_on_screen
goto :main

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


:draw_on_screen
  (
  :loop_antiflicker
    if "%time:~-1%"=="!time:~-1!" goto :loop_antiflicker
    cls
    REM echo(%nbsp%
    echo simple demo antiflicker %time%
    echo simple demo antiflicker %random%
    call :logo_nQ-downloader
    echo simple demo antiflicker
  )
exit/b