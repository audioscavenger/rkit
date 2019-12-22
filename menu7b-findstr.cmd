@echo off
if "%~1" equ "OptionSelection" goto %1
:: https://www.dostips.com/forum/viewtopic.php?f=3&t=6936

rem Activate a CheckList/RadioButton controlled by cursor keys
rem Antonio Perez Ayala

setlocal
set "switch="
set "endHeader="
:header
   cls
   echo/
   echo Example of Check List / Radio Button
   echo/
   echo Move selection lightbar with these cursor keys:
   echo Home/End = First/Last, Up/Down = Prev/Next; or via option's first letter.
   echo/
   %endHeader%
   if not defined switch (set "switch=/R") else set "switch="
   call :CheckList select="First option/Second option/Third option/Last option" %switch%
   echo/
   echo/
   if "%select%" equ "0" goto endProg
   echo Option(s) selected: %select%
   pause
goto header
:endProg
echo End of example
goto :EOF


This subroutine activate a CheckList/RadioButton form controlled by cursor control keys

%1 = Variable that receive the selection
%2 = Options list separated by slash
%3 = /R (switch) = Radio Button (instead of Check List)

:CheckList select= "option1/option2/..." [/R]
setlocal EnableDelayedExpansion

rem Process /R switch
if /I "%~3" equ "/R" (
   set "Radio=1"
   set "unmark=( )" & set "mark=(o)"
) else (
   set "Radio="
   set "unmark=[ ]" & set "mark=[X]"
)

rem Separate options
set "options=%~2"
set "lastOption=0"
for %%a in ("%options:/=" "%") do (
   set /A lastOption+=1
   set "option[!lastOption!]=%%~a"
   set "select[!lastOption!]=%unmark%"
   call set "moveSel[%%option[!lastOption!]:~0,1%%]=set sel=!lastOption!"
)
if defined Radio set "select[1]=%mark%"

rem Define working variables
for %%a in ("Enter=13" "Esc=27" "Space=32" "End=35" "Home=36" "UpArrow=38" "DownArrow=40" "LetterA=65" "LetterZ=90") do set %%a
set "letter=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
for /F %%a in ('echo prompt $H ^| cmd') do set "BS=%%a"
echo %BS%%BS%%BS%%BS%%BS%%BS%      >_

rem Define movements for standard keys
set "sel=1"
set "moveSel[%Home%]=set sel=1"
set "moveSel[%End%]=set sel=%lastOption%"
set "moveSel[%UpArrow%]=set /A sel-=^!^!(sel-1)"
set "moveSel[%DownArrow%]=set /A sel+=^!^!(sel-lastOption)"

rem Read keys via PowerShell  ->  Process keys in Batch
set /P "=Loading menu..." < NUL
PowerShell  ^
   Write-Host 0;  ^
   $validKeys = %End%..%Home%+%UpArrow%+%DownArrow%+%Space%+%Enter%+%Esc%+%LetterA%..%LetterZ%;  ^
   while ($key -ne %Enter% -and $key -ne %Esc%) {  ^
      $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode;  ^
      if ($validKeys.contains($key)) {Write-Host $key}  ^
   }  ^
%End PowerShell%  |  "%~F0" OptionSelection
endlocal & set "%~1=%errorlevel%"
del _
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
      if %%i equ %sel% (
         set /P "=!select[%%i]!  "
         findstr /A:70 . "!option[%%i]!\..\_" NUL
      ) else (
         echo !select[%%i]!  !option[%%i]!
      )
   ))
   echo/
   set /P "=Space=(De)Select, Enter=Continue, Esc=Cancel" < NUL

   rem Get a keycode from PowerShell
   set /P "keyCode="
   set /P "="

   rem Process it
   if %keyCode% equ %Enter% goto endSelection
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
      goto nextSelection
   )
   if %keyCode% lss %LetterA% goto moveSelection
      set /A keyCode-=LetterA
      set "keyCode=!letter:~%keyCode%,1!"
   :moveSelection
   !moveSel[%keyCode%]!

goto nextSelection
:endSelection
set "sel="
for /L %%i in (1,1,%lastOption%) do (
   if "!select[%%i]!" equ "%mark%" set "sel=!sel!%%i"
)
if not defined sel set "sel=0"
exit %sel%