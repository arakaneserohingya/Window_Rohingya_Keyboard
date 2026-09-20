@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "enable.ps1" -Predictive -Remove
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "install-predictive.ps1" -Remove
if errorlevel 1 goto failed
echo Predictive input method removed.
popd
pause
exit /b 0
:failed
echo Removal did not complete. Close apps using this input method, sign out, and try again.
popd
pause
exit /b 1
