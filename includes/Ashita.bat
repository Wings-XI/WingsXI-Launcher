@echo off
cd %~dp0

FOR /F "tokens=* USEBACKQ" %%F IN (`ini.cmd WingsXI-Launcher.ini Launcher configFile`) DO (
SET configFile=%%F
)

cd ashita
echo %configFile%
if exist "%configFile%" (
start "" ashita.exe --config="%configFile%" --noupdate
) else (
start "" ashita.exe --noupdate
echo if you would like to launch a specific config, please set the full or relative path in the config
timeout /t 10
)
