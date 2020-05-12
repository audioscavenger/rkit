@echo off
if "%~1" equ "OptionSelection" goto :%1
:: https://www.dostips.com/forum/viewtopic.php?f=3&t=6936

rem Activate a CheckList/RadioButton controlled by cursor keys
rem Antonio Perez Ayala

setlocal EnableDelayedExpansion
call win10colors-set.cmd
mode 100,40

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: start of magic menu
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set "switch="
set "endHeader="
set options=.First option 
set options=%options%/.Second option
set options=%options%/.Third option
set options=%options%/.%y%Last option
set options=%options%/_%r%aaa aaaaaaaa
set options=%options%/_bbb bbbbb bb
set options=%options%/_cccc ccccccc
set options=%options%/_dddc ccccccc
set options=%options%/.eee e e e
set options=%options%/.ffffffffff
set options=%options%/.gggg
set options=%options%/.eee e e e
set options=%options%/.ffffffffff
set options=%options%/.gggg
set options=%options%/.eee e e e
set options=%options%/.ffffffffff
set options=%options%/.gggg
set options=%options%/_cccc ccccccc
set options=%options%/_dddc ccccccc
:: calculate number of options here
for %%a in ("%options:/=" "%") do set /A lastOption+=1

:header
  cls
  call :logo_nQ-downloader
  echo/
  echo Example of Check List / Radio Button
  echo/
  echo Move selection lightbar with these cursor keys:
  echo Home/End = First/Last, Up/Down = Prev/Next; or via option's first letter.
  echo/
  %endHeader%
  if defined switch set "switch=/R"
  call :CheckList select="%options%" %switch%
  echo/
  echo/
  if "%select%" equ "0" goto :endProg
  echo Option(s) selected: %select%
  
  pause
:: example loop
REM goto :header
goto :main
:endProg
echo End of example
goto :EOF



This subroutine activate a CheckList/RadioButton form controlled by cursor control keys

%1 = Variable that receive the selection
%2 = Options list separated by slash
%3 = /R (switch) = Radio Button (instead of Check List)



:CheckList select= "option1/option2/..." [/R]
echo %~0 %ERRORLEVEL%
setlocal EnableDelayedExpansion

rem Process /R switch
if /I "%~3" equ "/R" (
  set "Radio=1"
  set "unmark=( )" & set "mark=(o)"
) else (
  set "Radio="
  set "unmark=[ ]" & set "mark=[x]"
)

rem Separate options
set "options=%~2"
set "lastOption=0"
for %%a in ("%options:/=" "%") do (
  set /A lastOption+=1
  set label=%%~a                                            
  REM :: findstr trick requires tab to have printable characters
  set "tab[!lastOption!]=_"
  REM :: labels starting with color will need 5 more spaces
  IF "!label:~2,1!"=="[" (
    set "option[!lastOption!]=!label:~1,45!"
    IF "!label:~0,1!"=="_" (
      set "tab[!lastOption!]=___"
      set "option[!lastOption!]=!label:~1,43!"
    )
  ) ELSE (
    set "option[!lastOption!]=!label:~1,40!"
    IF "!label:~0,1!"=="_" (
      set "tab[!lastOption!]=___"
      set "option[!lastOption!]=!label:~1,38!"
    )
  )
  set "select[!lastOption!]=%unmark%"
  REM pause
  REM IF "!label:~0,1!" EQU "_" (set "select[!lastOption!]=  %unmark%") ELSE (set "select[!lastOption!]=%unmark%")
  call set "moveSel[%%option[!lastOption!]:~0,1%%]=set sel=!lastOption!"
)
if defined Radio set "select[1]=%mark%"

rem Define working variables
for %%a in ("Enter=13" "Esc=27" "Space=32" "Endd=35" "Home=36" "UpArrow=38" "DownArrow=40" "LetterA=65" "LetterZ=90") do set %%a
set "letter=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
for /F %%a in ('echo prompt $H ^| cmd') do set "BS=%%a"
:: findstr trick
REM echo %BS%%BS%%BS%%BS%%BS%%BS%      >_

rem Define movements for standard keys
set "sel=1"
set "moveSel[%Home%]=set sel=1"
set "moveSel[%Endd%]=set sel=%lastOption%"
set "moveSel[%UpArrow%]=set /A sel-=^!^!(sel-1)"
set "moveSel[%DownArrow%]=set /A sel+=^!^!(sel-lastOption)"

rem Read keys via PowerShell  ->  Process keys in Batch
set /P "=Loading menu..." < NUL
PowerShell  ^
  Write-Host 0;  ^
  $validKeys = %Endd%..%Home%+%UpArrow%+%DownArrow%+%Space%+%Enter%+%Esc%+%LetterA%..%LetterZ%;  ^
  while ($key -ne %Enter% -and $key -ne %Esc%) {  ^
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode;  ^
    if ($validKeys.contains($key)) {Write-Host $key}  ^
  }  ^
%Endd PowerShell%  |  "%~F0" OptionSelection
:: %1 is actually "select" since = sign counts as separator
endlocal & set "%~1=%errorlevel%"
:: findstr trick
REM del _
exit /B


:OptionSelection
setlocal EnableDelayedExpansion

rem Wait for PS code start signal
set /P "keyCode="
set /P "="

set "endHeader=exit /B"
:nextSelection

  rem Clear the screen and show the list
  call :header
  < NUL (for /L %%i in (1,1,%lastOption%) do (
    set "num=  %%i"
    if "%%i" equ "%sel%" (
      REM :: findstr trick
      REM set /P "=%k%!tab[%%i]!%END%!num:~-2! !select[%%i]!  "
      REM findstr /A:17 . "!option[%%i]!\..\_" NUL
      echo !tab[%%i]:_= !!num:~-2! !select[%%i]!  %rc%!option[%%i]!%END%
    ) else (
      echo !tab[%%i]:_= !!num:~-2! !select[%%i]!  !option[%%i]!%END%
    )
  ))
  echo/
  set /P "=Space=(De)Select, Enter=Continue, Esc=Cancel" < NUL

  rem Get a keycode from PowerShell
  set /P "keyCode="
  set /P "="

  rem Process it
  if %keyCode% equ %Enter% goto :endSelection
  if %keyCode% equ %Esc% exit 0
  if %keyCode% equ %Space% (
    if defined Radio (
      set "select[%Radio%]=%unmark%"
      set "select[%sel%]=%mark%"
      set "Radio=%sel%"
    ) else (
      if "!select[%sel%]!" equ "%unmark%" (
        set "select[%sel%]=%mark%"
      ) else (
        set "select[%sel%]=%unmark%"
      )
    )
    goto :nextSelection
  )
  if %keyCode% lss %LetterA% goto :moveSelection
    set /A keyCode-=LetterA
    set "keyCode=!letter:~%keyCode%,1!"
  :moveSelection
  !moveSel[%keyCode%]!

goto :nextSelection

:endSelection
set "sel="
for /L %%i in (1,1,%lastOption%) do (
  REM if "!select[%%i]!" equ "%mark%" set "sel=!sel!%%i"
  REM :: 1<<x = 2 power x
  REM :: to get the original selections, just for loop in reverse and substract each power values of 2
  if "!select[%%i]!" equ "%mark%" set /A "sel+=1<<%%i"
)
if not defined sel set "sel=0"
REM echo exit %sel%
exit %sel%
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: end of magic menu
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:main
echo this is :main

call :listOptions %select%
goto :end

:listOptions %select%
echo :listOptions %1 with lastOption=%lastOption%
set binarySum=%1
:: %select% is a binary addition: sum of all selected options as power of 2
for /L %%i in (%lastOption%,-1,1) do (
  set /a "thisOne=1<<%%i"
  IF !binarySum! GEQ !thisOne! (
    set /a "binarySum-=1<<%%i"
    echo   Now we can execute option %%i
  )
)
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


:end
echo ----------------------- THE END ----------------------
pause

