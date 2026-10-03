[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [switch]$LocalOnly,
  [switch]$NonInteractive,
  [switch]$AsJson,
  [switch]$NoClear
)

$ErrorActionPreference = "Stop"
$Brand = "Created by Rafdi D. Ulhaq - exxrawrrr"
$TuiScript = Join-Path $PSScriptRoot "premium-tui.ps1"
if (Test-Path -LiteralPath $TuiScript) { . $TuiScript }

function Write-Line {
  param(
    [ValidateSet("OK","WAIT","FIX","INFO","FAIL")][string]$Kind,
    [string]$Message
  )
  if (Get-Command Write-OtakStatus -ErrorAction SilentlyContinue) {
    Write-OtakStatus -Kind $Kind -Message $Message
    return
  }
  $color = switch ($Kind) {
    "OK"   { "Green" }
    "WAIT" { "Yellow" }
    "FIX"  { "Yellow" }
    "INFO" { "Gray" }
    "FAIL" { "Red" }
  }
  Write-Host (" [{0}]" -f $Kind.PadRight(4)) -NoNewline -ForegroundColor $color
  Write-Host (" " + $Message)
}

function Write-Header {
  if (Get-Command Initialize-OtakTui -ErrorAction SilentlyContinue) {
    Initialize-OtakTui -Title "OTAK-ATIK STATUS" -NoClear:$NoClear
    Write-OtakLogo -Subtitle "REMOTE AI x COMPOSIO SETUP" -Mode "SYSTEM STATUS"
    Write-OtakProgress -Current 1 -Total 1 -Label "Checking installed components"
    return
  }
  if (-not $NoClear) { Clear-Host }
  try { [Console]::Title = "OTAK-ATIK STATUS" } catch {}
  Write-Host ""
  Write-Host "OTAK-ATIK STATUS" -ForegroundColor Cyan
  Write-Host $Brand -ForegroundColor Gray
}

$healthScript = Join-Path $PSScriptRoot "remote-growth-stable\get-health.ps1"
if (-not (Test-Path -LiteralPath $healthScript)) {
  if ($AsJson) {
    [ordered]@{ ok=$false; overall="BLOCKED"; error="health helper missing" } |
      ConvertTo-Json -Compress
  } else {
    Write-Header
    Write-Line "FAIL" "Health checker is missing. Re-run the OTAK-ATIK installer."
  }
  exit 5
}

$healthParams = @{
  InstallRoot = $InstallRoot
  AsJson = $true
}
if ($LocalOnly) { $healthParams.LocalOnly = $true }

try {
  $line = (& $healthScript @healthParams 2>$null | Select-Object -Last 1)
  $health = $line | ConvertFrom-Json
} catch {
  if ($AsJson) {
    [ordered]@{ ok=$false; overall="BLOCKED"; error=$_.Exception.Message } |
      ConvertTo-Json -Compress
  } else {
    Write-Header
    Write-Line "FAIL" "Status check could not read the Remote GROWTH health result."
  }
  exit 5
}

if ($AsJson) {
  $health | ConvertTo-Json -Depth 10 -Compress
  if ($health.overall -eq "READY") { exit 0 }
  if ($health.overall -eq "REPAIR_NEEDED") { exit 3 }
  if ($health.overall -eq "USER_ACTION") { exit 4 }
  exit 5
}

Write-Header

if (-not $health.config_present) {
  Write-Line "WAIT" "Remote GROWTH has not been set up on this Windows profile yet."
  Write-Line "INFO" "Run START.cmd to complete first-time setup."
  Write-Host ""
  Write-Host (" " + $Brand) -ForegroundColor DarkGray
  if (-not $NonInteractive) { [void](Read-Host "Press ENTER to close") }
  exit 4
}

if ($health.local.auth_guard_ok) {
  Write-Line "OK" "Local access protection"
} elseif ($health.local.checked) {
  Write-Line "FAIL" "Local access protection is not returning 401"
} else {
  Write-Line "FIX" "Local access protection could not be verified"
}

if ($health.local.inventory_match -and [int]($health.local.count) -eq 64) {
  Write-Line "OK" "Remote GROWTH local gateway  -  64/64 tools"
} else {
  Write-Line "FIX" ("Remote GROWTH local gateway  -  detected " + $health.local.count + "/64 tools")
}

if ($health.supervisor.running) {
  Write-Line "OK" "Runtime supervisor"
} else {
  Write-Line "FIX" "Runtime supervisor is not running"
}

if ($health.task.present) {
  Write-Line "OK" "Windows auto-start task"
} else {
  Write-Line "FIX" "Windows auto-start task is missing"
}

if (-not $LocalOnly) {
  if ($health.tailscale.installed -and $health.tailscale.connected) {
    Write-Line "OK" "Tailscale account connected"
  } elseif ($health.tailscale.installed) {
    Write-Line "WAIT" "Tailscale needs account sign-in"
  } else {
    Write-Line "WAIT" "Tailscale is not installed"
  }

  if ($health.funnel.expected) {
    Write-Line "OK" "Secure public route"
  } elseif ($health.funnel.conflict) {
    Write-Line "FAIL" "Secure public route points to another local service"
  } else {
    Write-Line "FIX" "Secure public route is missing"
  }

  if ($health.public.auth_guard_ok) {
    Write-Line "OK" "Public access protection  -  unauthenticated request blocked"
  } elseif ($health.public.checked) {
    Write-Line "FAIL" "Public access protection failed"
  } else {
    Write-Line "FIX" "Public access protection could not be verified"
  }

  if ($health.public.inventory_match -and [int]($health.public.count) -eq 64) {
    Write-Line "OK" "Public MCP  -  64/64 tools"
  } else {
    Write-Line "FIX" ("Public MCP  -  detected " + $health.public.count + "/64 tools")
  }

  if ($health.composio.last_sync_ok) {
    Write-Line "OK" "Composio  -  last verified sync 64 tools"
  } else {
    Write-Line "WAIT" "Composio needs guided reconnect or fresh sync"
  }
}

Write-Host ""
switch ([string]$health.overall) {
  "READY" {
    if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
      Write-OtakNotice -Title "SYSTEM READY" -Lines @(
        "Remote GROWTH is healthy.",
        "Authentication protection is active.",
        "The verified tool inventory is available."
      ) -Kind "OK"
    } else {
      Write-Host " Everything is ready." -ForegroundColor Green
    }
    $exitCode = 0
  }
  "REPAIR_NEEDED" {
    if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
      Write-OtakNotice -Title "REPAIR RECOMMENDED" -Lines @(
        "One or more OTAK-ATIK-owned components need repair.",
        "Open REPAIR.cmd. No technical diagnosis is required."
      ) -Kind "WARN"
    } else {
      Write-Host " One or more project-owned components need repair." -ForegroundColor Yellow
    }
    $exitCode = 3
  }
  "USER_ACTION" {
    if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
      Write-OtakNotice -Title "ACTION REQUIRED" -Lines @(
        "The computer is safe.",
        "One account-owned step still needs you.",
        "Open REPAIR.cmd to continue the guided recovery."
      ) -Kind "WARN"
    } else {
      Write-Host " The computer is safe, but one account-owned action is still required." -ForegroundColor Yellow
    }
    $exitCode = 4
  }
  default {
    if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
      Write-OtakNotice -Title "SAFETY BOUNDARY" -Lines @(
        "OTAK-ATIK stopped instead of taking ownership of an ambiguous state.",
        "REPAIR.cmd will diagnose it without overwriting unrelated services."
      ) -Kind "ERROR"
    } else {
      Write-Host " OTAK-ATIK stopped at a safety boundary." -ForegroundColor Red
    }
    $exitCode = 5
  }
}

if ($health.blocked.Count -gt 0) {
  Write-Host ""
  foreach ($item in $health.blocked) { Write-Line "FAIL" ([string]$item) }
}
if ($health.needs_user_action.Count -gt 0) {
  foreach ($item in $health.needs_user_action) { Write-Line "WAIT" ([string]$item) }
}

Write-Host ""
Write-Host (" " + $Brand) -ForegroundColor DarkGray
Write-Host ""
if (-not $NonInteractive) { [void](Read-Host "Press ENTER to close") }
exit $exitCode
