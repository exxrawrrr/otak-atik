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
$script:StateSchema = 1

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

function Initialize-Console {
  try { [Console]::Title = "OTAK-ATIK - Remote AI Setup Wizard" } catch {}
  try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
  if (-not $NoClear) {
    Clear-Host
  }
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
  param(
    [int]$Number,
    [int]$Total,
    [string]$Title
  )

  Write-Host ""
  Write-Host (" STEP {0} OF {1} " -f $Number, $Total) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
  Write-Host ("  " + $Title) -ForegroundColor Cyan
  Write-Host (" " + ("-" * 54)) -ForegroundColor DarkGray
}

function Write-Status {
  param(
    [ValidateSet("OK","WAIT","FIX","INFO","FAIL")]
    [string]$Kind,
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
  param(
    [string]$Prompt = "Press ENTER to continue or Q to exit"
  )

  if ($NonInteractive) { return $true }

  Write-Host ""
  $answer = Read-Host $Prompt
  if ($answer -match "^[Qq]$") {
    return $false
  }

  return $true
}

function New-DefaultState {
  return [ordered]@{
    schema = $script:StateSchema
    state = "NEW"
    updated_at = (Get-Date).ToString("o")
    source_root = $SourceRoot
    preflight = [ordered]@{}
    next_action = "PREFLIGHT"
  }
}

function Convert-StateToHashtable {
  param($Object)

  $state = New-DefaultState
  if ($null -eq $Object) { return $state }

  if ($Object.schema) { $state.schema = [int]$Object.schema }
  if ($Object.state) { $state.state = [string]$Object.state }
  if ($Object.updated_at) { $state.updated_at = [string]$Object.updated_at }
  if ($Object.source_root) { $state.source_root = [string]$Object.source_root }
  if ($Object.next_action) { $state.next_action = [string]$Object.next_action }

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
    $raw = Get-Content -Raw -Path $script:StatePath
    return (Convert-StateToHashtable ($raw | ConvertFrom-Json))
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
  $json = $State | ConvertTo-Json -Depth 6
  Set-Content -Path $script:StatePath -Value $json -Encoding UTF8
}

function Find-TailscaleExecutable {
  $cmd = Get-Command "tailscale" -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  if ($env:ProgramFiles) {
    $candidate = Join-Path $env:ProgramFiles "Tailscale\tailscale.exe"
    if (Test-Path $candidate) { return $candidate }
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
  }

  if (-not $result.installed) {
    return $result
  }

  if ($exe) {
    try {
      $raw = (& $exe status --json 2>$null | Out-String).Trim()
      if ($raw) {
        $json = $raw | ConvertFrom-Json
        if ($json.BackendState) {
          $result.backend = [string]$json.BackendState
          $result.connected = ($result.backend -eq "Running")
        }
      }
    } catch {
      Write-LogLine ("Tailscale status probe failed: " + $_.Exception.Message)
    }
  }

  return $result
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
      $clean = $nodeVersion.TrimStart("v")
      $nodeMajor = [int](($clean -split "\.")[0])
    } catch {
      $nodeFound = $false
    }
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

  if ($Preflight.windows) {
    Write-Status "OK" "Windows detected"
  } else {
    Write-Status "FAIL" "This guided setup currently supports Windows 10/11 only"
  }

  Write-Status "OK" ("PowerShell " + $Preflight.powershell_version)

  if ($Preflight.node_supported) {
    Write-Status "OK" ("Node.js " + $Preflight.node_version)
  } elseif ($Preflight.node_found) {
    Write-Status "FIX" ("Node.js " + $Preflight.node_version + " found; version 20+ is required")
  } else {
    Write-Status "FIX" "Node.js 20+ needs to be installed"
  }

  if ($Preflight.git_found) {
    Write-Status "OK" "Git detected"
  } else {
    Write-Status "INFO" "Git not detected; it is recommended for updates and development"
  }

  if ($Preflight.tailscale_installed) {
    if ($Preflight.tailscale_connected) {
      Write-Status "OK" "Secure connection app is installed and signed in"
    } elseif ($Preflight.tailscale_service -eq "Running") {
      Write-Status "WAIT" "Secure connection app is running but still needs account sign-in"
    } else {
      Write-Status "FIX" "Secure connection app is installed but not running"
    }
  } else {
    Write-Status "FIX" "Secure connection app needs to be installed"
  }
}

function Test-CorePreflight {
  param($Preflight)

  return (
    $Preflight.windows -and
    $Preflight.node_supported
  )
}

Initialize-Console
Write-BrandHeader

if ($DryRun) {
  Write-Status "INFO" "Dry-run mode: no files or settings will be changed."
}

$state = Load-SetupState

if ($state.state -ne "NEW") {
  Write-Status "INFO" ("Previous safe progress detected: " + $state.state)
  Write-Status "INFO" "The wizard will re-check reality instead of blindly replaying old steps."
}

Write-Host " This wizard prepares your computer for the guided" -ForegroundColor White
Write-Host " Composio + Remote GROWTH setup path." -ForegroundColor White
Write-Host ""
Write-Host " You will always sign in to your own accounts yourself." -ForegroundColor DarkGray
Write-Host " Secrets are not stored in this public repository." -ForegroundColor DarkGray

if (-not (Read-Continue -Prompt "Press ENTER to start or Q to exit")) {
  Write-Status "INFO" "Setup closed without making changes."
  Write-Footer
  exit 0
}

Write-Step 1 5 "Checking your computer"

$preflight = Get-Preflight
Show-Preflight $preflight

$coreReady = Test-CorePreflight $preflight
$state.preflight = $preflight

if (-not $coreReady) {
  $state.state = "NEW"
  $state.next_action = "FIX_PREFLIGHT"
  Save-SetupState $state

  Write-Host ""
  Write-Status "FAIL" "Core requirements are not ready, so setup will not continue yet."
  Write-Status "INFO" "No network, authentication, or remote-access settings were changed."
  Write-Footer
  exit 2
}

$state.state = "PREFLIGHT_OK"
$state.next_action = if ($preflight.tailscale_connected) { "VERIFY_TAILSCALE_ROUTE" } else { "CONNECT_TAILSCALE" }
Save-SetupState $state

Write-Host ""
Write-Status "OK" "Computer check passed"
if ($DryRun) {
  Write-Status "INFO" "Dry run complete; setup state was not written."
} else {
  Write-Status "INFO" ("Safe progress saved to " + $script:StatePath)
}

Write-Step 2 5 "Secure connection"

if ($preflight.tailscale_connected) {
  Write-Status "OK" "Your secure connection account is already signed in"
  Write-Status "WAIT" "Route/Funnel verification is intentionally deferred to the next wiring phase"
} elseif ($preflight.tailscale_installed) {
  Write-Status "WAIT" "Your secure connection account still needs sign-in"
} else {
  Write-Status "FIX" "Tailscale installation and sign-in are the next setup actions"
}

Write-Host ""
Write-Host " This build intentionally stops here." -ForegroundColor Yellow
Write-Host " The terminal UX, preflight checks, and resumable state are active;" -ForegroundColor Gray
Write-Host " secure-route and Composio wiring are not enabled yet." -ForegroundColor Gray
Write-Host ""
Write-Status "INFO" "No fake success state will be shown before those checks are real."

Write-Footer

if (-not $NonInteractive) {
  [void](Read-Host "Press ENTER to close")
}

exit 0
