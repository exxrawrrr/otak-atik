[CmdletBinding()]
param(
  [string]$RuntimeRoot = (Join-Path $HOME ".otak-atik\windows"),
  [string]$SourceRoot = ""
)

$ErrorActionPreference = "Stop"

$desktop = [Environment]::GetFolderPath("Desktop")
if (-not $desktop) {
  throw "Unable to resolve Desktop folder."
}

$target = Join-Path $desktop "OTAK-ATIK"
$advanced = Join-Path $target "ADVANCED"
New-Item -ItemType Directory -Force -Path $target | Out-Null
New-Item -ItemType Directory -Force -Path $advanced | Out-Null

# Remove only launcher names that this project itself created in older versions.
$legacyRootLaunchers = @(
  "01 - START REMOTE DESKTOP.bat",
  "02 - STATUS.bat",
  "03 - OPEN SETUP PAGES.bat",
  "04 - START BROWSER BRIDGE - OPTIONAL.bat",
  "05 - STOP REMOTE DESKTOP.bat",
  "06 - SETUP CODEX LOCAL MCP - NO REMOTE QUOTA.bat",
  "07 - WHICH MODE SHOULD I USE.bat"
)

foreach ($name in $legacyRootLaunchers) {
  $old = Join-Path $target $name
  if (Test-Path $old) {
    Remove-Item -LiteralPath $old -Force
  }
}

$wizardScript = Join-Path $RuntimeRoot "setup-wizard.ps1"
$sourceArg = ""
if ($SourceRoot) {
  $safeSourceRoot = $SourceRoot.Replace('"', '')
  $sourceArg = ' -SourceRoot "' + $safeSourceRoot + '"'
}

$startContent = @"
@echo off
setlocal
title OTAK-ATIK - Remote AI Setup Wizard
chcp 65001 >nul 2>&1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$wizardScript"$sourceArg
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  echo.
  echo OTAK-ATIK stopped safely with code %EXIT_CODE%.
  pause
)
exit /b %EXIT_CODE%
"@

Set-Content -Path (Join-Path $target "START.cmd") -Value $startContent -Encoding ASCII

$advancedLaunchers = @(
  @{ Name = "START REMOTE DESKTOP.bat"; Script = "start-remote-desktop.ps1" },
  @{ Name = "LEGACY STATUS.bat"; Script = "status.ps1" },
  @{ Name = "OPEN SETUP PAGES.bat"; Script = "open-setup-pages.ps1" },
  @{ Name = "START BROWSER BRIDGE - OPTIONAL.bat"; Script = "start-browser-bridge.ps1" },
  @{ Name = "STOP REMOTE DESKTOP.bat"; Script = "stop-remote-desktop.ps1" },
  @{ Name = "SETUP CODEX LOCAL MCP.bat"; Script = "setup-codex-local-mcp.ps1" },
  @{ Name = "TRANSPORT GUIDE.bat"; Script = "show-transport-guide.ps1" }
)

foreach ($item in $advancedLaunchers) {
  $script = Join-Path $RuntimeRoot $item.Script
  $bat = Join-Path $advanced $item.Name

  $content = @"
@echo off
title OTAK-ATIK Advanced
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$script"
if errorlevel 1 pause
"@

  Set-Content -Path $bat -Value $content -Encoding ASCII
}

$readme = @"
OTAK-ATIK

Primary action:
  START.cmd

The main folder is intentionally simple so a new user does not need
to choose between transport implementations.

Advanced / historical utilities are kept under:
  ADVANCED\

The guided setup wizard owns the recommended user journey.

Created by Rafdi D. Ulhaq - exxrawrrr
"@

Set-Content -Path (Join-Path $target "README.txt") -Value $readme -Encoding UTF8

Write-Host ("Desktop launcher ready: " + (Join-Path $target "START.cmd")) -ForegroundColor Green
Write-Host ("Advanced utilities: " + $advanced) -ForegroundColor DarkGray
