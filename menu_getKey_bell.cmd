@echo off
:: https://www.dostips.com/forum/viewtopic.php?f=3&t=3428
set Bell=7
set BackSpace=8
set Enter=13
set Space=32

:ReadLineTime var= seconds ["prompt"]
set %1=
set seconds=%2
Show %3 seconds ": "
set lastTime=%time:~0,-3%
:nextKey
   GetKey /N
   set key=%errorlevel%
   if %key% equ 0 (
      if %lastTime% equ %time:~0,-3% (
         goto nextKey
      ) else (
         set lastTime=%time:~0,-3%
         set /A seconds-=1
         if !seconds! gtr 0 (
            Show 13 %3 seconds ": " %1 " " %BackSpace%
            goto nextKey
         ) else (
            StrLen %1
            Show 13 %3 "0: " %Space%*!errorlevel! 13 10
            set %1=Input timeout
            exit /B 1
         )
      )
   )
   if %key% geq %Space% (
      rem Ascii Character
      Show %key%
      for /F "delims=" %%a in ('Show %key%') do set "%1=!%1!%%a"
   ) else if %key% equ %BackSpace% (
      if defined %1 (
         Show %BackSpace% %Space% %BackSpace%
         set "%1=!%1:~0,-1!"
      ) else (
         Show %Bell%
      )
   ) else if %key% equ %Enter% echo/& exit /B
goto nextKey