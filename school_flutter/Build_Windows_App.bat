@echo off
setlocal
cd /d "%~dp0"

set APP_FOLDER=%~dp0Ahmed_School_App_Windows
set APP_ZIP=%~dp0Ahmed_School_App_Windows.zip

echo Building Ahmed School App for Windows...
echo.
D:\flutter\bin\flutter.bat pub get
if errorlevel 1 goto failed

D:\flutter\bin\flutter.bat build windows
if errorlevel 1 goto failed

if exist "%APP_FOLDER%" rmdir /s /q "%APP_FOLDER%"
mkdir "%APP_FOLDER%"
xcopy /e /i /y "%~dp0build\windows\x64\runner\Release\*" "%APP_FOLDER%\"
if errorlevel 1 goto failed

powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%APP_FOLDER%\*' -DestinationPath '%APP_ZIP%' -Force"
if errorlevel 1 goto failed

echo.
echo Done.
echo App folder: %APP_FOLDER%
echo Zip file: %APP_ZIP%
echo Run: %APP_FOLDER%\school_flutter.exe
pause
exit /b 0

:failed
echo.
echo Build failed. Check the error above.
pause
exit /b 1
