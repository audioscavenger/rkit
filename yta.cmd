@echo OFF
@chcp 65000>nul
setlocal
:: downloads only audio from Youtube soundcloud and more https://github.com/yt-dlp/yt-dlp

:init

:defaults
set playlist_urls=%TEMP%\%~n0.playlist.txt
set ext=m4a
set BROWSER=firefox
set PROFILE_PATH=:"E:\users\firefox-profile-scavenger"
set NODE_PATH=--js-runtimes node:E:\Gitea\nQpuppeteer\nQpuppeteer\x64\node-v24.15.0-win-x64\

:prechecks
del /f /q %playlist_urls% >NUL 2>&1

:arguments
IF /I "%~1"==""       call :USAGE
IF /I "%~1"=="h"      call :USAGE
IF /I "%~1"=="-h"     call :USAGE
IF /I "%~1"=="--help" call :USAGE

IF /I     "%~1"=="mp3"  set "ext=mp3" & shift /1
IF /I     "%~1"=="m4a"  set "ext=m4a" & shift /1
IF /I     "%~1"=="loop" call :loop

:main
REM set /P BROWSER=BROWSER? [%BROWSER%] 

:: BUG: we cannot process urls with a ? in them so let's treat them first and exit
set "url=%~1"

IF NOT "%url:playlist?=%"=="%url%" call :url_extract_playlist "%url%"  %playlist_urls%
IF NOT EXIST %playlist_urls% IF NOT "%url:?=%"=="%url%" echo   "%url%">>%playlist_urls%

for %%a in ("%*") DO (
  IF EXIST "%%~a" (
    REM :: file is a shortcut
    echo IF /I "%%~xa"==".url" call :parse_shortcut "%%~a" %playlist_urls%
    IF /I "%%~xa"==".url" call :parse_shortcut "%%~a" %playlist_urls%
    
    REM :: file is a text file with urls
    echo IF /I "%~x1"==".txt" type %1 ^>^>%playlist_urls%
    IF /I "%~x1"==".txt" type %1 >>%playlist_urls%
  )
)

:: finally, we process all urls in the playlist file
call :url_dl %playlist_urls%

goto :end


:parse_shortcut shortcut playlist
echo %~0 %*
IF NOT EXIST %1 echo NOT FOUND: %1 & exit /b 1

pushd %~sdp1

for /f "usebackq tokens=1,* delims==" %%a in (`type %1`) DO (
  REM echo IF "%%~a"=="URL" set url=%%b
  REM pause
  IF "%%~a"=="URL" echo "%%~b">>%2
)

:: url shortcuts have this structure:
::  [InternetShortcut]
::  URL=https://www.youtube.com/feed/playlists
::  IDList=
::  HotKey=0
::  IconFile=E:\users\user\shortcutCache\xyz=.ico
::  IconIndex=0

popd
goto :EOF



:loop
set /P url=url? 

echo "%url%" >>%playlist_urls%

set answer=y
set /P answer=more? [%answer%] 
IF /I NOT "%answer%"=="y" goto :EOF

goto :loop


:url_extract_playlist url playlist
echo %~0 %*

echo %~sdp0\yt-dlp -x --flat-playlist --print webpage_url %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% %1 >%2
%~sdp0\yt-dlp -x --flat-playlist --print webpage_url %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% %1 >%2

goto :EOF


:url_dl playlist
echo %~0 %*
type %1

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


:: to list audio formats available you would need to to process each url one by one so why bother... newest command fallsback from m4a to mp3
REM %~sdp0\yt-dlp --list-formats %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% %1


REM if %ext%==m4a %~sdp0\yt-dlp --extract-audio -S aext:m4a:mp3,acodec:aac:mp3   --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% -a %playlist_urls%
REM if %ext%==mp3 %~sdp0\yt-dlp --extract-audio --audio-format mp3               --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% -a %playlist_urls%

%~sdp0\yt-dlp --extract-audio --audio-format m4a/mp3           --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% -a %playlist_urls%
goto :EOF


:USAGE
echo %~n0 ^<URL^> [ --no-playlist ]
echo %~n0 loop
exit /b 99
goto :EOF

:end


