[CmdletBinding()]
param(
  [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

$npx = (Get-Command npx.cmd -ErrorAction Stop).Source

$remote = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object {
    $_.CommandLine -match 'desktop-commander' -and
    $_.CommandLine -match '\bremote\b'
  }

if ($remote) {
  Write-Host "Remote Desktop Commander is already running." -ForegroundColor Green
  $remote | Select-Object ProcessId, Name, CommandLine | Format-Table -AutoSize
  if (-not $CheckOnly) {
    Read-Host "Press Enter to close"
  }
  return
}

if ($CheckOnly) {
  Write-Output ("REMOTE_LAUNCH_READY | " + $npx)
  return
}

Write-Host ""
Write-Host "Starting Remote Desktop Commander..." -ForegroundColor Cyan
Write-Host "Keep this window open while remote access is needed."
Write-Host ""

& $npx "@wonderwhy-er/desktop-commander@latest" "remote"

if ($LASTEXITCODE -ne 0) {
  throw ("REMOTE_DESKTOP_COMMANDER_EXIT_" + $LASTEXITCODE)
}
