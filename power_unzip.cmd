@echo off

:: power_unzip archive filter del
set file=%1
set filter=%2
set del=%3
IF NOT DEFINED filter echo USAGE: %~nx0 archive filter del& exit /b
IF NOT EXIST %file% echo USAGE: %~nx0 archive filter del& exit /b

powershell -executionPolicy bypass -Command "&{Add-Type -AssemblyName System.IO.Compression.FileSystem ; $Filter = '%filter%' ; $zip = [System.IO.Compression.ZipFile]::OpenRead('%file%') ; $zip.Entries | Where-Object { $_.Name -like $Filter } | ForEach-Object { $FileName = $_.Name ; [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$FileName", $true)} }"
IF NOT [%del%]==[keep] del /q %file% 2>NUL

