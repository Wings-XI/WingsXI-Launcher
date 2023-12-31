@echo off
mode con: cols=160 lines=40
cd %~dp0
set folder=Backups
mkdir %folder%
compact /c %folder%
cd %folder%

For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
For /f "tokens=1-2 delims=/:" %%a in ("%TIME%") do (set mytime=%%a-%%b)

set folder=%mydate%_%mytime%

mkdir "%folder%"
cd "%folder%"

set params=/mir /NFL /NDL /MT:4 /S /R:2 /W:30
robocopy %params% "..\..\SquareEnix\FINAL FANTASY XI\USER" "User"

echo Macro backup complete
timeout /t 5

robocopy %params% "..\..\Ashita" "Ashita" /XF *.DAT *.PNG *.zip *.log *.7z *.wave  /XD logs

cd %~dp0
echo Ashita backup complete. Now renaming any windower stub files
powershell.exe -command "& {get-childitem '%cd%\Ashita' -recurse -file | ? name -eq 'windower' | rename-item -newname windower_old}"
echo Now removing all Dats\WingsXI-Custom files to ensure compliance
powershell.exe -command "& {get-childitem '%cd%\Ashita\plugins\DATs\' -directory -erroraction silentlycontinue | ? name -eq 'WingsXI-Custom' | remove-item -confirm:$false -force -recurse}"

timeout /t 5