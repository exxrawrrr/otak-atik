$ErrorActionPreference = 'Stop'
$LocalRoot = Join-Path $env:LOCALAPPDATA 'otak-atik\remote-growth-native'
$ConfigPath = Join-Path $LocalRoot 'config.json'
$SecretPath = Join-Path $LocalRoot 'secrets\runtime-api-key.dpapi'

if (-not (Test-Path $ConfigPath)) {
  [pscustomobject]@{
    ok = $false
    configured = $false
    message = 'Run setup-tunnel.ps1 first.'
  } | ConvertTo-Json
  exit 1
}

$Config = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$ProfilePath = Join-Path $Config.profile_dir "$($Config.profile_name).yaml"
$ProfileSafe = $false
$TargetPresent = $false

if (Test-Path $ProfilePath) {
  $Text = Get-Content -Raw $ProfilePath
  $ApiMatch = [regex]::Match($Text,'(?m)^\s*api_key:\s*["'']?(.+?)["'']?\s*$')
  if ($ApiMatch.Success) {
    $ProfileSafe = ($ApiMatch.Groups[1].Value.Trim('"',"'") -eq 'env:CONTROL_PLANE_API_KEY')
  }
  $TargetPresent = $Text.Contains([string]$Config.mcp_server_url)
}

$Status = & (Join-Path $PSScriptRoot 'status-tunnel.ps1') | ConvertFrom-Json

[pscustomobject]@{
  ok = (
    (Test-Path $Config.tunnel_client_path) -and
    (Test-Path $ProfilePath) -and
    $ProfileSafe -and
    $TargetPresent
  )
  configured = $true
  tunnel_client_exists = (Test-Path $Config.tunnel_client_path)
  profile_exists = (Test-Path $ProfilePath)
  profile_uses_env_api_key = $ProfileSafe
  profile_target_matches_config = $TargetPresent
  encrypted_runtime_key_saved = (Test-Path $SecretPath)
  running = $Status.running
  health_http = $Status.health_http
  ready_http = $Status.ready_http
} | ConvertTo-Json -Depth 4
