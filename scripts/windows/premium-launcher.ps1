[CmdletBinding()]
param(
  [ValidateSet("Start","Status","Repair")][string]$Mode = "Start",
  [string]$BootstrapRoot = "",
  [switch]$InTerminal,
  [switch]$DryRun,
  [switch]$NonInteractive,
  [switch]$AsJson,
  [switch]$LocalOnly,
  [switch]$NoClear,
  [switch]$ResetState,
  [string]$InstallRoot = ""
)

$ErrorActionPreference = "Stop"

$ui = Join-Path $PSScriptRoot "premium-tui.ps1"
if (Test-Path -LiteralPath $ui) { . $ui }

function Test-HeadlessMode {
  return [bool](
    $env:CI -eq "true" -or
    $env:GITHUB_ACTIONS -eq "true" -or
    $NonInteractive -or
    $AsJson -or
    $DryRun
  )
}

function Quote-ProcessArgument {
  param([string]$Value)
  if ($null -eq $Value) { return '""' }
  return '"' + ($Value.Replace('"','\"')) + '"'
}

function Get-RelaunchArguments {
  $args = @("-Mode",$Mode,"-InTerminal")
  if ($BootstrapRoot) { $args += @("-BootstrapRoot",$BootstrapRoot) }
  if ($DryRun) { $args += "-DryRun" }
  if ($NonInteractive) { $args += "-NonInteractive" }
  if ($AsJson) { $args += "-AsJson" }
  if ($LocalOnly) { $args += "-LocalOnly" }
  if ($NoClear) { $args += "-NoClear" }
  if ($ResetState) { $args += "-ResetState" }
  if ($InstallRoot) { $args += @("-InstallRoot",$InstallRoot) }
  return $args
}

function Start-PremiumTerminal {
  $wt = Get-Command "wt.exe" -ErrorAction SilentlyContinue
  if (-not $wt) { return $false }

  $title = switch ($Mode) {
    "Status" { "OTAK-ATIK - Status" }
    "Repair" { "OTAK-ATIK - Repair" }
    default { "OTAK-ATIK - Remote AI Setup" }
  }

  $parts = @(
    "-w","new",
    "-M",
    "-f",
    "new-tab",
    "--title",(Quote-ProcessArgument $title),
    "powershell.exe",
    "-NoLogo",
    "-NoProfile",
    "-ExecutionPolicy","Bypass",
    "-File",(Quote-ProcessArgument $PSCommandPath)
  )

  foreach ($arg in @(Get-RelaunchArguments)) {
    $parts += (Quote-ProcessArgument ([string]$arg))
  }

  Start-Process -FilePath $wt.Source -ArgumentList ($parts -join " ") | Out-Null
  return $true
}

$headless = Test-HeadlessMode

function Exit-Premium {
  param([int]$Code)

  if ($Code -ne 0 -and -not $headless) {
    if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
      Write-OtakNotice -Title "SETUP PAUSED SAFELY" -Lines @(
        ("OTAK-ATIK stopped with code " + $Code + "."),
        "Your completed steps were not intentionally rolled back.",
        "Read the message above, then run START again to resume."
      ) -Kind "WARN"
    }
    [void](Read-Host "Press ENTER to close")
  }
  exit $Code
}

if (-not $InTerminal -and -not $headless -and -not $env:WT_SESSION) {
  if (Start-PremiumTerminal) { exit 0 }
}

$title = switch ($Mode) {
  "Status" { "OTAK-ATIK STATUS" }
  "Repair" { "OTAK-ATIK REPAIR" }
  default { "OTAK-ATIK - Remote AI Setup Wizard" }
}

if (Get-Command Initialize-OtakTui -ErrorAction SilentlyContinue) {
  Initialize-OtakTui -Title $title -NoClear:$NoClear
}

if ($Mode -eq "Start") {
  $installedWizard = Join-Path $HOME ".otak-atik\windows\setup-wizard.ps1"

  if ($BootstrapRoot) {
    $bootstrap = Join-Path $BootstrapRoot "scripts\install.ps1"
    if (-not (Test-Path -LiteralPath $bootstrap)) {
      if (Get-Command Write-OtakLogo -ErrorAction SilentlyContinue) {
        Write-OtakLogo -Subtitle "REMOTE AI x COMPOSIO SETUP" -Mode "BOOTSTRAP"
        Write-OtakNotice -Title "INSTALLER INCOMPLETE" -Lines @(
          "The extracted release folder is missing required files.",
          "Extract the full ZIP, then run START.cmd again."
        ) -Kind "ERROR"
      } else {
        Write-Host "OTAK-ATIK bootstrap files are incomplete." -ForegroundColor Red
      }
      Exit-Premium -Code 5
    }

    if (Get-Command Write-OtakLogo -ErrorAction SilentlyContinue) {
      Write-OtakLogo -Subtitle "REMOTE AI x COMPOSIO SETUP" -Mode "BOOTSTRAP"
      Write-OtakStatus -Kind "INFO" -Message "Preparing the durable local installation..."
    }

    & $bootstrap -NoOpenSetupPages
    if ($LASTEXITCODE -ne 0) {
      if (Get-Command Write-OtakStatus -ErrorAction SilentlyContinue) {
        Write-OtakStatus -Kind "FAIL" -Message ("Bootstrap stopped safely with code " + $LASTEXITCODE)
      }
      Exit-Premium -Code $LASTEXITCODE
    }
  }

  if (-not (Test-Path -LiteralPath $installedWizard)) {
    if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
      Write-OtakNotice -Title "FIRST START REQUIRED" -Lines @(
        "OTAK-ATIK is not installed on this Windows profile yet.",
        "Run START.cmd from the extracted release ZIP."
      ) -Kind "WARN"
    } else {
      Write-Host "OTAK-ATIK is not installed yet. Run START.cmd from the release ZIP." -ForegroundColor Yellow
    }
    Exit-Premium -Code 4
  }

  $wizardParams = @{}
  if ($DryRun) { $wizardParams.DryRun = $true }
  if ($NonInteractive) { $wizardParams.NonInteractive = $true }
  if ($NoClear) { $wizardParams.NoClear = $true }
  if ($ResetState) { $wizardParams.ResetState = $true }

  & $installedWizard @wizardParams
  Exit-Premium -Code $LASTEXITCODE
}

$targetScript = if ($Mode -eq "Status") {
  Join-Path $PSScriptRoot "remote-growth-status.ps1"
} else {
  Join-Path $PSScriptRoot "remote-growth-repair.ps1"
}

if (-not (Test-Path -LiteralPath $targetScript)) {
  if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
    Write-OtakLogo -Subtitle "REMOTE AI x COMPOSIO SETUP" -Mode $Mode.ToUpperInvariant()
    Write-OtakNotice -Title "FIRST START REQUIRED" -Lines @(
      "OTAK-ATIK has not finished its local installation.",
      "Run START.cmd first."
    ) -Kind "WARN"
  } else {
    Write-Host "OTAK-ATIK is not installed yet. Run START.cmd first." -ForegroundColor Yellow
  }
  Exit-Premium -Code 4
}

$targetParams = @{}
if ($InstallRoot) { $targetParams.InstallRoot = $InstallRoot }
if ($LocalOnly) { $targetParams.LocalOnly = $true }
if ($NonInteractive) { $targetParams.NonInteractive = $true }
if ($AsJson) { $targetParams.AsJson = $true }
if ($NoClear) { $targetParams.NoClear = $true }

& $targetScript @targetParams
Exit-Premium -Code $LASTEXITCODE
