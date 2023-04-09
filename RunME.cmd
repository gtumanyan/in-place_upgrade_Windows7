@setlocal DisableDelayedExpansion
rem @echo off
REM change wording if needed for echo commands..
SET "Version=v1.2"


:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows

if exist %SystemRoot%\Sysnative\cmd.exe (
set "_cmdf=%~f0"
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %*"
exit /b
)

TITLE Create Modified Windows 11 ISO To Be Able To Directly Upgrade From a Windows 7 Install %version%

echo===============================================
echo Check for Admin rights...
echo===============================================
if not "%1"=="am_admin" powershell start -verb runas '%0' am_admin & exit /b

:gotAdmin
pushd "%CD%"
CD /D "%~dp0"
cls

set "_wimlib=%~dp0bin\wimlib-imagex.exe"

if exist "ISO" RD /S /Q "ISO"
MkDir "ISO"
echo.
echo===============================================
echo Extracting the source ISO...
echo===============================================
echo.
bin\7z x -y -o"ISO\" "Source_ISO\"
for /f "tokens=2 delims=: " %%# in ('dism.exe /english /get-wiminfo /wimfile:"ISO\sources\install.esd" /index:1 ^| find /i "Architecture"') do set warch=%%#
 echo.
echo===============================================
echo Adding the modified %warch% UpgradeMatrix.xml to the %warch% install.esd...
echo===============================================
echo.
for /f "tokens=3 delims=: " %%i in ('%_wimlib% info ISO\sources\install.esd ^| findstr /c:"Image Count"') do set images=%%i
for /L %%i in (1,1,%images%) do (
  %_wimlib% update "ISO\Sources\install.esd" %%i --command="add 'UpgradeMatrix\%warch%\UpgradeMatrix.xml' '\Windows\servicing\Editions\UpgradeMatrix.xml'"
)
pause
echo.
echo===============================================
echo Optimizing the ESD file...
echo===============================================
echo.
%_wimlib% optimize "ISO\Sources\install.esd"
echo.
echo===============================================
echo Creating the ISO...
echo===============================================
echo.
bin\oscdimg.exe -bootdata:2#p0,e,b"ISO\boot\etfsboot.com"#pEF,e,b"ISO\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -lWindows11_%warch% ISO Windows11_%warch%_For_W7_Upgrade.iso
echo.
echo===============================================
echo Cleaning up the ISO folder...
echo===============================================
if exist "ISO" RD /S /Q "ISO"
echo.