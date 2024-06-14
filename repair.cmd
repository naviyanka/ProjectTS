@set naviver=2.6
@setlocal DisableDelayedExpansion
@echo off


set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64 bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
if /i "%%#"=="r1" set r1=1
if /i "%%#"=="r2" set r2=1
if /i "%%#"=="-qedit" (
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "1" /f 1>nul
rem check the code below admin elevation to understand why it's here
)
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
setlocal EnableDelayedExpansion
start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
exit /b
endlocal
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
setlocal EnableDelayedExpansion
start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
exit /b
endlocal
)

::========================================================================================================================================

set "blank="
set "mas=ht%blank%tps%blank%://mass%blank%grave.dev/"

::  Check if Null service is working, it's important for the batch script

sc query Null | find /i "RUNNING"
if %errorlevel% NEQ 0 (
echo:
echo Null service is not running, script may crash...
echo:
echo:
echo Help - %mas%troubleshoot.html
echo:
echo:
ping 127.0.0.1 -n 10
)
cls

::  Check LF line ending

pushd "%~dp0"
>nul findstr /v "$" "%~nx0" && (
echo:
echo Error: Script either has LF line ending issue or an empty line at the end of the script is missing.
echo:
ping 127.0.0.1 -n 6 >nul
popd
exit /b
)
popd

::========================================================================================================================================

cls
color 07
title  Microsoft_Windows_Repair %naviver%

set _args=
set _elev=
set _MASunattended=

set _args=%*
if defined _args set _args=%_args:"=%
if defined _args (
for %%A in (%_args%) do (
if /i "%%A"=="-el"                    set _elev=1
)
)

if defined _args echo "%_args%" | find /i "/" >nul && set _MASunattended=1

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set winbuild=1
set psc=powershell.exe
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G

set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (set _NCS=0)

call :_colorprep

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"

::========================================================================================================================================


for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
%nceline%
echo Unable to find powershell.exe in the system.
echo Aborting...
goto MASend
)

::========================================================================================================================================

::  Fix special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

echo "!_batf!" | find /i "!_ttemp!" %nul1% && (
if /i not "!_work!"=="!_ttemp!" (
%nceline%
echo Script is launched from the temp folder,
echo Most likely you are running the script directly from the archive file.
echo:
echo Extract the archive file and launch the script from the extracted folder.
goto MASend
)
)

::========================================================================================================================================

::  Elevate script as admin and pass arguments and preventing loop

%nul1% fltmc || (
if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
%nceline%
echo This script needs admin rights.
echo To do so, right click on this script and select 'Run as administrator'.
goto MASend
)

if not exist "%SystemRoot%\Temp\" mkdir "%SystemRoot%\Temp" %nul%

::========================================================================================================================================

::  This code disables QuickEdit for this cmd.exe session only without making permanent changes to the registry
::  It is added because clicking on the script window pauses the operation and leads to the confusion that script stopped due to an error

if defined _MASunattended set quedit=1
for %%# in (%_args%) do (if /i "%%#"=="-qedit" set quedit=1)

reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% || if not defined quedit (
reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "0" /f %nul1%
start cmd.exe /c ""!_batf!" %_args% -qedit"
rem quickedit reset code is added at the starting of the script instead of here because it takes time to reflect in some cases
exit /b
)

::========================================================================================================================================

::  Check for updates

set -=
set old=

for /f "delims=[] tokens=2" %%# in ('ping -4 -n 1 updatecheck.mass%-%grave.dev') do (
if not [%%#]==[] (echo "%%#" | find "127.69" %nul1% && (echo "%%#" | find "127.69.%naviver%" %nul1% || set old=1))
)

if defined old (
echo ________________________________________________
%eline%
echo You are running outdated version MAS %naviver%
echo ________________________________________________
echo:
if not defined _MASunattended (
echo [1] Get Latest MAS
echo [0] Continue Anyway
echo:
call :_color %_Green% "Enter a menu option in the Keyboard [1,0] :"
choice /C:10 /N
if !errorlevel!==2 rem
if !errorlevel!==1 (start ht%-%tps://github.com/mass%-%gravel/Microsoft-Acti%-%vation-Scripts & start %mas% & exit /b)
)
)
cls

::========================================================================================================================================

setlocal DisableDelayedExpansion

::  Check desktop location

set _desktop_=
for /f "skip=2 tokens=2*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_desktop_=%%b"
if not defined _desktop_ for /f "delims=" %%a in ('%psc% "& {write-host $([Environment]::GetFolderPath('Desktop'))}"') do call set "_desktop_=%%a"

setlocal EnableDelayedExpansion



::========================================================================================================================================

::========================================================================================================================================

::========================================================================================================================================

::========================================================================================================================================
:MainMenu

cls
color 07
title  Microsoft %blank%Activation %blank%Scripts %naviver%
mode 76, 30

echo:        
echo:            _   _             _                                                   
echo:    | \ | | __ ___   _(_)                                                  
echo:    |  \| |/ _` \ \ / / |                                                  
echo:    | |\  | (_| |\ V /| |                                                  
echo:    |_|_\_|\__,_| \_/ |_| _     _           _                 _            
echo:    |_   _| __ ___  _   _| |__ | | ___  ___| |__   ___   ___ | |_ ___ _ __ 
echo:      | || '__/ _ \| | | | '_ \| |/ _ \/ __| '_ \ / _ \ / _ \| __/ _ \ '__|
echo:      | || | | (_) | |_| | |_) | |  __/\__ \ | | | (_) | (_) | ||  __/ |   
echo:      |_||_|  \___/ \__,_|_.__/|_|\___||___/_| |_|\___/ \___/ \__\___|_|   
echo:
echo:
echo:             [1] Repair Windows
echo:             [2] Repair Microsoft Store
echo:             [3] Repair Windows Security
echo:             [4] SFC Scan
echo:             [5] DISM Commands
echo:             [6] Activation Services
echo:             [7] Performance Increment
echo:             [8] Help
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
call :_color2 %_White% "          " %_Green% "Enter a menu option in the Keyboard [1,2,3,4,5,6,7,8,0] :"
choice /C:123456780 /N
set _erl=%errorlevel%

if %_erl%==9 exit /b
if %_erl%==8 start %mas%troubleshoot.html & goto :MainMenu
if %_erl%==7 setlocal & call :performance      & cls & endlocal & goto :MainMenu
if %_erl%==6 setlocal & call :masact      & cls & endlocal & goto :MainMenu
if %_erl%==5 setlocal & call :DISM & cls & endlocal & goto :MainMenu
if %_erl%==4 setlocal & call :SFC     & cls & endlocal & goto :MainMenu
if %_erl%==3 setlocal & call :ReWinSec   & cls & endlocal & goto :MainMenu
if %_erl%==2 goto :ReMSStore
if %_erl%==1 setlocal & call :ReWin    & cls & endlocal & goto :MainMenu
goto :MainMenu
endlocal
::========================================================================================================================================

:ReMSStore

cls
color 07
title  Microsoft %blank%Activation %blank%Scripts %naviver%
mode 76, 30

echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                  Microsoft Windows Repair Methods:
echo:
echo:             [1] Reset Microsoft Store
echo:             [2] Remove Microsoft Store
echo:             [3] Re-register Microsoft Store
echo:             [4] Winget (Not Working)
echo:             [5] Download Microsoft Store Package
echo:             [6] Install Microsoft Store Package
echo:             [7] Go Back
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
call :_color2 %_White% "          " %_Green% "Enter a menu option in the Keyboard [1,2,3,4,5,6,7,8,0] :"
choice /C:123456780 /N
set _erl=%errorlevel%

if %_erl%==9 exit /b
if %_erl%==8 start %mas%troubleshoot.html & goto :MainMenu
if %_erl%==7 goto:MainMenu
if %_erl%==6 setlocal & call :InStore      & cls & endlocal & goto :ReMSStore
if %_erl%==5 setlocal & call :Dnstore & cls & endlocal & goto :ReMSStore
if %_erl%==4 setlocal & call :Winget     & cls & endlocal & goto :ReMSStore
if %_erl%==3 setlocal & call :Regstore   & cls & endlocal & goto :ReMSStore
if %_erl%==2 setlocal & call :RMstore   & cls & endlocal & goto :ReMSStore
if %_erl%==1 setlocal & call :RSstore    & cls & endlocal & goto :ReMSStore
goto :ReMSStore
endlocal
:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


::========================================================================================================================================

::========================================================================================================================================

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
:InStore
setlocal EnableDelayedExpansion
@echo off
cls
color 07
title Install Microsoft Store %naviver%
set _unattended=0
set "_exitmsg=Go back"
set psc=powershell.exe
cls
mode 110, 34
title  Install Microsoft Store %naviver%

echo:
echo Installing Microsoft Store Package...
set "packageDir=%USERPROFILE%\Desktop"
for %%G in ("%packageDir%\Microsoft.WindowsStore*.msixbundle") do (
    set "packagePath=%%~fG"
)
if not defined packagePath (
    echo No matching package file found.
    pause
    exit /b
)
powershell -Command "Add-AppxPackage -Path '!packagePath!'"
pause
goto dk_done

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
:Dnstore
@setlocal EnableDelayedExpansion
@echo off
cls
color 07
title Download Microsoft Store %naviver%
set _unattended=0
set "_exitmsg=Go back"
set psc=powershell.exe
cls
mode 110, 34
title  Download Microsoft Store %naviver%

echo:
echo Downloading Microsoft Store Package...
set pscript="C:\xamppp\htdocs\test1.ps1"
powershell -File "!pscript!"
pause
goto dk_done


:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:Winget
@echo off
setlocal enabledelayedexpansion

REM Define the path to the PowerShell executable based on system architecture
set "psExe=PowerShell.exe"

REM Specify the full path to the PowerShell executable
set "psPath=C:\Windows\system32\WindowsPowerShell\v1.0\%psExe%"

REM Define the winget command you want to run
set "wingetCommand=winget your-command-here"

REM Save the output of the winget command to a text file
"%psPath%" -Command "!wingetCommand!" > output.txt

REM Display the contents of the output file
type output.txt

REM Optionally, pause at the end to view the output before closing the window
pause

endlocal
goto dk_done

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
:Regstore
@setlocal DisableDelayedExpansion
@echo off
cls
color 07
title Register Microsoft Store %naviver%
set _unattended=0
set "_exitmsg=Go back"
set psc=powershell.exe
cls
mode 110, 34
title  Register Microsoft Store %naviver%

echo:
echo Initializing...
echo Registering Microsoft Store...

PowerShell -ExecutionPolicy Bypass -NoProfile -Command "Get-AppXPackage -AllUsers Microsoft.WindowsStore* | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}"

goto dk_done





:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:RSstore
@setlocal DisableDelayedExpansion
@echo off
cls
color 07
title Reset Microsoft Store %naviver%
set _unattended=0

cls
mode 110, 34
title  Reset Microsoft Store %naviver%

echo:
echo Initializing...
echo Resetting Microsoft Store...
wsreset.exe
goto dk_done


:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:RMstore
@setlocal DisableDelayedExpansion
@echo off
cls
color 07
title Remove Microsoft Store %naviver%
set _unattended=0

::========================================================================================================================================
::set "nul=>nul 2>&1"
set "_exitmsg=Go back"
set psc=powershell.exe
::========================================================================================================================================

::  Fix special characters limitation in path name

set "_work=%~dp0"
if "%_work:~-1%"=="\" set "_work=%_work:~0,-1%"

set "_batf=%~f0"
set "_batp=%_batf:'=''%"

set _PSarg="""%~f0""" -el %_args%

set "_ttemp=%userprofile%\AppData\Local\Temp"

setlocal EnableDelayedExpansion

::========================================================================================================================================

cls
mode 110, 34
title  Remove Microsoft Store %naviver%

echo:
echo Initializing...

::  Check PowerShell

%psc% $ExecutionContext.SessionState.LanguageMode %nul2% | find /i "Full" %nul1% || (
%eline%
%psc% $ExecutionContext.SessionState.LanguageMode
echo:
echo PowerShell is not working. Aborting...
echo If you have applied restrictions on Powershell then undo those changes.
echo:
echo Check this page for help. %mas%troubleshoot
goto dk_done
)
::========================================================================================================================================
call :ps_wsreset
goto dk_done

::========================================================================================================================================
:ps_wsreset
echo **WARNING:** Uninstalling the Microsoft Store can cause issues with your system and some functionalities might not work as expected. Proceed with caution and ensure you have a backup before running this script.

where PowerShell >nul 2>nul
if ERRORLEVEL 1 (
  echo PowerShell is not installed. This script requires PowerShell.
  exit /b 1
)

PowerShell -ExecutionPolicy Bypass -NoProfile -Command "Get-AppxPackage -alluser *WindowsStore* | Remove-Appxpackage"

if %ERRORLEVEL% EQU 0 (
  echo Microsoft Store uninstalled successfully.
) else (
  echo Error: Failed to uninstall Microsoft Store. (Error Code: %ERRORLEVEL%)
  echo  OR
  echo Microsoft Store might not be installed.
)
::========================================================================================================================================

::========================================================================================================================================

:dk_done

echo:
if %_unattended%==1 timeout /t 2 & exit /b
call :_color %_Yellow% "Press any key to %_exitmsg%..."
pause %nul1%
exit /b

::========================================================================================================================================

:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:_color

if %_NCS% EQU 1 (
if defined _unattended (echo %~2) else (echo %esc%[%~1%~2%esc%[0m)
) else (
if defined _unattended (echo %~2) else (call :batcol %~1 "%~2")
)
exit /b

:_color2

if %_NCS% EQU 1 (
echo %esc%[%~1%~2%esc%[%~3%~4%esc%[0m
) else (
call :batcol %~1 "%~2" %~3 "%~4"
)
exit /b

::=======================================

:: Colored text with pure batch method
:: Thanks to @dbenham and @jeb
:: stackoverflow.com/a/10407642

:batcol

pushd %_coltemp%
if not exist "'" (<nul >"'" set /p "=.")
setlocal
set "s=%~2"
set "t=%~4"
call :_batcol %1 s %3 t
del /f /q "'"
del /f /q "`.txt"
popd
exit /b

:_batcol

setlocal EnableDelayedExpansion
set "s=!%~2!"
set "t=!%~4!"
for /f delims^=^ eol^= %%i in ("!s!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~1 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
if "%~4"=="" echo(&exit /b
setlocal EnableDelayedExpansion
for /f delims^=^ eol^= %%i in ("!t!") do (
  if "!" equ "" setlocal DisableDelayedExpansion
    >`.txt (echo %%i\..\')
    findstr /a:%~3 /f:`.txt "."
    <nul set /p "=%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%%_BS%"
)
echo(
exit /b

::=======================================

:_colorprep

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"

set     "Red="41;97m""
set    "Gray="100;97m""
set   "Black="30m""
set   "Green="42;97m""
set    "Blue="44;97m""
set  "Yellow="43;97m""
set "Magenta="45;97m""

set    "_Red="40;91m""
set  "_Green="40;92m""
set   "_Blue="40;94m""
set  "_White="40;37m""
set "_Yellow="40;93m""

exit /b
)

for /f %%A in ('"prompt $H&for %%B in (1) do rem"') do set "_BS=%%A %%A"
set "_coltemp=%SystemRoot%\Temp"

set     "Red="CF""
set    "Gray="8F""
set   "Black="00""
set   "Green="2F""
set    "Blue="1F""
set  "Yellow="6F""
set "Magenta="5F""

set    "_Red="0C""
set  "_Green="0A""
set   "_Blue="09""
set  "_White="07""
set "_Yellow="0E""

exit /b

::========================================================================================================================================


:+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

:MASend
echo:
if defined _MASunattended timeout /t 2 & exit /b
echo Press any key to exit...
pause >nul
exit /b

::========================================================================================================================================
:: Leave empty line below
