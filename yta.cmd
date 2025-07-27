@echo OFF
setlocal
:: downloads only audio from Youtube soundcloud and more https://github.com/yt-dlp/yt-dlp

:defaults
set ext=mp3

:main
IF /I "%~1"==""       call :USAGE
IF /I "%~1"=="h"      call :USAGE
IF /I "%~1"=="-h"     call :USAGE
IF /I "%~1"=="--help" call :USAGE

IF /I     "%~1"=="mp3"  set "ext=mp3" & shift /1
IF /I     "%~1"=="m4a"  set "ext=m4a" & shift /1
IF /I     "%~1"=="loop" goto :loop

for %%a in (%*) DO (
  IF /I    "%%~xa"==".url" (call :url %%a) ELSE call :url_dl %%a
)

goto :end


:url
title %~n1
pushd %~sdp1

for /f "usebackq tokens=1,* delims==" %%a in (`type %1`) DO (
  REM echo IF "%%~a"=="URL" set url=%%b
  REM pause
  IF "%%~a"=="URL" set url=%%b
)
call :url_dl "%url%"
goto :EOF

:loop
set /P url=url? 
pwd
call :url_dl "%url%"
goto :loop

:url_dl
:: try to guess format
REM echo %1 | findstr bandcamp.com >NUL && set format=mp3
REM echo %1 | findstr bandcamp.com/track >NUL && set format=m4a

::  --throttled-rate 100K 
:: --extractor-args youtube:player_client=android 

REM set /p format=%format%? 
:: will end up with falac
REM yt-dlp %1 --extractor-args youtube:player_client=android -x --no-keep-video --embed-metadata
:: will end up recoding
REM yt-dlp %1 --extractor-args youtube:player_client=android -x --audio-format %format% --no-keep-video --embed-metadata
:: https://github.com/yt-dlp/yt-dlp?tab=readme-ov-file#sorting-formats
:: mp3 over m4a even if m4a available
REM yt-dlp %1 --extractor-args youtube:player_client=android -x -S aext:mp3:m4a --no-keep-video --embed-metadata
:: falac over m4a because apparently falac is legin inside m4a
REM yt-dlp %1 --extractor-args youtube:player_client=android -x -S aext:m4a:mp3 --no-keep-video --embed-metadata
:: now it's perfect: mp3 first, then m4a aac because 99% of FM transmitters only play mp3/flac/wma/wav this is BS
if %ext%==m4a %~sdp0\yt-dlp %1 -x -S aext:m4a:mp3,acodec:aac:mp3 --no-keep-video --embed-metadata --add-metadata
if %ext%==mp3 %~sdp0\yt-dlp %1 -x --audio-format mp3 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata
goto :EOF

:USAGE
echo %~n0 ^<URL^> [ --no-playlist ]
echo %~n0 loop
exit /b 99
goto :EOF

:end


