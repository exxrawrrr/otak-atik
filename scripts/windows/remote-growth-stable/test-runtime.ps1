[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [switch]$IncludePublic,
  [switch]$AsJson
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $InstallRoot "config.json"
$authFile = Join-Path $InstallRoot "auth.key"
if (-not (Test-Path -LiteralPath $configPath)) { throw "Runtime config not found: $configPath" }
if (-not (Test-Path -LiteralPath $authFile)) { throw "Runtime auth file not found." }

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$verify = Join-Path ([string]$config.appRoot) "verify_inventory.py"
$python = [string]$config.pythonExe
$localUrl = "http://127.0.0.1:$([int]$config.gatewayPort)/mcp"

function Get-Inventory {
  param([string]$Url)
  $line = (& $python $verify --url $Url --auth-file $authFile --expected 64 2>$null | Select-Object -Last 1)
  $exit = $LASTEXITCODE
  if (-not $line) {
    return [pscustomobject]@{ ok=$false; count=$null; inventory_match=$false; exit_code=$exit; error="no verifier output" }
  }
  try {
    $obj = $line | ConvertFrom-Json
    $obj | Add-Member -NotePropertyName exit_code -NotePropertyValue $exit -Force
    return $obj
  } catch {
    return [pscustomobject]@{ ok=$false; count=$null; inventory_match=$false; exit_code=$exit; error="invalid verifier output" }
  }
}

function Get-UnauthenticatedStatus {
  param([string]$Url)
  try {
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(15)
    $request = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $Url)
    $response = $client.SendAsync($request).GetAwaiter().GetResult()
    $status = [int]$response.StatusCode
    $response.Dispose()
    $request.Dispose()
    $client.Dispose()
    return $status
  } catch {
    return $null
  }
}

$local = Get-Inventory -Url $localUrl
$result = [ordered]@{
  ok = [bool]($local.inventory_match -and [int]$local.count -eq 64)
  local = [ordered]@{
    url = $localUrl
    count = $local.count
    inventory_match = [bool]$local.inventory_match
  }
  public = $null
}

if ($IncludePublic) {
  $publicUrl = [string]$config.publicMcpUrl
  if (-not $publicUrl) {
    $result.ok = $false
    $result.public = [ordered]@{ configured=$false; error="public MCP URL is not configured" }
  } else {
    $guard = Get-UnauthenticatedStatus -Url $publicUrl
    $public = Get-Inventory -Url $publicUrl
    $result.public = [ordered]@{
      configured = $true
      url = $publicUrl
      unauthenticated_status = $guard
      auth_guard_ok = ($guard -eq 401)
      count = $public.count
      inventory_match = [bool]$public.inventory_match
    }
    $result.ok = [bool]($result.ok -and $guard -eq 401 -and $public.inventory_match -and [int]$public.count -eq 64)
  }
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 6 -Compress
} else {
  Write-Host ""
  Write-Host "Remote GROWTH acceptance" -ForegroundColor Cyan
  Write-Host ("Local inventory : " + $(if ($result.local.inventory_match) { "64 / PASS" } else { "$($result.local.count) / FAIL" }))
  if ($IncludePublic) {
    if ($result.public.configured) {
      Write-Host ("Public 401      : " + $(if ($result.public.auth_guard_ok) { "PASS" } else { "FAIL" }))
      Write-Host ("Public inventory: " + $(if ($result.public.inventory_match) { "64 / PASS" } else { "$($result.public.count) / FAIL" }))
    } else {
      Write-Host "Public route    : NOT CONFIGURED"
    }
  }
}

if ($result.ok) { exit 0 }
exit 2
