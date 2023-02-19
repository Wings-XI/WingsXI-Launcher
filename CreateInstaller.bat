cd %~dp0
robocopy /S "tools" "build"
robocopy /S "build" "patch_input" /XF patch.exe
start "" Install.iit