@echo off
setlocal

:set_colors
REM set colorCompatibleVersions=-8-8.1-10-2016-2019-
REM IF DEFINED WindowsVersion IF "!colorCompatibleVersions:-%WindowsVersion%-=_!"=="%colorCompatibleVersions%" goto :EOF

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


call progressBar 10 "step a"
REM timeout /t 1 >NUL
call progressBar 20 "step 2"
REM timeout /t 1 >NUL
call progressBar 32 "step 3"
echo random error message text that will not fit on screen unless you have a lot of space
REM timeout /t 1 >NUL
call progressBar 50 "step 4444"
REM timeout /t 1 >NUL
call progressBar 100 "finalizing"
echo.
echo done
echo.

for /L %%n in (1,1,10) DO (
  call progressBar %%n0 "step %%n" # . [3%%nm
  ping -n 2 localhost >NUL
)
echo.
echo done
echo.

call progressBar 0 "step 0" "|" " "
timeout /t 1 >NUL
call progressBar 20 "step 2" "|" " "
timeout /t 1 >NUL
call progressBar 32 "step 3" "|" " "
timeout /t 1 >NUL
call progressBar 50 "step 4444" "|" " "
timeout /t 1 >NUL
call progressBar 100 "finalizing" "|" " "
echo.
echo done
echo.
pause

