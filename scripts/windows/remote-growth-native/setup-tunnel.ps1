param(
  [string]$McpServerUrl = 'http://127.0.0.1:18768/mcp',
  [string]$ProfileName = 'remote-growth-native',
  [string]$TunnelClientVersion = 'v0.0.15',
  [switch]$PersistEncryptedRuntimeKey
)

$ErrorActionPreference = 'Stop'
$LocalRoot = Join-Path $env:LOCALAPPDATA 'otak-atik\remote-growth-native'
$BinDir = Join-Path $LocalRoot 'bin'
$ProfileDir = Join-Path $LocalRoot 'profiles'
$SecretDir = Join-Path $LocalRoot 'secrets'
$DownloadDir = Join-Path $LocalRoot 'downloads'
$ConfigPath = Join-Path $LocalRoot 'config.json'
$SecretPath = Join-Path $SecretDir 'runtime-api-key.dpapi'

New-Item -ItemType Directory -Force -Path $LocalRoot,$BinDir,$ProfileDir,$SecretDir,$DownloadDir | Out-Null

$Exe = Join-Path $BinDir 'tunnel-client.exe'
if (-not (Test-Path $Exe)) {
  $ZipName = "tunnel-client-$TunnelClientVersion-windows-amd64.zip"
  $Base = "https://github.com/openai/tunnel-client/releases/download/$TunnelClientVersion"
  $ZipPath = Join-Path $DownloadDir $ZipName
  $SumsPath = Join-Path $DownloadDir 'SHA256SUMS.txt'
  $ExtractDir = Join-Path $DownloadDir 'extract'

  Write-Host "Downloading official OpenAI tunnel-client $TunnelClientVersion..." -ForegroundColor Cyan
  Invoke-WebRequest -Uri "$Base/$ZipName" -OutFile $ZipPath -UseBasicParsing -TimeoutSec 180
  Invoke-WebRequest -Uri "$Base/SHA256SUMS.txt" -OutFile $SumsPath -UseBasicParsing -TimeoutSec 60

  $Entry = Get-Content $SumsPath | Where-Object { $_ -match [regex]::Escape($ZipName) } | Select-Object -First 1
  if (-not $Entry) { throw 'Official checksum entry not found.' }

  $Expected = (($Entry -split '\s+')[0]).ToUpperInvariant()
  $Actual = (Get-FileHash $ZipPath -Algorithm SHA256).Hash.ToUpperInvariant()
  if ($Expected -ne $Actual) { throw 'tunnel-client archive checksum mismatch.' }

  Remove-Item $ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force
  $DownloadedExe = Get-ChildItem $ExtractDir -Recurse -File -Filter 'tunnel-client.exe' | Select-Object -First 1
  if (-not $DownloadedExe) { throw 'tunnel-client.exe not found in verified archive.' }
  Copy-Item $DownloadedExe.FullName $Exe -Force
}

$TunnelId = Read-Host 'OpenAI Tunnel ID (tunnel_...)'
if ($TunnelId -notmatch '^tunnel_[A-Za-z0-9_-]+$') {
  throw 'Tunnel ID format is invalid.'
}

$RuntimeSecure = Read-Host 'OpenAI Runtime API Key (hidden; never committed)' -AsSecureString
$Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($RuntimeSecure)
$RuntimePlain = $null

try {
  $RuntimePlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
  if ([string]::IsNullOrWhiteSpace($RuntimePlain)) { throw 'Runtime API key is empty.' }

  $env:CONTROL_PLANE_API_KEY = $RuntimePlain

  & $Exe init --sample sample_mcp_remote_no_auth --profile $ProfileName --profile-dir $ProfileDir --tunnel-id $TunnelId --mcp-server-url $McpServerUrl --health-listen-addr 127.0.0.1:18769 --force
  if ($LASTEXITCODE -ne 0) { throw "tunnel-client init failed with exit code $LASTEXITCODE." }

  $ProfilePath = Join-Path $ProfileDir "$ProfileName.yaml"
  if (-not (Test-Path $ProfilePath)) { throw 'Tunnel profile was not created.' }

  $ProfileText = Get-Content -Raw $ProfilePath
  $ProfileText = [regex]::Replace(
    $ProfileText,
    ('(?m)^(\\s*api' + '_key:)\\s*.+?$'),
    ('$1 env:CONTROL_PLANE_' + 'API_KEY'),
    1
  )
  [IO.File]::WriteAllText($ProfilePath,$ProfileText,(New-Object Text.UTF8Encoding($false)))

  if ($PersistEncryptedRuntimeKey) {
    $RuntimeSecure | ConvertFrom-SecureString | Set-Content $SecretPath -Encoding ASCII
  } else {
    Remove-Item $SecretPath -Force -ErrorAction SilentlyContinue
  }

  $Config = [ordered]@{
    profile_name = $ProfileName
    profile_dir = $ProfileDir
    tunnel_client_path = $Exe
    mcp_server_url = $McpServerUrl
    health_url = 'http://127.0.0.1:18769/healthz'
    ready_url = 'http://127.0.0.1:18769/readyz'
    encrypted_runtime_key_saved = [bool]$PersistEncryptedRuntimeKey
  }
  $Config | ConvertTo-Json -Depth 4 | Set-Content $ConfigPath -Encoding UTF8

  & $Exe doctor --profile $ProfileName --profile-dir $ProfileDir --explain --json
  if ($LASTEXITCODE -ne 0) { throw "tunnel-client doctor failed with exit code $LASTEXITCODE." }

  [pscustomobject]@{
    ok = $true
    profile = $ProfileName
    mcp_server_url = $McpServerUrl
    tunnel_id_saved_locally = $true
    runtime_key_saved_encrypted = [bool]$PersistEncryptedRuntimeKey
    runtime_key_written_to_profile = $false
    local_root = $LocalRoot
  } | ConvertTo-Json -Depth 4
}
finally {
  $env:CONTROL_PLANE_API_KEY = $null
  $RuntimePlain = $null
  $RuntimeSecure = $null
  if ($Ptr -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
  }
}
