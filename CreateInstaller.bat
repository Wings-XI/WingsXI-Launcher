cd %~dp0
robocopy /S "includes" "build"
robocopy /S "build" "patch_input" /XF patch.exe
start "" Install.iit