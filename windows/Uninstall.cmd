@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable.ps1" -Remove
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
if errorlevel 1 goto failed
pause
exit /b 0
:failed
echo Removal did not complete. Read the error above.
pause
exit /b 1
