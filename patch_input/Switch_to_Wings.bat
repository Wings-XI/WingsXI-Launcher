@echo off
echo NOTE: Make sure this .bat file is located in the \PlayOnline\SquareEnix\ directory for the install you wish to play on. Example: C:\Program Files (x86)\PlayOnline\SquareEnix\Switch.bat
echo.
pause
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Administrative permissions confirmed.
    echo. 
    echo This .bat will re-register FFXi.dll, FFXiMain.dll, and FFXiVersions.dll for this folder's install.
    echo If you have placed this Switch.bat correctly per the note above, hit any key to continue.
    pause
    goto DLL
) else (
    echo These commands require administrator permissions. Run this .bat file as admin to proceed.
    echo. 
    echo This window will now close when you hit any key.
    pause >nul
    exit
)

:DLL
@echo on
if "%PROCESSOR_ARCHITECTURE%"=="x86" (set architecture=) else (set architecture=\WOW6432Node)

reg add "HKLM\SOFTWARE%architecture%\PlayOnlineUS\InstallFolder" /v 0001 /d "%~dp0FINAL FANTASY XI" /f
reg add "HKLM\SOFTWARE%architecture%\PlayOnlineUS\InstallFolder" /v 0002 /d "%~dp0TetraMaster" /f
reg add "HKLM\SOFTWARE%architecture%\PlayOnlineUS\InstallFolder" /v 1000 /d "%~dp0PlayOnlineViewer" /f
reg add "HKLM\SOFTWARE%architecture%\PlayOnlineUS\SquareEnix\FinalFantasyXI" /v 0042 /d "%~dp0FINAL FANTASY XI" /f
reg add "HKLM\SOFTWARE%architecture%\PlayOnlineUS\Interface" /v 0001 /d "38fbfb02" /f

regsvr32 /s "%~dp0\FINAL FANTASY XI\FFXi.dll"
regsvr32 /s "%~dp0\FINAL FANTASY XI\FFXiMain.dll"
regsvr32 /s "%~dp0\FINAL FANTASY XI\FFXiVersions.dll"

pause