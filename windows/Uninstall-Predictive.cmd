@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable.ps1" -Predictive -Remove
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-predictive.ps1" -Remove
if errorlevel 1 goto failed
echo Predictive input method removed.
pause
exit /b 0
:failed
echo Removal did not complete. Close apps using this input method, sign out, and try again.
pause
exit /b 1
