@echo off

:: power_download url output [user pass]
set url=%1
set file=%2
set user=%3
set password=%4
for %%x in (wget.exe) do (set wget=%%~$PATH:x)
IF EXIST .\wget.exe set wget=.\wget.exe

IF NOT DEFINED file echo USAGE: %~nx0 url output [user pass]& exit /b
IF EXIST %file% del /q %file% 2>NUL
IF DEFINED wget (
  wget %url% -O %file% --user=%user% --password=%password% 2>&1 | findstr /C:saved
) ELSE (
  powershell -executionPolicy bypass -Command "&{$client = new-object System.Net.WebClient ; $client.DownloadFile('%url%','%file%')}"
)
