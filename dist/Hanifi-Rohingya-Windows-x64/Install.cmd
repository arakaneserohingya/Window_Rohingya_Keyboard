@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable.ps1"
if errorlevel 1 goto failed
echo Installation complete. Sign out and back in before typing.
pause
exit /b 0
:failed
echo Installation did not complete. Read the error above.
pause
exit /b 1
