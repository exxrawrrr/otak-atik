$ErrorActionPreference = 'Stop'
$LocalRoot = Join-Path $env:LOCALAPPDATA 'otak-atik\remote-growth-native'
$ConfigPath = Join-Path $LocalRoot 'config.json'

if (-not (Test-Path $ConfigPath)) {
  [pscustomobject]@{configured=$false;running=$false} | ConvertTo-Json
  exit 1
}

$Config = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$Processes = @(Get-CimInstance Win32_Process | Where-Object {
  $_.Name -ieq 'tunnel-client.exe' -and
  $_.CommandLine -match '(?i)run' -and
  $_.CommandLine -match [regex]::Escape([string]$Config.profile_name)
})

$Health = $null
$Ready = $null
try { $Health = (Invoke-WebRequest $Config.health_url -UseBasicParsing -TimeoutSec 2).StatusCode } catch {}
try { $Ready = (Invoke-WebRequest $Config.ready_url -UseBasicParsing -TimeoutSec 2).StatusCode } catch {}

[pscustomobject]@{
  configured = $true
  profile = $Config.profile_name
  mcp_server_url = $Config.mcp_server_url
  running = ($Processes.Count -gt 0)
  process_count = $Processes.Count
  health_http = $Health
  ready_http = $Ready
  encrypted_runtime_key_saved = [bool]$Config.encrypted_runtime_key_saved
} | ConvertTo-Json -Depth 4
