@echo off
setlocal
pushd "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "install.ps1"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "enable.ps1"
if errorlevel 1 goto failed
echo.
echo ======================================================
echo Installation complete. Sign out and back in before typing.
echo ======================================================
popd
pause
exit /b 0
:failed
echo.
echo Installation did not complete. Read the error above.
popd
pause
exit /b 1
