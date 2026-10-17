@echo OFF
REM @chcp 65000>nul
setlocal
:: downloads audio m4a/mp3 by default, from Youtube soundcloud and more https://github.com/yt-dlp/yt-dlp

:init

:defaults
set VERBOSE=
set QUIET=--quiet

set VIDEO_ID=
set playlist_urls=%TEMP%\%~n0.playlist.txt
set audioFormat=--audio-format m4a/mp3
set videoFormat=-t mp4
set maxAudioQuality=128K
set maxVideoQuality=480
REM set maxVideoQuality=720
set USAGE=
set UPDATE=
set VIDEO=true
set AUDIO=
set SUBS=
set SUBS_FILENAME=%TMP%\subs
set lang=en

set BROWSER=firefox
set PROFILE_PATH="E:\users\firefox-profile-scavenger"
set NODE_PATH=
set ffmpeg_path=E:\wintools\PortableApps\Magick

:prechecks

where busybox >NUL 2>&1 || (echo error: buxybox not found & exit 1)

del /f /q "%playlist_urls%" >NUL 2>&1

call :detect_node
call :detect_profile
call :arguments %*

IF DEFINED USAGE call :USAGE & goto :end
IF DEFINED UPDATE call :update & goto :end

REM try and parse each parameter as url, since we cannot for loop arguments that contain ? or =
IF NOT "%~1"=="" IF NOT EXIST "%~1" call :parse_url %1
IF NOT "%~2"=="" IF NOT EXIST "%~2" call :parse_url %2
IF NOT "%~3"=="" IF NOT EXIST "%~3" call :parse_url %3
IF NOT "%~4"=="" IF NOT EXIST "%~4" call :parse_url %4

IF DEFINED USAGE call :USAGE & goto :end


:main

IF DEFINED VERSOSE set QUIET=

:: remove double quotes
REM powershell -Command "(Get-Content '%playlist_urls%') -replace '\"', '' | Set-Content '%playlist_urls%'"
busybox sed -i s/"""//g "%playlist_urls%"

:: finally, we process all urls in the playlist file
IF DEFINED VIDEO call :video_dl "%playlist_urls%"
IF DEFINED AUDIO call :audio_dl "%playlist_urls%"
IF DEFINED SUBS  call :subs_dl "%playlist_urls%" "%SUBS_FILENAME%" %lang%

goto :end


:arguments %*
IF "%~1"=="" set USAGE=true

:arg_loop
IF "%~1"=="" goto :arg_done

IF /I "%~1"=="-h"       set USAGE=true
IF /I "%~1"=="--help"   set USAGE=true
IF /I "%~1"=="-V"       set VERSOSE=true
IF /I "%~1"=="--verbose" set VERSOSE=true
IF /I "%~1"=="--update" set UPDATE=true
IF /I "%~1"=="--node" (
  IF "%~2"=="" (
    set USAGE=true
  ) ELSE (
    set NODE_PATH=--js-runtimes "node:%~2"
    shift /1
  )
)
IF /I "%~1"=="--browser" (
  IF "%~2"=="" (
    set USAGE=true
  ) ELSE (
    set "browser=%~2"
    shift /1
  )
)
IF /I "%~1"=="--profile" (
  IF "%~2"=="" (
    set USAGE=true
  ) ELSE (
    set PROFILE_PATH="%~2"
    shift /1
  )
)
IF /I "%~1"=="--mp3"    set audioFormat=-t mp3
IF /I "%~1"=="--m4a"    set audioFormat=-t aac
IF /I "%~1"=="--video"  set "VIDEO=true" & set "AUDIO=" & set "SUBS="
IF /I "%~1"=="--audio"  set "VIDEO=" & set "AUDIO=true" & set "SUBS="
IF /I "%~1"=="--subs"   set "VIDEO=" & set "AUDIO=" & set "SUBS=true"
IF /I "%~1"=="--dump"   set "DUMP=true"
IF /I "%~1"=="--loop"   call :loop

IF EXIST "%~1" call :parse_file "%~1"

shift /1
goto :arg_loop

:arg_done
goto :EOF


:detect_node
if defined NODE_PATH goto :EOF
setlocal enabledelayedexpansion
set "FOUND_PATH="
for /f "delims=" %%p in ('where node 2^>nul') do if not defined FOUND_PATH set "FOUND_PATH=%%~dpp"
if not defined FOUND_PATH (
  endlocal
  goto :detect_node_fallback
)
if "!FOUND_PATH:~-1!"=="\" set "FOUND_PATH=!FOUND_PATH:~0,-1!"
set "NODE_PATH=--js-runtimes "node:!FOUND_PATH!""
for /f "delims=" %%v in ("!NODE_PATH!") do endlocal & set "NODE_PATH=%%v"
goto :EOF

:detect_node_fallback
for %%d in (
  "E:\Gitea\nQpuppeteer\nQpuppeteer\x64\node-v24.15.0-win-x64"
  "C:\Program Files\nodejs"
) do if not defined NODE_PATH if exist "%%~d\node.exe" set NODE_PATH=--js-runtimes "node:%%~d"
goto :EOF

:detect_profile
setlocal enabledelayedexpansion
set "FF_DIR=%APPDATA%\Mozilla\Firefox"
set "REL_PATH="
set "CUR_PATH="
set "CUR_DEFAULT=0"
set "IN_INSTALL=0"
if not exist "%FF_DIR%\profiles.ini" goto :dp_done
for /f "usebackq delims=" %%L in ("%FF_DIR%\profiles.ini") do (
  set "line=%%L"
  if "!line:~0,1!"=="[" (
    if "!IN_INSTALL!"=="1" if not defined REL_PATH if defined CUR_PATH set "REL_PATH=!CUR_PATH!"
    set "CUR_PATH="
    set "CUR_DEFAULT=0"
    if /I "!line:~0,8!"=="[Install" (set "IN_INSTALL=1") else (set "IN_INSTALL=0")
  ) else (
    for /f "tokens=1,* delims==" %%a in ("!line!") do (
      if /I "%%a"=="Path" set "CUR_PATH=%%b"
      if /I "%%a"=="Default" (
        if "%%b"=="1" set "CUR_DEFAULT=1"
        set "val=%%b"
        if not "!val:/=!"=="!val!" set "REL_PATH=%%b"
      )
    )
    if "!IN_INSTALL!"=="0" if "!CUR_DEFAULT!"=="1" if not defined REL_PATH if defined CUR_PATH (
      set "REL_PATH=!CUR_PATH!"
      set "CUR_DEFAULT=0"
    )
  )
)
if "!IN_INSTALL!"=="1" if not defined REL_PATH if defined CUR_PATH set "REL_PATH=!CUR_PATH!"
if not defined REL_PATH if defined CUR_PATH if "!CUR_DEFAULT!"=="1" set "REL_PATH=!CUR_PATH!"
:dp_done
if defined REL_PATH (
  if exist "%FF_DIR%\!REL_PATH!" (
    endlocal & set "PROFILE_PATH="%FF_DIR%\%REL_PATH%""
  ) else if exist "!REL_PATH!" (
    endlocal & set "PROFILE_PATH="!REL_PATH!""
  ) else (
    endlocal
  )
) else (
  endlocal
)
goto :EOF

:USAGE
echo %~n0 [options] ^<URL ^| url_list.txt ^| shortcut.url^>
echo %~n0 --video           download only video; *default
echo %~n0 --audio           download only audio; default is auto m4a/mp3
echo %~n0   --mp3             force audio to mp3 (ffmpeg required)
echo %~n0   --m4a             force audio to m4a
echo %~n0 --subs            download /tmp/subs.video_id.en.vtt (only english) and create transcript /tmp/subs.video_id.en.txt
echo %~n0   --dump            also dump transcript to stdout
echo %~n0 --loop            loop over asking for urls one by one
echo %~n0 --update          download latest yt-dlp release from GitHub
echo %~n0 --node    ^<path^>  use node at path for yt-dlp js runtime
echo %~n0 --browser ^<name^>  use browser's cookies; *firefox
echo %~n0   --profile ^<path^>  browser profile path if not default
echo %~n0 -V ^| --verbose    disable quiet mode
echo %~n0 --help            show this help
exit /b 99
goto :EOF


:parse_file file

REM :: file is a Windows shortcut
IF /I "%~x1"==".url" call :parse_shortcut "%~1" "%playlist_urls%"

REM :: file is a text file with urls
IF /I "%~x1"==".txt" findstr /I /B "http" "%~1" >>"%playlist_urls%"

goto :EOF


:parse_url "url"

:: BUG: we cannot process urls with a ? in them so let's treat them first and exit
set "url=%~1"

IF /I NOT "%url:~0,4%"=="http" exit /b 0

:: url is a playlist
IF NOT "%url:playlist?=%"=="%url%" call :extract_url_from_playlist "%url%" "%playlist_urls%" & exit /b 0

:: url is a video - we don't test that because yt-dlp can download anything
REM IF NOT "%url:?=%"=="%url%" echo  "%url%">>"%playlist_urls%" & exit /b 0
echo "%url%" >>"%playlist_urls%"

goto :EOF


:parse_shortcut shortcut playlist_urls
IF NOT EXIST "%~1" echo NOT FOUND: %1 & exit /b 1

pushd "%~sdp1"

for /f "usebackq tokens=1,* delims==" %%a in (`type "%~1"`) DO (
  REM echo IF "%%~a"=="URL" set url=%%b
  REM pause
  IF "%%~a"=="URL" echo "%%~b">>"%~2"
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

echo "%url%" >>"%playlist_urls%"

set answer=y
set /P answer=more? [%answer%] 
IF /I NOT "%answer%"=="y" goto :EOF

goto :loop


:extract_url_from_playlist url playlist_urls

IF DEFINED VERSOSE echo %~sdp0\yt-dlp %QUIET% -x --flat-playlist --print webpage_url %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% %1
%~sdp0\yt-dlp %QUIET% -x --flat-playlist --print webpage_url %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% %1 >"%~2"

goto :EOF


:audio_dl playlist
IF DEFINED VERSOSE echo ---------------------------------- maxAudioQuality=%maxAudioQuality% ----------------------------------
IF DEFINED VERSOSE type "%~1"

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
REM %~sdp0\yt-dlp %QUIET% --list-formats %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% %1


REM if %ext%==m4a %~sdp0\yt-dlp %QUIET% --extract-audio -S aext:m4a:mp3,acodec:aac:mp3   --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file %playlist_urls%
REM if %ext%==mp3 %~sdp0\yt-dlp %QUIET% --extract-audio --audio-format mp3               --audio-quality 0 --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file %playlist_urls%

IF DEFINED VERSOSE echo %~sdp0\yt-dlp %QUIET% --extract-audio %audioFormat% --audio-quality %maxAudioQuality% --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file "%~1" --ffmpeg-location "%ffmpeg_path%"
%~sdp0\yt-dlp %QUIET% --extract-audio %audioFormat% --audio-quality %maxAudioQuality% --no-keep-video --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file "%~1" --ffmpeg-location "%ffmpeg_path%"

goto :EOF


:video_dl playlist
IF DEFINED VERSOSE echo ---------------------------------- maxAudioQuality=%maxAudioQuality% ----------------------------------
type "%~1"

IF DEFINED VERSOSE echo %~sdp0\yt-dlp %QUIET% %videoFormat% -f "bv*[height<=%maxVideoQuality%]+ba/b[height<=%maxVideoQuality%]" --audio-quality %maxAudioQuality% --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file "%~1" --ffmpeg-location "%ffmpeg_path%"
%~sdp0\yt-dlp %QUIET% %videoFormat% -f "bv*[height<=%maxVideoQuality%]+ba/b[height<=%maxVideoQuality%]" --audio-quality %maxAudioQuality% --embed-metadata --embed-thumbnail --add-metadata %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file "%~1" --ffmpeg-location "%ffmpeg_path%"

goto :EOF


:update
echo Updating yt-dlp to latest release...
set "url="
for /f "usebackq delims=" %%u in (`curl -sL https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest ^| jq -r ".assets[] | select(.name==\"yt-dlp.exe\") | .browser_download_url"`) do set "url=%%u"
if not defined url (
  echo ERROR: could not determine latest yt-dlp download URL
  exit /b 1
)
echo Latest release URL: %url%
curl -L -o "%~sdp0yt-dlp.exe.new" "%url%"
if errorlevel 1 (
  del /f /q "%~sdp0yt-dlp.exe.new" >NUL 2>&1
  echo ERROR: download failed
  exit /b 1
)
move /y "%~sdp0yt-dlp.exe.new" "%~sdp0yt-dlp.exe" >NUL
if errorlevel 1 (
  echo ERROR: could not replace yt-dlp.exe
  exit /b 1
)
echo yt-dlp updated successfully.
goto :EOF


:vtt2transcript SUBS_FILE_RAW TRANSCRIPT
echo %*
pause
REM sed -E '
  REM /^[0-9]{2}:[0-9]{2}/d;  # Remove timecode blocks
  REM /^WEBVTT/d;             # Remove file header
  REM /^Kind:/d;              # Remove metadata rows
  REM /^Language:/d;          # Remove language declaration lines
  REM s/<[^>]*>//g;           # Strip word-by-word timing markers and styling tags
REM ' "$FILE_PATH" | awk 'NF' | uniq

where perl >NUL 2>&1 && perl -pe "s/^[0-9]{2}:[0-9]{2}.*\n//g; s/^(WEBVTT|Kind:|Language:).*\n//g; s/<[^>]*>//g" %1 | busybox awk "NF" | busybox uniq > %2 && exit /b
where sd   >NUL 2>&1 && grep -Ev "^[0-9]{2}:[0-9]{2}|^WEBVTT|^Kind:|^Language:" %1 | sd "<[^>]*>" "" | busybox awk "NF" | busybox uniq > %2 && exit /b
busybox sed -E "/^[0-9]{2}:[0-9]{2}/d; /^WEBVTT/d; /^Kind:/d; /^Language:/d; s/<[^>]*>//g" %1 | busybox awk "NF" | busybox uniq > %2 && exit /b

goto :EOF


:subs_dl playlist SUBS_FILENAME lang
set playlist=%1
set SUBS_FILENAME=%2.raw_

IF DEFINED VERSOSE echo playlist=   %playlist%
IF DEFINED VERSOSE echo TRANSCRIPT= %SUBS_FILE%
REM %~sdp0\yt-dlp %QUIET% --skip-download --dump-json --extractor-args "youtube:skip=translated_subs" %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% "https://www.youtube.com/watch?v=jojMVmRZABw" 
REM %~sdp0\yt-dlp %QUIET% --skip-download --dump-json --extractor-args "youtube:skip=translated_subs" %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file "%~1" 
REM %~sdp0\yt-dlp %QUIET% --skip-download --dump-json --extractor-args "youtube:skip=translated_subs" %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file "%~1" | jq -r "(.subtitles.en // .automatic_captions.en)[] | select(.ext == \"vtt\") | .url" | xargs curl -s

:: download vtt with name = subs.raw_9aTRnV6g0eQ.en.vtt
IF DEFINED VERSOSE echo %~sdp0\yt-dlp %QUIET% --skip-download --write-subs --write-auto-subs --sub-langs "%lang%" --extractor-args "youtube:skip=translated_subs" -o "%SUBS_FILENAME%%%(id)s" %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file %1
%~sdp0\yt-dlp %QUIET% --skip-download --write-subs --write-auto-subs --sub-langs "%lang%" --extractor-args "youtube:skip=translated_subs" -o "%SUBS_FILENAME%%%(id)s" %NODE_PATH% --cookies-from-browser %BROWSER%:%PROFILE_PATH% --batch-file %1

:: count number of videos
for /f %%l in ('busybox wc -l ^< yta.playlist.txt') DO set numVideos=%%l
IF %numVideos% GTR 1 exit /b 0

:: Process local files to strip out timecodes, layout tags, and duplicates
setlocal enabledelayedexpansion

for /f %%v in ('type %playlist% ^|  busybox cut -d= -f2') DO (
  REM :: first, get the VIDEO_ID
  set VIDEO_ID=%%v
  set SUBS_FILE_RAW=""
  set TRANSCRIPT=""
  REM :: second, detect the file
  for /f %%f in ('busybox ls "%~2.raw_!VIDEO_ID!.%~3.vtt"') DO set SUBS_FILE_RAW=%%f
  REM :: set TRANSCRIPT file name
  set TRANSCRIPT="%~2.%VIDEO_ID%.%~3.txt"
  REM :: file will not exist if url was a playlist
  IF EXIST !SUBS_FILE_RAW! call :vtt2transcript !SUBS_FILE_RAW! !TRANSCRIPT!
  REM :: and dump the transcript to stdout
  IF DEFINED DUMP IF EXIST !TRANSCRIPT! type !TRANSCRIPT!
)
endlocal

goto :EOF


:end
