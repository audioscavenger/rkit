@echo OFF
REM @chcp 65000>nul
setlocal
:: downloads audio m4a/mp3 by default, from Youtube soundcloud and more https://github.com/yt-dlp/yt-dlp

:init

:defaults
set playlist_urls=%TEMP%\%~n0.playlist.txt
set audioFormat=--audio-format m4a/mp3
set videoFormat=-t mp4
set maxVideoQuality=480
REM set maxVideoQuality=720
set USAGE=
set VIDEO=

set BROWSER=firefox
set PROFILE_PATH=:"E:\users\firefox-profile-scavenger"
set NODE_PATH=--js-runtimes node:E:\Gitea\nQpuppeteer\nQpuppeteer\x64\node-v24.15.0-win-x64\
set ffmpeg_path=E:\wintools\PortableApps\Magick\

:prechecks
del /f /q %playlist_urls% >NUL 2>&1

call :arguments %*

REM try and parse each parameter as url, since we cannot for loop arguments that contain ? or =
IF NOT EXIST "%~1" call :parse_url %1
IF NOT EXIST "%~2" call :parse_url %2
IF NOT EXIST "%~3" call :parse_url %3
IF NOT EXIST "%~4" call :parse_url %4

IF DEFINED USAGE goto :USAGE


:main
REM set /P BROWSER=BROWSER? [%BROWSER%] 

:: remove double quotes
REM powershell -Command "(Get-Content '%playlist_urls%') -replace '\"', '' | Set-Content '%playlist_urls%'"
busybox sed -i s/"""//g %playlist_urls%

:: finally, we process all urls in the playlist file
IF DEFINED VIDEO (
        call :video_dl %playlist_urls%
) ELSE  call :audio_dl %playlist_urls%

goto :end


:arguments %*
echo %~0 %*

IF "%~1"=="" set USAGE=true

for %%a in (%*) DO (

  IF    "%%~a"=="-h"        set USAGE=true
  IF    "%%~a"=="--help"    set USAGE=true
  IF /I "%%~a"=="-mp3"      set audioFormat=-t mp3
  IF /I "%%~a"=="-m4a"      set audioFormat=-t aac
  IF /I "%%~a"=="-v"        set VIDEO=true
  IF /I "%%~a"=="-loop"     call :loop
  
  IF EXIST "%%~a" call :parse_file "%%~a"
  
  shift /1
)

goto :EOF


:parse_file file
echo %~0 %*

REM :: file is a Windows shortcut
IF /I "%%~x1"==".url" call :parse_shortcut "%%~1" %playlist_urls%

REM :: file is a text file with urls
IF /I "%~x1"==".txt" findstr /I /B "http" %1 >>%playlist_urls%

goto :EOF


:parse_url "url"
echo %~0 %*

:: BUG: we cannot process urls with a ? in them so let's treat them first and exit
set "url=%~1"

IF /I NOT "%url:~0,4%"=="http" exit /b 0

echo testing url=%url%
:: url is a playlist
IF NOT "%url:playlist?=%"=="%url%" call :extract_url_from_playlist "%url%"  %playlist_urls% & exit /b 0

:: url is a video - we don't test that because yt-dlp can download anything
REM IF NOT "%url:?=%"=="%url%" echo  "%url%">>%playlist_urls% & exit /b 0
echo "%url%" >>%playlist_urls%

goto :EOF


:parse_shortcut shortcut playlist_urls
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


:extract_url_from_playlist url playlist_urls
echo %~0 %*

echo %~sdp0\yt-dlp -x --flat-playlist --print webpage_url %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% %1 >%2
%~sdp0\yt-dlp -x --flat-playlist --print webpage_url %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% %1 >%2

goto :EOF


:audio_dl playlist
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


REM if %ext%==m4a %~sdp0\yt-dlp --extract-audio -S aext:m4a:mp3,acodec:aac:mp3   --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% --batch-file %playlist_urls%
REM if %ext%==mp3 %~sdp0\yt-dlp --extract-audio --audio-format mp3               --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% --batch-file %playlist_urls%

echo %~sdp0\yt-dlp --extract-audio %audioFormat% --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% --batch-file %playlist_urls% --ffmpeg-location %ffmpeg_path%
%~sdp0\yt-dlp --extract-audio %audioFormat% --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% --batch-file %playlist_urls% --ffmpeg-location %ffmpeg_path%

goto :EOF


:video_dl playlist
echo %~0 %*
type %1

echo %~sdp0\yt-dlp %videoFormat% -f "bv*[height<=%maxVideoQuality%]+ba/b[height<=%maxVideoQuality%]" --audio-quality 0 --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% --batch-file %playlist_urls% --ffmpeg-location %ffmpeg_path%
%~sdp0\yt-dlp %videoFormat% -f "bv*[height<=%maxVideoQuality%]+ba/b[height<=%maxVideoQuality%]" --audio-quality 0 --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%%PROFILE_PATH% --batch-file %playlist_urls% --ffmpeg-location %ffmpeg_path%

goto :EOF



:USAGE
echo %~n0 [options] ^<URL ^| url_list.txt ^| shortcut.url^>
echo %~n0 -mp3      force convert to mp3; default is m4a then mp3 if unavailable
echo %~n0 -m4a      force convert to m4a; default is m4a then mp3 if unavailable
echo %~n0 -v        download video
echo %~n0 -loop     loop over asking for urls one by one
pause
exit /b 99
goto :EOF

:end


