[CmdletBinding()]
param(
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$remote = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object {
    $_.CommandLine -match 'desktop-commander' -and
    $_.CommandLine -match '\bremote\b'
  }

if (-not $remote) {
  Write-Host "Remote Desktop Commander device agent is not running." -ForegroundColor Yellow
  Read-Host "Press Enter to close"
  return
}

if (-not $Force) {
  $answer = Read-Host "Stop Remote Desktop Commander device-agent processes? Type YES to continue"
  if ($answer -ne "YES") {
    Write-Host "Cancelled."
    return
  }
}

foreach ($process in $remote) {
  Write-Host ("Stopping PID " + $process.ProcessId)
  Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
}

Write-Host "Remote Desktop Commander device agent stopped." -ForegroundColor Green
