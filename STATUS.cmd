@echo off
setlocal
title OTAK-ATIK STATUS
chcp 65001 >nul 2>&1
set "STATUS_SCRIPT=%USERPROFILE%\.otak-atik\windows\remote-growth-status.ps1"
if not exist "%STATUS_SCRIPT%" (
  echo.
  echo OTAK-ATIK is not installed yet.
  echo Run START.cmd first.
  pause
  exit /b 4
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%STATUS_SCRIPT%" %*
exit /b %ERRORLEVEL%
