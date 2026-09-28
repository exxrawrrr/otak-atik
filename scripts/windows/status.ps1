[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

function Test-Command($Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Find-SuperAssistant {
  $root = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
  if (-not (Test-Path $root)) { return $null }

  $id = "kngiafgkdnlkgmefdafaibkibegkcaef"
  $match = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
    ForEach-Object {
      $ext = Join-Path $_.FullName ("Extensions\" + $id)
      if (Test-Path $ext) { $ext }
    } |
    Select-Object -First 1

  return $match
}

Write-Host ""
Write-Host "otak-atik Windows status" -ForegroundColor Cyan
Write-Host "------------------------"

if (Test-Command "node") {
  Write-Host ("[ok] Node " + (node --version)) -ForegroundColor Green
} else {
  Write-Host "[!!] Node not found" -ForegroundColor Red
}

if (Test-Command "git") {
  Write-Host "[ok] Git detected" -ForegroundColor Green
} else {
  Write-Host "[--] Git not detected" -ForegroundColor Yellow
}

$remote = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object {
    $_.CommandLine -match 'desktop-commander' -and
    $_.CommandLine -match '\bremote\b'
  }

if ($remote) {
  Write-Host "[ok] Remote Desktop Commander device agent: RUNNING" -ForegroundColor Green
} else {
  Write-Host "[--] Remote Desktop Commander device agent: OFF" -ForegroundColor Yellow
}

$bridge = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -match 'mcp-superassistant-proxy' }

if ($bridge) {
  Write-Host "[ok] MCP SuperAssistant proxy: RUNNING" -ForegroundColor Green
} else {
  Write-Host "[--] MCP SuperAssistant proxy: OFF (optional)" -ForegroundColor DarkGray
}

$extension = Find-SuperAssistant
if ($extension) {
  Write-Host "[ok] MCP SuperAssistant Chrome extension detected" -ForegroundColor Green
} else {
  Write-Host "[--] MCP SuperAssistant Chrome extension not detected (optional)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Recommended remote MCP endpoint:"
Write-Host "https://mcp.desktopcommander.app/mcp" -ForegroundColor Cyan
Write-Host ""
Write-Host "Browser bridge is optional; it is not required for native Remote Desktop Commander."
Write-Host ""

Read-Host "Press Enter to close"
