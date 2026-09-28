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
  @{ Name = "01 - START REMOTE DESKTOP.bat"; Script = "start-remote-desktop.ps1" },
  @{ Name = "02 - STATUS.bat"; Script = "status.ps1" },
  @{ Name = "03 - OPEN SETUP PAGES.bat"; Script = "open-setup-pages.ps1" },
  @{ Name = "04 - START BROWSER BRIDGE - OPTIONAL.bat"; Script = "start-browser-bridge.ps1" },
  @{ Name = "05 - STOP REMOTE DESKTOP.bat"; Script = "stop-remote-desktop.ps1" },
  @{ Name = "06 - SETUP CODEX LOCAL MCP - NO REMOTE QUOTA.bat"; Script = "setup-codex-local-mcp.ps1" },
  @{ Name = "07 - WHICH MODE SHOULD I USE.bat"; Script = "show-transport-guide.ps1" }
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
    Recommended for ChatGPT/web/mobile remote access.
    Uses the hosted Remote Desktop Commander path.

02 - STATUS
    Checks Node, Git, Remote Desktop Commander, and optional browser bridge.

03 - OPEN SETUP PAGES
    Opens setup documentation and provider pages.

04 - START BROWSER BRIDGE - OPTIONAL
    MCP SuperAssistant path. Not required for Remote Desktop Commander.

05 - STOP REMOTE DESKTOP
    Stops matching Remote Desktop Commander device-agent processes.

06 - SETUP CODEX LOCAL MCP - NO REMOTE QUOTA
    Configures local Desktop Commander MCP in Codex when Codex CLI is installed.

07 - WHICH MODE SHOULD I USE
    Shows the simple transport decision guide.

Remote MCP:
https://mcp.desktopcommander.app/mcp

Rule of thumb:
remote work -> remote MCP
local work  -> local MCP
"@

Set-Content -Path (Join-Path $target "README.txt") -Value $readme -Encoding UTF8

Write-Host ("Desktop launchers created: " + $target) -ForegroundColor Green
