:: ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:become_admin
:: Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: If error flag is set, we do not have admin.
if "%errorlevel%" NEQ "0" (
  echo Requesting administrative privileges...
  goto :become_admin_UACPrompt
) else ( goto become_admin_gotAdmin )

:become_admin_UACPrompt
  echo Set UAC = CreateObject^("Shell.Application"^) >"%TEMP%\getadmin.vbs"
  echo UAC.ShellExecute "cmd.exe", "/c %~s0 %*", "", "runas", 1 >> "%temp%\getadmin.vbs"
  CScript //B "%temp%\getadmin.vbs"
  exit /B

:become_admin_gotAdmin
  del /f /q "%temp%\getadmin.vbs" 2>NUL
  pushd "%CD%"
  CD /D "%~dp0"
:: ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
