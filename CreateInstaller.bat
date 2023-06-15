cd %~dp0
robocopy /S "includes" "build"
robocopy /S "build" "patch_input" /XF patch.exe patch.dat version.txt /XD data
robocopy /S "build" "patch_input" /IF launchcfg
start "" Install.iit