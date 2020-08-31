@echo OFF
:: version=2.0
:: to get a correct date from a US date and time

set _output=
set TIMEEND=%2

IF NOT DEFINED TIMESTART set TIMESTART=%1
if /I "x%1x" EQU "xSTARTx" set "TIMESTART=%TIME%" & goto :END
IF NOT DEFINED TIMESTART echo usage: %~nx0 TIMESTART [TIMEEND] 1>&2 & set "TIMESTART=%TIME%" & echo TIMESTART=%TIME% 1>&2 & goto :END

IF NOT DEFINED TIMEEND set "TIMEEND=%TIME%"
call :setMicrotime
call :showTime %3 %4 %5
goto :END

:setMicrotime
:: TIMESTART=16:50:41,12
:: 18:07:54.08 18:37:04.05
::http://www.robvanderwoude.com/battech_leadingzero.php
::SET /A Var = 100%Var% %% 100
:: case where time < 10 and look like "9:10:06.19"
if "%TIMESTART:~1,1%" == ":" set TIMESTART=0%TIMESTART%
:: case where time < 10 and look like " 9:10:06.19"
if "%TIMESTART:~0,1%" == " " set TIMESTART=%TIMESTART: =0%

set /A startmicrotime=(100%TIMESTART:~0,2% %% 100)*360000
set /A startmicrotime+=(100%TIMESTART:~3,2% %% 100)*6000
set /A startmicrotime+=(100%TIMESTART:~6,2% %% 100)*100
set /A startmicrotime+=100%TIMESTART:~-2% %% 100

:: case where time < 10 and look like "9:10:06.19"
if "%TIMEEND:~1,1%" == ":" set TIMEEND=0%TIMEEND%
:: case where time < 10 and look like " 9:10:06.19"
if "%TIMEEND:~0,1%" == " " set TIMEEND=%TIMEEND: =0%
set /A endmicrotime=(100%TIMEEND:~0,2% %% 100)*360000
set /A endmicrotime+=(100%TIMEEND:~3,2% %% 100)*6000
set /A endmicrotime+=(100%TIMEEND:~6,2% %% 100)*100
set /A endmicrotime+=100%TIMEEND:~-2% %% 100

rem cs means cents of a second
set /A totalcs=endmicrotime-startmicrotime
set    totalms=%totalcs%0
set /A totals=%totalcs%/100
goto :EOF

:showTime _outputs
echo microtime (100's of second) end - start = %endmicrotime% - %startmicrotime% 1>&2
echo. 1>&2
echo TIMESTART =%TIMESTART%  1>&2
echo TIMEEND   =%TIMEEND% 1>&2
echo %%totalms%% = %totalms% ms 1>&2
echo %%totalcs%% = %totalcs% cs 1>&2
echo %%totals%%  = %totals% s 1>&2

for %%o in (%*) DO (
  if "%%o"=="-ms" call set _output=%%_output%% %totalms%
  if "%%o"=="-cs" call set _output=%%_output%% %totalcs%
  if "%%o"=="-s"  call set _output=%%_output%% %totals%
)
IF DEFINED _output echo %_output%
goto :EOF

:END
rem pause
