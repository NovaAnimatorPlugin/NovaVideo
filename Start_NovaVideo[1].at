@echo off
title NovaVideo
py "%~dp0NovaVideo.py" %1 2>nul
if not errorlevel 1 goto :eof
python "%~dp0NovaVideo.py" %1
if not errorlevel 1 goto :eof
echo.
echo Python 3 was not found. Install it from https://www.python.org/downloads/
echo (tick "Add python.exe to PATH") and run this file again.
pause
