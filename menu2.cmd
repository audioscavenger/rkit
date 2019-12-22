@if (@CodeSection == @Batch) @then
:: https://stackoverflow.com/questions/31390783/batch-file-arrow-key-navigation
:: https://stackoverflow.com/questions/48199216/conditional-compilation-error-in-batch-working-for-one-script-but-not-anothers
:: add curshow and curpos: https://www.dostips.com/forum/viewtopic.php?f=3&t=3428

@echo off 

rem Create GetKey.exe auxiliary program and show its usage
rem http://www.dostips.com/forum/viewtopic.php?f=3&t=3428
rem Antonio Perez Ayala

echo Get a key from keyboard and return its value in ERRORLEVEL.
echo/
echo GetKey [/N]
echo/
echo Ascii characters are returned as positive values, extended keys as negative.
echo/
echo If /N switch is given, no wait for a key: immediately return zero if no key
echo was pressed.
echo/

if not exist GetKey.exe call :ExtractBinaryFile GetKey.exe
goto :EOF


rem Extract Binary File from hexadecimal digits placed in a "resource" in this .bat file

:ExtractBinaryFile filename.ext
setlocal EnableDelayedExpansion
set "start="
set "end="
for /F "tokens=1,3 delims=:=>" %%a in ('findstr /N /B "</*resource" "%~F0"') do (
   if not defined start (
      if "%%~b" equ "%~1" set start=%%a
   ) else if not defined end set end=%%a
)
(for /F "skip=%start% tokens=1* delims=:" %%a in ('findstr /N "^" "%~F0"') do (
   if "%%a" == "%end%" goto decodeHexFile
   echo %%b
)) > "%~1.hex"
:decodeHexFile
Cscript //nologo //E:JScript "%~F0" "%~1" < "%~1.hex"
del "%~1.hex"
exit /B

<resource id="GetKey.exe">
4D5A900003[3]04[3]FFFF[2]B8[7]40[35]B0[3]0E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F74
2062652072756E20696E20444F53206D6F64652E0D0D0A24[7]55B5B8FD11D4D6AE11D4D6AE11D4D6AE9FCBC5AE18D4D6AEED
F4C4AE13D4D6AE5269636811D4D6AE[8]5045[2]4C0102005A66D14F[8]E0000F010B01050C0002[3]02[7]10[3]10[3]20[4]40[2]10
[3]02[2]04[7]04[8]30[3]02[6]03[5]10[2]10[4]10[2]10[6]10[11]1820[2]3C[84]20[2]18[27]2E74657874[3]96[4]10[3]02[3]02[14]20[2]602E
7264617461[2]BA[4]20[3]02[3]04[14]40[2]40[8]E806[3]50E873[3]E840[3]E85F[3]803E00741866813E2F57740766813E2F77740A
FF150C20400085C07419FF151020400085C074073DE0[3]7508FF1510204000F7D8C3CCCCCCCCE82F[3]8BF08A06463C227509
8A06463C2275F9EB0C8A06463C20740484C075F54EC38A06463C2074F94EC3CCFF2504204000FF2500204000FF2510204000FF
250C2040[363]7A20[2]6C20[6]A420[2]9A20[6]5420[10]8C20[3]20[2]6020[10]AE20[2]0C20[22]7A20[2]6C20[6]A420[2]9A20[6]9B004578
697450726F6365737300E600476574436F6D6D616E644C696E6541006B65726E656C33322E646C6C[2]CE005F6765746368[2]11
015F6B62686974[2]6D73766372742E646C6C[328]
</resource>


@end


// Convert Ascii hexadecimal digits from Stdin to a binary string
var count, output = "";
while ( !WScript.Stdin.AtEndOfStream ) {
   var input = WScript.Stdin.ReadLine();
   for ( var index = 0; index < input.length; ) {
      if ( input.charAt(index) == '[' ) {
         for ( count = ++index; input.charAt(index) != ']' ; index++ ) ;
         count = parseInt(input.slice(count,index++));
         for ( var i = 1; i <= count; i++ ) output += String.fromCharCode(0);
      } else {
         output += String.fromCharCode(parseInt(input.substr(index,2),16));
         index += 2;
      }
   }
}

// Write the binary string to the output file
var ado = WScript.CreateObject("ADODB.Stream");
ado.Type = 2;  // adTypeText = 2
ado.CharSet = "iso-8859-1";  // right code page for output (no adjustments)
ado.Open();
ado.WriteText(output);
ado.SaveToFile(WScript.Arguments(0),2); // adSaveCreateOverWrite = 2
ado.Close();