@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-predictive.ps1"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable.ps1" -Predictive
if errorlevel 1 goto failed
echo Sign out and back in. Select Hanifi Rohingya Predictive with Win+Space.
pause
exit /b 0
:failed
echo Predictive installation did not complete. Read the error above.
pause
exit /b 1
