$ErrorActionPreference = 'Stop'
$LocalRoot = Join-Path $env:LOCALAPPDATA 'otak-atik\remote-growth-native'
$ConfigPath = Join-Path $LocalRoot 'config.json'

if (-not (Test-Path $ConfigPath)) {
  Write-Output 'NOT_CONFIGURED'
  exit 0
}

$Config = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$Processes = @(Get-CimInstance Win32_Process | Where-Object {
  $_.Name -ieq 'tunnel-client.exe' -and
  $_.CommandLine -match '(?i)run' -and
  $_.CommandLine -match [regex]::Escape([string]$Config.profile_name)
})

foreach ($Process in $Processes) {
  Stop-Process -Id $Process.ProcessId -Force -ErrorAction SilentlyContinue
}

[pscustomobject]@{
  ok = $true
  stopped_processes = $Processes.Count
} | ConvertTo-Json
