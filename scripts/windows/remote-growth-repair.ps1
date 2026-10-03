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
  if ($AsJson) { return }
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
  if ($AsJson) { return }
  if (Get-Command Initialize-OtakTui -ErrorAction SilentlyContinue) {
    Initialize-OtakTui -Title "OTAK-ATIK REPAIR" -NoClear:$NoClear
    Write-OtakLogo -Subtitle "REMOTE AI x COMPOSIO SETUP" -Mode "SAFE REPAIR"
    Write-OtakNotice -Title "SAFE SELF-HEALING" -Lines @(
      "Only OTAK-ATIK-owned components may be restarted or recreated.",
      "Foreign port owners and unrelated services are never terminated.",
      "Authentication protection is re-verified before success."
    ) -Kind "INFO"
    return
  }
  if (-not $NoClear) { Clear-Host }
  try { [Console]::Title = "OTAK-ATIK REPAIR" } catch {}
  Write-Host ""
  Write-Host "OTAK-ATIK REPAIR" -ForegroundColor Cyan
  Write-Host $Brand -ForegroundColor Gray
}

function Get-Health {
  param([switch]$Quick)

  $healthScript = Join-Path $PSScriptRoot "remote-growth-stable\get-health.ps1"
  if (-not (Test-Path -LiteralPath $healthScript)) {
    throw "Health helper is missing. Re-run the OTAK-ATIK installer."
  }
  $healthParams = @{
    InstallRoot = $InstallRoot
    AsJson = $true
  }
  if ($LocalOnly) { $healthParams.LocalOnly = $true }
  if ($Quick) { $healthParams.Quick = $true }
  $line = (& $healthScript @healthParams 2>$null | Select-Object -Last 1)
  if (-not $line) { throw "Health helper returned no result." }
  return ($line | ConvertFrom-Json)
}

function Test-ProjectPortOwner {
  param([int]$Port,[string[]]$Patterns)

  $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if (-not $conn) { return $true }

  $proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + [int]$conn.OwningProcess) -ErrorAction SilentlyContinue
  $cmd = if ($proc) { [string]$proc.CommandLine } else { "" }
  foreach ($pattern in $Patterns) {
    if ($cmd -notmatch $pattern) { return $false }
  }
  return $true
}

function Stop-ProjectRuntime {
  param($Config)

  $supervisorPath = Join-Path $InstallRoot "supervisor.ps1"
  $escapedSupervisor = [regex]::Escape($supervisorPath)
  $targets = @()

  $targets += @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Name -eq "powershell.exe" -and
      [string]$_.CommandLine -match $escapedSupervisor
    })

  foreach ($port in @([int]$Config.gatewayPort,[int]$Config.upstreamPort)) {
    $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
      Select-Object -First 1
    if ($conn) {
      $proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + [int]$conn.OwningProcess) -ErrorAction SilentlyContinue
      if ($proc) { $targets += $proc }
    }
  }

  $targets = @($targets | Sort-Object ProcessId -Unique)
  foreach ($proc in $targets) {
    $cmd = [string]$proc.CommandLine
    $owned = (
      $cmd -match $escapedSupervisor -or
      ($cmd -match "gateway\.py" -and $cmd -match [regex]::Escape([string]$Config.gatewayPort)) -or
      ($cmd -match "windows-mcp" -and $cmd -match [regex]::Escape([string]$Config.upstreamPort))
    )
    if ($owned) {
      Stop-Process -Id ([int]$proc.ProcessId) -Force -ErrorAction SilentlyContinue
    }
  }
}

function Ensure-AutoStartTask {
  param($Config)

  $taskName = [string]$Config.taskName
  if (-not $taskName) { return $false }
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    return $true
  }

  $supervisorPath = Join-Path $InstallRoot "supervisor.ps1"
  if (-not (Test-Path -LiteralPath $supervisorPath)) { return $false }

  $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $supervisorPath + '"')
  $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
  $principal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited

  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Starts the portable OTAK-ATIK Remote GROWTH Stable runtime at logon." -Force | Out-Null
  return $true
}

function Start-Supervisor {
  param($Config)

  $supervisorPath = Join-Path $InstallRoot "supervisor.ps1"
  if (-not (Test-Path -LiteralPath $supervisorPath)) { return $false }

  $escaped = [regex]::Escape($supervisorPath)
  $existing = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Name -eq "powershell.exe" -and
      [string]$_.CommandLine -match $escaped
    })
  if ($existing.Count -gt 0) { return $true }

  $taskName = [string]$Config.taskName
  if ($taskName -and (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue)) {
    try {
      Start-ScheduledTask -TaskName $taskName
      return $true
    } catch {}
  }

  $quoted = '"' + $supervisorPath.Replace('"','') + '"'
  Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$quoted)
  return $true
}

function Wait-LocalReady {
  for ($i = 0; $i -lt 45; $i++) {
    if (-not $AsJson -and (Get-Command Write-OtakActivity -ErrorAction SilentlyContinue)) {
      Write-OtakActivity -Message "Restarting protected runtime components..." -Frame $i
    }
    Start-Sleep -Seconds 1
    $quick = Get-Health -Quick
    if ($quick.blocked.Count -gt 0) { return $quick }
    if ($quick.gateway.state -eq "owned" -and $quick.upstream.state -eq "owned") {
      if (-not $AsJson -and (Get-Command Complete-OtakActivity -ErrorAction SilentlyContinue)) {
        Complete-OtakActivity -Message "Runtime listeners are back online"
      }
      break
    }
  }

  for ($attempt = 0; $attempt -lt 2; $attempt++) {
    if (-not $AsJson) {
      Write-Line "WAIT" "Re-validating HTTP 401 protection and the complete 64-tool inventory..."
    }
    $health = Get-Health
    if ($health.local.auth_guard_ok -and $health.local.inventory_match -and [int]$health.local.count -eq 64) {
      return $health
    }
    if ($health.blocked.Count -gt 0) { return $health }
    Start-Sleep -Seconds 3
  }

  return (Get-Health)
}

function Disable-ExpectedFunnel {
  param($Config)

  $exe = [string]$Config.tailscaleExe
  if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
    Set-Content -LiteralPath (Join-Path $InstallRoot "disabled.flag") -Value "security-fail-closed" -Encoding ASCII
    Stop-ProjectRuntime -Config $Config
    return "runtime-disabled"
  }

  try {
    $raw = (& $exe funnel status --json 2>$null | Out-String).Trim()
    if ($raw) {
      $json = $raw | ConvertFrom-Json
      $active = @()
      if ($json.AllowFunnel) {
        $active = @($json.AllowFunnel.PSObject.Properties.Name)
      }

      $expectedAuthority = ""
      try { $expectedAuthority = ([uri]([string]$Config.publicMcpUrl)).Authority } catch {}

      if ($active.Count -eq 1 -and $expectedAuthority -and $active[0] -eq $expectedAuthority) {
        & $exe funnel reset 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { return "funnel-reset" }
      }
    }
  } catch {}

  Set-Content -LiteralPath (Join-Path $InstallRoot "disabled.flag") -Value "security-fail-closed" -Encoding ASCII
  Stop-ProjectRuntime -Config $Config
  return "runtime-disabled"
}

function Emit-Final {
  param($Health,[string[]]$Actions,[int]$ExitCode)

  if ($AsJson) {
    [ordered]@{
      ok = [bool]($ExitCode -eq 0)
      overall = [string]$Health.overall
      actions = $Actions
      health = $Health
    } | ConvertTo-Json -Depth 12 -Compress
  } else {
    Write-Host ""
    if ($ExitCode -eq 0) {
      if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
        Write-OtakNotice -Title "REPAIR COMPLETE" -Lines @(
          "OTAK-ATIK-owned components are healthy again.",
          "Authentication protection is active.",
          "64 / 64 tools verified."
        ) -Kind "OK"
      } else {
        Write-Host " Repair complete. Everything is ready." -ForegroundColor Green
      }
    } elseif ($Health.overall -eq "USER_ACTION") {
      if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
        Write-OtakNotice -Title "ACTION REQUIRED" -Lines @(
          "Automatic repair is complete.",
          "One account-owned action remains for you."
        ) -Kind "WARN"
      } else {
        Write-Host " Automatic repair is complete; one account-owned action remains." -ForegroundColor Yellow
      }
    } else {
      if (Get-Command Write-OtakNotice -ErrorAction SilentlyContinue) {
        Write-OtakNotice -Title "SAFETY BOUNDARY" -Lines @(
          "Repair stopped safely.",
          "OTAK-ATIK did not take ownership of an unrelated process or route."
        ) -Kind "ERROR"
      } else {
        Write-Host " Repair stopped at a safety boundary." -ForegroundColor Red
      }
    }
    if (Get-Command Write-OtakFooter -ErrorAction SilentlyContinue) {
      Write-OtakFooter -Brand $Brand
    } else {
      Write-Host ""
      Write-Host (" " + $Brand) -ForegroundColor DarkGray
      Write-Host ""
    }
    if (-not $NonInteractive) { [void](Read-Host "Press ENTER to close") }
  }
  exit $ExitCode
}

Write-Header
$actions = @()

try {
  $health = Get-Health
} catch {
  if ($AsJson) {
    [ordered]@{ok=$false;overall="BLOCKED";actions=@();error=$_.Exception.Message} |
      ConvertTo-Json -Compress
  } else {
    Write-Line "FAIL" $_.Exception.Message
  }
  exit 5
}

if (-not $health.config_present -or -not $health.auth_present) {
  Write-Line "WAIT" "First-time setup is incomplete."
  Write-Line "INFO" "Run the START launcher; REPAIR will not invent or replace account credentials."
  Emit-Final -Health $health -Actions $actions -ExitCode 4
}

$configPath = Join-Path $InstallRoot "config.json"
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

$disabledPath = Join-Path $InstallRoot "disabled.flag"
if (Test-Path -LiteralPath $disabledPath) {
  Remove-Item -LiteralPath $disabledPath -Force
  $actions += "Cleared the OTAK-ATIK safety marker for explicit revalidation."
  Write-Line "INFO" "Safety marker cleared for this explicit repair attempt"
}

$gatewaySafe = Test-ProjectPortOwner -Port ([int]$config.gatewayPort) -Patterns @("gateway\.py",[regex]::Escape([string]$config.gatewayPort))
$upstreamSafe = Test-ProjectPortOwner -Port ([int]$config.upstreamPort) -Patterns @("windows-mcp",[regex]::Escape([string]$config.upstreamPort))

if (-not $gatewaySafe -or -not $upstreamSafe) {
  Write-Line "FAIL" "A Remote GROWTH port is owned by another application."
  Write-Line "INFO" "OTAK-ATIK will not terminate or overwrite that process."
  Emit-Final -Health $health -Actions $actions -ExitCode 5
}

if (-not $LocalOnly -and $health.public.checked -and -not $health.public.auth_guard_ok) {
  $failClosedMode = Disable-ExpectedFunnel -Config $config
  $actions += ("Fail-closed public protection: " + $failClosedMode)
  Write-Line "FAIL" "Public access protection failed; OTAK-ATIK removed or neutralized its public exposure."
  $health = Get-Health
  Emit-Final -Health $health -Actions $actions -ExitCode 5
}

if (-not $health.local.auth_guard_ok -and $health.local.checked) {
  Stop-ProjectRuntime -Config $config
  $actions += "Restarted project-owned runtime after local authentication check failed."
  Write-Line "FIX" "Restarting the protected local runtime"
}

if (-not $health.task.present) {
  if (Ensure-AutoStartTask -Config $config) {
    $actions += "Recreated the current-user auto-start task."
    Write-Line "OK" "Windows auto-start task repaired"
  } else {
    Write-Line "FAIL" "Could not recreate the Windows auto-start task."
  }
}

if (-not $health.supervisor.running -or $health.gateway.state -eq "missing" -or $health.upstream.state -eq "missing" -or -not $health.local.inventory_match) {
  [void](Start-Supervisor -Config $config)
  $actions += "Started the Remote GROWTH supervisor through the project auto-start path."
  Write-Line "FIX" "Starting Remote GROWTH supervisor"
}

$health = Wait-LocalReady
if (-not $health.local.auth_guard_ok) {
  Write-Line "FAIL" "Local access protection is still unhealthy."
  Emit-Final -Health $health -Actions $actions -ExitCode 5
}
if (-not $health.local.inventory_match -or [int]$health.local.count -ne 64) {
  Write-Line "FAIL" "Local gateway did not recover to 64 tools."
  Emit-Final -Health $health -Actions $actions -ExitCode 5
}
Write-Line "OK" "Local Remote GROWTH recovered  -  64/64 tools"

if ($LocalOnly) {
  $health = Get-Health
  $code = if ($health.ok) { 0 } else { 5 }
  Emit-Final -Health $health -Actions $actions -ExitCode $code
}

$service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
if ($service -and $service.Status -ne "Running") {
  try {
    Start-Service -Name "Tailscale"
    Start-Sleep -Seconds 2
    $actions += "Started the Tailscale Windows service."
    Write-Line "OK" "Tailscale Windows service started"
  } catch {
    Write-Line "FAIL" "Tailscale service could not be started."
  }
}

$health = Get-Health
if (-not $health.tailscale.installed) {
  Write-Line "WAIT" "Tailscale is not installed; the START launcher is required."
  Emit-Final -Health $health -Actions $actions -ExitCode 4
}

if (-not $health.tailscale.connected) {
  if ($NonInteractive) {
    Write-Line "WAIT" "Tailscale account login is required."
    Emit-Final -Health $health -Actions $actions -ExitCode 4
  }

  Write-Line "WAIT" "Tailscale needs your account login."
  $answer = Read-Host "Press ENTER to open Tailscale login or Q to stop"
  if ($answer -match "^[Qq]$") {
    Emit-Final -Health $health -Actions $actions -ExitCode 4
  }

  try { & ([string]$config.tailscaleExe) login } catch {}
  Start-Sleep -Seconds 3
  $health = Get-Health
}

if (-not $health.tailscale.connected) {
  Write-Line "WAIT" "Tailscale is still waiting for account login."
  Emit-Final -Health $health -Actions $actions -ExitCode 4
}
if (-not $health.tailscale.dns_match) {
  Write-Line "WAIT" "This Tailscale device identity changed."
  Write-Line "INFO" "Run the START launcher so the public URL and allowed hostname can be refreshed safely."
  Emit-Final -Health $health -Actions $actions -ExitCode 4
}

if (-not $health.funnel.expected) {
  if ($health.funnel.conflict) {
    Write-Line "FAIL" "The configured Funnel HTTPS port points to another local service."
    Emit-Final -Health $health -Actions $actions -ExitCode 5
  }

  $funnelHelper = Join-Path $PSScriptRoot "remote-growth-stable\configure-funnel.ps1"
  if (-not (Test-Path -LiteralPath $funnelHelper)) {
    Write-Line "FAIL" "Secure-route repair helper is missing."
    Emit-Final -Health $health -Actions $actions -ExitCode 5
  }

  Write-Line "FIX" "Repairing the secure public route"
  if ($NonInteractive) {
    & $funnelHelper -InstallRoot $InstallRoot -NonInteractive | Out-Null
  } else {
    & $funnelHelper -InstallRoot $InstallRoot | Out-Null
  }
  if ($LASTEXITCODE -eq 0) {
    $actions += "Restored the expected Tailscale Funnel route."
  }
}

$health = Get-Health
if ($health.public.checked -and -not $health.public.auth_guard_ok) {
  $failClosedMode = Disable-ExpectedFunnel -Config $config
  $actions += ("Fail-closed public protection: " + $failClosedMode)
  Write-Line "FAIL" "Public security verification failed; OTAK-ATIK removed or neutralized its public exposure."
  $health = Get-Health
  Emit-Final -Health $health -Actions $actions -ExitCode 5
}
if (-not $health.public.inventory_match -or [int]$health.public.count -ne 64) {
  Write-Line "FAIL" "Public MCP did not recover to 64 tools."
  Emit-Final -Health $health -Actions $actions -ExitCode 5
}
Write-Line "OK" "Secure public route recovered  -  401 guard + 64/64 tools"

if (-not $health.composio.last_sync_ok) {
  Write-Line "WAIT" "Core connection is healthy, but Composio needs a guided reconnect/sync."
  Write-Line "INFO" "Run the START launcher; account credentials remain under your control."
  Emit-Final -Health $health -Actions $actions -ExitCode 4
}

Emit-Final -Health $health -Actions $actions -ExitCode 0
