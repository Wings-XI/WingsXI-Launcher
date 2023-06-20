cd %~dp0
robocopy /S "includes" "build"
del /q patch_input\data
robocopy /S "build" "patch_input" /XF patch.exe patch.dat version.txt *.sft *.mfx *.ift *.dll
robocopy /S "build" "patch_input" /IF launchcfg
start "" Install.iit