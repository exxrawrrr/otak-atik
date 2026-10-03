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
$GuidedDataRoot = if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "otak-atik" } else { $Target }
$RuntimeSourceRoot = Join-Path $GuidedDataRoot "runtime-source\remote-growth-stable"
$BrowserConfig = Join-Path $Target "mcp-superassistant.json"
$BrowserConfigSource = Join-Path $RepoRoot "config\browser-bridge\mcp-superassistant.json"
$FirstRunMarker = Join-Path $Target "install.complete"

Write-Host ""
Write-Host "OTAK-ATIK installer" -ForegroundColor Cyan
Write-Host "Created by Rafdi D. Ulhaq - exxrawrrr" -ForegroundColor DarkGray
Write-Host "-------------------"

$NodeReady = $false
$nodeCommand = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCommand) {
  try {
    $NodeMajor = [int](node -p "process.versions.node.split('.')[0]")
    if ($NodeMajor -ge 20) {
      $NodeReady = $true
      Write-Host ("[ok] Node " + (node --version))
    } else {
      Write-Warning "Node.js is below 20. Guided Windows setup will still work; developer CLI linking will be skipped."
    }
  } catch {
    Write-Warning "Node.js could not be inspected. Guided Windows setup will still work."
  }
} else {
  Write-Host "[--] Node.js not found (optional for guided Windows setup)" -ForegroundColor DarkGray
}

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
  Write-Host ("Would copy portable 64-tool runtime source to: " + $RuntimeSourceRoot)
  Write-Host ("Would prepare browser bridge config: " + $BrowserConfig)
  if (-not $NoDesktopLaunchers) {
    Write-Host ("Would create primary launchers under: " + $desktopTarget)
    Write-Host "  START.cmd  STATUS.cmd  REPAIR.cmd"
    Write-Host ("Would keep advanced utilities under: " + (Join-Path $desktopTarget "ADVANCED"))
  }
  if ($NodeReady) {
    Write-Host "Would run: npm link"
  } else {
    Write-Host "Would skip npm link because Node.js 20+ is optional for the guided Windows path."
  }
  Write-Host "Would preserve existing user config unless -Force is supplied."
  Write-Host "Would NOT open setup pages unless -OpenSetupPages is explicitly supplied."
  Write-Host ""
  Write-Host "No modifications performed."
  exit 0
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null
New-Item -ItemType Directory -Force -Path $RuntimeRoot | Out-Null
New-Item -ItemType Directory -Force -Path $GuidedDataRoot | Out-Null
New-Item -ItemType Directory -Force -Path $RuntimeSourceRoot | Out-Null

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

Copy-Item (Join-Path $RepoRoot "scripts\windows\*") $RuntimeRoot -Recurse -Force
Write-Host ("[sync] Windows helpers -> " + $RuntimeRoot)

Copy-Item (Join-Path $RepoRoot "runtime\remote-growth-stable\*") $RuntimeSourceRoot -Recurse -Force
Write-Host ("[sync] Remote GROWTH runtime source -> " + $RuntimeSourceRoot)

if ($NodeReady) {
  Push-Location $RepoRoot
  try {
    npm link
  } finally {
    Pop-Location
  }
} else {
  Write-Host "[skip] npm link (Node.js 20+ not available; guided Windows setup remains available)"
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
