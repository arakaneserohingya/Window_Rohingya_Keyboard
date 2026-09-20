@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "enable.ps1" -Remove
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "uninstall.ps1"
if errorlevel 1 goto failed
popd
pause
exit /b 0
:failed
echo Removal did not complete. Read the error above.
popd
pause
exit /b 1
