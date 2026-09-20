@echo off
setlocal
cd /d "%~dp0"
echo ======================================================
echo    Hanifi Rohingya Predictive Keyboard for Windows
echo          Brought to you by: Ahkter Husin
echo     Website: rohingyahub.org ^| GitHub: @arakaneserohingya
echo ======================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-predictive.ps1"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0enable.ps1" -Predictive
if errorlevel 1 goto failed
echo.
echo ======================================================
echo Sign out and back in. Select Hanifi Rohingya Predictive with Win+Space.
echo ======================================================
pause
exit /b 0
:failed
echo.
echo Predictive installation did not complete. Read the error above.
pause
exit /b 1
