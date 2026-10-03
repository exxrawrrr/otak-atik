[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [string]$UserId = "",
  [string]$ComposioApiKey = "",
  [switch]$NonInteractive,
  [switch]$AsJson
)

$ErrorActionPreference = "Stop"
$BaseUrl = "https://backend.composio.dev/api/v3.1"

function Emit-Result {
  param($Value, [int]$ExitCode)
  if ($AsJson) {
    $Value | ConvertTo-Json -Depth 8 -Compress
  } else {
    Write-Host ""
    Write-Host "Composio connection" -ForegroundColor Cyan
    if ($Value.slug) { Write-Host ("Toolkit : " + $Value.slug) }
    Write-Host ("Tools   : " + $(if ($Value.synced_count -eq 64) { "64 / PASS" } else { "$($Value.synced_count) / NOT READY" }))
  }
  exit $ExitCode
}

function ConvertFrom-Secure {
  param([Security.SecureString]$Secure)
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Invoke-Composio {
  param(
    [ValidateSet("GET","POST","PATCH","DELETE")][string]$Method,
    [string]$Path,
    $Body = $null
  )
  $headers = @{ "x-api-key" = $script:ApiKey }
  $params = @{
    Method = $Method
    Uri = ($BaseUrl + $Path)
    Headers = $headers
    TimeoutSec = 45
  }
  if ($null -ne $Body) {
    $params.ContentType = "application/json"
    $params.Body = ($Body | ConvertTo-Json -Depth 12)
  }
  return Invoke-RestMethod @params
}

function New-StableSlugSeed {
  param([string]$Value)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
    $hash = $sha.ComputeHash($bytes)
    $short = ([BitConverter]::ToString($hash).Replace("-","").ToLowerInvariant()).Substring(0,10)
  } finally {
    $sha.Dispose()
  }
  $machine = ($env:COMPUTERNAME -replace "[^A-Za-z0-9]","_").Trim("_")
  if (-not $machine) { $machine = "WINDOWS" }
  return ("REMOTE_GROWTH_" + $machine + "_" + $short).ToUpperInvariant()
}

$configPath = Join-Path $InstallRoot "config.json"
$authFile = Join-Path $InstallRoot "auth.key"
$metaPath = Join-Path $InstallRoot "composio.json"
if (-not (Test-Path -LiteralPath $configPath) -or -not (Test-Path -LiteralPath $authFile)) {
  Emit-Result ([ordered]@{ok=$false; error="Remote GROWTH runtime is not installed"; synced_count=$null}) 2
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$publicUrl = [string]$config.publicMcpUrl
if (-not $publicUrl) {
  Emit-Result ([ordered]@{ok=$false; error="Public MCP URL is not configured"; synced_count=$null}) 2
}

if (-not $UserId) {
  $raw = ("otak-atik-" + $env:COMPUTERNAME + "-" + $env:USERNAME).ToLowerInvariant()
  $UserId = ($raw -replace "[^a-z0-9_-]","-")
  if ($UserId.Length -gt 64) { $UserId = $UserId.Substring(0,64) }
}

if (-not $ComposioApiKey) {
  if ($NonInteractive) {
    Emit-Result ([ordered]@{
      ok=$false
      needs_user_action=$true
      action="COMPOSIO_PROJECT_API_KEY"
      error="Composio Project API Key is required once for setup."
      synced_count=$null
    }) 3
  }

  Write-Host ""
  Write-Host "STEP — Connect Composio" -ForegroundColor Cyan
  Write-Host "Composio Custom MCP is currently API-managed." -ForegroundColor White
  Write-Host "OTAK-ATIK needs your Composio Project API Key once to register this private connection." -ForegroundColor White
  Write-Host "The project key is used in memory only and is not saved." -ForegroundColor DarkGray
  Write-Host "Opening Composio..." -ForegroundColor Gray
  try { Start-Process "https://dashboard.composio.dev" } catch {}
  $secure = Read-Host "Paste your Composio Project API Key" -AsSecureString
  $ComposioApiKey = ConvertFrom-Secure -Secure $secure
}

if (-not $ComposioApiKey) {
  Emit-Result ([ordered]@{ok=$false; error="Composio Project API Key was empty"; synced_count=$null}) 2
}
$script:ApiKey = $ComposioApiKey

$slugSeed = New-StableSlugSeed -Value $publicUrl
$slug = ""
$accountId = ""
$authConfigId = ""

try {
  $upsert = Invoke-Composio -Method POST -Path "/custom/toolkits/upsert" -Body @{
    slug = $slugSeed
    toolkit_config = @{
      name = ("Remote GROWTH " + $env:COMPUTERNAME)
      app_url = $publicUrl
      auth_schemes = @(
        @{
          mode = "API_KEY"
          headers = @{ Authorization = "Bearer {{generic_api_key}}" }
        }
      )
    }
  }
  $slug = [string]$upsert.slug
} catch {
  $message = $_.Exception.Message
  if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $message = $_.ErrorDetails.Message }
  Emit-Result ([ordered]@{
    ok=$false
    error=("Composio Custom MCP registration failed: " + $message)
    synced_count=$null
  }) 2
}

if (-not $slug) {
  Emit-Result ([ordered]@{ok=$false; error="Composio did not return a Custom MCP toolkit slug"; synced_count=$null}) 2
}

try {
  $authConfigs = Invoke-Composio -Method GET -Path ("/auth_configs?toolkit_slug=" + [uri]::EscapeDataString($slug) + "&limit=50")
  $candidate = @($authConfigs.items | Where-Object {
    [string]$_.auth_scheme -eq "API_KEY" -and [string]$_.status -ne "DISABLED"
  } | Select-Object -First 1)
  if ($candidate.Count -gt 0) {
    $authConfigId = [string]$candidate[0].id
  }
} catch {
  $authConfigId = ""
}

if (-not $authConfigId) {
  Emit-Result ([ordered]@{
    ok=$false
    slug=$slug
    error="The Custom MCP toolkit exists, but its API-key auth config was not discoverable."
    synced_count=$null
  }) 2
}

if (Test-Path -LiteralPath $metaPath) {
  try {
    $old = Get-Content -Raw -LiteralPath $metaPath | ConvertFrom-Json
    if ([string]$old.publicMcpUrl -eq $publicUrl -and [string]$old.slug -eq $slug) {
      $accountId = [string]$old.connectedAccountId
    }
  } catch {}
}

$accountActive = $false
if ($accountId) {
  try {
    $existingAccount = Invoke-Composio -Method GET -Path ("/connected_accounts/" + [uri]::EscapeDataString($accountId))
    $accountActive = ([string]$existingAccount.status -eq "ACTIVE")
  } catch {
    $accountActive = $false
    $accountId = ""
  }
}

if (-not $accountActive) {
  try {
    $link = Invoke-Composio -Method POST -Path "/connected_accounts/link" -Body @{
      auth_config_id = $authConfigId
      user_id = $UserId
      alias = ("remote-growth-" + $env:COMPUTERNAME.ToLowerInvariant())
    }
  } catch {
    $message = $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $message = $_.ErrorDetails.Message }
    Emit-Result ([ordered]@{
      ok=$false
      slug=$slug
      error=("Could not create the Composio secure connection page: " + $message)
      synced_count=$null
    }) 2
  }

  $accountId = [string]$link.connected_account_id
  $redirectUrl = [string]$link.redirect_url
  if (-not $accountId -or -not $redirectUrl) {
    Emit-Result ([ordered]@{ok=$false; slug=$slug; error="Composio did not return a connection URL"; synced_count=$null}) 2
  }

  $meta = [ordered]@{
    schemaVersion = 1
    publicMcpUrl = $publicUrl
    slug = $slug
    authConfigId = $authConfigId
    connectedAccountId = $accountId
    userId = $UserId
    syncedCount = $null
    updatedAt = (Get-Date).ToString("o")
  }
  $meta | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

  if ($NonInteractive) {
    Emit-Result ([ordered]@{
      ok=$false
      needs_user_action=$true
      action="COMPOSIO_CONNECT"
      redirect_url=$redirectUrl
      slug=$slug
      connected_account_id=$accountId
      synced_count=$null
    }) 3
  }

  $remoteAccessKey = (Get-Content -Raw -LiteralPath $authFile).Trim()
  Set-Clipboard -Value $remoteAccessKey
  $remoteAccessKey = $null

  Write-Host ""
  Write-Host "Remote GROWTH access code copied to the clipboard." -ForegroundColor Green
  Write-Host "A Composio connection page will open." -ForegroundColor White
  Write-Host "Paste the copied access code when Composio asks for the API key, then connect." -ForegroundColor White
  try { Start-Process $redirectUrl } catch {
    Write-Host ("Open this address: " + $redirectUrl) -ForegroundColor Yellow
  }

  Write-Host ""
  Write-Host "Waiting for Composio..." -ForegroundColor Gray
  for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep -Seconds 2
    try {
      $account = Invoke-Composio -Method GET -Path ("/connected_accounts/" + [uri]::EscapeDataString($accountId))
      if ([string]$account.status -eq "ACTIVE") {
        $accountActive = $true
        break
      }
      if ([string]$account.status -in @("FAILED","REVOKED","EXPIRED")) {
        break
      }
    } catch {}
  }
}

if (-not $accountActive) {
  Emit-Result ([ordered]@{
    ok=$false
    slug=$slug
    connected_account_id=$accountId
    error="Composio connection is not ACTIVE yet. Run START.cmd again after completing the connection page."
    synced_count=$null
  }) 2
}

$synced = $null
for ($i = 0; $i -lt 12; $i++) {
  try {
    $synced = Invoke-Composio -Method POST -Path "/custom/toolkits/sync" -Body @{
      slug = $slug
      connected_account_id = $accountId
    }
    if ([int]$synced.synced_count -eq 64) { break }
  } catch {
    $synced = $null
  }
  Start-Sleep -Seconds 5
}

if (-not $synced -or [int]$synced.synced_count -ne 64) {
  Emit-Result ([ordered]@{
    ok=$false
    slug=$slug
    connected_account_id=$accountId
    error="Composio is connected, but Custom MCP sync did not verify exactly 64 tools."
    synced_count=$(if ($synced) { $synced.synced_count } else { $null })
  }) 2
}

$meta = [ordered]@{
  schemaVersion = 1
  publicMcpUrl = $publicUrl
  slug = $slug
  authConfigId = $authConfigId
  connectedAccountId = $accountId
  userId = $UserId
  syncedCount = 64
  updatedAt = (Get-Date).ToString("o")
}
$meta | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

$script:ApiKey = $null
$ComposioApiKey = $null

Emit-Result ([ordered]@{
  ok=$true
  slug=$slug
  connected_account_id=$accountId
  synced_count=64
  public_url=$publicUrl
}) 0
