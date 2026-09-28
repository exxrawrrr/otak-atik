[CmdletBinding()]
param(
  [string]$RuntimeRoot = (Join-Path $HOME ".otak-atik\windows")
)

$ErrorActionPreference = "Stop"

$desktop = [Environment]::GetFolderPath("Desktop")
if (-not $desktop) {
  throw "Unable to resolve Desktop folder."
}

$target = Join-Path $desktop "OTAK-ATIK"
New-Item -ItemType Directory -Force -Path $target | Out-Null

$launchers = @(
  @{
    Name = "01 - START REMOTE DESKTOP.bat"
    Script = "start-remote-desktop.ps1"
  },
  @{
    Name = "02 - STATUS.bat"
    Script = "status.ps1"
  },
  @{
    Name = "03 - OPEN SETUP PAGES.bat"
    Script = "open-setup-pages.ps1"
  },
  @{
    Name = "04 - START BROWSER BRIDGE - OPTIONAL.bat"
    Script = "start-browser-bridge.ps1"
  },
  @{
    Name = "05 - STOP REMOTE DESKTOP.bat"
    Script = "stop-remote-desktop.ps1"
  }
)

foreach ($item in $launchers) {
  $script = Join-Path $RuntimeRoot $item.Script
  $bat = Join-Path $target $item.Name

  $content = @"
@echo off
title otak-atik
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$script"
if errorlevel 1 pause
"@

  Set-Content -Path $bat -Value $content -Encoding ASCII
}

$readme = @"
OTAK-ATIK WINDOWS LAUNCHERS

01 - START REMOTE DESKTOP
    Recommended. Starts Remote Desktop Commander device agent.

02 - STATUS
    Checks Node, Git, Remote Desktop Commander, and optional browser bridge.

03 - OPEN SETUP PAGES
    Opens setup documentation, Remote Desktop Commander, and MCP SuperAssistant.

04 - START BROWSER BRIDGE - OPTIONAL
    Only needed for the MCP SuperAssistant browser-extension path.

05 - STOP REMOTE DESKTOP
    Stops matching Remote Desktop Commander device-agent processes.

Remote MCP endpoint:
https://mcp.desktopcommander.app/mcp
"@

Set-Content -Path (Join-Path $target "README.txt") -Value $readme -Encoding UTF8

Write-Host ("Desktop launchers created: " + $target) -ForegroundColor Green
