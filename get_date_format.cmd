@echo OFF
:: version=2.0
:: to get a correct date from a US date and time

set CURRENT_DATE=%DATE:/=-%
set CURRENT_TIME=%TIME::=-%

:: case where time < 10 and look like "9:10:06.19"
if "%CURRENT_TIME:~1,1%" == ":" set CURRENT_TIME=0%CURRENT_TIME%
:: case where time < 10 and look like " 9:10:06.19"
if "%CURRENT_TIME:~0,1%" == " " set CURRENT_TIME=%CURRENT_TIME: =0%

set thisHour=%CURRENT_TIME:~0,2%
IF %thisHour% LSS 1 set thisHour=24
IF %thisHour% LSS 10 (set /a lastHour=%thisHour:~1,1%-1) ELSE set /a lastHour=thisHour-1
IF %lastHour% LSS 10 (set lastHour=0%lastHour%%TIME:~2,3%) ELSE set lastHour=%lastHour%%TIME:~2,3%

:: Get the date into ISO 8601 standard format (yyyy-mm-dd)
REM for /f %%a in ('^<NUL %WMIC% OS GET LocalDateTime ^| %FIND% "."') DO set DTS=%%a
REM LocalDateTime
REM 20220611102642.568000-420
REM set CUR_DATE=%DTS:~0,4%-%DTS:~4,2%-%DTS:~6,2%
REM CUR_DATE=2022-06-11

:: Tue 05/26/2015
echo DATE="%DATE%"
:: 16:52:15.61
echo TIME="%TIME%"
:: "Tue 05-26-2015 "
echo CURRENT_DATE="%CURRENT_DATE%"
:: " 9-51-35.64 "
echo CURRENT_TIME="%CURRENT_TIME%"
set GOOD_TIME=%CURRENT_TIME:~0,8%

set GOOD_DATE=%CURRENT_DATE:~0,10%
:: ISO
if "%CURRENT_DATE:~2,1%" EQU "-" set GOOD_DATE=%DATE:~6,4%-%DATE:~3,2%-%DATE:~0,2%
:: US
if "%CURRENT_DATE:~3,1%" EQU " " set GOOD_DATE=%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%
set CURRENT_DATE_NOSEP=%GOOD_DATE:-=%

set GOOD_DATETIME=%GOOD_DATE%_%GOOD_TIME%

echo:
echo lastHour=%lastHour%
echo GOOD_DATE=%GOOD_DATE%
echo GOOD_TIME=%GOOD_TIME%
echo GOOD_DATETIME=%GOOD_DATETIME%
set CURRENT_DATETIME_NOSEP=%GOOD_DATETIME:-=%
echo CURRENT_DATE_NOSEP=%CURRENT_DATE_NOSEP%
echo CURRENT_DATETIME_NOSEP=%CURRENT_DATETIME_NOSEP%

set months=