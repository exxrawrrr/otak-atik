@echo off
setlocal
title OTAK-ATIK REPAIR
chcp 65001 >nul 2>&1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\premium-launcher.ps1" -Mode Repair %*
exit /b %ERRORLEVEL%
