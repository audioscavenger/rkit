@echo off
REM for %%a in (fonts/*.flf) do @echo %%~na & @pyfiglet -f %%~na %%~na
for /F %%a in ('pyfiglet -l') do @echo %%~na | tee -a %~dpn0.txt & @pyfiglet -w 250 -f %%~na %%~na | tee -a %~dpn0.txt
pause