:: solution based on these steps: https://stackoverflow.com/questions/359424/detach-move-subdirectory-into-separate-git-repository/17864475#17864475
@echo OFF
setlocal enabledelayedexpansion

:init
REM subFolderLocal=tools\\rkit-nQ
REM echo $subFolderLocal
set subFolderLocal=%1

set "PATH=C:\Program Files\Git\mingw64\bin\;%PATH%"

:prechecks
IF NOT EXIST %subFolderLocal%\ echo ERROR: %subFolderLocal% is not a subfolder & exit /b 1
where git || echo ERROR: git not found & exit /b 1*

::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:main
REM subFolderGit=tools/rkit-nQ
set subFolderGit=%subFolderLocal:\=/%

call :gitUpdateFromRemote
call :gitUpdateRemote
::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:gitGetName
for /f git config --local remote.origin.url
goto :EOF

:gitUpdateRemote
git add -A && git commit -m "%subFolderGit% last commit before"
git push --all
goto :EOF

:gitUpdateFromRemote
git stash
git fetch --all
git stash pop
goto :EOF

:end
