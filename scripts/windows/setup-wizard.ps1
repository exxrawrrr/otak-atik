[CmdletBinding()]
param(
  [string]$SourceRoot = "",
  [switch]$DryRun,
  [switch]$NonInteractive,
  [switch]$ResetState,
  [switch]$NoClear
)

$ErrorActionPreference = "Stop"

$script:Brand = "Created by Rafdi D. Ulhaq - exxrawrrr"
$script:AppName = "OTAK-ATIK"
$script:StateSchema = 2
$script:ComposioCustomMcpUrl = "https://dashboard.composio.dev/~/org/connect/apps?add-custom-mcp=true"
$script:PublicHttpsPort = 443

function Get-UserDataRoot {
  if ($env:LOCALAPPDATA) {
    return (Join-Path $env:LOCALAPPDATA "otak-atik")
  }
  return (Join-Path $HOME ".otak-atik")
}

$script:DataRoot = Get-UserDataRoot
$script:StatePath = Join-Path $script:DataRoot "setup-state.json"
$script:LogRoot = Join-Path $script:DataRoot "logs"
$script:LogPath = Join-Path $script:LogRoot ("setup-" + (Get-Date -Format "yyyyMMdd") + ".log")
$script:RemoteInstallRoot = Join-Path $script:DataRoot "remote-growth-stable"

function Initialize-Console {
  try { [Console]::Title = "OTAK-ATIK - Remote AI Setup Wizard" } catch {}
  try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
  if (-not $NoClear) { Clear-Host }
}

function Write-LogLine {
  param([string]$Message)
  if ($DryRun) { return }
  try {
    New-Item -ItemType Directory -Force -Path $script:LogRoot | Out-Null
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"), $Message
    Add-Content -Path $script:LogPath -Value $line -Encoding UTF8
  } catch {
    # Logging must never break setup.
  }
}

function Write-BrandHeader {
  Write-Host ""
  Write-Host "+======================================================+" -ForegroundColor DarkCyan
  Write-Host "|                      OTAK-ATIK                       |" -ForegroundColor Cyan
  Write-Host "|                Remote AI Setup Wizard                |" -ForegroundColor Cyan
  Write-Host "|                                                      |" -ForegroundColor DarkCyan
  Write-Host "|       Created by Rafdi D. Ulhaq - exxrawrrr          |" -ForegroundColor White
  Write-Host "+======================================================+" -ForegroundColor DarkCyan
  Write-Host ""
}

function Write-Step {
  param([int]$Number,[int]$Total,[string]$Title)
  Write-Host ""
  Write-Host (" STEP {0} OF {1} " -f $Number, $Total) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
  Write-Host ("  " + $Title) -ForegroundColor Cyan
  Write-Host (" " + ("-" * 54)) -ForegroundColor DarkGray
}

function Write-Status {
  param(
    [ValidateSet("OK","WAIT","FIX","INFO","FAIL")][string]$Kind,
    [string]$Message
  )
  $color = switch ($Kind) {
    "OK"   { "Green" }
    "WAIT" { "Yellow" }
    "FIX"  { "Yellow" }
    "INFO" { "Gray" }
    "FAIL" { "Red" }
  }
  Write-Host (" [{0}]" -f $Kind.PadRight(4)) -NoNewline -ForegroundColor $color
  Write-Host (" " + $Message)
  Write-LogLine ("[{0}] {1}" -f $Kind, $Message)
}

function Write-Footer {
  Write-Host ""
  Write-Host (" " + $script:Brand) -ForegroundColor DarkGray
  Write-Host ""
}

function Read-Continue {
  param([string]$Prompt = "Press ENTER to continue or Q to exit")
  if ($NonInteractive) { return $true }
  Write-Host ""
  $answer = Read-Host $Prompt
  return ($answer -notmatch "^[Qq]$")
}

function New-DefaultState {
  return [ordered]@{
    schema = $script:StateSchema
    state = "NEW"
    updated_at = (Get-Date).ToString("o")
    source_root = $SourceRoot
    preflight = [ordered]@{}
    next_action = "PREFLIGHT"
    tailscale_dns = ""
    public_mcp_url = ""
    runtime_install_root = $script:RemoteInstallRoot
    composio_confirmed_count = $null
    composio_confirmation = ""
  }
}

function Convert-StateToHashtable {
  param($Object)
  $state = New-DefaultState
  if ($null -eq $Object) { return $state }
  foreach ($name in @(
    "schema","state","updated_at","source_root","next_action",
    "tailscale_dns","public_mcp_url","runtime_install_root",
    "composio_confirmed_count","composio_confirmation"
  )) {
    $prop = $Object.PSObject.Properties[$name]
    if ($prop) { $state[$name] = $prop.Value }
  }
  if ($Object.preflight) {
    foreach ($prop in $Object.preflight.PSObject.Properties) {
      $state.preflight[$prop.Name] = $prop.Value
    }
  }
  return $state
}

function Load-SetupState {
  if ($ResetState -or -not (Test-Path $script:StatePath)) {
    return (New-DefaultState)
  }
  try {
    return (Convert-StateToHashtable ((Get-Content -Raw -Path $script:StatePath) | ConvertFrom-Json))
  } catch {
    Write-Status "INFO" "Previous setup progress could not be read. A safe new session will be used."
    Write-LogLine ("State read failed: " + $_.Exception.Message)
    return (New-DefaultState)
  }
}

function Save-SetupState {
  param($State)
  if ($DryRun) { return }
  New-Item -ItemType Directory -Force -Path $script:DataRoot | Out-Null
  $State.updated_at = (Get-Date).ToString("o")
  $State | ConvertTo-Json -Depth 8 | Set-Content -Path $script:StatePath -Encoding UTF8
}

function Find-TailscaleExecutable {
  $cmd = Get-Command "tailscale.exe" -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command "tailscale" -ErrorAction SilentlyContinue }
  if ($cmd) { return $cmd.Source }

  $fallbacks = @()
  if ($env:ProgramFiles) { $fallbacks += (Join-Path $env:ProgramFiles "Tailscale\tailscale.exe") }
  $pf86 = [Environment]::GetFolderPath("ProgramFilesX86")
  if ($pf86) { $fallbacks += (Join-Path $pf86 "Tailscale\tailscale.exe") }
  foreach ($candidate in $fallbacks) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
  }
  return $null
}

function Get-TailscaleState {
  $exe = Find-TailscaleExecutable
  $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
  $result = [ordered]@{
    installed = [bool]($exe -or $service)
    executable = $exe
    service = if ($service) { [string]$service.Status } else { "Unknown" }
    backend = "Unknown"
    connected = $false
    dns_name = ""
  }
  if (-not $result.installed -or -not $exe) { return $result }

  try {
    $raw = (& $exe status --json 2>$null | Out-String).Trim()
    if ($raw) {
      $json = $raw | ConvertFrom-Json
      $result.backend = [string]$json.BackendState
      $result.connected = ($result.backend -eq "Running")
      if ($json.Self -and $json.Self.DNSName) {
        $result.dns_name = ([string]$json.Self.DNSName).TrimEnd(".")
      }
    }
  } catch {
    Write-LogLine ("Tailscale status probe failed: " + $_.Exception.Message)
  }
  return $result
}

function Install-TailscaleGuided {
  if ($DryRun) {
    Write-Status "INFO" "Would install Tailscale with winget: Tailscale.Tailscale"
    return $false
  }
  $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
  if (-not $winget) {
    Write-Status "FAIL" "Automatic Tailscale installation requires winget."
    return $false
  }
  if (-not (Read-Continue -Prompt "Press ENTER to install Tailscale or Q to exit")) { return $false }
  Write-Status "INFO" "Installing the secure connection app..."
  & $winget.Source install --id Tailscale.Tailscale -e --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) {
    Write-Status "FAIL" "Tailscale installation did not complete successfully."
    return $false
  }
  return [bool](Find-TailscaleExecutable)
}

function Ensure-TailscaleConnected {
  $ts = Get-TailscaleState

  if (-not $ts.installed) {
    Write-Status "FIX" "Tailscale needs to be installed"
    if (-not (Install-TailscaleGuided)) { return $null }
    $ts = Get-TailscaleState
  }

  if ($DryRun) {
    if ($ts.connected) {
      Write-Status "OK" "Tailscale is already connected"
    } else {
      Write-Status "INFO" "Would open the user's Tailscale login flow and re-check the device"
    }
    return $ts
  }

  $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
  if ($service -and $service.Status -ne "Running") {
    try {
      Start-Service -Name "Tailscale"
      Start-Sleep -Seconds 2
      Write-Status "OK" "Secure connection service started"
    } catch {
      Write-Status "FAIL" "Tailscale is installed but its Windows service could not be started."
      return $null
    }
  }

  $ts = Get-TailscaleState
  if (-not $ts.connected) {
    Write-Status "WAIT" "Tailscale needs your account login"
    Write-Host " A browser sign-in may open. Finish login with your own account," -ForegroundColor Gray
    Write-Host " then return to this terminal." -ForegroundColor Gray
    if (-not (Read-Continue -Prompt "Press ENTER to open Tailscale login or Q to exit")) { return $null }
    try {
      & $ts.executable login
    } catch {
      Write-LogLine ("tailscale login failed: " + $_.Exception.Message)
    }

    for ($i = 0; $i -lt 20; $i++) {
      Start-Sleep -Seconds 2
      $ts = Get-TailscaleState
      if ($ts.connected -and $ts.dns_name) { break }
    }
  }

  if (-not $ts.connected) {
    Write-Status "FAIL" "Tailscale is installed, but this computer is not connected to an account yet."
    return $null
  }
  if (-not $ts.dns_name) {
    Write-Status "FAIL" "Tailscale is connected but did not return a device DNS name required by Funnel."
    return $null
  }

  Write-Status "OK" "Tailscale account connected"
  Write-Status "OK" "This device has a secure DNS identity"
  return $ts
}

function Resolve-RuntimeSourceRoot {
  $candidates = @()
  if ($SourceRoot) {
    $candidates += (Join-Path $SourceRoot "runtime\remote-growth-stable")
  }
  $candidates += (Join-Path $script:DataRoot "runtime-source\remote-growth-stable")
  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate "MCP_GATEWAY\gateway.py"))) {
      return $candidate
    }
  }
  return $null
}

function Resolve-RemoteHelper {
  param([string]$Name)
  $candidates = @()
  if ($SourceRoot) {
    $candidates += (Join-Path $SourceRoot ("scripts\windows\remote-growth-stable\" + $Name))
  }
  $candidates += (Join-Path $PSScriptRoot ("remote-growth-stable\" + $Name))
  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
  }
  return $null
}

function Get-FunnelStatus {
  param([string]$TailscaleExe)
  try { return ((& $TailscaleExe funnel status 2>&1) -join [Environment]::NewLine) }
  catch { return [string]$_ }
}

function Get-PublicMcpUrl {
  param([string]$DnsName,[int]$Port)
  if ($Port -eq 443) { return "https://$DnsName/mcp" }
  return "https://$($DnsName):$Port/mcp"
}

function Get-PublicBaseUrl {
  param([string]$DnsName,[int]$Port)
  if ($Port -eq 443) { return "https://$DnsName" }
  return "https://$($DnsName):$Port"
}

function Test-ExpectedFunnel {
  param([string]$Status,[string]$DnsName,[int]$HttpsPort,[int]$TargetPort)
  $base = Get-PublicBaseUrl -DnsName $DnsName -Port $HttpsPort
  return (
    $Status -match [regex]::Escape($base) -and
    $Status -match [regex]::Escape("127.0.0.1:$TargetPort")
  )
}

function Test-FunnelPortConflict {
  param([string]$Status,[string]$DnsName,[int]$HttpsPort,[int]$TargetPort)
  $base = Get-PublicBaseUrl -DnsName $DnsName -Port $HttpsPort
  if ($Status -notmatch [regex]::Escape($base)) { return $false }
  return ($Status -notmatch [regex]::Escape("127.0.0.1:$TargetPort"))
}

function Enable-GuidedFunnel {
  param([string]$TailscaleExe,[string]$DnsName,[int]$HttpsPort,[int]$TargetPort)

  if ($DryRun) {
    Write-Status "INFO" ("Would verify Funnel HTTPS " + $HttpsPort + " and map it only to the verified local gateway")
    return $true
  }

  $status = Get-FunnelStatus -TailscaleExe $TailscaleExe
  if (Test-ExpectedFunnel -Status $status -DnsName $DnsName -HttpsPort $HttpsPort -TargetPort $TargetPort) {
    Write-Status "OK" "Secure public route already points to Remote GROWTH"
    return $true
  }
  if (Test-FunnelPortConflict -Status $status -DnsName $DnsName -HttpsPort $HttpsPort -TargetPort $TargetPort) {
    Write-Status "FAIL" ("Tailscale HTTPS port " + $HttpsPort + " is already mapped to another local service.")
    Write-Status "INFO" "OTAK-ATIK will not overwrite that route automatically."
    return $false
  }

  Write-Status "WAIT" "The local 64-tool gateway is ready. The next action exposes only that protected gateway through Tailscale."
  if (-not (Read-Continue -Prompt "Press ENTER to enable the secure route or Q to exit")) { return $false }

  $output = ((& $TailscaleExe funnel --bg --yes ("--https=" + $HttpsPort) $TargetPort 2>&1) -join [Environment]::NewLine)
  $exitCode = $LASTEXITCODE

  if ($exitCode -ne 0) {
    $match = [regex]::Match($output, "https://[^\s]+")
    if ($match.Success) {
      $approvalUrl = $match.Value.TrimEnd(".",",",")")
      Write-Status "WAIT" "Tailscale needs one-time Funnel approval in your browser"
      try { Start-Process $approvalUrl } catch {}
      if (-not (Read-Continue -Prompt "Approve Funnel in the browser, then press ENTER to retry or Q to exit")) { return $false }
      $output = ((& $TailscaleExe funnel --bg --yes ("--https=" + $HttpsPort) $TargetPort 2>&1) -join [Environment]::NewLine)
      $exitCode = $LASTEXITCODE
    }
  }

  if ($exitCode -ne 0) {
    Write-LogLine ("Funnel command failed: " + $output)
    Write-Status "FAIL" "Tailscale could not create the secure public route."
    return $false
  }

  for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Seconds 2
    $status = Get-FunnelStatus -TailscaleExe $TailscaleExe
    if (Test-ExpectedFunnel -Status $status -DnsName $DnsName -HttpsPort $HttpsPort -TargetPort $TargetPort) {
      Write-Status "OK" "Secure public route points to the verified gateway"
      return $true
    }
  }

  Write-Status "FAIL" "Tailscale returned successfully, but the expected gateway mapping was not found."
  return $false
}

function Invoke-RuntimeAcceptance {
  param([switch]$Public)
  $testScript = Resolve-RemoteHelper -Name "test-runtime.ps1"
  if (-not $testScript) { return $null }
  $args = @("-InstallRoot",$script:RemoteInstallRoot,"-AsJson")
  if ($Public) { $args += "-IncludePublic" }
  $line = (& $testScript @args 2>$null | Select-Object -Last 1)
  $code = $LASTEXITCODE
  if (-not $line) { return $null }
  try {
    $obj = $line | ConvertFrom-Json
    $obj | Add-Member -NotePropertyName exit_code -NotePropertyValue $code -Force
    return $obj
  } catch {
    return $null
  }
}

function Copy-TextValue {
  param([string]$Value,[string]$Label)
  try {
    Set-Clipboard -Value $Value
    Write-Status "OK" ($Label + " copied to clipboard")
  } catch {
    Write-Status "FAIL" ("Could not copy " + $Label.ToLower() + " to clipboard")
  }
}

function Get-Preflight {
  $isWindows = ($env:OS -eq "Windows_NT")
  $psVersion = $PSVersionTable.PSVersion.ToString()
  $nodeFound = [bool](Get-Command "node" -ErrorAction SilentlyContinue)
  $nodeVersion = $null
  $nodeMajor = 0
  if ($nodeFound) {
    try {
      $nodeVersion = (& node --version 2>$null | Out-String).Trim()
      $nodeMajor = [int](($nodeVersion.TrimStart("v") -split "\.")[0])
    } catch { $nodeFound = $false }
  }
  $gitFound = [bool](Get-Command "git" -ErrorAction SilentlyContinue)
  $tailscale = Get-TailscaleState
  return [ordered]@{
    windows = $isWindows
    powershell_version = $psVersion
    node_found = $nodeFound
    node_version = $nodeVersion
    node_major = $nodeMajor
    node_supported = ($nodeFound -and $nodeMajor -ge 20)
    git_found = $gitFound
    tailscale_installed = [bool]$tailscale.installed
    tailscale_service = [string]$tailscale.service
    tailscale_backend = [string]$tailscale.backend
    tailscale_connected = [bool]$tailscale.connected
  }
}

function Show-Preflight {
  param($Preflight)
  if ($Preflight.windows) { Write-Status "OK" "Windows detected" }
  else { Write-Status "FAIL" "This guided setup currently supports Windows 10/11 only" }

  Write-Status "OK" ("PowerShell " + $Preflight.powershell_version)

  if ($Preflight.node_supported) { Write-Status "OK" ("Node.js " + $Preflight.node_version) }
  elseif ($Preflight.node_found) { Write-Status "FIX" ("Node.js " + $Preflight.node_version + " found; version 20+ is required") }
  else { Write-Status "FIX" "Node.js 20+ needs to be installed" }

  if ($Preflight.git_found) { Write-Status "OK" "Git detected" }
  else { Write-Status "INFO" "Git not detected; it is recommended for updates and development" }

  if ($Preflight.tailscale_installed) {
    if ($Preflight.tailscale_connected) { Write-Status "OK" "Tailscale is installed and signed in" }
    elseif ($Preflight.tailscale_service -eq "Running") { Write-Status "WAIT" "Tailscale is running but still needs account sign-in" }
    else { Write-Status "FIX" "Tailscale is installed but not running" }
  } else {
    Write-Status "FIX" "Tailscale needs to be installed"
  }
}

Initialize-Console
Write-BrandHeader

if ($DryRun) { Write-Status "INFO" "Dry-run mode: no files, accounts, routes, or settings will be changed." }

$state = Load-SetupState
if ($state.state -ne "NEW") {
  Write-Status "INFO" ("Previous safe progress detected: " + $state.state)
  Write-Status "INFO" "The wizard will re-check the real machine instead of blindly replaying old steps."
}

Write-Host " This wizard prepares ChatGPT access through Composio," -ForegroundColor White
Write-Host " Tailscale, and the protected Remote GROWTH 64-tool gateway." -ForegroundColor White
Write-Host ""
Write-Host " You sign in to your own accounts. Secrets stay local." -ForegroundColor DarkGray

if (-not (Read-Continue -Prompt "Press ENTER to start or Q to exit")) {
  Write-Status "INFO" "Setup closed without making changes."
  Write-Footer
  exit 0
}

Write-Step 1 5 "Checking your computer"
$preflight = Get-Preflight
Show-Preflight $preflight
$state.preflight = $preflight

if (-not $preflight.windows) {
  $state.state = "NEW"
  $state.next_action = "UNSUPPORTED_OS"
  Save-SetupState $state
  Write-Status "FAIL" "This setup cannot continue on the current operating system."
  Write-Footer
  exit 2
}

if (-not $preflight.node_supported) {
  if ($DryRun) {
    Write-Status "INFO" "Would offer automatic Node.js LTS installation before continuing."
  } else {
    $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if (-not $winget) {
      Write-Status "FAIL" "Node.js 20+ is required and winget is unavailable for automatic installation."
      Write-Footer
      exit 2
    }
    if (-not (Read-Continue -Prompt "Press ENTER to install/upgrade Node.js LTS or Q to exit")) {
      Write-Footer
      exit 0
    }
    & $winget.Source install --id OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
      Write-Status "FAIL" "Node.js installation/upgrade did not complete successfully."
      Write-Footer
      exit 2
    }
    $preflight = Get-Preflight
    if (-not $preflight.node_supported) {
      Write-Status "WAIT" "Node.js was installed, but this terminal has not picked up the new PATH yet."
      Write-Status "INFO" "Close this window and run START.cmd again."
      Write-Footer
      exit 0
    }
  }
}

$state.state = "PREFLIGHT_OK"
$state.next_action = "CONNECT_TAILSCALE"
Save-SetupState $state
Write-Status "OK" "Computer check passed"

Write-Step 2 5 "Secure connection"
$ts = Ensure-TailscaleConnected
if ($DryRun) {
  Write-Status "INFO" "Dry run: account login and Funnel changes are skipped."
  Write-Step 3 5 "Preparing Remote GROWTH"
  $runtimeSource = Resolve-RuntimeSourceRoot
  $runtimeInstaller = Resolve-RemoteHelper -Name "install-runtime.ps1"
  if ($runtimeSource -and $runtimeInstaller) {
    & $runtimeInstaller -SourceRuntimeRoot $runtimeSource -TailscaleDnsName "" -PublicHttpsPort $script:PublicHttpsPort -InstallPrerequisites -DryRun
  } else {
    Write-Status "FAIL" "Portable runtime source/helper is missing from this checkout/install."
    Write-Footer
    exit 2
  }
  Write-Step 4 5 "Connect Composio"
  Write-Status "INFO" "Would open the dedicated Composio Add Custom MCP page only after public security checks pass."
  Write-Step 5 5 "Final check"
  Write-Status "INFO" "Would require public HTTP 401 without auth and authenticated tools/list == 64."
  Write-Footer
  exit 0
}

if (-not $ts) {
  $state.next_action = "CONNECT_TAILSCALE"
  Save-SetupState $state
  Write-Footer
  exit 2
}

$state.state = "TAILSCALE_READY"
$state.next_action = "INSTALL_GATEWAY"
$state.tailscale_dns = [string]$ts.dns_name
Save-SetupState $state

Write-Step 3 5 "Preparing Remote GROWTH"
$runtimeSource = Resolve-RuntimeSourceRoot
$runtimeInstaller = Resolve-RemoteHelper -Name "install-runtime.ps1"
if (-not $runtimeSource -or -not $runtimeInstaller) {
  Write-Status "FAIL" "Portable Remote GROWTH runtime files are missing."
  Write-Footer
  exit 2
}

Write-Status "INFO" "Installing the isolated 64-tool runtime and verifying it locally..."
try {
  & $runtimeInstaller -SourceRuntimeRoot $runtimeSource -InstallRoot $script:RemoteInstallRoot -TailscaleDnsName ([string]$ts.dns_name) -TailscaleExe ([string]$ts.executable) -PublicHttpsPort $script:PublicHttpsPort -InstallPrerequisites
  if ($LASTEXITCODE -ne 0) { throw "runtime installer exited with code $LASTEXITCODE" }
} catch {
  Write-LogLine ("Runtime install failed: " + $_.Exception.Message)
  Write-Status "FAIL" "Remote GROWTH did not pass the local 64-tool verification."
  Write-Status "INFO" "Nothing will be exposed publicly until the local runtime is healthy."
  Write-Footer
  exit 2
}

$localAcceptance = Invoke-RuntimeAcceptance
if (-not $localAcceptance -or -not $localAcceptance.ok -or [int]$localAcceptance.local.count -ne 64) {
  Write-Status "FAIL" "Local gateway exists, but the expected 64-tool inventory was not verified."
  Write-Footer
  exit 2
}
Write-Status "OK" "Remote GROWTH local gateway"
Write-Status "OK" "64 tools verified locally"
Write-Status "OK" "Secure access code generated and kept local"

$configPath = Join-Path $script:RemoteInstallRoot "config.json"
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$publicUrl = [string]$config.publicMcpUrl

if (-not (Enable-GuidedFunnel -TailscaleExe ([string]$ts.executable) -DnsName ([string]$ts.dns_name) -HttpsPort $script:PublicHttpsPort -TargetPort ([int]$config.gatewayPort))) {
  $state.state = "GATEWAY_READY"
  $state.next_action = "ENABLE_PUBLIC_ROUTE"
  Save-SetupState $state
  Write-Footer
  exit 2
}

Write-Status "WAIT" "Checking the public route and authentication boundary..."
$publicAcceptance = $null
for ($i = 0; $i -lt 15; $i++) {
  $publicAcceptance = Invoke-RuntimeAcceptance -Public
  if ($publicAcceptance -and $publicAcceptance.ok) { break }
  Start-Sleep -Seconds 3
}

if (-not $publicAcceptance -or -not $publicAcceptance.ok) {
  Write-Status "FAIL" "The secure route exists, but public acceptance is not fully healthy yet."
  if ($publicAcceptance -and $publicAcceptance.public) {
    if ($publicAcceptance.public.unauthenticated_status -ne 401) {
      Write-Status "FAIL" "Unauthenticated public traffic was not confirmed as HTTP 401."
    }
    if (-not $publicAcceptance.public.inventory_match) {
      Write-Status "FAIL" "Authenticated public tools/list did not return exactly 64 tools."
    }
  }
  Write-Status "INFO" "Composio will not be opened until these checks pass."
  $state.state = "GATEWAY_READY"
  $state.next_action = "VERIFY_PUBLIC_ROUTE"
  Save-SetupState $state
  Write-Footer
  exit 2
}

Write-Status "OK" "Public endpoint reachable"
Write-Status "OK" "Unauthorized access blocked with HTTP 401"
Write-Status "OK" "Authenticated public inventory: 64 tools"

$state.state = "PUBLIC_ROUTE_READY"
$state.next_action = "CONNECT_COMPOSIO"
$state.public_mcp_url = $publicUrl
$state.runtime_install_root = $script:RemoteInstallRoot
Save-SetupState $state

Write-Step 4 5 "Connect Composio"
Write-Host " Your protected MCP server is ready." -ForegroundColor White
Write-Host ""
Write-Host " Composio setup values:" -ForegroundColor Cyan
Write-Host "   Name           : Remote GROWTH Stable"
Write-Host "   Transport      : HTTP / Streamable HTTP"
Write-Host ("   MCP URL        : " + $publicUrl)
Write-Host "   Authentication : Bearer"
Write-Host ""
Write-Host " If Composio asks for a header instead of a token field:" -ForegroundColor DarkGray
Write-Host "   Header name    : Authorization" -ForegroundColor DarkGray
Write-Host "   Header value   : Bearer <secure access code>" -ForegroundColor DarkGray
Write-Host ""
Write-Host " The access code is never printed here." -ForegroundColor DarkGray
Write-Host ""

try {
  Start-Process $script:ComposioCustomMcpUrl
  Write-Status "OK" "Opened Composio Add Custom MCP"
} catch {
  Write-Status "INFO" ("Open this page in your browser: " + $script:ComposioCustomMcpUrl)
}

$authFile = Join-Path $script:RemoteInstallRoot "auth.key"
$state.state = "COMPOSIO_WAITING"
$state.next_action = "CONFIRM_COMPOSIO"
Save-SetupState $state

$confirmedCount = $null
while ($null -eq $confirmedCount) {
  Write-Host ""
  Write-Host " [C] Copy MCP URL" -ForegroundColor Cyan
  Write-Host " [K] Copy secure access code" -ForegroundColor Cyan
  Write-Host " [O] Open Composio again" -ForegroundColor Cyan
  Write-Host " [ENTER] I connected it; check the tool count" -ForegroundColor Green
  Write-Host " [Q] Save progress and exit" -ForegroundColor DarkGray
  $choice = Read-Host "Choose"

  switch -Regex ($choice) {
    "^[Cc]$" {
      Copy-TextValue -Value $publicUrl -Label "MCP URL"
      continue
    }
    "^[Kk]$" {
      $token = (Get-Content -Raw -LiteralPath $authFile).Trim()
      Copy-TextValue -Value $token -Label "Secure access code"
      Remove-Variable token -ErrorAction SilentlyContinue
      continue
    }
    "^[Oo]$" {
      try { Start-Process $script:ComposioCustomMcpUrl } catch {}
      continue
    }
    "^[Qq]$" {
      Write-Status "INFO" "Progress saved. Run START.cmd again to continue."
      Write-Footer
      exit 0
    }
    "^$" {
      $rawCount = Read-Host "How many tools does Composio show? Enter the number"
      $parsed = 0
      if ([int]::TryParse($rawCount, [ref]$parsed)) {
        $confirmedCount = $parsed
      } else {
        Write-Status "WAIT" "Enter the tool count shown by Composio."
      }
      continue
    }
    default {
      Write-Status "INFO" "Choose C, K, O, ENTER, or Q."
    }
  }
}

if ($confirmedCount -ne 64) {
  Write-Status "FAIL" ("Composio shows " + $confirmedCount + " tools; this release requires exactly 64.")
  Write-Status "INFO" "The connection is not marked complete. Re-open START.cmd after fixing the Composio connection."
  $state.composio_confirmed_count = $confirmedCount
  $state.composio_confirmation = "user-observed"
  $state.next_action = "CONFIRM_COMPOSIO"
  Save-SetupState $state
  Write-Footer
  exit 2
}

$state.state = "COMPOSIO_CONNECTED"
$state.next_action = "FINAL_ACCEPTANCE"
$state.composio_confirmed_count = 64
$state.composio_confirmation = "user-observed"
Save-SetupState $state
Write-Status "OK" "Composio tool count confirmed: 64"

Write-Step 5 5 "Final check"
$tsFinal = Get-TailscaleState
$funnelFinal = if ($tsFinal.executable) { Get-FunnelStatus -TailscaleExe ([string]$tsFinal.executable) } else { "" }
$publicFinal = Invoke-RuntimeAcceptance -Public

$tailscaleOk = [bool]($tsFinal.connected -and $tsFinal.dns_name)
$funnelOk = [bool](Test-ExpectedFunnel -Status $funnelFinal -DnsName ([string]$state.tailscale_dns) -HttpsPort $script:PublicHttpsPort -TargetPort 18765)
$acceptanceOk = [bool]($publicFinal -and $publicFinal.ok)

Write-Status $(if ($tailscaleOk) { "OK" } else { "FAIL" }) "Tailscale connection"
Write-Status $(if ($funnelOk) { "OK" } else { "FAIL" }) "Secure public route"
Write-Status $(if ($acceptanceOk) { "OK" } else { "FAIL" }) "Authentication + public 64-tool inventory"
Write-Status "OK" "Composio: 64 tools confirmed by the user"

if (-not ($tailscaleOk -and $funnelOk -and $acceptanceOk)) {
  $state.next_action = "FINAL_ACCEPTANCE"
  Save-SetupState $state
  Write-Status "FAIL" "Final acceptance is incomplete. Setup remains safely resumable."
  Write-Footer
  exit 2
}

$state.state = "ACCEPTANCE_PASSED"
$state.next_action = "READY"
Save-SetupState $state

Write-Host ""
Write-Host "+======================================================+" -ForegroundColor Green
Write-Host "|                   SETUP COMPLETE                     |" -ForegroundColor Green
Write-Host "|                                                      |" -ForegroundColor Green
Write-Host "|       Remote GROWTH + Composio is ready.             |" -ForegroundColor White
Write-Host "|                 64 tools verified.                   |" -ForegroundColor White
Write-Host "+======================================================+" -ForegroundColor Green
Write-Footer

if (-not $NonInteractive) { [void](Read-Host "Press ENTER to close") }
exit 0
