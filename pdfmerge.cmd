@echo OFF
setlocal
setlocal ENABLEEXTENSIONS
setlocal ENABLEDELAYEDEXPANSION
REM set VERBOSE=true
REM set DEBUG=true
set DEMO=
call :set_colors

:: pattern examples: "*", "*" "sep" "n", "n" "sep" "*"
set USAGE=%HIGH%%r%Usage: %c%%~n0 [-v^^^|-d]^^^<^^^*^^^> ^^^| ^^^<^^^*^^^|n separator n^^^|^^^*^^^>%END%
IF [%1]==[] echo %USAGE% & echo. & pause & exit /b

IF [%1]==[-v] set VERBOSE=true & shift /1
IF [%1]==[-d] set DEBUG=true & shift /1
IF [%1]==[-v] set VERBOSE=true & shift /1
IF DEFINED DEBUG set VERBOSE=true & set PAUSE=pause

set pattern1=%~1
set separator=%~2
set pattern2=%~3

:: parameters tests
IF [%1]==[] echo %USAGE% & echo. & pause & exit /b
IF [%pattern1%]==[*] IF [%2]==[] goto :main
:: from now on, there should be 3 parameters
IF [%pattern2%]==[] echo %USAGE% & echo. & pause & exit /b
IF /I [%pattern1%]==[*] IF /I NOT [%pattern2%]==[n] echo %USAGE% & echo. & pause & exit /b
IF /I [%pattern1%]==[n] IF /I NOT [%pattern2%]==[*] echo %USAGE% & echo. & pause & exit /b

::::::::::::::::::::::::::::::::::::::
:main
:: pre-checks
for /f %%a in ('dir /b /a-d *%separator%*.pdf ^| find /v /c "::"') do set numFiles=%%a
IF %numFiles% LSS 2 echo ERROR: this works for 2+ files & pause * exit /b 99

echo %c%Merging %numFiles% files ...%END%
%PAUSE%

:: IF pattern2 empty means pattern1==* therefore files are sorted alphabetical
IF DEFINED DEBUG IF [%pattern2%]==[] (echo %m%call :oneshot%END%) ELSE (echo %m%call :pattern%END%)
%PAUSE%
IF [%pattern2%]==[] (call :oneshot) ELSE (call :pattern)

goto :end
::::::::::::::::::::::::::::::::::::::

:set_colors
set END=[0m
set HIGH=[1m
set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m
goto :EOF

:oneshot
set pdfname=%numFiles%-ordered
IF DEFINED VERBOSE echo %y%pdftk *.pdf cat output %pdfname%.pdf%END%
%PAUSE%
pdftk *.pdf cat output %pdfname%.pdf
goto :EOF


:pattern
set pdfname=%numFiles%-pattern

:: files from 1 to 9
IF /I [%pattern1%]==[*] (set pattern2=?) ELSE (set pattern1=?)
IF DEFINED VERBOSE echo %y%IF %numFiles% GTR 1 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-1.pdf%END%
%PAUSE%
IF %numFiles% GTR 1 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-1.pdf

:: files from 10 to 99
IF /I [%pattern1%]==[*] (set pattern2=??) ELSE (set pattern1=??)
IF DEFINED VERBOSE echo %y%IF %numFiles% GEQ 10 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-2.pdf%END%
%PAUSE%
IF %numFiles% GEQ 10 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-2.pdf

:: files from 100 to 999
IF /I [%pattern1%]==[*] (set pattern2=???) ELSE (set pattern1=???)
IF DEFINED VERBOSE echo %y%IF %numFiles% GEQ 100 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-3.pdf%END%
%PAUSE%
IF %numFiles% GEQ 100 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-3.pdf

:: files from 1000 to 9999
IF /I [%pattern1%]==[*] (set pattern2=????) ELSE (set pattern1=????)
IF DEFINED VERBOSE echo %y%IF %numFiles% GEQ 1000 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-4.pdf%END%
%PAUSE%
IF %numFiles% GEQ 1000 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-4.pdf

echo %c%Assemble temporary files ...%END%
IF DEFINED DEBUG echo[%m% & dir /b pattern-?.pdf & echo[%END%
%PAUSE%
pdftk pattern-?.pdf cat output %pdfname%.pdf 2>NUL

echo %c%Delete temporary files ...%END%
del /f /q pattern-?.pdf 2>NUL

goto :EOF


:1by1-OFF
set pdfname=%numFiles%-1by1
:: https://stackoverflow.com/questions/3018289/xcopy-file-rename-suppress-does-xxx-specify-a-file-name-message
echo]>1.pdf
IF DEFINED VERBOSE %y%echo xcopy /y *_1.pdf 1.pdf%END%
IF NOT DEFINED DEMO xcopy /y *_1.pdf 1.pdf >NUL 2>NUL

for /L %%a in (2,1,%numFiles%) DO (
  set /a prev=%%a-1
  IF DEFINED VERBOSE %y%echo pdftk !prev!.pdf *_%%a.pdf cat output %%a.pdf%END%
  IF NOT DEFINED DEMO pdftk !prev!.pdf *_%%a.pdf cat output %%a.pdf
  IF DEFINED VERBOSE %y%echo del /q !prev!.pdf%END%
  IF NOT DEFINED DEMO del /q !prev!.pdf
  %PAUSE%
)
move /y %numFiles%.pdf %pdfname%.pdf
goto :EOF


:end
echo %c%Merging %numFiles% files ... %g%OK: %pdfname%.pdf%END%
endlocal
