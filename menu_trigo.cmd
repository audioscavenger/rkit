@echo off
rem DRAWEQUATION.BAT - Draw simple equations y=f(x) in X-Y plane
rem Antonio Perez Ayala

setlocal EnableDelayedExpansion
set and=if

Window Size
call :GetCoords numCols= numLines=
set /A maxCol=numCols-1, maxLine=numLines-1

:get_f(x)
title MS-DOS - Draw Equation
color
cls
echo/
echo Enter the equation as an arithmetic expression that just use X and constants.
echo/
echo You may increase drawing precision by managing decimal places; to do that,
echo chose a number of decimals (ie: 2) and use it this way:
echo/
echo In the equation follow these rules:
echo - To add/sub constants to X, include decimals to them: X+3.00  X-2.00
echo - Mul/Div of X by a constant is correct (no decimals): X*5  X/4
echo - To multiply X-term by X-term, divide the product by "one": X*X/1.00
echo - To divide X-term by X-term, multiply first term by "one": X*1.00/X
echo/
echo Enter drawing limits with decimals: -6.00,5.80 or -110.00,130.00
echo/
echo For example, this equation: (x+4)(x+1)(x-3)
echo must be entered this way:   (x+4.00)*(x+1.00)/1.00*(x-3.00)/1.00
echo/
echo Or the equivalent polynomial: x^^3+2x^^2-11x-12
echo is entered this way: x*x/1.00*x/1.00+2*x*x/1.00-11*x-12
echo/

set Of(x)=
set /P "Of(x)=Enter equation: "
if not defined Of(x) goto endDraw
set "f(x)=!Of(x):.=!"

:get_Xaxis
echo/
set /P "axis=Enter X axis limits (left,right): "
for /F "tokens=1,2 delims=, " %%a in ("%axis%") do (
   set Oleft=%%a
   set Oright=%%b
)
set left=%Oleft:.=%
set right=%Oright:.=%
set /A "xStep=(right-left)/maxCol, right=left+xStep*numCols"
if %xStep% equ 0 echo Must be larger (%numCols% steps at least) & goto get_Xaxis

:get_Yaxis
echo/
set /P "axis=Enter Y axis limits (bottom,top): "
for /F "tokens=1,2 delims=, " %%a in ("%axis%") do (
   set Obottom=%%a
   set Otop=%%b
)
set bottom=%Obottom:.=%
set top=%Otop:.=%
set /A "yStep=(top-bottom)/maxLine"
if %yStep% equ 0 echo Must be larger (%numLines% steps at least) & goto get_Yaxis

title MS-DOS - Draw Equation - y=!Of(x)!
color 17
cls
if %left% lss 0 %and% %right% gtr 0 (
   set /A "xZero=(-left)/xStep, xZeroM1=xZero-1"
   Show Otop:-!xZeroM1! 32 124  13 10
   CursorPos !xZero! +0
   for /L %%y in (2,1,%maxLine%) do (
      Show "|"
      CursorPos -1 +1
   )
   Show 13  Obottom:-!xZeroM1! 32 124
)

if %bottom% lss 0 %and% %top% gtr 0 (
   set /A "yZero=maxLine+(bottom)/yStep, maxColDiv2=maxCol/2"
   CursorPos=0,!yZero!
   Show 45*%maxCol%  13 10
   Show Oleft
   CursorPos=!maxColDiv2!,+0
   Show Oright:-!maxColDiv2!
)

set x=%left%
for /L %%x in (0,1,%maxCol%) do (
   set /A "y=(Top-(%f(x)%))/yStep"
   if !y! lss 0 (
      CursorPos=%%x,0
      echo ^^
   ) else if !y! gtr %maxLine% (
      CursorPos=%%x,%maxLine%
      echo v
   ) else (
      CursorPos=%%x,!y!
      echo @
   )
   set /A x+=xStep
)
CursorPos=0,%maxLine%
Show "Press any key when ready"
GetKey
goto get_f(x)

:DefineSinTable

rem Definition of SIN table values (SIN(x)*65535) for 0-360 degrees
rem Antonio Perez Ayala

set Quad1=0
for %%a in ( 1144  2287  3430  4572  5712  6850  7987  9121 10252 11380 12505 13626 14742 15855 16962 
            18064 19161 20252 21336 22415 23486 24550 25607 26656 27697 28729 29753 30767 31772 32768 
            33754 34729 35693 36647 37590 38521 39441 40348 41243 42126 42995 43852 44695 45525 46341 
            47143 47930 48703 49461 50203 50931 51643 52339 53020 53684 54332 54963 55578 56175 56756 
            57319 57865 58393 58903 59396 59870 60326 60764 61183 61584 61966 62328 62672 62997 63303 
            63589 63856 64104 64332 64540 64729 64898 65048 65177 65287 65376 65446 65496 65526 65535
           ) do (
   set /A Quad1+=1, Quad2=180-Quad1, Quad3=180+Quad1, Quad4=360-Quad1
   set SIN[!Quad1!]=%%a
   set SIN[!Quad2!]=%%a
   set SIN[!Quad3!]=-%%a
   set SIN[!Quad4!]=-%%a
)
for %%a in (0 180 360) do set SIN[%%a]=0

rem Additional values used in DRAWEQUATION.BAT (degrees must be multiple of 80)
set Quad5=360
for /L %%a in (1,1,40) do (
   set /A Quad5+=1
   set SIN[!Quad5!]=!SIN[%%a]!
)

for /L %%i in (1,1,5) do set Quad%%i=
exit /B


:endDraw
title MS-DOS
goto :EOF


:GetCoords Cols= Lines=
set /A "%1=%errorlevel%&0xFFFF, %2=(%errorlevel%>>16)&0xFFFF"
exit /B

