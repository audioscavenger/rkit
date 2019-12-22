@if (@CodeSection == @Batch) @then
@echo off
rem Usage: xxx.cmd "first choice" "second choice" third fourth
rem Returns user choice as var variable - e.g. var=first choice
rem Screen is cleared on exit
setlocal EnableDelayedExpansion
rem Multi-line menu with options selection via DOSKEY
rem Antonio Perez Ayala
rem Define the options
set numOpts=0
set OPT=%*
if not DEFINED OPT set OPT="This is the First" Second Third Fourth Fifth "666 66" "777 777" 888 999 10101 111 1212
for %%a in (%OPT%) do set /A numOpts+=1&&set option[!numOpts!]=%%~a
rem Clear previous doskey history
doskey /LISTSIZE=!numOpts!
rem Fill doskey history with menu options
cscript //nologo /E:JScript "%~f0" EnterOpts
for /L %%i in (1,1,%numOpts%) do set /P "var="
cls
rem Send a F7 key to open the selection menu
cscript //nologo /E:JScript "%~f0" > nul
set var=
set /P "var=Select the desired option: " > nul
endlocal & set var=%var%
doskey /LISTSIZE=0
cls
goto :eof
@end
var wshShell = WScript.CreateObject("WScript.Shell"),
    envVar = wshShell.Environment("Process"),
    numOpts = parseInt(envVar("numOpts"));
if ( WScript.Arguments.Length ) {
   // Enter menu options
   for ( var i=1; i <= numOpts; i++ ) {
      wshShell.SendKeys(envVar("option["+i+"]")+"{ENTER}");
   }
} else {
   // Enter a F7 to open the menu
   wshShell.SendKeys("{F7}");
   wshShell.SendKeys("{HOME}");
}