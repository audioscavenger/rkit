@echo off 
setlocal EnableDelayedExpansion

pause

call :task_new

goto :eof

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:task_new

setlocal 

call :Font

mode 48,6

set t0=!time!

(
 for /F "delims==" %%v in ('set') do if not %%v lss 5 set "%%v="

 set AF=1 %anti flikering. Keep redraw near timer coalescing for windows 7 and up%
 set /a t=100000, rn=0, n=t

 for /L %%N in (!t!,1,199999) do (
  set /a "n=%%N , p1=!n:~1,1!*3, p2=!n:~2,1!*3, p3=!n:~3,1!*3, p4=!n:~4,1!*3, p5=!n:~5,1!*3"
  for /f "tokens=1-5" %%p in ("!p1! !p2! !p3! !p4! !p5!") do (
   if defined AF For /L %%L in (0,3,27) do ( 
          if not "!OT!"=="!time:~10,1!" (
            cls & for %%R in (0 1 2 3 4) do echo(             !%%R:~%%p,3! !%%R:~%%q,3! !%%R:~%%r,3! !%%R:~%%s,3! !%%R:~%%t,3! !%%R:~%%L,3!
            set /a rn+=1
            set OT=!time:~10,1!
          )
        ) else For /L %%L in (0,3,27) do cls & for %%R in (0 1 2 3 4) do echo(           !%%R:~%%p,3! !%%R:~%%q,3! !%%R:~%%r,3! !%%R:~%%s,3! !%%R:~%%t,3! !%%R:~%%L,3!
  )
  if %%N gtr !t! (
    for /F "tokens=1-8 delims=:.," %%a in ("%t0: =0%:!time: =0!") do set /a "a=(((1%%e-1%%a)*60)+1%%f-1%%b)*6000+1%%g%%h-1%%c%%d, a+=(a>>31) & 8640000"
    if defined AF (set /a "FPS=rn*100/a, t+=(FPS+100)") else set /a "FPS=(%%N-100000)*100*10/a, t+=(FPS+800)"
    title %2 FPS=!FPS!
    set a=&set FPS=
  )

 ) %_END for /L %%N_%

) %_END BLOCK_%

endlocal

mode 80,25

goto :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:Font

Set "F=F6DE49279F3F3CFB793E73FCF7F249F7DFEF3C" % 3x5 Binary Font%

:: Decompact Font (This code is good for fonts with large number of characters. Leave for code snip)
For %%h in (0 1 2 3 4 5 6 7 8 9 A B C D E F
) do (
  set /a "r=10000+(0x%%h&8)/8*1000+(0x%%h&4)/4*100+(0x%%h&2)/2*10+(0x%%h&1)"
  For %%r in (!r:~1!) do set "F=!F:%%h=%%r!"
)

set F=!F:0=°!&set "F=!F:1=Û!" %ALT+0176 & ALT+0219%
rem set F=!F:0= !&set "F=!F:1=*!" %ASCII%

for /L %%i in (0,15,135) do for /L %%R in (0,1,4) do (
  set /a p=%%i+%%R*3
  for %%a in (!p!) do set %%R=!%%R!!F:~%%a,3!
)

goto :eof
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::