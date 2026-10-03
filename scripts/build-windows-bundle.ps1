[CmdletBinding()]
param(
  [string]$OutputRoot = "",
  [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $Version) {
  $manifest = Get-Content -Raw -LiteralPath (Join-Path $repoRoot "package.json") | ConvertFrom-Json
  $Version = [string]$manifest.version
}
if (-not $OutputRoot) {
  $OutputRoot = Join-Path $repoRoot "dist"
}

$bundleName = "OTAK-ATIK-Windows-v$Version"
$stage = Join-Path $OutputRoot $bundleName
$zip = Join-Path $OutputRoot ($bundleName + ".zip")
$shaFile = $zip + ".sha256"

if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
if (Test-Path -LiteralPath $shaFile) { Remove-Item -LiteralPath $shaFile -Force }

New-Item -ItemType Directory -Force -Path $stage | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "scripts") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "config\browser-bridge") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "runtime") | Out-Null

foreach ($name in @("START.cmd","STATUS.cmd","REPAIR.cmd","LICENSE","NOTICE")) {
  Copy-Item -LiteralPath (Join-Path $repoRoot $name) -Destination (Join-Path $stage $name) -Force
}

Copy-Item -LiteralPath (Join-Path $repoRoot "scripts\install.ps1") -Destination (Join-Path $stage "scripts\install.ps1") -Force
Copy-Item -LiteralPath (Join-Path $repoRoot "scripts\windows") -Destination (Join-Path $stage "scripts\windows") -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repoRoot "runtime\remote-growth-stable") -Destination (Join-Path $stage "runtime\remote-growth-stable") -Recurse -Force
Copy-Item -LiteralPath (Join-Path $repoRoot "config\default.json") -Destination (Join-Path $stage "config\default.json") -Force
Copy-Item -LiteralPath (Join-Path $repoRoot "config\browser-bridge\mcp-superassistant.json") -Destination (Join-Path $stage "config\browser-bridge\mcp-superassistant.json") -Force

@"
OTAK-ATIK — Windows Guided Setup
Version $Version

Created by Rafdi D. Ulhaq - exxrawrrr

FIRST TIME
1. Extract this ZIP to a normal folder.
2. Double-click START.cmd.
3. Follow the terminal. Sign in only when Tailscale or Composio asks you.

AFTER SETUP
START.cmd  = continue setup / reconnect an account
STATUS.cmd = check whether everything is healthy
REPAIR.cmd = safely repair OTAK-ATIK-owned components

You do NOT need Git or Node.js for the guided Windows setup.
Do not move only one .cmd file by itself; keep the extracted folder together until START.cmd has prepared the Desktop launchers.

Security rules:
- your Remote GROWTH access code stays local;
- your Composio Project API Key is used in memory only;
- OTAK-ATIK will not kill unrelated processes that own its configured ports;
- public access is accepted only after unauthenticated traffic is rejected with HTTP 401 and authenticated inventory reports exactly 64 tools.

After the first START, the installer creates:
Desktop\OTAK-ATIK\START.cmd
Desktop\OTAK-ATIK\STATUS.cmd
Desktop\OTAK-ATIK\REPAIR.cmd

Those installed launchers use cached files outside this extracted bundle, so the downloaded folder is no longer required for normal operation.
"@ | Set-Content -LiteralPath (Join-Path $stage "README-FIRST.txt") -Encoding UTF8

Set-Content -LiteralPath (Join-Path $stage "VERSION.txt") -Value $Version -Encoding ASCII

$forbiddenNames = @("auth.key","composio.json","setup-state.json",".env")
$forbiddenPatterns = @(
  "D:\RAFDI_DATA",
  "C:\Users\User",
  "tail39bf37",
  "rafdiulhaq001@gmail.com"
)

$badNames = @(Get-ChildItem -LiteralPath $stage -Recurse -Force -File | Where-Object {
  $forbiddenNames -contains $_.Name
})
if ($badNames.Count -gt 0) {
  throw ("Release bundle contains forbidden runtime/secret files: " + (($badNames.FullName) -join ", "))
}

$findings = @()
Get-ChildItem -LiteralPath $stage -Recurse -File | ForEach-Object {
  $path = $_.FullName
  foreach ($pattern in $forbiddenPatterns) {
    $match = Select-String -LiteralPath $path -Pattern $pattern -SimpleMatch -ErrorAction SilentlyContinue
    if ($match) { $findings += $match }
  }
}
if ($findings.Count -gt 0) {
  $findings | Format-Table Path,LineNumber,Line -AutoSize
  throw "Release bundle contains machine-specific or private identity data."
}

Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal -Force
$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash.ToLowerInvariant()
Set-Content -LiteralPath $shaFile -Value ($hash + "  " + (Split-Path -Leaf $zip)) -Encoding ASCII

$result = [ordered]@{
  version = $Version
  bundle = $zip
  sha256 = $hash
  files = @(Get-ChildItem -LiteralPath $stage -Recurse -File).Count
  size_bytes = (Get-Item -LiteralPath $zip).Length
}

$result | ConvertTo-Json -Compress
