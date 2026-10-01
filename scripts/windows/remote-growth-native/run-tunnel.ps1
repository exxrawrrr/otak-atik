param(
  [switch]$Detached
)

$ErrorActionPreference = 'Stop'
$LocalRoot = Join-Path $env:LOCALAPPDATA 'otak-atik\remote-growth-native'
$ConfigPath = Join-Path $LocalRoot 'config.json'
$SecretPath = Join-Path $LocalRoot 'secrets\runtime-api-key.dpapi'

if (-not (Test-Path $ConfigPath)) {
  throw 'Native tunnel is not configured. Run setup-tunnel.ps1 first.'
}

$Config = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$Exe = $Config.tunnel_client_path
if (-not (Test-Path $Exe)) { throw 'Configured tunnel-client.exe is missing.' }

$Existing = @(Get-CimInstance Win32_Process | Where-Object {
  $_.Name -ieq 'tunnel-client.exe' -and
  $_.CommandLine -match '(?i)run' -and
  $_.CommandLine -match [regex]::Escape([string]$Config.profile_name)
})
if ($Existing.Count -gt 0) {
  [pscustomobject]@{ok=$true;status='ALREADY_RUNNING';process_count=$Existing.Count} | ConvertTo-Json
  exit 0
}

if (Test-Path $SecretPath) {
  $Secure = Get-Content -Raw $SecretPath | ConvertTo-SecureString
} else {
  $Secure = Read-Host 'OpenAI Runtime API Key (hidden; memory only)' -AsSecureString
}

$Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
$Plain = $null
try {
  $Plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
  if ([string]::IsNullOrWhiteSpace($Plain)) { throw 'Runtime API key is empty.' }
  $env:CONTROL_PLANE_API_KEY = $Plain

  $Args = @('run','--profile',[string]$Config.profile_name,'--profile-dir',[string]$Config.profile_dir)

  if ($Detached) {
    $Process = Start-Process -FilePath $Exe -ArgumentList $Args -WindowStyle Hidden -PassThru

    $Deadline = (Get-Date).AddSeconds(45)
    $Health = $null
    $Ready = $null
    while ((Get-Date) -lt $Deadline) {
      try { $Health = (Invoke-WebRequest $Config.health_url -UseBasicParsing -TimeoutSec 2).StatusCode } catch { $Health = $null }
      try { $Ready = (Invoke-WebRequest $Config.ready_url -UseBasicParsing -TimeoutSec 2).StatusCode } catch { $Ready = $null }
      if ($Health -eq 200 -and $Ready -eq 200) { break }
      Start-Sleep -Seconds 1
    }

    if ($Health -ne 200 -or $Ready -ne 200) {
      throw 'Tunnel process started but health/readiness did not reach HTTP 200.'
    }

    [pscustomobject]@{
      ok = $true
      status = 'RUNNING'
      pid = $Process.Id
      health_http = $Health
      ready_http = $Ready
    } | ConvertTo-Json
  } else {
    & $Exe @Args
    exit $LASTEXITCODE
  }
}
finally {
  $env:CONTROL_PLANE_API_KEY = $null
  $Plain = $null
  $Secure = $null
  if ($Ptr -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
  }
}
