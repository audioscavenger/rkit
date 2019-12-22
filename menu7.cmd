@echo off
if "%~1" equ "OptionSelection" goto %1
:: https://www.dostips.com/forum/viewtopic.php?f=3&t=6936

rem Activate an horizontal menu controlled by cursor keys
rem Antonio Perez Ayala

setlocal EnableDelayedExpansion
cls
echo/
echo Example of horizontal menu
echo/
echo Change selected option with these cursor keys:
echo Home/End = First/Last, Left/Right = Prev/Next.
:loop
   echo/
   echo/
   call :HMenu select="Press Enter to continue, Esc to cancel: " Insert/Append/Update/Delete
   echo Option selected: %select%
if %select% neq 0 goto Loop
echo End of menu example
goto :EOF


This subroutine activate a one-line selection menu controlled by cursor control keys

:HMenu  select=  prompt  option1/option2/...
setlocal EnableDelayedExpansion

rem Separate options
set "options=%~3"
set "lastOption=0"
(
   set "options="
   for %%a in ("%options:/=" "%") do (
      set /A lastOption+=1
      set "option[!lastOption!]=%%~a"
      set "options=!options! %%~a "
   )
)

rem Define working variables
for %%a in ("Enter=13" "Esc=27" "End=35" "Home=36" "LeftArrow=37" "RightArrow=39") do set %%a
for /F %%a in ('copy /Z "%~F0" NUL') do set "CR=%%a"
for /F %%a in ('echo prompt $H ^| cmd') do set "BS=%%a"

rem Define movements for standard keys
set "sel=1"
set "moveSel[%Home%]=set sel=1"
set "moveSel[%End%]=set sel=%lastOption%"
set "moveSel[%LeftArrow%]=set /A sel-=^!^!(sel-1)"
set "moveSel[%RightArrow%]=set /A sel+=^!^!(sel-lastOption)"

rem Read keys via PowerShell  ->  Process keys in Batch
set /P "=Loading menu..." < NUL
PowerShell  ^
   Write-Host 0;  ^
   $validKeys = %End%..%LeftArrow%+%RightArrow%+%Enter%+%Esc%;  ^
   while ($key -ne %Enter% -and $key -ne %Esc%) {  ^
      $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').VirtualKeyCode;  ^
      if ($validKeys.contains($key)) {Write-Host $key}  ^
   }  ^
%End PowerShell%  |  "%~F0" OptionSelection %2
endlocal & set "%~1=%errorlevel%"
echo/
exit /B


:OptionSelection
setlocal EnableDelayedExpansion

rem Wait for PS code start signal
set /P "keyCode="
set /P "="

:nextSelection

   rem Show prompt: options
   for %%s in ("!option[%sel%]!") do set /P "=%BS%!CR!%~2!options: %%~s =[%%~s]!" < NUL

   rem Get a keycode from PowerShell
   set /P "keyCode="
   set /P "="

   rem Process it
   if %keyCode% equ %Enter% goto endSelection
   if %keyCode% equ %Esc% set "sel=0" & goto endSelection
   !moveSel[%keyCode%]!

goto nextSelection

:endSelection
exit %sel%
