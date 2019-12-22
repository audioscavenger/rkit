@echo off
if "%~1" equ "OptionSelection" goto %1
@echo off
if "%~1" equ "OptionSelection" goto %1
:: https://www.dostips.com/forum/viewtopic.php?f=3&t=6936

rem Activate a vertical selection menu controlled by cursor keys
rem Antonio Perez Ayala

rem Example: define menu options, menu messages and first letter of options (see description below)
setlocal EnableDelayedExpansion
set "option.length=0"
for %%a in ("First option =Description of first option            "
            "Second option=The option below don't have description"
            "Third option =                                       "
            "Last option  =Description of last option             ") do (
   for /F "tokens=1,2 delims==" %%b in (%%a) do (
      set /A option.length+=1
      set "option[!option.length!]=%%b"
      set "message[!option.length!]=%%c"
      call set "moveSel[%%option[!option.length!]:~0,1%%]=set sel=!option.length!"
   )
)

:loop
   cls
   echo/
   echo Description of :VMenu subroutine: how to show a vertical selection menu.
   echo/
   echo call :VMenu select options [messages]
   echo/
   echo     select     Variable that receives the number of selected option
   echo     options    Name of array with the options
   echo     messages   Name of array with messages, optional
   echo/
   echo "options" is an array with the text to show for each menu option;
   echo all texts must be aligned (filled with spaces) to the same lenght.
   echo/
   echo A variable with same "options" name and ".length" postfix must contain
   echo the number of options in the menu; for example: set options.length=4
   echo/
   echo "messages" is an optional array with companion descriptions for each option;
   echo all descriptions must be aligned to the same lenght (even the empty ones).
   echo/
   echo The highlighted option can be changed with these cursor keys:
   echo Home/End = First/Last, Up/Down = Prev/Next, or via option's first letter;
   echo Enter = Select option and continue, Esc = Cancel selection (return zero).
   echo/
   echo/
   rem  For example:

   call :VMenu select=option message
   echo/
   if %select% equ 0 goto exitLoop
   echo Option selected: %select%
   pause
goto loop
:exitLoop
echo End of menu example
goto :EOF
   

This subroutine activate a selection menu controlled by cursor control keys

:VMenu select= option [message]
setlocal

rem Define working variables
for %%a in ("Enter=13" "Esc=27" "End=35" "Home=36" "UpArrow=38" "DownArrow=40" "LetterA=65" "LetterZ=90") do set %%a
set "letter=ABCDEFGHIJKLMNOPQRSTUVWXYZ"
for /F %%a in ('echo prompt $H ^| cmd') do set "BS=%%a"
echo %BS%%BS%%BS%%BS%%BS%%BS%      >_

rem Define selection bar movements for standard keys
set "sel=1"
set "moveSel[%Home%]=set sel=1"
set "moveSel[%End%]=set sel=!%2.length!"
set "moveSel[%UpArrow%]=set /A sel-=^!^!(sel-1)"
set "moveSel[%DownArrow%]=set /A sel+=^!^!(sel-%2.length)"

rem Read keys via PowerShell  ->  Process keys in Batch
set /P "=Loading menu..." < NUL
PowerShell  ^
   $console = $Host.UI.RawUI;  ^
   $curSize = $console.CursorSize;  ^
   $console.CursorSize = 0;  ^
   $curPos = $console.CursorPosition;  ^
   $curPos.X = 0;  ^
   $console.CursorPosition = $curPos;  ^
   Write-Host 0;  ^
   $validKeys = %End%..%Home%+%UpArrow%+%DownArrow%+%Enter%+%Esc%+%LetterA%..%LetterZ%;  ^
   while ($key -ne %Enter% -and $key -ne %Esc%) {  ^
      $key = $console.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode;  ^
      if ($validKeys.contains($key)) {  ^
         if ($key -ne %Enter% -and $key -ne %Esc%) {$console.CursorPosition = $curPos}  ^
         Write-Host $key  ^
      }  ^
   }  ^
   $console.CursorSize = $curSize;  ^
%End PowerShell%  |  "%~F0" OptionSelection %2 %3
endlocal & set "%1=%errorlevel%"
del _
exit /B


:OptionSelection %1 option [message]
setlocal EnableDelayedExpansion

rem Wait for PS code start signal
set /P "keyCode="
set /P "="

:nextSelection

   rem Show menu options
   for /L %%i in (1,1,!%2.length!) do (
      if %%i equ %sel% (
         set /P "=.%BS%    " < NUL
         findstr /A:70 . "!%2[%%i]!\..\_" NUL
      ) else (
         echo     !%2[%%i]!
      )
   )
   if defined %3[%sel%] (
      echo/
      echo(!%3[%sel%]!
   )

   rem Get a keycode from PowerShell
   set /P "keyCode="
   set /P "="

   rem Process it
   if %keyCode% equ %Enter% goto endSelection
   if %keyCode% equ %Esc% set "sel=0" & goto endSelection
   if %keyCode% lss %LetterA% goto moveSelection
      set /A keyCode-=LetterA
      set "keyCode=!letter:~%keyCode%,1!"
   :moveSelection
   !moveSel[%keyCode%]!

goto nextSelection
:endSelection
exit %sel%