@echo off
setlocal
title OTAK-ATIK - Remote AI Setup Wizard
chcp 65001 >nul 2>&1

set "BOOTSTRAP=%~dp0scripts\install.ps1"
set "INSTALLED_WIZARD=%USERPROFILE%\.otak-atik\windows\setup-wizard.ps1"

if not exist "%BOOTSTRAP%" (
  echo.
  echo OTAK-ATIK bootstrap files are incomplete.
  echo Please extract the full release ZIP before running START.cmd.
  pause
  exit /b 5
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP%" -NoOpenSetupPages
set "INSTALL_EXIT=%ERRORLEVEL%"
if not "%INSTALL_EXIT%"=="0" (
  echo.
  echo OTAK-ATIK could not prepare the local installation.
  pause
  exit /b %INSTALL_EXIT%
)

if not exist "%INSTALLED_WIZARD%" (
  echo.
  echo OTAK-ATIK installed files are incomplete.
  pause
  exit /b 5
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%INSTALLED_WIZARD%" %*
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo OTAK-ATIK stopped safely with code %EXIT_CODE%.
  pause
)
exit /b %EXIT_CODE%
