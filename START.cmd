@echo off
setlocal
title OTAK-ATIK - Remote AI Setup Wizard
chcp 65001 >nul 2>&1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\setup-wizard.ps1" -SourceRoot "%~dp0"
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo OTAK-ATIK stopped safely with code %EXIT_CODE%.
  pause
)
exit /b %EXIT_CODE%
