@echo off
setlocal
cd /d "%~dp0"
echo ======================================================
echo        Hanifi Rohingya Keyboard for Windows
echo          Brought to you by: Ahkter Husin
echo     Website: rohingyahub.org ^| GitHub: @arakaneserohingya
echo ======================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable.ps1"
if errorlevel 1 goto failed
echo.
echo ======================================================
echo Installation complete. Sign out and back in before typing.
echo ======================================================
pause
exit /b 0
:failed
echo.
echo Installation did not complete. Read the error above.
pause
exit /b 1
