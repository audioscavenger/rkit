@echo OFF
REM pushd "%~dp0"
setlocal
REM setlocal enabledelayedexpansion
verify on

set version=1.6
set author=AudioscavengeR
::-----------------------------------------------------------------------------------
:: Purpose:
:: - Benchmark for 7zip: compress a list of files with different settings and factors:
::    + Temporary folders: to test if drive overhead really matters
::    + methods by their extention: zip, 7z, add your own...
::    + compression levels: 0 1 3 5 7 9
:: - finally gather time and size data to produce a CSV output you can play with
:: - for more information on 7z switches, see https://sevenzip.osdn.jp/chm/cmdline/switches/
::-----------------------------------------------------------------------------------
:: Usage:
:: 1. setup :defaults, :init and :prechecks
:: 2. call the batch and that's it
:: 3. parameters accepted: -D -V -l
::-----------------------------------------------------------------------------------
:: Features:
:: - auto-detection of 7zip on your system
:: - colors
:: - a wealth of parameters can be ajusted
:: - parametric output field list easy to update
::-----------------------------------------------------------------------------------
:: Requisites:
:: - 7z.exe
:: - get_date_format.cmd
:: - get_timelapse.cmd
:: - 64bit Windows recommended
::-----------------------------------------------------------------------------------
:: Changelog:
:: 1.1  accomodate special chars
:: 1.2  default compression level is 5, among 1,3,5,7,9
:: 1.3  CSV field names and list is parametrable
:: 1.4  CSV and LOG using CPU name
:: 1.5  fix OUTPUTFOLDER
:: 1.6  make sure testFile EXT is included in zipFile name
::-----------------------------------------------------------------------------------
:: TODO LIST:
:: - add files tests as parameter
:: - add :arguments to process more agruments
:: - add unzip to tests decompression speed?
:: - include get_timelapse.cmd and get_date_format.cmd in this batch to get rid of requisites?
:: - try and get rid of these unix binaries?
::-----------------------------------------------------------------------------------
::-----------------------------------------------------------------------------------

:top
:: DEMO=["", echo]
set DEMO=
REM set DEMO=echo

:: DEBUG=["", -D]
set DEBUG=
REM set DEBUG=-D

:: VERBOSE=["", -V]
REM set VERBOSE=
set VERBOSE=-V

:: PAUSE=[echo.^>NUL, pause 1>&2]
set PAUSE=echo.^>NUL
REM set PAUSE=pause 1>&2

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:defaults
set PRINT_CSV=
:: MODE=[1BY1, GROUPED]
set MODE=1BY1
:: zip METHOD=[Copy, Deflate, Deflate64, BZip2, LZMA, PPMd]
:: 7z  METHOD=[LZMA, LZMA2, PPMd, BZip2, Deflate, Delta, BCJ, BCJ2, Copy]
set METHOD_zip=Deflate
set METHOD_7z=LZMA2

set FUNCTION=ZIP
set FIC=.
set INPUTFOLDER=.
set TEMPFOLDER=%CD%
set OUTPUTFOLDER=%INPUTFOLDER%
set nbThreadsDefault=2
set archiveEXT=001-9 7z-0 arj-4 bz2-2 bzip2-2 cab-7 cpio-12 deb-11 dmg-17 fat-21 gz-14 gzip-14 hfs-18 lha-6 lzh-6 lzma-16 rar-3 rpm-10 squashfs-24 swm-15 tar-13 taz-5 tbz-2 tbz2-2 tgz-14 tpz-14 txz-23 wim-15 xar-19 xz-23 z-5 zip-1


:init
:: there is no noticeable differences in using different temporary drives
REM set TEMPFOLDERs=C:\tmp S:\tmp T:\tmp
set TEMPFOLDERs=T:\tmp
set OUTPUTFOLDER=T:\tmp
set DATAOUTPUT=S:\www\posts\_7z-study

set zipEXTs=zip 7z
:: set LEVEL=[0 | 1 | 3 | 5 | 7 | 9 ]
set LEVELs=1 3 5 7 9
set testFiles=8MBSegaGenesis.md ResidentEvil2.z64 CrashBandicoot-PSX.bin

:: these are the fields that will go in the CSV:
REM set fields=DATE TIME cpuName TEMPFOLDER INPUTFOLDER OUTPUTFOLDER testFile testFileExt zipEXT METHOD LEVEL fileSize zipSize totalms
set fields=DATE TIME cpuName testFile testFileExt zipEXT METHOD LEVEL fileSize zipSize totalms

call :reset cpuName fileSize zipSize header line EXT threadNum listFiles TIMESTART TIMEEND METHOD LEVEL threadLogs USAGE zipEXT SUBREP totalBytes nbFicsThread nbFicsTotal


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:prechecks
IF NOT "%~1"=="" set testFiles=%*

call :detect_admin_mode >NUL 2>NUL
call :set_colors
call :get_date_format >NUL 2>NUL
call :detect_CPUname
call :detectCpuThreads
call :detect_sevenZip

:: awk port for Windows is just used to auto-size the columns when printing out the CSV at the end
for %%x in (7z.exe) DO set "sevenZip=%%~$PATH:x"


:: https://sevenzip.osdn.jp/chm/cmdline/switches/method.htm ::::::::::::::::::::::::::::::::::::::::::
REM Zip
REM Parameter 	Default 	Description
REM x=[0 | 1 | 3 | 5 | 7 | 9 ] 	5 	Sets level of compression.
REM m={MethodID} 	Deflate 	Sets a method: Copy, Deflate, Deflate64, BZip2, LZMA, PPMd.
REM fb={NumFastBytes} 	32 	Sets number of Fast Bytes for Deflate encoder.
REM pass={NumPasses} 	1 	Sets number of Passes for Deflate encoder.
REM d={Size}[b|k|m] 	900000 	Sets Dictionary size for BZip2
REM mem={Size}[b|k|m] 	24 	Sets size of used memory for PPMd.
REM o={Size} 	8 	Sets model order for PPMd.
REM mt=[off | on | {N}] 	on 	Sets multithreading mode.
REM em={EncryptionMethodID} 	ZipCrypto 	Sets a encryption method: ZipCrypto, AES128, AES192, AES256
REM tc=[off | on] 	on 	Stores NTFS timestamps for files: Modification time, Creation time, Last access time.
REM cl=[off | on] 	off 	7-Zip always uses local code page for file names.
REM cu=[off | on] 	off 	7-Zip uses UTF-8 for file names that contain non-ASCII symbols.
REM cp={CodePage} 	off 	Sets code page


:: https://sevenzip.osdn.jp/chm/cmdline/switches/           ::::::::::::::::::::::::::::::::::::::::::
:: https://sevenzip.osdn.jp/chm/cmdline/switches/method.htm ::::::::::::::::::::::::::::::::::::::::::
:: we now use one window per thread with cpu affinity so the 7z commands must reflect that
:: + must add -mmt1 when using cmd affinity
:: + By default (if cl/cu are absents), 7-Zip uses UTF-8 encoding only for file names that contain symbols unsupported by local code page.
:: -mm=Deflate
REM set commandZIP=%sevenZip% a -y -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp2 -mx=%LEVEL% -t%zipEXT% -w%TEMPFOLDER% 
REM set commandZIP=%sevenZip% a -y -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp2 -mx=%LEVEL% -t%zipEXT%
REM set commandZIP=%sevenZip% a -y -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp2 -mx=%LEVEL%
set commandZIP=%sevenZip% a -y -bd -bb0 -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp1
set commandUNZIP=%sevenZip% e -y -bso1 -bse2 -bsp1 -o"%TEMPFOLDER%\tmp"
set LISTZIP=%sevenZip% l -bd
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

set CURRENTBATCH=%~n0

set nbFicsTotal=0
set totalBytes=0
set nbFicsThread=0
set NbOldFic=0
set nbNewArch=0
set NbNewFic=0
set NbKO=0
set H0=%DATE% %TIME%

set "ERRLOG=%DATAOUTPUT%\7z-%cpuName%-%GOOD_DATE%.err.log"
set "STDLOG=%DATAOUTPUT%\7z-%cpuName%-%GOOD_DATE%.out.log"
set "CSV=%DATAOUTPUT%\7z-%cpuName%.csv"

REM IF NOT EXIST %CSV% echo testFile;TEMPFOLDER;METHOD;zipEXT;LEVEL;nbThreads;totals;msPerFile;mbPerSec>%CSV%
IF NOT EXIST %CSV% (
  for %%a in (%fields%) DO call set "header=%%header%%%%a;"
  call echo %%header%%>%CSV%
)


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main

for %%a in (%*) DO (
  IF "%%a"=="-D" set DEBUG=-D
  IF "%%a"=="-V" set VERBOSE=-V
  IF "%%a"=="-l" set PRINT_CSV=true
)

IF DEFINED PRINT_CSV call :log_footer & exit /b

:: :ZIPwrapper exits with zipFile size
call :ZIPwrapper %testFiles%
call :log_footer

goto :end
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:ZIPwrapper files
IF DEFINED DEBUG echo %m%DEBUG: %~0 %HIGH%%*%END% 1>&2

echo ================================================================================ 1>&2

REM set commandZIP=%sevenZip% a -y -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp2 -mx=%LEVEL% -t%zipEXT% -w%TEMPFOLDER% 
REM set commandZIP=%sevenZip% a -y -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp2 -mx=%LEVEL% -t%zipEXT%
REM set commandZIP=%sevenZip% a -y -sccUTF-8 -scsUTF-8 -sse -bso1 -bse2 -bsp2 -mx=%LEVEL%

for %%F in (%*) DO (
  for %%T in (%TEMPFOLDERs%) DO (
    for %%Z in (%zipEXTs%) DO (
      for %%L in (%LEVELs%) DO (
        call :ZIP %%T %%Z %%L "%OUTPUTFOLDER%\%%~nxF.%%Z" "%%~F"
      )
    )
  )
)

goto :EOF


:ZIP
IF DEFINED DEBUG echo %m%DEBUG: %~0 %HIGH%%*%END% 1>&2

set TEMPFOLDER=%1
set zipEXT=%2
set LEVEL=%3
set zipFile=%~4
set testFile=%~5
set testFileExt=%~x5
set "testFileExt=%testFileExt:.=%"
set "INPUTFOLDER=%~dp5"

call set METHOD=%%METHOD_%zipEXT%%%

set /A nbFicsTotal+=1
:: we need to include the FS overhead to create the zipFile unfortunately
del /f /q "%zipFile%" 2>NUL

REM echo %HIGH%%k% %commandZIP% %END% "%~n1.%zipEXT%" %1 1>&2
IF DEFINED VERBOSE echo   %HIGH%%k% %commandZIP% %END% -w%TEMPFOLDER% -t%zipEXT% -mx=%LEVEL% -- "%zipFile%" "%testFile%" 1>&2

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
call get_timelapse start 2>NUL
%commandZIP% -w%TEMPFOLDER% -t%zipEXT% -mx=%LEVEL% -- "%zipFile%" "%testFile%" >NUL 2>%ERRLOG%
call get_timelapse 2>NUL
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: print errors
call :isEmpty %ERRLOG% || (echo %r% 1>&2 & type %ERRLOG% 1>&2 & echo %END% 1>&2)

:: get fileSize
call :isEmpty "%testFile%" && set fileSize=0 || call set fileSize=%%ERRORLEVEL%%
:: get zipSize
call :isEmpty "%zipFile%" && set zipSize=0 || call set zipSize=%%ERRORLEVEL%%

:: exit here, the rest cannot be done within a loop
IF %zipSize% EQU 0 echo %r%ERROR zipSize=0%END% & exit /b 0

set /A nbNewArch+=1
REM echo %testFile%;%TEMPFOLDER%;%METHOD%;%zipEXT%;%LEVEL%;%TEMPFOLDER%;%nbThreads%;%totals%;%msPerFile%;%mbPerSec%>>%CSV%
set line=
for %%a in (%fields%) DO call set "line=%%line%%%%%%a%%;"
call echo %%line:~0,-1%%>>%CSV%

exit /b %zipSize%
goto :EOF


:log_footer
IF DEFINED DEBUG echo %m%DEBUG: %~0 %HIGH%%*%END% 1>&2

REM set /A totals=totalms/1000
REM set /A msPerFile=totalms/nbNewArch
REM set /A mbPerSec=1000*(totalBytes/1048576)/totalms
REM echo %HIGH%%w%%METHOD%.%zipEXT%.%LEVEL%: %y%%nbNewArch% files / %nbThreads% threads = %totals% seconds = %msPerFile% ms/file = %mbPerSec% mB/s %END%


IF DEFINED DEBUG echo DEBUG: CSV = %CSV% 1>&2

awk -F; "BEGIN { getline; L=1; for (i=1; i<=NF; ++i) { line[L,i] = $i; len[i]=length(line[L,i]) }; L++; } {   for (i=1; i<=NF; ++i) {     line[L,i] = $i;     if (truncate == 0) { if (length($i) > len[i]) { len[i]=length($i) } }   };   L++; } END {   for (L=1; L<=NR; ++L) {     for (i=1; i<=NF; ++i) {       printf """%%-*s%%s""", len[i], substr(line[L,i],1,len[i]), (i<NF?OFS:ORS)     }   } }" %CSV%
echo ================================================================================ 1>&2

goto :EOF



REM :reset var1 ..
:reset
for %%a in (%*) DO call set %%a=
goto :EOF


:isEmpty
IF NOT EXIST %1 exit /b 0
exit /b 0%~z1
goto :EOF


:detect_CPUname
:: update so your log/csv files have a name you like
REM set cpuName=Intel(R) Core(TM) i7-8750H CPU @ 2.20GHz
REM set cpuName=AMD Ryzen 5 1600 Six-Core Processor
for /F "tokens=*" %%a in ('wmic cpu get Name ^| findstr /R .') DO set cpuName=%%a

set cpuName=%cpuName%
set cpuName=%cpuName: =-%
set cpuName=%cpuName:Intel(R)-=%
set cpuName=%cpuName:Core(TM)-=%
set cpuName=%cpuName:CPU-@-=%
set cpuName=%cpuName:AMD-=%
set cpuName=%cpuName:-Processor=%
set cpuName=%cpuName:--=%
set cpuName=%cpuName:--=%

REM echo cpuName=%cpuName%
goto :EOF


:detect_sevenZip
:: addapt to your environment
for %%x in (7z.exe) DO set "sevenZip=%%~$PATH:x"
IF NOT DEFINED MYFILES set MYFILES=.
IF NOT DEFINED sevenZip IF EXIST %MYFILES%\7z.exe set "sevenZip=%MYFILES%\7z.exe"
IF NOT DEFINED sevenZip IF EXIST "%DIRTOOLS%\7z.exe" set "sevenZip=%DIRTOOLS%\7z.exe"
IF NOT DEFINED sevenZip IF EXIST "%ProgramFiles%\7-Zip\7z.exe" set "sevenZip=%ProgramFiles%\7-Zip\7z.exe"
IF NOT DEFINED sevenZip IF EXIST "%ProgramFiles(x86)%\7-zip\7z.exe" set "sevenZip=%ProgramFiles(x86)%\7-zip\7z.exe"
IF NOT DEFINED sevenZip call :error sevenZip NOT FOUND
goto :EOF


:detectCpuThreads
:: you could auto assign a number of threads and add this to your test...
IF NOT DEFINED nbThreads set /A nbThreads=%NUMBER_OF_PROCESSORS%-1
IF %nbThreads% EQU 0 set nbThreads=%nbThreadsDefault%
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
REM call win10colors-set.cmd >NUL 2>NUL && goto :EOF

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


:error "msg"
echo:%r% 1>&2
echo ============================================================== 1>&2
echo %HIGH%%r%  ERROR:%END%%r% %* 1>&2
echo ============================================================== 1>&2
echo:%END% 1>&2
exit 1
goto :EOF


:END

