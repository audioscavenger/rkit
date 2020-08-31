@echo off
REM for %%a in (fonts/*.flf) do @echo %%~na & @pyfiglet -f %%~na %%~na
for /F %%a in ('pyfiglet -l') do @echo %%~na & @pyfiglet -f %%~na %%~na
pause