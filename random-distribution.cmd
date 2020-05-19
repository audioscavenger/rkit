@echo off
setlocal enabledelayedexpansion

FOR /l %%a in (1,1,7) DO set value%%a=0
FOR /l %%a in (1,1,1000) DO set /A rvalue!RANDOM:~0,1!+=1
FOR /l %%a in (1,1,10000) DO set /A tvalue!TIME:~-1!+=1
FOR /l %%a in (1,1,7) DO call echo Rvalue%%a=%%Rvalue%%a%%
FOR /l %%a in (1,1,7) DO call echo Tvalue%%a=%%Tvalue%%a%%
REM Rvalue1=346
REM Rvalue2=350
REM Rvalue3=118
REM Rvalue4=36
REM Rvalue5=30
REM Rvalue6=26
REM Rvalue7=31
REM Tvalue1=1005
REM Tvalue2=984
REM Tvalue3=714
REM Tvalue4=1072
REM Tvalue5=948
REM Tvalue6=911
REM Tvalue7=1377