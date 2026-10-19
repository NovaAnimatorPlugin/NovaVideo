@echo off
title NovaVideo
rem Runs NovaVideo.ps1 for this window only (does not change your PowerShell settings).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0NovaVideo.ps1" %*
echo.
pause
