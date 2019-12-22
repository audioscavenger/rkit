@echo off

:Select [/bf] "prompt" [/bf] option1 option2 ...
rem Antonio Perez Ayala

if "%~1" neq "" goto begin
:usage
echo Activate a selection of options in one line.
echo/
echo call :Select [/bf] "prompt" [/bf] option1 option2 ...
echo/
echo Prompt must be enclosed in quotes; use "" if prompt not wanted.
echo/
echo /bf specify attribute(s) used in next parameters, option in focus will be shown
echo in reversed attribute. If attribute not given, current position color is used.
echo/
echo Options may be simple words or "Several words in quotes"; the first digit or
echo uppercase letter in an option may be used to select it with just one key.
echo/
echo At end, the number of the selected option is returned in ERRORLEVEL.
goto :EOF

:begin
setlocal EnableDelayedExpansion

rem Define auxiliary variables
set name=
for %%a in (RightArrow=-77 LeftArrow=-75 Ctrl_RightArrow=-116 Ctrl_LeftArrow=-115 ) do (
   if not defined name (
      set name=%%a
   ) else (
      set action[%%a]=!name!
      set name=
   )
)
set EnterKey=13
set Digit0=48
set UpcaseZ=90
set LowcaseA=97
set HexDigit=0123456789ABCDEF

rem Show prompt with given, or current, attribute
set "attrib=%~1"
shift
if %attrib:~0,1% equ / (
   ColorShow %attrib% %1 / " "
   shift
) else (
   ColorShow "%attrib% "
   set attrib=
)

rem Get given, or current, attribute for options
set "attrib2=%~1"
if %attrib2:~0,1% equ / (
   set attrib=%attrib2%
   shift
)
if defined attrib goto getFocusAttrib
ColorShow
set /A "text=%errorlevel%&0xF, back=%errorlevel%>>4"
set attrib=/!HexDigit:~%back%,1!!HexDigit:~%text%,1!
:getFocusAttrib
set focusAttrib=/%attrib:~2,1%%attrib:~1,1%

rem Get options
set lastOpt=0
:nextOption
   set /A lastOpt+=1
   set option[%lastOpt%]=%~1
   CursorPos
   set position[%lastOpt%]=%errorlevel%
   ColorShow %attrib% "%~1" / " "
   for /F "delims=" %%a in ('Ascii "%~1"') do (
      for %%b in (%%a) do (
         if %%b geq %Digit0% if %%b leq %UpcaseZ% (
            set action[%%b]=%lastOpt%
            goto endOption
         )
      )
   )
   :endOption
   shift
if "%~1" neq "" goto nextOption

rem Select option
set /A opt=1, newOpt=1, key=0
CursorSize 0
:setFocus
   CursorPos !position[%opt%]!
   ColorShow %focusAttrib% option[%opt%]
   if %key% gtr 0 goto optSelected
   :nextKey
      GetKey
      set key=%errorlevel%
      if %key% equ %EnterKey% goto optSelected
      if %key% geq %LowcaseA% set /A key-=32
      if defined action[%key%] (
         if %key% lss 0 (
            call :!action[%key%]!
         ) else (
            set newOpt=!action[%key%]!
         )
      )
   if %newOpt% equ %opt% goto nextKey
   CursorPos !position[%opt%]!
   ColorShow %attrib% option[%opt%]
   set opt=%newOpt%
goto setFocus
:optSelected
CursorSize /L
echo/
exit /B %opt%

:RightArrow
if %opt% lss %lastOpt% set /A newOpt=opt+1
exit /B

:LeftArrow
if %opt% gtr 1 set /A newOpt=opt-1
exit /B

:Ctrl_RightArrow
if %opt% lss %lastOpt% set newOpt=%lastOpt%
exit /B

:Ctrl_LeftArrow
if %opt% gtr 1 set newOpt=1
exit /B