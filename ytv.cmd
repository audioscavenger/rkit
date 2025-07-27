@echo OFF
setlocal

:: downloads only audio from Youtube soundcloud and more https://github.com/yt-dlp/yt-dlp

IF /I "%~1"==""       call :USAGE
IF /I "%~1"=="h"      call :USAGE
IF /I "%~1"=="-h"     call :USAGE
IF /I "%~1"=="--help" call :USAGE

:main
IF /I     "%~1"=="loop" goto :loop
IF /I    "%~x1"==".url" call :url %1 & goto :end
call :dl %1

goto :end


:url
title %~n1
pushd %~sdp1

for /f "usebackq tokens=1,* delims==" %%a in (`type %1`) DO (
  REM echo IF "%%~a"=="URL" set url=%%b
  REM pause
  IF "%%~a"=="URL" set url=%%b
)
call :dl "%url%"
goto :EOF

:loop
set /P url=url? 
pwd
call :dl "%url%"
goto :loop

:dl
::  --throttled-rate 100K 
:: --extractor-args youtube:player_client=android 

REM %~sdp0\yt-dlp %1 --embed-metadata -S res,ext:mp4:m4a --recode mp4
%~sdp0\yt-dlp %1 --embed-metadata -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"

goto :EOF

:USAGE
echo %~n0 ^<URL^> [ --no-playlist ]
echo %~n0 loop
exit /b 99
goto :EOF

:end




