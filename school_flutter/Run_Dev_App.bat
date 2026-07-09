@echo off
cd /d "%~dp0"
echo Starting Ahmed School App in development mode...
echo Changes in lib\main.dart will hot reload while this window stays open.
echo.
D:\flutter\bin\flutter.bat run -d windows
pause
