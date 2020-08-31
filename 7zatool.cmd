@echo OFF
REM pushd "%~dp0"                           NOT FOR SYSTEM-WIDE SCRIPTS
setlocal
REM setlocal enabledelayedexpansion         SHOULD NEVER BE THE DEFAULT
verify on

:top
chcp 65001 >NUL

:: DEMO=["", echo]
REM set DEMO=echo

:: DEBUG=["", -D]
REM set DEBUG=-D

:: VERBOSE=["", -V]
REM set VERBOSE=-V

:: PAUSE=[echo:^>NUL, pause 1>&2]
set PAUSE=echo:^>NUL
REM set PAUSE=pause 1>&2

:: BREAK=["", true]
set BREAK=

::-----------------------------------------------------------------------------------
:: 1.1  accomodate special chars
:: 1.2  default compression level is 5, among 1,3,5,7,9
:: 2.0  multithreads
:: 2.1  switch to UTF-8 handling
:: 2.2  archives excluded when zipping "*"
:: 2.3  revamped arguments a little bit to make consistent
::-----------------------------------------------------------------------------------
:: TODO LIST:
:: - autokill thread when parent is killed?
:: - deal with multiple EXT?
:: - deal with already zipped files and REzip them when using "*" with parameter -R
:: - must add 7z -mmt1 when using cmd affinity
:: - must add cmd affinity option although it's useless
:: 2.x  added -R switch to FIRCE REzip already zipped files
::-----------------------------------------------------------------------------------
:: Ce batch est a utiliser dans le shell avec un clic droit sur UN fichier => SendTo
:: 2 MODES de fonctionnement : 
::  1BY1    = extrait les archives puis rezip chaque fichier independamment
::  GROUPED = extrait les archives puis rezip les archives de façon identique
::-----------------------------------------------------------------------------------
:: EXEMPLES :
::-----------------------------------------------------------------------------------
:: 1) clic droit sur un type de fichier autre que ".zip"
::  => ZIP chaque fichier + repertoire du repertoire en cours en ".EXT_ZIP"
:: 2) clic droit sur un fichier ".zip"
::  => REZIP chaque fichier ".zip" en ".EXT_ZIP"
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: => Pour debuguer, commenter le @echo OFF
:: => Pour tester si ça marche, mettre ci-dessous DEMO=echo
:: => Pour le mode VERBOSE (plus d'affichage) vider la variable VERBOSE (VERBOSE="")
:: => Pour changer de MODE, (Default=1By1) mettre MODE=[1BY1, GROUPED]
:: => Pour changer de format d'archive, changer TYPE=[zip, 7z, LZMA, Bzip2, gzip]
:: => Mettez le nombre de Threads nbThreads= correspondant à votre machine
:: => Pour changer le LEVEL de compression mettre LEVEL=[1-9] (9 = le plus fort)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: M.2 drive - %TEMP% same drive + affinity: ----------------------------------------
REM zip.zip.5: 194 files / 6 threads = 20 seconds = 103 ms/file = 12 mB/s
REM zip.zip.5: 194 files / 5 threads = 19 seconds = 101 ms/file = 13 mB/s
REM zip.zip.5: 194 files / 4 threads = 21 seconds = 108 ms/file = 12 mB/s
REM zip.zip.5: 194 files / 3 threads = 26 seconds = 134 ms/file = 9 mB/s
REM zip.zip.5: 194 files / 2 threads = 26 seconds = 134 ms/file = 9 mB/s
REM zip.zip.5: 194 files / 1 threads = 43 seconds = 226 ms/file = 5 mB/s
:: M.2 drive - %TEMP% same drive - no affinity: -------------------------------------
REM zip.zip.5: 194 files / 6 threads = 16 seconds =  82 ms/file = 15 mB/s - 100% cpu
REM zip.zip.5: 194 files / 5 threads = 15 seconds =  77 ms/file = 16 mB/s - 90% cpu
REM zip.zip.5: 194 files / 4 threads = 15 seconds =  77 ms/file = 16 mB/s - 75% cpu
REM zip.zip.5: 194 files / 3 threads = 18 seconds =  92 ms/file = 13 mB/s - 55% cpu
REM zip.zip.5: 194 files / 2 threads = 25 seconds = 129 ms/file = 10 mB/s - 35% cpu
REM zip.zip.5: 194 files / 1 threads = 41 seconds = 215 ms/file = 6 mB/s - 25% cpu
:: 5400rpm drive - %TEMP% other drive - no affinity: --------------------------------
REM zip.zip.5: 194 files / 5 threads = 14 seconds = 72 ms/file = 17 mB/s - 90% cpu
::-----------------------------------------------------------------------------------
:: Overhead calculation with 1 thread:
REM get_timelapse start & (for %a in (*) DO 7z a -y -bd -tzip -mx5 -sdel -sse "%a.zip" "%a" >NUL) & get_timelapse
REM zip.zip.5: 194 files / 135 MB / 1 threads = 28 seconds = 144 ms/file = 5 mB/s
:: Overhead estimation for 1 thread + affinity: (28-43)/28 = -53% = half slower
:: Overhead estimation for 1 thread - affinity: (28-41)/28 = -46% = half slower
:: Overhead estimation for 5 thread - affinity: (28-15)/28 = +46% = twice faster
:: Overhead disappears with 2 threads
:: Gains observed at (NUMBER_OF_PROCESSORS - 2 or 3)!
:: Gains lost when using all cores
::-----------------------------------------------------------------------------------
::-----------------------------------------------------------------------------------

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:defaults
set "EXT=*"
:: MODE=[1BY1, GROUPED]
set MODE=1BY1
:: TYPE=[zip,7z]
set TYPE=zip
:: caracteres interdits lors du rezip - inside zipfile or in filename
set FORBIDDEN_CHARS="\%%|\^"

set FUNCTION=ZIP
set WORKFOLDER=.
:: set LEVEL=[0 | 1 | 3 | 5 | 7 | 9 ]
set LEVEL=5
set INCLUDE_SUBREP=n
set EXCLUDE_ZIPPED=true
set splitPREFIX=____
set nbThreadsDefault=2


:init
call :reset METHOD threadNum listFiles TIMESTART TIMEEND threadLogs USAGE zipEXT SUBREP totalBytes nbFicsThread nbFicsTotal nbThreads archiveEXTonly
set archiveEXT=001-9 7z-0 arj-4 bz2-2 bzip2-2 cab-7 cpio-12 deb-11 dmg-17 fat-21 gz-14 gzip-14 hfs-18 lha-6 lzh-6 lzma-16 rar-3 rpm-10 squashfs-24 swm-15 tar-13 taz-5 tbz-2 tbz2-2 tgz-14 tpz-14 txz-23 wim-15 xar-19 xz-23 z-5 zip-1
set zip.METHODS=Copy,Deflate,Deflate64,BZip2,LZMA,PPMd
set zip.METHOD=Deflate
set zip.zipEXT=zip
set 7z.METHODS=LZMA,LZMA2,PPMd,BZip2,Deflate,Delta,BCJ,BCJ2,Copy
set 7z.METHOD=LZMA2
set 7z.zipEXT=7z

call :detect_admin_mode >NUL
call :set_colors

IF DEFINED DEBUG call :DEBUG before arguments
call :arguments %* || goto :end
IF DEFINED DEBUG call :DEBUG after arguments

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::



:: at this point, %1 is still the fic/folder passed in arguments
:prechecks
IF DEFINED threadNum IF NOT DEFINED listFiles call :error Parameter -l listFiles is mandatory with -t threadNum || goto :end
IF DEFINED threadNum IF NOT DEFINED EXT call :error Which EXTention to zip? use -e EXT || goto :end

REM set "EXT=%EXT: =%"
IF NOT DEFINED EXT call :whichExtension

IF /I "%WORKFOLDER%"=="%CD%"  set "WORKFOLDER=."
IF /I "%WORKFOLDER%"=="%CD%\" set "WORKFOLDER=."

call :detectCpuThreads

:: TYPE -> extension + METHOD
call set "zipEXT=%%%TYPE%.zipEXT%%"
IF NOT DEFINED zipEXT call :error archive TYPE=%TYPE% is not supported & exit /b 1

IF NOT DEFINED METHOD call set "METHOD=%%%TYPE%.METHOD%%"
IF DEFINED DEBUG echo METHOD=%METHOD%

call set isMethodCompatible=%%%TYPE%.METHODS:%METHOD%=COMPATIBLE%%
echo %isMethodCompatible% | findstr COMPATIBLE >NUL || (echo call :error METHOD=%METHOD% is incompatible with %TYPE% archives & echo exit /b 1)

:: FORCE_LONE_FICS=[true, ""]
:: VALIDE pour : REZIP + pas de changement d'extentions
:: Permet de forcer le rezip d'archives qui ne contiennent qu'un seul fichier
if /I "%MODE%"=="1BY1" set FORCE_LONE_FICS=true
if /I NOT "%EXT%"=="%zipEXT%" set FORCE_LONE_FICS=true
echo %archiveEXT% | findstr "%EXT%-" >NUL && set FUNCTION=REZIP

call :detect_sevenZip

:: https://sevenzip.osdn.jp/chm/cmdline/switches/method.htm ::::::::::::::::::::::::::::::::::::::::::
:: we now use one window per thread with cpu affinity so the 7z commands must reflect that
:: + must add -mmt1 when using cmd affinity
set commandZIP=%sevenZip% a -y -bd -t%zipEXT% -mm=%METHOD% -mx%LEVEL% -sdel -sse -sccUTF-8 -scsUTF-8 -- 
set UNZIP=%sevenZip% e -y -bd -o"%WORKFOLDER%\tmp"
set LISTZIP=%sevenZip% l -bd
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::set UNZIP_MASK="\"C:\\Program Files\\7-Zip\\7z.exe\" a -y"
pushd "%WORKFOLDER%"
set CURRENTBATCH=%~n0
set LISTE=%TEMP%\%CURRENTBATCH%_liste.%RANDOM%.txt
set LISTE_KO="%WORKFOLDER%\%CURRENTBATCH%.liste.KO.txt"
set LISTE_TMP=%TEMP%\%CURRENTBATCH%_liste.%RANDOM%.tmp.txt
IF DEFINED threadNum (
  set LOG="%WORKFOLDER%\%CURRENTBATCH%.out.%threadNum%.log"
  set ERRORS="%WORKFOLDER%\%CURRENTBATCH%.err.%threadNum%.log"
) ELSE (
  set LOG="%WORKFOLDER%\%CURRENTBATCH%.out.log"
  set ERRORS="%WORKFOLDER%\%CURRENTBATCH%.err.log"
)
set LOGG=tee -a %LOG% 1>&2
set LOGR=tee -a %ERRORS% 1>&2

set nbFicsTotal=0
set totalBytes=0
set nbFicsThread=0
set NbOldFic=0
set nbNewArch=0
set NbNewFic=0
set NbKO=0
set H0=%DATE% %TIME%


:autorun
IF DEFINED DEBUG call :DEBUG :autorun

::  ____  _             _     _____ _                        _          __  __
:: / ___|| |_ __ _ _ __| |_  |_   _| |__  _ __ ___  __ _  __| |         \ \/ /_
:: \___ \| __/ _` | '__| __|   | | | '_ \| '__/ _ \/ _` |/ _` |          \  /(_)
::  ___) | || (_| | |  | |_    | | | | | | | |  __/ (_| | (_| |          /  \ _
:: |____/ \__\__,_|_|   \__|   |_| |_| |_|_|  \___|\__,_|\__,_|  _____  /_/\_(_)
::                                                              |_____|
IF DEFINED threadNum call :zipFileThread %listFiles% %zipEXT% && exit /b 0 || exit /b %NbKO%
::  _____ _____ _____ _____ _____ _____ _____ _____ _____ _____ 
:: |_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main
title %~n0.0
IF DEFINED DEBUG echo %m%DEBUG:                    THIS IS MAIN BATCH %END% 1>&2

REM call :psResize "%~n0.0" 80 0 800 600 >NUL 2>&1
call :cmdowMove "%~n0.0" 80 0 800 600 >NUL 2>&1
:: cleanup previous windows
call :cleanupLogs
call :cleanupThreads

IF DEFINED DEBUG echo %m%DEBUG: call :%FUNCTION% %END% 1>&2
%PAUSE%
call :%FUNCTION%

REM timeout /t 60
goto :end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:arguments %*
IF DEFINED DEBUG echo %m%DEBUG: %~0 %HIGH%%* %END% 1>&2

IF "%~1"=="" set "USAGE=true" & exit /b 99

call :isFile %1 && set "WORKFOLDER=%~dp1" || set "WORKFOLDER=%~1"
call :isFile %1 set "EXT=%~x1" && set "EXT=%EXT:~1"

for %%a in (%*) DO (
  REM :: arguments separated by ,;= (comma/semicolon/equal) count as separator
  REM :: official solution is to escape them with double quotes: "a,b,c"
  
  REM :: TODO: handle multiple EXT
  REM IF [%%a]==[-e] call set "EXT=%%EXT%% %%~2"
  IF [%%a]==[-h]      set "USAGE=true" & exit /b 99
  IF [%%a]==[--help]  set "USAGE=true" & exit /b 99
  
  IF [%%a]==[-e] call set "EXT=%%~2"
  IF [%%a]==[-z] call set "TYPE=%%~2"
  IF [%%a]==[-m] call set "METHOD=%%~2"
  IF [%%a]==[-t] call set "threadNum=%%~2" & call title %~n0.%%~2
  IF [%%a]==[-l] call set "listFiles=%%~2"
  IF [%%a]==[-n] call set "nbThreads=%%~2"
  IF [%%a]==[-R]      set "EXCLUDE_ZIPPED="

  IF [%%a]==[-T] set DEMO=echo
  IF [%%a]==[-D] set "DEBUG=-D" & set "VERBOSE=-V"
  IF [%%a]==[-P] set PAUSE=pause
  IF [%%a]==[-V] IF DEFINED VERBOSE (set VERBOSE=) ELSE set VERBOSE=-V

  shift /1
)
exit /b 0
goto :EOF


:USAGE
   echo usage: %~n0%HIGH%%c% ^<folder^|file^> [arguments] %END%
   echo usage: %~n0%c% -h --help                    %w%USAGE
echo %k%usage: %~n0%c% -e EXT [-e ..]               %w%Extensions to zip ^(default=*^)
echo %k%usage: %~n0%c% -z TYPE                      %w%Archive TYPE among %HIGH%%c%zip,7z%END%
echo %k%usage: %~n0%c% -m METHOD                    %w%Compression METHOD among %HIGH%%c%LZMA2,PPMd,BZip2,Deflate,Copy,etc...%END%
echo %k%usage: %~n0%c% -t threadNum                 %w%threadNum to run - MUST come with -l
echo %k%usage: %~n0%c% -n nbThreads                 %w%FORCE using nbThreads ^(default = nbCores - 1 ^)
echo %k%usage: %~n0%c% -l listFiles                 %w%listFiles to zip
echo %k%usage: %~n0%c% -T                           %w%DEMO mode
echo %k%usage: %~n0%c% -D                           %w%invert DEBUG   mode ^(OFF*^)
echo %k%usage: %~n0%c% -V                           %w%invert VERBOSE mode ^(ON*^)
echo %k%usage: %~n0%c% -P                           %w%PAUSE
echo.%END%
echo EXAMPLES:
echo %k%usage: %~n0%c%                              %w%ZIP %WORKFOLDER%\*.%EXT%  into %TYPE% files
echo %k%usage: %~n0%c% -z 7z                        %w%ZIP %WORKFOLDER%\*.%EXT%  into 7z  files
echo %k%usage: %~n0%c% -z zip -e md                 %w%ZIP %WORKFOLDER%\*.md into 7z  files
echo.%END%
goto :EOF


:whichExtension
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2

IF NOT DEFINED EXT set /P EXT=EXTension to rezip? [%EXT%] 
set /P INCLUDE_SUBREP=Include subrep? [N/y] 

IF NOT DEFINED EXT set "EXT=*"
if /I "%INCLUDE_SUBREP%"=="y" set SUBREP=SUBREP
goto :EOF


:buildFileList EXT
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2

:: count files and get total size
for /F "tokens=1,3" %%a in ('dir /a:-d *.%~1 ^| findstr /C:" File"') DO set "nbFicsTotal=%%a" && set "totalBytes=%%b"


set "totalBytes=%totalBytes:,=%"

:: get file list in %LISTE% as well
REM dir /b /a:-d *.%EXT% | egrep -v %FORBIDDEN_CHARS% >%LISTE%
dir /b /a:-d *.%EXT% >%LISTE%

goto :EOF


:ZIP
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
chcp 65001 >NUL

call :buildFileList "%EXT%"

REM for /F %%x in ('wc -l %LISTE%') do set nbFicsTotal=%%x
set /A nbFicsTotalSplit=1+(nbFicsTotal/nbThreads)

IF DEFINED DEBUG echo %m%DEBUG: %END%split -l %nbFicsTotalSplit% %LISTE% %splitPREFIX%
split -l %nbFicsTotalSplit% %LISTE% %splitPREFIX%

IF DEFINED DEBUG call :DEBUG :log_header ZIP
call :log_header ZIP

REM for /F "tokens=*" %%F in (%LISTE%) do call :zipFile "%%~nF.%zipEXT%" "%%F"
REM for %%F in (*.%EXT%) do call :zipFile "%%~nF.%zipEXT%" "%%F"

:: pyfiglet -f doh Start
::    SSSSSSSSSSSSSSS      tttt                                                        tttt  
::  SS:::::::::::::::S  ttt:::t                                                     ttt:::t
:: S:::::SSSSSS::::::S  t:::::t                                                     t:::::t
:: S:::::S     SSSSSSS  t:::::t                                                     t:::::t
:: S:::::S        ttttttt:::::ttttttt      aaaaaaaaaaaaa  rrrrr   rrrrrrrrr   ttttttt:::::ttttttt
:: S:::::S        t:::::::::::::::::t      a::::::::::::a r::::rrr:::::::::r  t:::::::::::::::::t
::  S::::SSSS     t:::::::::::::::::t      aaaaaaaaa:::::ar:::::::::::::::::r t:::::::::::::::::t
::   SS::::::SSSSStttttt:::::::tttttt               a::::arr::::::rrrrr::::::rtttttt:::::::tttttt
::     SSS::::::::SS    t:::::t              aaaaaaa:::::a r:::::r     r:::::r      t:::::t
::        SSSSSS::::S   t:::::t            aa::::::::::::a r:::::r     rrrrrrr      t:::::t
::             S:::::S  t:::::t           a::::aaaa::::::a r:::::r                  t:::::t
::             S:::::S  t:::::t    tttttta::::a    a:::::a r:::::r                  t:::::t    tttttt
:: SSSSSSS     S:::::S  t::::::tttt:::::ta::::a    a:::::a r:::::r                  t::::::tttt:::::t
:: S::::::SSSSSS:::::S  tt::::::::::::::ta:::::aaaa::::::a r:::::r                  tt::::::::::::::t
:: S:::::::::::::::SS     tt:::::::::::tt a::::::::::aa:::ar:::::r                    tt:::::::::::tt
::  SSSSSSSSSSSSSSS         ttttttttttt    aaaaaaaaaa  aaaarrrrrrr                      ttttttttttt
set TIMESTART=%TIME%

for /L %%n in (1,1,%nbThreads%) DO call :startThread %%n
%PAUSE%

:: INFO: BUG: busybox tail will show colors BUT it CANNOT resolve patterns with * or whatever
REM busybox tail -q -f "%WORKFOLDER%\%CURRENTBATCH%.out.*.log" "%WORKFOLDER%\%CURRENTBATCH%.err.*.log" 1>&2
for /L %%n in (1,1,%nbThreads%) DO call set threadLogs=%%threadLogs%% "%WORKFOLDER%\%CURRENTBATCH%.out.%%n.log"

:: cannot follow logs!!! the batch would never end...
REM busybox tail -q -f %threadLogs% 1>&2
call :loopForCompletion
echo.

for /F %%k in ('wc -l "%WORKFOLDER%\%CURRENTBATCH%.err.*.log" 2^>NUL') DO set NbKO=%%k
set /A nbNewArch=%nbFicsTotal%-%NbKO%

for /F %%a in ('call get_timelapse %TIMESTART% %TIME% -ms 2^>NUL') DO set /A totalms=%%a

:: pyfiglet -f doh End
::                                                     dddddddd
:: EEEEEEEEEEEEEEEEEEEEEE                              d::::::d
:: E::::::::::::::::::::E                              d::::::d
:: E::::::::::::::::::::E                              d::::::d
:: EE::::::EEEEEEEEE::::E                              d:::::d
::   E:::::E       EEEEEEnnnn  nnnnnnnn        ddddddddd:::::d
::   E:::::E             n:::nn::::::::nn    dd::::::::::::::d
::   E::::::EEEEEEEEEE   n::::::::::::::nn  d::::::::::::::::d
::   E:::::::::::::::E   nn:::::::::::::::nd:::::::ddddd:::::d
::   E:::::::::::::::E     n:::::nnnn:::::nd::::::d    d:::::d
::   E::::::EEEEEEEEEE     n::::n    n::::nd:::::d     d:::::d
::   E:::::E               n::::n    n::::nd:::::d     d:::::d
::   E:::::E       EEEEEE  n::::n    n::::nd:::::d     d:::::d
:: EE::::::EEEEEEEE:::::E  n::::n    n::::nd::::::ddddd::::::dd
:: E::::::::::::::::::::E  n::::n    n::::n d:::::::::::::::::d
:: E::::::::::::::::::::E  n::::n    n::::n  d:::::::::ddd::::d
:: EEEEEEEEEEEEEEEEEEEEEE  nnnnnn    nnnnnn   ddddddddd   ddddd
goto :EOF


:startThread threadNum
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
set threadNum=%1
set thisThread=0

setlocal enabledelayedexpansion
for %%F in (%splitPREFIX%*) DO (
  set /A thisThread+=1
  IF !thisThread! EQU %threadNum% set thisList=%%F
)
setlocal disabledelayedexpansion
IF DEFINED DEBUG echo DEBUG: thisList=%thisList%

REM for /F "tokens=*" %%F in (%thisList%) do call :zipFile "%%~nF.%zipEXT%" "%%F"

:: BUG: cmd /C will keep the forced title but window may close when cmdow is invoked
:: BUG: /T:color works only with /K not /C
:: this gets killed by cmdow when moving:
REM start "%~n0.%threadNum%" /NEWWINDOW /affinity %threadNum% cmd /T:20 /S /K "timeout /t 60"
:: this doesn't work as the window title changes
REM start "%~n0.%threadNum%" /NEWWINDOW /affinity %threadNum% cmd /T:20 /K pause
:: this is impossible, what we need to do is call back this script with specific parameters
REM start "%~n0.%threadNum%" /NEWWINDOW /affinity %threadNum% cmd /T:20 /S /C for /F "tokens=*" %%F in (%thisList%) do call :zipFile "%%~nF.%zipEXT%" "%%F"

:: INFO: BUG: * even when escaped, will be resolved to * files in current folder at some point
IF "%EXT%"=="*" (set EXTension=) ELSE set "EXTension=-e %EXT%"
:: INFO: BUG: cannot modify a variable inline
IF DEFINED DEMO set "DEMOMODE=%DEMO:echo=-T%"

:: threads will not close when done: /K - threads will auto close when done: /C
REM set cmdOPTION=/T:20 /K
REM set cmdOPTION=/K
set cmdOPTION=/C
IF DEFINED DEBUG set cmdOPTION=/K

echo starting child "%~n0.%threadNum%"...
IF DEFINED DEBUG echo DEBUG: start "%~n0.%threadNum%" /I /NEWWINDOW /affinity %threadNum% cmd %cmdOPTION% "%~dpnx0" %WORKFOLDER% %DEMOMODE% %VERBOSE% %DEBUG% %EXTension% -z %TYPE% -t %threadNum% -l %thisList%
%PAUSE%
start "%~n0.%threadNum%" /NEWWINDOW /I cmd %cmdOPTION% "%~dpnx0" %WORKFOLDER% %DEMOMODE% %VERBOSE% %DEBUG% %EXTension% -z %TYPE% -t %threadNum% -l %thisList%

REM :cmdowMoveChild parentWindowTitle windowTitle left top ww hh numWindow
IF DEFINED DEBUG echo DEBUG: call :cmdowMoveChild %~n0.0 %~n0.%threadNum% 10 0 640 100 %threadNum%
call :cmdowMoveChild %~n0.0 %~n0.%threadNum% 10 0 640 100 %threadNum%
%PAUSE%
goto :EOF


:: '########:'##::::'##:'########::'########::::'###::::'########:::'######::
:: ... ##..:: ##:::: ##: ##.... ##: ##.....::::'## ##::: ##.... ##:'##... ##:
:: ::: ##:::: ##:::: ##: ##:::: ##: ##::::::::'##:. ##:: ##:::: ##: ##:::..::
:: ::: ##:::: #########: ########:: ######:::'##:::. ##: ##:::: ##:. ######::
:: ::: ##:::: ##.... ##: ##.. ##::: ##...:::: #########: ##:::: ##::..... ##:
:: ::: ##:::: ##:::: ##: ##::. ##:: ##::::::: ##.... ##: ##:::: ##:'##::: ##:
:: ::: ##:::: ##:::: ##: ##:::. ##: ########: ##:::: ##: ########::. ######::
:: :::..:::::..:::::..::..:::::..::........::..:::::..::........::::......:::

:zipFileThread list zipEXT
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
set "list=%~1"
set "ext=%~2"

chcp 65001 >NUL

for /F %%x in ('wc -l %list%') do set nbFicsThread=%%x
REM call :countLines %list% && set nbFicsThread=0 || set nbFicsThread=%ERRORLEVEL%
IF DEFINED VERBOSE echo %y%thread %threadNum% starting with LIST=%list% and %nbFicsThread% files %END% 1>&2
IF %nbFicsThread% EQU 0 call :error Empty file %list% & timeout /t 10 & exit

%PAUSE%
cls
:: half-second wait because cmdow takes time to resize window
ping -n 2 localhost >NUL

for /F "tokens=*" %%F in (%list%) do call :zipFile "%%~nF.%ext%" "%%F"
exit /b %NbKO%
goto :EOF


:zipFile archive file
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2

REM echo set "archive=%~1"
REM echo set "file=%~2"
set "archive=%~1"
set "file=%~2"

set /A nbNewArch+=1
set /A Pct=100*%nbNewArch%/%nbFicsThread%

IF DEFINED VERBOSE (echo %HIGH%%k%ZIP %nbNewArch%/%nbFicsThread% :%END% "%file%" ... |%LOGG% ) ELSE call progressBar %Pct% "%nbNewArch%/%nbFicsThread% : %file%..." # . %y%
IF DEFINED DEBUG (echo %HIGH%%k%%commandZIP%%END% "%archive%" "%file%" |%LOGG% ) ELSE echo %HIGH%%k%%commandZIP%%END% "%archive%" "%file%">>%LOG%

%DEMO% %commandZIP% "%archive%" "%file%" 2>&1 | findstr /E Ok >NUL
if %ERRORLEVEL% NEQ 0 IF NOT DEFINED DEMO (
  echo ERROR: %~0 "%file%" |%LOGR%
  set /A NbKO+=1
  echo "%file%">>%LISTE_KO%
)
IF DEFINED DEMO timeout /t 1 >NUL

%PAUSE%
goto :EOF


:loopForCompletion
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2

FOR /F %%l in ('wc -l %threadLogs% 2^>NUL') DO set totalArch=%%l
:: totalArch can be empty because threads have not started logging yet
set /A Pct=100*(0+totalArch)/nbFicsTotal
call progressBar %Pct% "%totalArch%/%nbFicsTotal% files done" # . %g%
timeout /t 1 >NUL

IF %Pct% LSS 100 call :loopForCompletion
goto :EOF


:: '##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'##:
:: . ##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'##::
:: :. ##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'##:::
:: ::. ##::::'#######:'#######:'#######:'#######:'#######:'#######::::'##::::
:: :::. ##:::........:........:........:........:........:........:::'##:::::
:: ::::. ##:::::::::::::::::::::::::::::::::::::::::::::::::::::::::'##::::::
:: :::::. ##:::::::::::::::::::::::::::::::::::::::::::::::::::::::'##:::::::
:: ::::::..::::::::::::::::::::::::::::::::::::::::::::::::::::::::..::::::::



:REZIP
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
dir /b /a:-d *.%EXT% >%LISTE%
for /F %%x in ('wc -l %LISTE%') do set nbFicsTotal=%%x
call :log_header REZIP

IF DEFINED DEBUG (
  echo DEBUG: ----------------------------------------------- 1>&2
  echo DEBUG: LISTE=%LISTE% 1>&2
  echo DEBUG: ------------- 1>&2
  type %LISTE% 1>&2
  echo DEBUG: ----------------------------------------------- 1>&2
  %PAUSE%
)

for /F "tokens=*" %%a in (%LISTE%) do call :FUNC_REZIP "%%a"
%PAUSE%
goto :EOF

:FUNC_REZIP
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
set "FIC2REZIP=%~1"
set "REP2REZIP=%~dp1"
set BREAK=

set /A NbOldFic+=1
echo %~0 UNZIP %NbOldFic%/%nbFicsTotal% : %FIC2REZIP% ... |%LOGG%

:: we are rezipping * in a folder, no need to check file names
REM call :VERIF_CHARS_INSIDE "%FIC2REZIP%"
IF DEFINED DEBUG echo BREAK=%BREAK%
if DEFINED BREAK goto :EOF

if NOT DEFINED FORCE_LONE_FICS call :countZipContent
if DEFINED BREAK goto :EOF

IF DEFINED DEBUG echo %c%%UNZIP% %FIC2REZIP%%END% 1>&2
%UNZIP% %FIC2REZIP% | grep ^Extracting | cut -c11- >%LISTE_TMP%
if %ERRORLEVEL% EQU 0 (
  call :REZIP_%MODE% %FIC2REZIP%
) ELSE (
  echo KO %~0 sur          %FIC2REZIP% |%LOGR%
  set /A NbKO=%NbKO%+1
  rd /s /q "%WORKFOLDER%\tmp"
  echo %FIC2REZIP% >>%LISTE_KO%
)

:: type %LISTE_TMP%
%PAUSE%
goto :EOF


:countZipContent
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
%LISTZIP% %FIC2REZIP% | awk "(NR>7) {print}" | wc -l >%TMP%
:: ZipContent > 3 => l'archive contient plus d'un fichier
:: => si FORCE_LONE_FICS=NO alors on ne rezip pas l'archive 
for /F %%y in (%TMP%) do set ZipContent=%%y

set BREAK=true
if %ZipContent% GTR 3 set BREAK=
goto :EOF


:VERIF_CHARS_IN_NAME-OFF filename
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
echo %1 | egrep %FORBIDDEN_CHARS%
if %ERRORLEVEL% EQU 0 (
  set BREAK=true
  echo KO %~0 CHARS INTERDIT sur %1 |%LOGR%
  set /A NbKO=%NbKO%+1
  )
goto :EOF


:VERIF_CHARS_INSIDE-OFF filename
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
%LISTZIP% %1 | egrep %FORBIDDEN_CHARS%
if %ERRORLEVEL% EQU 0 (
  set BREAK=true
  echo KO %~0 CHARS INTERDIT dans %1 |%LOGR%
  set /A NbKO+=1
  )
goto :EOF


:REZIP_1BY1
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
set OLDZIPFILE=%1
::echo LISTE_TMP=%LISTE_TMP%
::type %LISTE_TMP%
::echo REP2REZIP=X%REP2REZIP%X
::echo zipEXT=X%zipEXT%X
::pause


IF DEFINED VERBOSE echo REZIP des fichiers de %OLDZIPFILE% ... |%LOGG%
REM for /F "tokens=*" %%A in (%LISTE_TMP%) do call :FUNC_1BY1 "%REP2REZIP%%%~nA.%zipEXT%" "%%A"

pushd "%WORKFOLDER%\tmp"
IF DEFINED VERBOSE echo %c%%commandZIP% "%~dp1..\%~n1.%zipEXT%" * %END%
%PAUSE%
echo %~0 "%~n1.%zipEXT%" ... |%LOGG%
%DEMO% %commandZIP% "%~dp1..\%~n1.%zipEXT%" * 2>&1 | findstr /E Ok >NUL
popd

REM IF DEFINED VERBOSE echo DEL %OLDZIPFILE% ... |%LOGG%
REM %PAUSE%
REM %DEMO% del /Q /F %OLDZIPFILE%

set /A nbNewArch+=1
set /A NbNewFic+=1

goto :EOF


:REZIP_GROUPED
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
set OLDZIPFILE=%REP2REZIP%%~n1
set OLD_zipEXT=%~x1

IF DEFINED VERBOSE echo DEL "%OLDZIPFILE%%OLD_zipEXT%" ... |%LOGG%
%DEMO% del /Q /F "%OLDZIPFILE%%OLD_zipEXT%"

IF DEFINED VERBOSE echo REZIP de "%OLDZIPFILE%.%zipEXT%" avec tous les fichiers ... |%LOGG%
set /A nbNewArch=%nbNewArch%+1
for /F "tokens=*" %%A in (%LISTE_TMP%) do call :FUNC_GROUPED "%%A"

goto :EOF


:FUNC_GROUPED
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
set /A NbNewFic=%NbNewFic%+1

if /I "%DEMO%" EQU "echo" echo %commandZIP% "%OLDZIPFILE%.%zipEXT%" %1
%DEMO% %commandZIP% "%OLDZIPFILE%.%zipEXT%" %1 | egrep "^Compressing|Ok" >>%LOG%
if %ERRORLEVEL% NEQ 0 (
  echo KO %~0   sur          "%OLDZIPFILE%.%zipEXT%" |%LOGR%
  set /A NbKO=%NbKO%+1
  )

%DEMO% del /Q /F %1
goto :EOF


:error msg
echo   %HIGH%%r%ERROR:%END%%r% %* %END%
REM timeout /t 10
exit /b 1
goto :EOF


:isEmpty
IF NOT EXIST %1 exit /b 0
exit /b 0%~z1
goto :EOF


:isFile
for /f "tokens=1,2 delims=d" %%A in ("-%~a1") do if "%%B" neq "" exit /b 1
exit /b 0
goto :EOF


:isFolder
for /f "tokens=1,2 delims=d" %%A in ("-%~a1") do if "%%B" neq "" exit /b 0
exit /b 1
goto :EOF

:countLines file
:: match counts NON EMPTY lines only
for /f %%a in ('findstr /R /N "..*$" %1 ^| %SystemRoot%\System32\find /C ":"') do set count=%%a
exit /b %count%

REM :isDefined var1 ..
:isDefined
set undefined=0
for %%a in (%*) DO IF NOT DEFINED %%a set /A "undefined+=1"
exit /b %undefined%
goto :EOF

REM :reset var1 ..
:reset
for %%a in (%*) DO call set %%a=
goto :EOF


:detectCpuThreads
IF NOT DEFINED nbThreads set /A nbThreads=%NUMBER_OF_PROCESSORS%-1
IF %nbThreads% EQU 0 set nbThreads=%nbThreadsDefault%
goto :EOF


:cmdowMoveChild parentWindowTitle windowTitle left top ww hh numWindow
:: https://ritchielawrence.github.io/cmdow/
set parentWindowTitle=%1
set windowTitle=%2
set Left=%3
set Top=%4
set Width=%5
set Height=%6
set numWindow=%7

REM cmdow 7zatool.1 /p
REM Handle  Lev Pid -Window status-   Left    Top  Width Height Image    Caption
REM 0x940930 1 4464 Res Ina Ena Vis   1106     55    640    200 cmd      7zatool.1

REM cmdow %1 /p
for /F "tokens=8,9,10,11" %%a in ('cmdow %parentWindowTitle% /p /b') DO (
  set parentLeft=%%a
  set parentTop=%%b
  set parentWidth=%%c
  set parentHeight=%%d
)
set /A childLeft=parentLeft+parentWidth
set /A childTop=parentTop+(numWindow-1)*Height

IF DEFINED DEBUG echo DEBUG: call :cmdowMove %windowTitle% %childLeft% %childTop% %Width% %Height%
call :cmdowMove %windowTitle% %childLeft% %childTop% %Width% %Height%

cmdow %1 /act

goto :EOF

:cmdowMove windowTitle left top ww hh
:: https://ritchielawrence.github.io/cmdow/
IF DEFINED DEBUG echo DEBUG: cmdow %1 /mov %2 %3 /siz %4 %5 /act
cmdow %1 /mov %2 %3 /siz %4 %5 /act
REM /TOP
goto :EOF


:psResize windowTitle left top ww hh numWindow
:: https://gist.github.com/coldnebo/1148334
:: https://stackoverflow.com/questions/60650922/powershell-windows-terminal-size-and-position-manipulation
set "windowTitle=%~1"
set "left=%~2"
set "top=%~3"
set "ww=%~4"
set "hh=%~5"
set "numWindow=%~6"

REM PowerShell -ExecutionPolicy Bypass -File %TEMP%\7zatool.psResize.ps1
echo Add-Type @^" >%TEMP%\%~1.psResize.ps1
echo using System; >>%TEMP%\%~1.psResize.ps1
echo using System.Runtime.InteropServices; >>%TEMP%\%~1.psResize.ps1
echo public class Win32 { >>%TEMP%\%~1.psResize.ps1
echo   [DllImport^("user32.dll"^)] >>%TEMP%\%~1.psResize.ps1
echo   [return: MarshalAs^(UnmanagedType.Bool^)] >>%TEMP%\%~1.psResize.ps1
echo   public static extern bool GetWindowRect^(IntPtr hWnd, out RECT lpRect^); >>%TEMP%\%~1.psResize.ps1
echo   [DllImport^("user32.dll"^)] >>%TEMP%\%~1.psResize.ps1
echo   [return: MarshalAs^(UnmanagedType.Bool^)] >>%TEMP%\%~1.psResize.ps1
echo   public static extern bool GetClientRect^(IntPtr hWnd, out RECT lpRect^); >>%TEMP%\%~1.psResize.ps1
echo   [DllImport^("user32.dll"^)] >>%TEMP%\%~1.psResize.ps1
echo   [return: MarshalAs^(UnmanagedType.Bool^)] >>%TEMP%\%~1.psResize.ps1
echo   public static extern bool MoveWindow^(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint^); >>%TEMP%\%~1.psResize.ps1
echo } >>%TEMP%\%~1.psResize.ps1
echo public struct RECT >>%TEMP%\%~1.psResize.ps1
echo { >>%TEMP%\%~1.psResize.ps1
echo   public int Left;        // x position of upper-left corner >>%TEMP%\%~1.psResize.ps1
echo   public int Top;         // y position of upper-left corner >>%TEMP%\%~1.psResize.ps1
echo   public int Right;       // x position of lower-right corner >>%TEMP%\%~1.psResize.ps1
echo   public int Bottom;      // y position of lower-right corner >>%TEMP%\%~1.psResize.ps1
echo } >>%TEMP%\%~1.psResize.ps1
echo ^"@ >>%TEMP%\%~1.psResize.ps1
echo $rcWindow = New-Object RECT >>%TEMP%\%~1.psResize.ps1
echo $rcClient = New-Object RECT >>%TEMP%\%~1.psResize.ps1
echo $h = ^(Get-Process ^| where {$_.MainWindowTitle -eq "%~1"}^).MainWindowHandle >>%TEMP%\%~1.psResize.ps1
echo [Win32]::GetWindowRect^($h,[ref]$rcWindow^) >>%TEMP%\%~1.psResize.ps1
echo [Win32]::GetClientRect^($h,[ref]$rcClient^) >>%TEMP%\%~1.psResize.ps1
echo $width = %ww% >>%TEMP%\%~1.psResize.ps1
echo $height = %hh% >>%TEMP%\%~1.psResize.ps1
echo $dx = ^($rcWindow.Right - $rcWindow.Left^) - $rcClient.Right >>%TEMP%\%~1.psResize.ps1
echo $dy = ^($rcWindow.Bottom - $rcWindow.Top^) - $rcClient.Bottom >>%TEMP%\%~1.psResize.ps1
IF DEFINED numWindow (
echo [Win32]::MoveWindow^($h, $rct.Left + %left% + %ww%, $rct.Top + %top% + ^(^(%numWindow% * %hh%^) - %hh%^), $width + $dx, $height + $dy, $true ^) >>%TEMP%\%~1.psResize.ps1
) ELSE (
echo [Win32]::MoveWindow^($h, $rct.Left + %left%, $rct.Top + %top%, $width + $dx, $height + $dy, $true ^) >>%TEMP%\%~1.psResize.ps1
)

echo PowerShell -ExecutionPolicy Bypass -File %TEMP%\%~1.psResize.ps1
PowerShell -ExecutionPolicy Bypass -File %TEMP%\%~1.psResize.ps1
goto :EOF


:cleanupLogs
IF DEFINED DEBUG echo %HIGH%%b%%~0%END%%c% %* %END% 1>&2
IF DEFINED DEBUG echo del /Q /F "%WORKFOLDER%\%CURRENTBATCH%.*" "%WORKFOLDER%\%splitPREFIX%*" 1>&2
rd /s /q "%WORKFOLDER%\tmp" >NUL 2>&1
del /Q /F "%WORKFOLDER%\%CURRENTBATCH%.*" "%WORKFOLDER%\%splitPREFIX%*" 2>NUL
goto :EOF


:cleanupThreads
IF DEFINED DEBUG echo %HIGH%%b%%~0%END%%c% %* %END% 1>&2
:: the * in the windowtitle name is needed for the titles can get messed up
for /L %%n in (1,1,%nbThreads%) DO taskkill /T /F /IM cmd.exe /FI "WINDOWTITLE eq %~n0.%%n*" >NUL 2>&1
goto :EOF


:detect_admin_mode [num]
IF DEFINED DEBUG echo DEBUG: %m%%~n0 %~0 %HIGH%%*%END% 1>&2
:: https://stackoverflow.com/questions/1894967/how-to-request-administrator-access-inside-a-batch-file

set req=%1
set bits=32
set bitx=x86
IF DEFINED PROCESSOR_ARCHITEW6432 echo WARNING: running 32bit cmd on 64bit system 1>&2
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  set arch=-x64
  set bits=64
  set bitx=x64
)
%SystemRoot%\system32\whoami /groups | findstr "12288" >NUL && set "ADMIN=0" || set "ADMIN=1"
IF %ADMIN% EQU 0 (
  echo Batch started with %HIGH%%y%ADMIN%END% rights 1>&2
) ELSE (
  echo Batch started with %y%USER%END% rights 1>&2
)

IF DEFINED req (
  IF NOT "%ADMIN%" EQU "%req%" (
    IF "%ADMIN%" GTR "%req%" (
      echo %y%Batch started with USER privileges, when ADMIN was needed.%END% 1>&2
      IF DEFINED AUTOMATED exit
      REM :UACPrompt
      net localgroup administrators | findstr "%USERNAME%" >NUL || call :error %~0: User %USERNAME% is NOT localadmin
      echo Set UAC = CreateObject^("Shell.Application"^) >"%TEMP%\getadmin.vbs"
      REM :: WARNING: cannot use escaped parameters with this one:
      IF DEFINED params (
      echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params:"=""%", "", "runas", 1 >>"%TEMP%\getadmin.vbs"
      ) ELSE echo UAC.ShellExecute "cmd.exe", "/c %~s0", "", "runas", 1 >>"%TEMP%\getadmin.vbs"
      CScript //B "%TEMP%\getadmin.vbs"
      del /q "%TEMP%\getadmin.vbs"
    ) ELSE (
      echo %r%Batch started with ADMIN privileges, when USER was needed. EXIT%END% 1>&2
      IF NOT DEFINED AUTOMATED pause 1>&2
    )
    exit
  )
)

set osType=workstation
wmic os get Caption /value | findstr Server >%TMP%\wmic.tmp.txt && set "osType=server" || ver >%TMP%\ver.tmp.txt

:: https://www.lifewire.com/windows-version-numbers-2625171
:: Microsoft Windows [Version 10.0.17763.615]
IF "%osType%"=="workstation" (
  findstr /C:"Version 10.0" %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=10"    && exit /b 0
  findstr /C:"Version 6.3"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=8.1"   && exit /b 0
  findstr /C:"Version 6.2"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=8"     && exit /b 0
  findstr /C:"Version 6.1"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=7"     && exit /b 0
  findstr /C:"Version 6.0"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=Vista" && exit /b 0
  findstr /C:"Version 5.1"  %TMP%\ver.tmp.txt >NUL && set "WindowsVersion=XP"    && exit /b 0
) ELSE (
  for /f "tokens=4" %%a in (%TMP%\wmic.tmp.txt) do    set "WindowsVersion=%%a"   && exit /b 0
)
goto :EOF


:set_colors
IF DEFINED END goto :EOF
set colorCompatibleVersions=-8-8.1-10-2016-2019-
call set colorIncompatible=%%colorCompatibleVersions:-%WindowsVersion%-=COMPATIBLE%%
IF "%colorCompatibleVersions%"=="%colorIncompatible%" exit /b 1
call win10colors-set.cmd >NUL 2>&1 && goto :EOF

set END=[0m
set HIGH=[1m
set Underline=[4m
set REVERSE=[7m

set k=[30m
set r=[31m
set g=[32m
set y=[33m
set b=[34m
set m=[35m
set c=[36m
set w=[37m

goto :EOF
:: BUG: some space are needed after :set_colors


:detect_sevenZip
for %%x in (7z.exe) DO set "sevenZip=%%~$PATH:x"
IF NOT DEFINED sevenZip IF EXIST .\7z.exe set "sevenZip=.\7z.exe"
IF NOT DEFINED sevenZip IF EXIST "%DIRTOOLS%\7z.exe" set "sevenZip=%DIRTOOLS%\7z.exe"
IF NOT DEFINED sevenZip IF EXIST "%ProgramFiles%\7-Zip\7z.exe" set "sevenZip=%ProgramFiles%\7-Zip\7z.exe"
IF NOT DEFINED sevenZip IF EXIST "%ProgramFiles(x86)%\7-zip\7z.exe" set "sevenZip=%ProgramFiles(x86)%\7-zip\7z.exe"
IF NOT DEFINED sevenZip call :error sevenZip NOT FOUND
goto :EOF


:DEBUG
echo %END%%m%----------------DEBUG---------------- %* %END% 1>&2
IF DEFINED threadNum echo %y%I AM THREAD number %HIGH%%threadNum% 1>&2
echo %HIGH%%m%EXT=%EXT% 1>&2
echo %HIGH%%m%FIC=%FIC% 1>&2
echo %HIGH%%m%TYPE=%TYPE% 1>&2
echo %HIGH%%m%zipEXT=%zipEXT% 1>&2
echo %HIGH%%m%threadNum=%threadNum% 1>&2
echo %HIGH%%m%listFiles=%listFiles% 1>&2
echo %HIGH%%m%LISTE=%LISTE% 1>&2
echo. 1>&2
echo %HIGH%%m%WORKFOLDER=%WORKFOLDER% 1>&2
echo %HIGH%%m%USAGE=%USAGE% 1>&2
echo %HIGH%%m%DEMO=%DEMO% 1>&2
echo %HIGH%%m%nbFicsTotal=%nbFicsTotal% 1>&2
echo %HIGH%%m%totalBytes=%totalBytes% 1>&2
echo %HIGH%%m%nbThreads=%nbThreads% 1>&2
echo %HIGH%%m%nbFicsTotalSplit=%nbFicsTotalSplit% 1>&2
echo %END%%m%----------------DEBUG----------------%END% 1>&2
goto :EOF


:log_header
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2

echo ================================================================================ |%LOGG%
echo %DATE% %TIME% |%LOGG%
:: INFO: BUG: piping a redirect through busybox tee needs to be escaped 3 times
echo %c%%FUNCTION% %HIGH%%nbFicsTotal% %END%files.%y%%EXT%%END% -^^^> %g%%zipEXT%  /  nbThreads=%nbThreads% %END% |%LOGG%
IF DEFINED DEBUG wc -l %splitPREFIX%*  |%LOGG%
echo MODE=%MODE% - ORIGINAL=%EXT% - TYPE=%TYPE% - ZIP_EXT=%zipEXT% - LEVEL=%LEVEL% |%LOGG%
echo Repertoire de travail : %WORKFOLDER% |%LOGG%
echo + Sous-Repertoires    : %INCLUDE_SUBREP% |%LOGG%
echo ================================================================================ |%LOGG%
IF DEFINED DEBUG (pause 1>&2) else timeout /t 5 1>&2
goto :EOF


:log_footer
IF DEFINED DEBUG echo DEBUG: %m%%~0 %HIGH%%*%END% 1>&2
IF DEFINED DEBUG call :DEBUG :log_footer
echo ================================================================================ |%LOGG%
echo %nbFicsTotal% files processed |%LOGG%
echo %g%%nbNewArch% archive created %END% |%LOGG%
echo %r%%NbKO% errors %END% |%LOGG%
REM echo %NbOldFic% files reprocessed |%LOGG%
REM echo %NbNewFic% fichiers recompresses |%LOGG%
echo ================================================================================ |%LOGG%

set /A totals=totalms/1000
set /A msPerFile=totalms/nbNewArch
set /A mbPerSec=1000*(totalBytes/1048576)/totalms

echo %HIGH%%w%%TYPE%.%zipEXT%.%LEVEL%: %y%%nbNewArch% files / %nbThreads% threads = %totals% seconds = %msPerFile% ms/file = %mbPerSec% mB/s %END% |%LOGG%
echo TYPE;zipEXT;LEVEL;nbNewArch;nbThreads;totals;msPerFile;mbPerSec |%LOGG%
echo %TYPE%;%zipEXT%;%LEVEL%;%nbNewArch%;%nbThreads%;%totals%;%msPerFile%;%mbPerSec% |%LOGG%

if %NbKO% GTR 0 (
  echo %r%##############################ERRORS######################################## |%LOGG%
  type %ERRORS% "%WORKFOLDER%\%CURRENTBATCH%.err.*.log" 2>NUL |%LOGG%
  echo #################################ERRORS########################################%END% |%LOGG%
  echo LISTE=    %LISTE_TMP% |%LOGG%
  echo LISTE_KO= %LISTE_KO% |%LOGG%
  )
call :isEmpty %LISTE_KO%
IF %ERRORLEVEL% GTR 0 (
  echo %y%#################################LISTE_KO###################################### |%LOGG%
  type %LISTE_KO%
  echo #################################LISTE_KO######################################%END% |%LOGG%
)
echo H0=       %H0% |%LOGG%
echo HFIN=     %DATE% %TIME% |%LOGG%
echo ================================================================================ |%LOGG%
goto :EOF


:END
chcp 437 >NUL
IF DEFINED USAGE call :USAGE 1>&2 & exit /b 99
call :log_footer
IF NOT DEFINED DEBUG call :cleanupThreads
IF %NbKO% EQU 0 call :cleanupLogs

