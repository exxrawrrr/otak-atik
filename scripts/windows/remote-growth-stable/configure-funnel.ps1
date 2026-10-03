[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [switch]$NonInteractive,
  [switch]$AsJson
)

$ErrorActionPreference = "Stop"

function Emit-Result {
  param($Value, [int]$ExitCode)
  if ($AsJson) {
    $Value | ConvertTo-Json -Depth 8 -Compress
  } else {
    Write-Host ""
    Write-Host "Secure route" -ForegroundColor Cyan
    Write-Host ("Funnel mapping : " + $(if ($Value.funnel_ok) { "PASS" } else { "FAIL" }))
    Write-Host ("Public 401     : " + $(if ($Value.auth_guard_ok) { "PASS" } else { "FAIL" }))
    Write-Host ("Public tools   : " + $(if ($Value.inventory_match) { "64 / PASS" } else { "$($Value.tool_count) / FAIL" }))
  }
  exit $ExitCode
}

$configPath = Join-Path $InstallRoot "config.json"
if (-not (Test-Path -LiteralPath $configPath)) {
  Emit-Result ([ordered]@{ok=$false; error="runtime config missing"; funnel_ok=$false; auth_guard_ok=$false; inventory_match=$false; tool_count=$null}) 2
}

$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$tailscale = [string]$config.tailscaleExe
if (-not $tailscale -or -not (Test-Path -LiteralPath $tailscale)) {
  Emit-Result ([ordered]@{ok=$false; error="Tailscale executable missing"; funnel_ok=$false; auth_guard_ok=$false; inventory_match=$false; tool_count=$null}) 2
}
if (-not [string]$config.tailscaleDnsName -or -not [string]$config.publicMcpUrl) {
  Emit-Result ([ordered]@{ok=$false; error="Tailscale DNS/public URL missing from runtime config"; funnel_ok=$false; auth_guard_ok=$false; inventory_match=$false; tool_count=$null}) 2
}

function Get-FunnelText {
  return ((& $tailscale funnel status 2>&1) -join [Environment]::NewLine)
}

function Test-ExpectedMapping {
  param([string]$Text)
  $expectedBase = ([string]$config.publicMcpUrl) -replace "/mcp$",""
  return (
    $Text -match [regex]::Escape($expectedBase) -and
    $Text -match [regex]::Escape("127.0.0.1:$([int]$config.gatewayPort)")
  )
}

$statusText = Get-FunnelText
$mappingOk = Test-ExpectedMapping -Text $statusText

if (-not $mappingOk) {
  $publicPort = [int]$config.publicHttpsPort
  $portMarker = if ($publicPort -eq 443) { "https://" } else { ":$publicPort" }

  if ($statusText -notmatch "No serve config" -and $statusText -match [regex]::Escape($portMarker)) {
    Emit-Result ([ordered]@{
      ok=$false
      error="The selected Tailscale Funnel HTTPS port is already configured differently. OTAK-ATIK refuses to overwrite it."
      funnel_ok=$false
      auth_guard_ok=$false
      inventory_match=$false
      tool_count=$null
    }) 2
  }

  if ($NonInteractive) {
    Emit-Result ([ordered]@{ok=$false; error="user approval required to enable Tailscale Funnel"; needs_user_action=$true; funnel_ok=$false; auth_guard_ok=$false; inventory_match=$false; tool_count=$null}) 3
  }

  Write-Host ""
  Write-Host "OTAK-ATIK needs to enable the secure public route." -ForegroundColor Cyan
  Write-Host "This uses Tailscale Funnel and keeps Remote GROWTH bound to localhost." -ForegroundColor Gray
  [void](Read-Host "Press ENTER to enable the secure route")

  $output = (& $tailscale funnel --bg --yes --https=$publicPort ([int]$config.gatewayPort) 2>&1) -join [Environment]::NewLine
  $firstExit = $LASTEXITCODE

  $statusText = Get-FunnelText
  $mappingOk = Test-ExpectedMapping -Text $statusText

  if (-not $mappingOk) {
    $approval = [regex]::Match($output, "https://[^\s]+")
    if ($approval.Success -and $approval.Value -match "tailscale\.com") {
      Write-Host "Tailscale needs one account approval. Opening it now..." -ForegroundColor Yellow
      Start-Process $approval.Value
      [void](Read-Host "Finish the Tailscale approval in your browser, then press ENTER")
      $output = (& $tailscale funnel --bg --yes --https=$publicPort ([int]$config.gatewayPort) 2>&1) -join [Environment]::NewLine
      $statusText = Get-FunnelText
      $mappingOk = Test-ExpectedMapping -Text $statusText
    }
  }

  if (-not $mappingOk) {
    Emit-Result ([ordered]@{
      ok=$false
      error="Tailscale Funnel did not converge to the expected Remote GROWTH mapping."
      command_exit=$firstExit
      funnel_ok=$false
      auth_guard_ok=$false
      inventory_match=$false
      tool_count=$null
    }) 2
  }
}

$testScript = Join-Path (Split-Path -Parent $PSScriptRoot) "remote-growth-stable\test-runtime.ps1"
$last = $null
for ($i = 0; $i -lt 8; $i++) {
  $line = (& $testScript -InstallRoot $InstallRoot -IncludePublic -AsJson 2>$null | Select-Object -Last 1)
  if ($line) {
    try { $last = $line | ConvertFrom-Json } catch { $last = $null }
  }
  if ($last -and $last.ok) { break }
  Start-Sleep -Seconds 5
}

if (-not $last) {
  Emit-Result ([ordered]@{ok=$false; error="public verification returned no result"; funnel_ok=$mappingOk; auth_guard_ok=$false; inventory_match=$false; tool_count=$null}) 2
}

Emit-Result ([ordered]@{
  ok=[bool]($mappingOk -and $last.ok)
  funnel_ok=$mappingOk
  public_url=[string]$config.publicMcpUrl
  auth_guard_ok=[bool]$last.public.auth_guard_ok
  unauthenticated_status=$last.public.unauthenticated_status
  inventory_match=[bool]$last.public.inventory_match
  tool_count=$last.public.count
}) $(if ($mappingOk -and $last.ok) { 0 } else { 2 })
