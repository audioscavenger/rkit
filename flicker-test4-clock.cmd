:: Fifteen-segment display clock
::
:: neorobin @ 20161007_205515
::

@echo off

    set "_A="A = !!(x-1)""
    set "_B="B = (!!(x-1) ^& !!(x-4))""
    set "_C="C = 1""
    set "_D="D = (!(x^&3) ^| !!(x^&~3)) ^& !!(x-7)""
REM set "_E="E = 0""                                    & rem never display
    set "_F="F = !!(x-5)^&!!(x-6)""
    set "_G="G = !!(x-1)^&!!(x-7)""
    set "_H="H = !(!x ^| !(x-1) ^| !(x-7))""
    set "_I="I = 1""
    set "_J="J = ~x ^& 1 ^& !!(x-4)""
REM set "_K="K = 0""                                    & rem never display
    set "_L="L = !!(x-2)""
    set "_M="M = (!!(x-1) ^& !!(x-4) ^& !!(x-7))""
    set "_N="N = (!!(x-1) ^& !!(x-4) ^& !!(x-7))""
    set "_O="O = 1""


@echo off & setlocal enabledelayedexpansion

for /f "tokens=2 delims=[]" %%a in ('ver') do for /f "tokens=2 delims=. " %%a in ("%%a") do (
    set /a "NO_CLS=-((%%a-7)>>31)"
)

set /a "wid=37, hei=6, linesWantBackAbove = hei - 1, cntBS = 2 + (wid + 7) / 8 * linesWantBackAbove"
set "TAB=	" & for /F %%a in ('"prompt $h&for %%b in (1) do rem"')do Set "BS=%%a"
set "BSs=" & for /L %%a in (1 1 !cntBS!) do set "BSs=!BSs!%BS%"

color 0a & mode %wid%,%hei%

set "__=0" & set "_= "
for /l %%i in () do (
    set /a "t=!time:~-1!" & set /a "t ^= z, z ^= t"
    if !t! neq 0 (
        set "S=" & set "zeroOrOne=0"
        for %%L in ("A B C" "D _ F" "G H I" "J _ L" "M N O") do (
            for %%d in (0 _ 1 _ : _ 3 _ 4 _ : _ 6 _ 7 _ : _ 9 _ 10) do (
                if "%%d" geq "0" (
                    set "tm=!time: =0!" & set "x=!tm:~%%d,1!"
                    for %%_ in (%%~L) do set /a !_%%_! & set "S=!S!!%%_!"
                ) else if "!zeroOrOne!%%d"=="1:" (set "S=!S!*") else set "S=!S! "
            )
            set /a "zeroOrOne^=1"
        )
        set "S=!S:1=#!" & set "S=!S:0= !"

        if !NO_CLS!==1 (    (2>nul echo;%TAB%!BSs!) & <nul set /p "=%BS%"
        ) else              CLS

        <nul set /p "=!S!"
    )
)
Top