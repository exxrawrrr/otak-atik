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
    Write-Host ("Toolkit : " + $(if ($Value.slug) { $Value.slug } else { "<not created>" }))
    Write-Host ("Tools   : " + $(if ($Value.synced_count -eq 64) { "64 / PASS" } else { "$($Value.synced_count) / FAIL" }))
  }
  exit $ExitCode
}

function ConvertFrom-Secure {
  param([Security.SecureString]$Secure)
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
  try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
  finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
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
    Emit-Result ([ordered]@{ok=$false; error="Composio project API key required"; needs_user_action=$true; synced_count=$null}) 3
  }

  Write-Host ""
  Write-Host "STEP — Connect Composio" -ForegroundColor Cyan
  Write-Host "A Composio Project API Key is needed once to create your private Custom MCP connection." -ForegroundColor White
  Write-Host "The key is used in memory only and is not saved by OTAK-ATIK." -ForegroundColor DarkGray
  Write-Host "Opening Composio Platform..." -ForegroundColor Gray
  Start-Process "https://dashboard.composio.dev"
  $secure = Read-Host "Paste your Composio Project API Key" -AsSecureString
  $ComposioApiKey = ConvertFrom-Secure -Secure $secure
}
if (-not $ComposioApiKey) {
  Emit-Result ([ordered]@{ok=$false; error="Composio API key was empty"; synced_count=$null}) 2
}

$headers = @{
  "x-api-key" = $ComposioApiKey
  "Content-Type" = "application/json"
}

$slug = ""
$accountId = ""
$redirectUrl = ""

if (Test-Path -LiteralPath $metaPath) {
  try {
    $old = Get-Content -Raw -LiteralPath $metaPath | ConvertFrom-Json
    if ([string]$old.publicMcpUrl -eq $publicUrl) {
      $slug = [string]$old.slug
      $accountId = [string]$old.connectedAccountId
    }
  } catch {}
}

if (-not $slug -or -not $accountId) {
  $createBody = [ordered]@{
    name = "Remote GROWTH $env:COMPUTERNAME"
    app_url = $publicUrl
    auth_schemes = @(
      [ordered]@{
        mode = "API_KEY"
        headers = [ordered]@{
          Authorization = "Bearer {{generic_api_key}}"
        }
      }
    )
    user_id = $UserId
  } | ConvertTo-Json -Depth 8

  try {
    $created = Invoke-RestMethod -Method Post -Uri ($BaseUrl + "/custom/toolkits") -Headers $headers -Body $createBody -TimeoutSec 45
  } catch {
    $message = $_.Exception.Message
    if ($_.ErrorDetails -and $_.ErrorDetails.Message) { $message = $_.ErrorDetails.Message }
    Emit-Result ([ordered]@{
      ok=$false
      error=("Composio Custom MCP creation failed: " + $message)
      note="Custom MCP is experimental. If an old private toolkit for this same URL already exists, remove/reconnect it in Composio Platform before retrying."
      synced_count=$null
    }) 2
  }

  $slug = [string]$created.slug
  if ($created.connect_link) {
    $redirectUrl = [string]$created.connect_link.redirect_url
    $accountId = [string]$created.connect_link.connected_account_id
  }

  if (-not $slug -or -not $redirectUrl -or -not $accountId) {
    Emit-Result ([ordered]@{ok=$false; error="Composio did not return a private connect link"; slug=$slug; synced_count=$null}) 2
  }

  try {
    $patchBody = @{
      api_key_field = @{
        display_name = "Remote GROWTH access code"
        description = "Paste the secure access code copied by OTAK-ATIK."
      }
    } | ConvertTo-Json -Depth 5
    Invoke-RestMethod -Method Patch -Uri ($BaseUrl + "/custom/toolkits/" + [uri]::EscapeDataString($slug)) -Headers $headers -Body $patchBody -TimeoutSec 30 | Out-Null
  } catch {
    # Friendly field copy is optional and must not block connection setup.
  }

  $meta = [ordered]@{
    schemaVersion = 1
    publicMcpUrl = $publicUrl
    slug = $slug
    connectedAccountId = $accountId
    userId = $UserId
    syncedCount = $null
    updatedAt = (Get-Date).ToString("o")
  }
  $meta | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

  if ($NonInteractive) {
    Emit-Result ([ordered]@{ok=$false; needs_user_action=$true; redirect_url=$redirectUrl; slug=$slug; connected_account_id=$accountId; synced_count=$null}) 3
  }

  $token = (Get-Content -Raw -LiteralPath $authFile).Trim()
  Set-Clipboard -Value $token
  $token = $null

  Write-Host ""
  Write-Host "Your Remote GROWTH access code has been copied to the clipboard." -ForegroundColor Green
  Write-Host "Composio will now ask for it. Paste it into the access-code field and connect." -ForegroundColor White
  Start-Process $redirectUrl
  [void](Read-Host "Finish the Composio connection in your browser, then press ENTER")
}

$synced = $null
for ($i = 0; $i -lt 12; $i++) {
  try {
    $body = @{
      slug = $slug
      connected_account_id = $accountId
    } | ConvertTo-Json -Depth 4
    $synced = Invoke-RestMethod -Method Post -Uri ($BaseUrl + "/custom/toolkits/sync") -Headers $headers -Body $body -TimeoutSec 45
    if ([int]$synced.synced_count -eq 64) { break }
  } catch {
    $synced = $null
  }
  Start-Sleep -Seconds 5
}

if (-not $synced -or [int]$synced.synced_count -ne 64) {
  Emit-Result ([ordered]@{
    ok=$false
    error="Composio connection exists, but the Custom MCP sync did not verify exactly 64 tools."
    slug=$slug
    connected_account_id=$accountId
    synced_count=$(if ($synced) { $synced.synced_count } else { $null })
  }) 2
}

$meta = [ordered]@{
  schemaVersion = 1
  publicMcpUrl = $publicUrl
  slug = $slug
  connectedAccountId = $accountId
  userId = $UserId
  syncedCount = 64
  updatedAt = (Get-Date).ToString("o")
}
$meta | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $metaPath -Encoding UTF8

$ComposioApiKey = $null

Emit-Result ([ordered]@{
  ok=$true
  slug=$slug
  connected_account_id=$accountId
  synced_count=64
  public_url=$publicUrl
}) 0
