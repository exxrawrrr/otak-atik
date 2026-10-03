@echo off
setlocal
title OTAK-ATIK REPAIR
chcp 65001 >nul 2>&1
set "REPAIR_SCRIPT=%USERPROFILE%\.otak-atik\windows\remote-growth-repair.ps1"
if not exist "%REPAIR_SCRIPT%" (
  echo.
  echo OTAK-ATIK is not installed yet.
  echo Run START.cmd first.
  pause
  exit /b 4
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%REPAIR_SCRIPT%" %*
exit /b %ERRORLEVEL%
