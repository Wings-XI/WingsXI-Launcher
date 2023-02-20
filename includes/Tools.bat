@echo off
cd %~dp0

FOR /F "tokens=* USEBACKQ" %%F IN (`ini.cmd WingsXI-Launcher.ini Launcher region`) DO (
SET region=%%F
)

if [%region%]==[] (
set exeDir=SquareEnix\FINAL FANTASY XI\ToolsUS
) else (
set exeDir=SquareEnix\FINAL FANTASY XI\Tools%region%
)
echo %*
if exist "%exeDir%" (
start "" "%exeDir%\%*"
) else (
start "" "SquareEnix\FINAL FANTASY XI\ToolsUS\%*"
)
