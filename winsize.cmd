:: Console Resize values via PowerShell (changeable)
SET "_PSResize=100 54 100 9997"

:: Check for powershell via PATH variable
POWERSHELL "Exit" >NUL 2>&1 && SET "_PS=1"
IF NOT DEFINED _PS (ECHO No&do something) ELSE (ECHO Yes&do something)
 
:: PS-Console Resizing
IF DEFINED _PS CALL:_PS_ReSize %_PSRESIZE%
goto :end

:_PS_Resize  winWidth  winHeight  bufWidth  bufHeight
:: Mode sets buffer size-not window size
MODE %1,%2

:: resize
powershell -command "&{$H=get-host;$W=$H.ui.rawui;$B=$W.buffersize;$B.width=%3;$B.height=%4;$W.buffersize=$B;}"
GOTO:EOF

:end
pause

