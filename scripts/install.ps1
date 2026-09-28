param(
  [switch]$DryRun,
  [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Target = Join-Path $HOME ".otak-atik"
$TargetConfig = Join-Path $Target "config.json"
$SourceConfig = Join-Path $RepoRoot "config\default.json"

Write-Host ""
Write-Host "otak-atik installer"
Write-Host "-------------------"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw "Node.js is required (20+)."
}

$NodeMajor = [int]((node -p "process.versions.node.split('.')[0]"))
if ($NodeMajor -lt 20) {
  throw "Node.js 20+ is required."
}

Write-Host "[ok] Node $(node --version)"

if (Get-Command git -ErrorAction SilentlyContinue) {
  Write-Host "[ok] Git detected"
} else {
  Write-Warning "Git was not detected."
}

if ($DryRun) {
  Write-Host ""
  Write-Host "DRY RUN"
  Write-Host "Would create: $Target"
  if (Test-Path $TargetConfig) {
    Write-Host "Would preserve existing config: $TargetConfig"
  } else {
    Write-Host "Would create config: $TargetConfig"
  }
  Write-Host "Would run: npm link"
  Write-Host ""
  Write-Host "No modifications performed."
  exit 0
}

New-Item -ItemType Directory -Force -Path $Target | Out-Null

if ((Test-Path $TargetConfig) -and -not $Force) {
  Write-Host "[keep] Existing config: $TargetConfig"
} else {
  Copy-Item $SourceConfig $TargetConfig -Force
  Write-Host "[write] $TargetConfig"
}

Push-Location $RepoRoot
try {
  npm link
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "Installed."
Write-Host "Run: otak-atik doctor"
