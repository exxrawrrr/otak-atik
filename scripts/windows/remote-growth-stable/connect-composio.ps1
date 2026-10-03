[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [string]$UserId = "",
  [string]$ComposioApiKey = "",
  [switch]$NonInteractive,
  [switch]$AsJson
)

$ErrorActionPreference = "Stop"
$script:BaseUrl = "https://backend.composio.dev/api/v3.1"

function Emit-Result {
  param(
    $Value,
    [int]$ExitCode
  )

  if ($AsJson) {
    $Value | ConvertTo-Json -Depth 10 -Compress
  } else {
    Write-Host ""
    Write-Host "Composio Custom MCP" -ForegroundColor Cyan

    if ($Value.slug) {
      Write-Host ("Toolkit : " + [string]$Value.slug)
    }

    if ($null -ne $Value.synced_count) {
      $count = [int]$Value.synced_count
      if ($count -eq 64) {
        Write-Host "Tools   : 64 / PASS" -ForegroundColor Green
      } else {
        Write-Host ("Tools   : " + $count + " / NOT READY") -ForegroundColor Yellow
      }
    }

    if ($Value.error) {
      Write-Host ("Error   : " + [string]$Value.error) -ForegroundColor Red
    }
  }

  exit $ExitCode
}

function ConvertFrom-SecureStringPlain {
  param([Security.SecureString]$Secure)

  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Invoke-ComposioApi {
  param(
    [ValidateSet("GET","POST","PATCH","DELETE")]
    [string]$Method,
    [string]$Path,
    $Body = $null
  )

  $headers = @{
    "x-api-key" = $ComposioApiKey
  }

  $request = @{
    Method = $Method
    Uri = ($script:BaseUrl + $Path)
    Headers = $headers
    TimeoutSec = 45
  }

  if ($null -ne $Body) {
    $request.ContentType = "application/json"
    $request.Body = ($Body | ConvertTo-Json -Depth 15 -Compress)
  }

  return Invoke-RestMethod @request
}

function Get-ApiErrorMessage {
  param($ErrorRecord)

  if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
    return [string]$ErrorRecord.ErrorDetails.Message
  }

  return [string]$ErrorRecord.Exception.Message
}

function New-StableSlugSeed {
  param([string]$Value)

  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Value)
    $hash = $sha.ComputeHash($bytes)
  } finally {
    $sha.Dispose()
  }

  $short = ([BitConverter]::ToString($hash).Replace("-","").ToLowerInvariant()).Substring(0,12)
  return ("REMOTE_GROWTH_" + $short).ToUpperInvariant()
}

function New-StableUserId {
  $machine = [string]$env:COMPUTERNAME
  $user = [string]$env:USERNAME
  $raw = ("otak-atik-" + $machine + "-" + $user).ToLowerInvariant()
  $clean = ($raw -replace "[^a-z0-9_-]","-").Trim("-")
  if (-not $clean) {
    $clean = "otak-atik-user"
  }
  if ($clean.Length -gt 64) {
    $clean = $clean.Substring(0,64)
  }
  return $clean
}

function Read-ExistingMetadata {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return $null
  }

  try {
    return (Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Save-Metadata {
  param(
    [string]$Path,
    [string]$PublicUrl,
    [string]$Slug,
    [string]$AuthConfigId,
    [string]$ConnectedAccountId,
    [string]$UserIdValue,
    $SyncedCount
  )

  $meta = [ordered]@{
    schemaVersion = 2
    publicMcpUrl = $PublicUrl
    slug = $Slug
    authConfigId = $AuthConfigId
    connectedAccountId = $ConnectedAccountId
    userId = $UserIdValue
    syncedCount = $SyncedCount
    updatedAt = (Get-Date).ToString("o")
  }

  $meta | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-AuthConfig {
  param([string]$ToolkitSlug)

  $encoded = [uri]::EscapeDataString($ToolkitSlug)
  $response = Invoke-ComposioApi -Method GET -Path ("/auth_configs?toolkit_slug=" + $encoded + "&show_disabled=false&limit=200")

  $items = @($response.items)
  foreach ($item in $items) {
    if (
      [string]$item.auth_scheme -eq "API_KEY" -and
      [string]$item.status -ne "DISABLED"
    ) {
      return $item
    }
  }

  return $null
}

function New-AuthConfig {
  param([string]$ToolkitSlug)

  $response = Invoke-ComposioApi -Method POST -Path "/auth_configs" -Body @{
    toolkit = @{
      slug = $ToolkitSlug
    }
    auth_config = @{
      type = "use_custom_auth"
      authScheme = "API_KEY"
      credentials = @{}
      is_enabled_for_tool_router = $true
    }
  }

  if (-not $response.auth_config -or -not $response.auth_config.id) {
    throw "Composio did not return an auth config id."
  }

  return $response.auth_config
}

function Ensure-ToolRouterEnabled {
  param($AuthConfig)

  if ($AuthConfig.is_enabled_for_tool_router -eq $true) {
    return
  }

  $id = [string]$AuthConfig.id
  if (-not $id) {
    return
  }

  try {
    [void](Invoke-ComposioApi -Method PATCH -Path ("/auth_configs/" + [uri]::EscapeDataString($id)) -Body @{
      type = "custom"
      is_enabled_for_tool_router = $true
    })
  } catch {
    # Tool sync and explicit connected-account use can still work.
    # Do not discard an otherwise-valid existing auth config here.
  }
}

function Get-ConnectedAccount {
  param(
    [string]$ConnectedAccountId,
    [string]$ToolkitSlug,
    [string]$ExpectedUserId
  )

  if (-not $ConnectedAccountId) {
    return $null
  }

  try {
    $account = Invoke-ComposioApi -Method GET -Path ("/connected_accounts/" + [uri]::EscapeDataString($ConnectedAccountId))
  } catch {
    return $null
  }

  if ([string]$account.toolkit.slug -ne $ToolkitSlug) {
    return $null
  }

  if ([string]$account.user_id -ne $ExpectedUserId) {
    return $null
  }

  return $account
}

function New-ConnectionLink {
  param(
    [string]$AuthConfigId,
    [string]$UserIdValue
  )

  return Invoke-ComposioApi -Method POST -Path "/connected_accounts/link" -Body @{
    auth_config_id = $AuthConfigId
    user_id = $UserIdValue
  }
}

function Wait-ForActiveAccount {
  param(
    [string]$ConnectedAccountId,
    [int]$Attempts = 90
  )

  for ($i = 0; $i -lt $Attempts; $i++) {
    try {
      $account = Invoke-ComposioApi -Method GET -Path ("/connected_accounts/" + [uri]::EscapeDataString($ConnectedAccountId))
      $status = [string]$account.status

      if ($status -eq "ACTIVE") {
        return $account
      }

      if ($status -in @("FAILED","REVOKED","EXPIRED","INACTIVE")) {
        return $account
      }
    } catch {
      # Transient polling errors are retried.
    }

    Start-Sleep -Seconds 2
  }

  return $null
}

function Sync-CustomToolkit {
  param(
    [string]$ToolkitSlug,
    [string]$ConnectedAccountId
  )

  return Invoke-ComposioApi -Method POST -Path "/custom/toolkits/sync" -Body @{
    slug = $ToolkitSlug
    connected_account_id = $ConnectedAccountId
  }
}

$configPath = Join-Path $InstallRoot "config.json"
$authFile = Join-Path $InstallRoot "auth.key"
$metaPath = Join-Path $InstallRoot "composio.json"

if (
  -not (Test-Path -LiteralPath $configPath) -or
  -not (Test-Path -LiteralPath $authFile)
) {
  Emit-Result ([ordered]@{
    ok = $false
    error = "Remote GROWTH runtime is not installed."
    synced_count = $null
  }) 2
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$publicUrl = [string]$config.publicMcpUrl

if (-not $publicUrl) {
  Emit-Result ([ordered]@{
    ok = $false
    error = "Public MCP URL is not configured."
    synced_count = $null
  }) 2
}

if (-not $UserId) {
  $UserId = New-StableUserId
}

if (-not $ComposioApiKey) {
  if ($NonInteractive) {
    Emit-Result ([ordered]@{
      ok = $false
      needs_user_action = $true
      action = "COMPOSIO_PROJECT_API_KEY"
      error = "A Composio Project API Key is required once for Custom MCP setup."
      synced_count = $null
    }) 3
  }

  Write-Host ""
  Write-Host "STEP - Connect Composio" -ForegroundColor Cyan
  Write-Host "Composio Custom MCP is currently API-managed." -ForegroundColor White
  Write-Host "OTAK-ATIK needs your Composio Project API Key once to register this private MCP." -ForegroundColor White
  Write-Host "The project key is kept in memory only and is not saved to disk." -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "In Composio: Settings > Project Settings > API Keys" -ForegroundColor Gray

  try {
    Start-Process "https://dashboard.composio.dev"
  } catch {
    # The terminal instructions remain sufficient if browser opening fails.
  }

  $secure = Read-Host "Paste your Composio Project API Key" -AsSecureString
  $ComposioApiKey = ConvertFrom-SecureStringPlain -Secure $secure
  $secure = $null
}

if (-not $ComposioApiKey) {
  Emit-Result ([ordered]@{
    ok = $false
    error = "Composio Project API Key was empty."
    synced_count = $null
  }) 2
}

$slugSeed = New-StableSlugSeed -Value $publicUrl
$slug = ""
$authConfigId = ""
$accountId = ""
$existingMeta = Read-ExistingMetadata -Path $metaPath

try {
  $upsert = Invoke-ComposioApi -Method POST -Path "/custom/toolkits/upsert" -Body @{
    slug = $slugSeed
    toolkit_config = @{
      name = "Remote GROWTH Stable"
      app_url = $publicUrl
      auth_schemes = @(
        @{
          mode = "API_KEY"
          headers = @{
            Authorization = "Bearer {{generic_api_key}}"
          }
        }
      )
    }
  }

  $slug = [string]$upsert.slug
} catch {
  $message = Get-ApiErrorMessage -ErrorRecord $_
    $ComposioApiKey = ""

  Emit-Result ([ordered]@{
    ok = $false
    error = ("Custom MCP registration failed: " + $message)
    synced_count = $null
  }) 2
}

if (-not $slug) {
    $ComposioApiKey = ""

  Emit-Result ([ordered]@{
    ok = $false
    error = "Composio did not return a Custom MCP toolkit slug."
    synced_count = $null
  }) 2
}

try {
  $authConfig = Get-AuthConfig -ToolkitSlug $slug

  if ($null -eq $authConfig) {
    $authConfig = New-AuthConfig -ToolkitSlug $slug
  } else {
    Ensure-ToolRouterEnabled -AuthConfig $authConfig
  }

  $authConfigId = [string]$authConfig.id
} catch {
  $message = Get-ApiErrorMessage -ErrorRecord $_
    $ComposioApiKey = ""

  Emit-Result ([ordered]@{
    ok = $false
    slug = $slug
    error = ("Auth config setup failed: " + $message)
    synced_count = $null
  }) 2
}

if (-not $authConfigId) {
    $ComposioApiKey = ""

  Emit-Result ([ordered]@{
    ok = $false
    slug = $slug
    error = "Composio did not return an API-key auth config id."
    synced_count = $null
  }) 2
}

if (
  $existingMeta -and
  [string]$existingMeta.publicMcpUrl -eq $publicUrl -and
  [string]$existingMeta.slug -eq $slug -and
  [string]$existingMeta.userId -eq $UserId
) {
  $accountId = [string]$existingMeta.connectedAccountId
}

$account = Get-ConnectedAccount -ConnectedAccountId $accountId -ToolkitSlug $slug -ExpectedUserId $UserId
$accountActive = ($null -ne $account -and [string]$account.status -eq "ACTIVE")

if (-not $accountActive) {
  try {
    $link = New-ConnectionLink -AuthConfigId $authConfigId -UserIdValue $UserId
  } catch {
    $message = Get-ApiErrorMessage -ErrorRecord $_
        $ComposioApiKey = ""

    Emit-Result ([ordered]@{
      ok = $false
      slug = $slug
      error = ("Could not create the Composio connection page: " + $message)
      synced_count = $null
    }) 2
  }

  $accountId = [string]$link.connected_account_id
  $redirectUrl = [string]$link.redirect_url

  if (-not $accountId -or -not $redirectUrl) {
        $ComposioApiKey = ""

    Emit-Result ([ordered]@{
      ok = $false
      slug = $slug
      error = "Composio did not return a connection URL."
      synced_count = $null
    }) 2
  }

  Save-Metadata -Path $metaPath -PublicUrl $publicUrl -Slug $slug -AuthConfigId $authConfigId -ConnectedAccountId $accountId -UserIdValue $UserId -SyncedCount $null

  if ($NonInteractive) {
        $ComposioApiKey = ""

    Emit-Result ([ordered]@{
      ok = $false
      needs_user_action = $true
      action = "COMPOSIO_CONNECT"
      redirect_url = $redirectUrl
      slug = $slug
      connected_account_id = $accountId
      synced_count = $null
    }) 3
  }

  $remoteAccessKey = (Get-Content -Raw -LiteralPath $authFile).Trim()

  try {
    Set-Clipboard -Value $remoteAccessKey
    Write-Host ""
    Write-Host "Remote GROWTH access code copied to the clipboard." -ForegroundColor Green
  } catch {
    Write-Host ""
    Write-Host "Clipboard copy failed. Re-run setup after clipboard access is available." -ForegroundColor Red
    $remoteAccessKey = ""
        $ComposioApiKey = ""

    Emit-Result ([ordered]@{
      ok = $false
      slug = $slug
      connected_account_id = $accountId
      error = "Could not copy the Remote GROWTH access code to the clipboard."
      synced_count = $null
    }) 2
  }

  $remoteAccessKey = ""

  Write-Host "A Composio connection page will open." -ForegroundColor White
  Write-Host "Paste the copied access code when Composio asks for the API key, then click Connect." -ForegroundColor White

  try {
    Start-Process $redirectUrl
  } catch {
    Write-Host ("Open this address: " + $redirectUrl) -ForegroundColor Yellow
  }

  Write-Host ""
  Write-Host "Waiting for the Composio connection to become active..." -ForegroundColor Gray

  $account = Wait-ForActiveAccount -ConnectedAccountId $accountId
  $accountActive = ($null -ne $account -and [string]$account.status -eq "ACTIVE")
}

if (-not $accountActive) {
  $statusText = ""
  if ($account) {
    $statusText = [string]$account.status
  }

  Save-Metadata -Path $metaPath -PublicUrl $publicUrl -Slug $slug -AuthConfigId $authConfigId -ConnectedAccountId $accountId -UserIdValue $UserId -SyncedCount $null

    $ComposioApiKey = ""

  Emit-Result ([ordered]@{
    ok = $false
    slug = $slug
    connected_account_id = $accountId
    account_status = $statusText
    error = "Composio connection is not ACTIVE yet. Complete the hosted connection page, then run START.cmd again."
    synced_count = $null
  }) 2
}

$synced = $null
for ($i = 0; $i -lt 12; $i++) {
  try {
    $synced = Sync-CustomToolkit -ToolkitSlug $slug -ConnectedAccountId $accountId
  } catch {
    $synced = $null
  }

  if ($synced -and [int]$synced.synced_count -eq 64) {
    break
  }

  Start-Sleep -Seconds 5
}

if (-not $synced -or [int]$synced.synced_count -ne 64) {
  $count = $null
  if ($synced) {
    $count = $synced.synced_count
  }

  Save-Metadata -Path $metaPath -PublicUrl $publicUrl -Slug $slug -AuthConfigId $authConfigId -ConnectedAccountId $accountId -UserIdValue $UserId -SyncedCount $count

    $ComposioApiKey = ""

  Emit-Result ([ordered]@{
    ok = $false
    slug = $slug
    connected_account_id = $accountId
    error = "Composio is connected, but Custom MCP sync did not verify exactly 64 tools."
    synced_count = $count
  }) 2
}

Save-Metadata -Path $metaPath -PublicUrl $publicUrl -Slug $slug -AuthConfigId $authConfigId -ConnectedAccountId $accountId -UserIdValue $UserId -SyncedCount 64

$ComposioApiKey = ""

Emit-Result ([ordered]@{
  ok = $true
  slug = $slug
  connected_account_id = $accountId
  synced_count = 64
  public_url = $publicUrl
}) 0
