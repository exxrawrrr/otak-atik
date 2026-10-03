@echo off
setlocal
title OTAK-ATIK STATUS
chcp 65001 >nul 2>&1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\windows\remote-growth-status.ps1"
exit /b %ERRORLEVEL%
