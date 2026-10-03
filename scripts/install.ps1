param(
  [switch]$DryRun,
  [switch]$Force,
  [switch]$NoDesktopLaunchers,
  [switch]$OpenSetupPages,
  [switch]$NoOpenSetupPages
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$Target = Join-Path $HOME ".otak-atik"
$TargetConfig = Join-Path $Target "config.json"
$SourceConfig = Join-Path $RepoRoot "config\default.json"
$RuntimeRoot = Join-Path $Target "windows"
$BrowserConfig = Join-Path $Target "mcp-superassistant.json"
$BrowserConfigSource = Join-Path $RepoRoot "config\browser-bridge\mcp-superassistant.json"
$FirstRunMarker = Join-Path $Target "install.complete"

Write-Host ""
Write-Host "OTAK-ATIK installer" -ForegroundColor Cyan
Write-Host "Created by Rafdi D. Ulhaq - exxrawrrr" -ForegroundColor DarkGray
Write-Host "-------------------"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw "Node.js is required (20+)."
}

$NodeMajor = [int](node -p "process.versions.node.split('.')[0]")
if ($NodeMajor -lt 20) {
  throw "Node.js 20+ is required."
}

Write-Host ("[ok] Node " + (node --version))

if (Get-Command git -ErrorAction SilentlyContinue) {
  Write-Host "[ok] Git detected"
} else {
  Write-Warning "Git was not detected."
}

$desktop = [Environment]::GetFolderPath("Desktop")
$desktopTarget = if ($desktop) { Join-Path $desktop "OTAK-ATIK" } else { "<unresolved>" }

if ($DryRun) {
  Write-Host ""
  Write-Host "DRY RUN" -ForegroundColor Yellow
  Write-Host ("Would create/update: " + $Target)
  Write-Host ("Would copy Windows helpers to: " + $RuntimeRoot)
  Write-Host ("Would prepare browser bridge config: " + $BrowserConfig)
  if (-not $NoDesktopLaunchers) {
    Write-Host ("Would create primary launcher: " + (Join-Path $desktopTarget "START.cmd"))
    Write-Host ("Would keep advanced utilities under: " + (Join-Path $desktopTarget "ADVANCED"))
  }
  Write-Host "Would run: npm link"
  Write-Host "Would preserve existing user config unless -Force is supplied."
  Write-Host "Would NOT open setup pages unless -OpenSetupPages is explicitly supplied."
  Write-Host ""
  Write-Host "No modifications performed."
  exit 0
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null
New-Item -ItemType Directory -Force -Path $RuntimeRoot | Out-Null

if ((Test-Path $TargetConfig) -and -not $Force) {
  Write-Host ("[keep] Existing config: " + $TargetConfig)
} else {
  Copy-Item $SourceConfig $TargetConfig -Force
  Write-Host ("[write] " + $TargetConfig)
}

if (-not (Test-Path $BrowserConfig) -or $Force) {
  Copy-Item $BrowserConfigSource $BrowserConfig -Force
  Write-Host ("[write] " + $BrowserConfig)
} else {
  Write-Host ("[keep] Existing browser bridge config: " + $BrowserConfig)
}

Copy-Item (Join-Path $RepoRoot "scripts\windows\*.ps1") $RuntimeRoot -Force
Write-Host ("[sync] Windows helpers -> " + $RuntimeRoot)

Push-Location $RepoRoot
try {
  npm link
} finally {
  Pop-Location
}

if (-not $NoDesktopLaunchers) {
  & (Join-Path $RuntimeRoot "install-launchers.ps1") -RuntimeRoot $RuntimeRoot -SourceRoot $RepoRoot
}

Set-Content -Path $FirstRunMarker -Value (Get-Date).ToString("o") -Encoding ASCII

$shouldOpen = $OpenSetupPages -and -not $NoOpenSetupPages
if ($shouldOpen) {
  & (Join-Path $RuntimeRoot "open-setup-pages.ps1")
}

Write-Host ""
Write-Host "Installed." -ForegroundColor Green
Write-Host "Recommended next step:"
Write-Host ("  " + (Join-Path $desktopTarget "START.cmd")) -ForegroundColor Cyan
Write-Host ""
Write-Host "The guided wizard will tell the user when an external login page is actually needed."
