@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "install-predictive.ps1"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "enable.ps1" -Predictive
if errorlevel 1 goto failed
echo.
echo ======================================================
echo Sign out and back in. Select Hanifi Rohingya Predictive with Win+Space.
echo ======================================================
popd
pause
exit /b 0
:failed
echo.
echo Predictive installation did not complete. Read the error above.
popd
pause
exit /b 1
