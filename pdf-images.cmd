@echo OFF
IF "%~1"=="" echo %~n0 ^<PDF^> & exit /b 99
pdfimages.exe -j -list %1 %1
