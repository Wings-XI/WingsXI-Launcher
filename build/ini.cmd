@setlocal enableextensions enabledelayedexpansion
@echo off
REM https://stackoverflow.com/questions/2866117/windows-batch-script-to-read-an-ini-file
set file=%~1
set area=[%~2]
set key=%~3
set currarea=
for /f "usebackq delims=" %%a in ("!file!") do (
    set ln=%%a
    if "x!ln:~0,1!"=="x[" (
        set currarea=!ln!
    ) else (
        for /f "tokens=1,2 delims==" %%b in ("!ln!") do (
            set currkey=%%b
            set currval=%%c
            if "x!area!"=="x!currarea!" if "x!key!"=="x!currkey!" (
                echo !currval!
            )
        )
    )
)
endlocal
