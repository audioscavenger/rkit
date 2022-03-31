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
IF %numFiles% LSS 2 echo %r%ERROR: this works for 2+ files%END% & pause * exit /b 99

::::::::::::: USE CASES ::::::::::::::
%PAUSE%
:: all files in alphabetical order? oneshot
IF [%pattern2%]==[] call :oneshot & goto :end

:: file names start with the number: pattern
IF [%pattern1%]==[n] call :pattern & goto :end

:: all files have the same name, just the end number differs: pattern
:: all files have different name, and the end number differs: 1by1
:: -> get name of the first file:
for /f "tokens=1 delims=%separator%" %%a in ('dir /b *%separator%1.pdf') DO set firstName=%%a
:: -> IF numFilesByName = numFiles then all files have same name: pattern
for /f %%a in ('dir /b /a-d %firstName%%separator%*.pdf ^| find /v /c "::"') do set numFilesByName=%%a

IF %numFilesByName% EQU %numFiles% (call :pattern) ELSE (call :1by1)

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
echo %b%%DATE% %TIME% %c%Merging %numFiles% files%END% Using oneshot: ultra fast
%PAUSE%

set pdfname=%numFiles%-ordered
IF DEFINED VERBOSE echo %y%pdftk *.pdf cat output %pdfname%.pdf%END%
%PAUSE%
pdftk *.pdf cat output %pdfname%.pdf
goto :EOF


:pattern
echo %b%%DATE% %TIME% %c%Merging %numFiles% files%END% Using pattern: fast
%PAUSE%

:: this procedure works only when files are all named the same: guid_nn.pdf for example
:: if the file names are all different just like files in Processing\ folder, 1by1 should be used instead
set pdfname=%numFiles%-pattern

:: BUG: for MSDOS, "?" means 1 or 0 character. that's a problem because ?? means 2 characters, or 1 or 0
:: Therefore pattern1=???? will also collect ?, ?? and ??? files

:: files from 1 to 9
IF /I [%pattern1%]==[*] (set pattern2=?) ELSE (set pattern1=?)
IF DEFINED VERBOSE echo %y%IF %numFiles% GTR 1 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-1.pdf%END%
%PAUSE%
IF %numFiles% GTR 1 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-1.pdf
IF EXIST pattern-1.pdf md pattern-1 & move /y %pattern1%%separator%%pattern2%.pdf pattern-1\ >NUL 2>NUL

:: files from 10 to 99
IF /I [%pattern1%]==[*] (set pattern2=??) ELSE (set pattern1=??)
IF DEFINED VERBOSE echo %y%IF %numFiles% GEQ 10 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-2.pdf%END%
%PAUSE%
IF %numFiles% GEQ 10 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-2.pdf
IF EXIST pattern-2.pdf md pattern-2 & move /y %pattern1%%separator%%pattern2%.pdf pattern-1\ >NUL 2>NUL

:: files from 100 to 999
IF /I [%pattern1%]==[*] (set pattern2=???) ELSE (set pattern1=???)
IF DEFINED VERBOSE echo %y%IF %numFiles% GEQ 100 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-3.pdf%END%
%PAUSE%
IF %numFiles% GEQ 100 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-3.pdf
IF EXIST pattern-3.pdf md pattern-3 & move /y %pattern1%%separator%%pattern2%.pdf pattern-1\ >NUL 2>NUL

:: files from 1000 to 9999
IF /I [%pattern1%]==[*] (set pattern2=????) ELSE (set pattern1=????)
IF DEFINED VERBOSE echo %y%IF %numFiles% GEQ 1000 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-4.pdf%END%
%PAUSE%
IF %numFiles% GEQ 1000 pdftk %pattern1%%separator%%pattern2%.pdf cat output pattern-4.pdf
IF EXIST pattern-4.pdf md pattern-4 & move /y %pattern1%%separator%%pattern2%.pdf pattern-1\ >NUL 2>NUL

echo %c%Assemble temporary files ...%END%
IF DEFINED DEBUG echo[%m% & dir /b pattern-?.pdf & echo[%END%
%PAUSE%
pdftk pattern-?.pdf cat output %pdfname%.pdf 2>NUL

echo %c%Move files back to root ...%END%
for /L %%a in (1,1,4) DO (
  move /y pattern-%%a\* .\ >NUL 2>NUL
  rd /q pattern-%%a 2>NUL
)

echo %c%Delete temporary files ...%END%
del /f /q pattern-?.pdf 2>NUL

goto :EOF


:1by1
echo %b%%DATE% %TIME% %c%Merging %numFiles% files%END% Using 1by1: ultra slow
%PAUSE%

:: this procedure is really slow but necessary when file names are all different and just the file number can order them
set pdfname=%numFiles%-1by1
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: https://stackoverflow.com/questions/3018289/xcopy-file-rename-suppress-does-xxx-specify-a-file-name-message
IF DEFINED VERBOSE %y%echo echo]^>1.pdf ^& xcopy /y *_1.pdf 1.pdf%END%
IF NOT DEFINED DEMO echo]>1.pdf & xcopy /y *_1.pdf 1.pdf >NUL 2>NUL

for /L %%a in (2,1,%numFiles%) DO (
  set /a prev=%%a-1
  IF DEFINED VERBOSE %y%echo pdftk *%separator%!prev!.pdf *%separator%%%a.pdf cat output %%a.pdf%END%
  IF NOT DEFINED DEMO pdftk *%separator%!prev!.pdf *%separator%%%a.pdf cat output %%a.pdf
  IF DEFINED VERBOSE %y%echo del /q !prev!.pdf%END%
  IF NOT DEFINED DEMO del /q !prev!.pdf
  set /a modulo=%%a %% 100
  IF !modulo! EQU 0 echo %DATE% %TIME%         %%a files done...
  %PAUSE%
)
move /y %numFiles%.pdf %pdfname%.pdf
goto :EOF


:end
echo %b%%DATE% %TIME% %c%Merging %numFiles% files ... %g%OK: %pdfname%.pdf%END%
endlocal
