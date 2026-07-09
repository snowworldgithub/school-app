@echo off
cd /d "%~dp0"
echo Starting Ahmed School App...
echo.
where py >nul 2>nul
if %errorlevel%==0 (
  start "" "http://localhost:8090"
  py -m http.server 8090
  goto :eof
)

where python >nul 2>nul
if %errorlevel%==0 (
  start "" "http://localhost:8090"
  python -m http.server 8090
  goto :eof
)

echo Python is required to start this local web app.
echo Install Python, then run this file again.
pause
