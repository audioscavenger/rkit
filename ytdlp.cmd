@echo OFF
pushd "%~dp0"
setlocal

IF "%~1"=="" (
  echo %~n0 ^<URL^> [ --no-playlist ]
  exit /b 99
)

yt-dlp %1 -x --audio-format m4a --no-keep-video --embed-metadata

