@echo off
setlocal
setlocal enableextensions disabledelayedexpansion
chcp 65001 >NUL
call :set_colors

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: version 2.2 - overhead of colors
IF "%~1"=="" echo usage: call progressBar value ["text" [barchar [spacechar [%%color%% [barArea]]]]]]
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


IF NOT "%~3"=="" call :initProgressBar %3 %4 %5 %6
call :drawProgressBar %1 "%~2."

REM call :initProgressBar "|" " "
REM call :drawProgressBar 0 "this is a custom progress bar"
REM for /l %%f in (0 1 100) do (
  REM call :drawProgressBar %%f 
REM )

:: Clean all after use - useless as we endlocal
REM call :finalizeProgressBar 1

exit /b


:drawProgressBar value [text]
if "%~1"=="" goto :eof
if not defined pb.barArea call :initProgressBar
setlocal enableextensions enabledelayedexpansion
set /a "pb.value=%~1 %% 101", "pb.filled=pb.value*pb.barArea/100", "pb.dotted=pb.barArea-pb.filled", "pb.pct=1000+pb.value"
set "pb.pct=%pb.pct:~-3%"
if "%~2"=="" (
  set "pb.text="
) else ( 
  set "pb.text=%~2%pb.back%"
  set "pb.text=!pb.text:~0,%pb.textArea%!"
  call :substr %2 0 %pb.textArea% pb.text
)
<nul set /p "pb.prompt=[%pb.color%!pb.fill:~0,%pb.filled%!%pb.colorEND%!pb.dots:~0,%pb.dotted%!][ %pb.pct% ] %pb.text%!pb.cr!"
endlocal
goto :eof

:initProgressBar [fillChar] [dotChar] [color] [barArea]
if defined pb.cr call :finalizeProgressBar
for /f %%a in ('copy "%~f0" nul /z') do set "pb.cr=%%a"
if "%~1"=="" ( set "pb.fillChar=█" ) else ( set "pb.fillChar=%~1" )
if "%~2"=="" ( set "pb.dotChar=." ) else ( set "pb.dotChar=%~2" )
if NOT "%~3"=="" set "pb.color=%~3" & set "pb.colorEND=%END%"
set pb.barArea=%4
set "pb.console.columns="
for /f "tokens=2 skip=4" %%f in ('mode con') do if not defined pb.console.columns set "pb.console.columns=%%f"
IF NOT DEFINED pb.barArea (set /a "pb.barArea=pb.console.columns/2-2", "pb.textArea=pb.barArea-6") ELSE set /a "pb.textArea=pb.console.columns-pb.barArea-11"
set "pb.fill="
setlocal enableextensions enabledelayedexpansion
for /l %%p in (1,1,%pb.barArea%) do set "pb.fill=!pb.fill!%pb.fillChar%"
set "pb.fill=!pb.fill:~0,%pb.barArea%!"
set "pb.dots=!pb.fill:%pb.fillChar%=%pb.dotChar%!"
set "pb.back=!pb.fill:~0,%pb.textArea%!
set "pb.back=!pb.back:%pb.fillChar%= !"
endlocal & set "pb.fill=%pb.fill%" & set "pb.dots=%pb.dots%" & set "pb.back=%pb.back%"
goto :eof

:finalizeProgressBar [erase]
if defined pb.cr (
  if not "%~1"=="" (
    setlocal enabledelayedexpansion
    set "pb.back="
    for /l %%p in (1,1,%pb.console.columns%) do set "pb.back=!pb.back! "
    <nul set /p "pb.prompt=!pb.cr!!pb.back:~1!!pb.cr!"
    endlocal
  )
)
for /f "tokens=1 delims==" %%v in ('set pb.') do set "%%v="
goto :eof

:substr inputVar start end [outputVar]
:: :substr not perfect yet, issues depends where the cutoff happens
IF DEFINED %1 (call set "string=%%%~1%%") ELSE set "string=%~1"
call :len string
set lenString=%ERRORLEVEL%
::  echo 1 :len %1 lenString=%lenString%
set stringESC=%string:=%
call :len stringESC
set /A "diff=lenString-%ERRORLEVEL%"
::  echo 2 diff = %diff%
IF %3 LEQ 9 (set colorShift=0) ELSE set colorShift=9
set /a "even=diff%%2"
::  echo %diff% even=%even%
set /A "overHead=%3+even+colorShift*diff/2"
::  echo 3 set /A overHead=%3+9*(%diff%)/2 = %overHead%
IF NOT "%~4"=="" (call set "%4=%%string:~%2,%overHead%%%") ELSE call echo %%string:~%2,%overHead%%%
::  call echo 4 call set %%4=%4 = %%string:~%2,%overHead%%%
goto :EOF

:len varName/string
:: :len varName - not actual value!
:: https://stackoverflow.com/questions/5837418/how-do-you-get-the-string-length-in-a-batch-file/8566001#8566001
IF DEFINED %1 (call echo:%%%1%%>%TMP%\%~n0.tmp) ELSE (echo:%~1>%TMP%\%~n0.tmp)
FOR %%? IN (%TMP%\%~n0.tmp) DO SET /A "strLength=%%~z? - 2"
exit /b %strLength%
goto :EOF

:set_colors
IF DEFINED END exit /b 0
set END=[0m
set HIGH=[1m
set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m
goto :EOF

