@echo off

:: power_download url output [user pass]
set url=%1
set outputFile=%2
set user=%3
set password=%4

IF NOT DEFINED outputFile echo USAGE: %~nx0 url output [user pass]& exit /b
IF EXIST %outputFile% del /q %outputFile% 2>NUL
IF EXIST wget.exe set wget=wget.exe
IF DEFINED wget (
  wget --no-check-certificate %url% -O %outputFile% --user=%user% --password=%password% 2>&1 | findstr /C:saved
) ELSE (
  powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile('%url%','%outputFile%')}"
)
