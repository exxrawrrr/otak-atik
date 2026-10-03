[CmdletBinding()]
param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [switch]$LocalOnly,
  [switch]$Quick,
  [switch]$AsJson
)

$ErrorActionPreference = "Stop"

function Get-PortState {
  param([int]$Port,[string[]]$ExpectedPatterns)

  $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1
  if (-not $conn) {
    return [ordered]@{ state="missing"; pid=$null; command_line="" }
  }

  $pidValue = [int]$conn.OwningProcess
  $proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $pidValue) -ErrorAction SilentlyContinue
  $cmd = if ($proc) { [string]$proc.CommandLine } else { "" }
  $owned = $true
  foreach ($pattern in $ExpectedPatterns) {
    if ($cmd -notmatch $pattern) { $owned = $false; break }
  }

  return [ordered]@{
    state = if ($owned) { "owned" } else { "foreign" }
    pid = $pidValue
    command_line = $cmd
  }
}

function Get-TailscaleHealth {
  param([string]$Exe,[string]$ExpectedDns)

  $service = Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue
  $result = [ordered]@{
    installed = [bool]($Exe -and (Test-Path -LiteralPath $Exe))
    service = if ($service) { [string]$service.Status } else { "Missing" }
    connected = $false
    dns_name = ""
    dns_match = $false
  }

  if (-not $result.installed) { return $result }

  try {
    $raw = (& $Exe status --json 2>$null | Out-String).Trim()
    if ($raw) {
      $json = $raw | ConvertFrom-Json
      $result.connected = ([string]$json.BackendState -eq "Running")
      if ($json.Self -and $json.Self.DNSName) {
        $result.dns_name = ([string]$json.Self.DNSName).TrimEnd(".")
      }
    }
  } catch {}

  $result.dns_match = [bool](
    $result.dns_name -and
    $ExpectedDns -and
    ($result.dns_name -eq $ExpectedDns)
  )
  return $result
}

function Get-FunnelHealth {
  param($Config)

  $result = [ordered]@{
    available = $false
    expected = $false
    conflict = $false
    status_text = ""
  }

  $exe = [string]$Config.tailscaleExe
  if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { return $result }

  try {
    $text = ((& $exe funnel status 2>&1) -join [Environment]::NewLine)
    $result.available = $true
    $result.status_text = $text

    $publicBase = ([string]$Config.publicMcpUrl) -replace "/mcp$",""
    $target = "127.0.0.1:$([int]$Config.gatewayPort)"
    $hasBase = [bool]($publicBase -and $text -match [regex]::Escape($publicBase))
    $hasTarget = [bool]($text -match [regex]::Escape($target))

    $result.expected = [bool]($hasBase -and $hasTarget)
    if ($hasBase -and -not $hasTarget) { $result.conflict = $true }
  } catch {}

  return $result
}

$configPath = Join-Path $InstallRoot "config.json"
$authFile = Join-Path $InstallRoot "auth.key"
$composioPath = Join-Path $InstallRoot "composio.json"

$result = [ordered]@{
  schema = 1
  overall = "UNKNOWN"
  ok = $false
  install_root = $InstallRoot
  config_present = (Test-Path -LiteralPath $configPath)
  auth_present = (Test-Path -LiteralPath $authFile)
  disabled_marker = (Test-Path -LiteralPath (Join-Path $InstallRoot "disabled.flag"))
  task = [ordered]@{ present=$false; state="Missing" }
  supervisor = [ordered]@{ running=$false; pid=$null }
  upstream = $null
  gateway = $null
  local = [ordered]@{ checked=$false; auth_guard_ok=$false; unauthenticated_status=$null; count=$null; inventory_match=$false }
  tailscale = $null
  funnel = $null
  public = [ordered]@{ checked=$false; auth_guard_ok=$false; unauthenticated_status=$null; count=$null; inventory_match=$false }
  composio = [ordered]@{ metadata_present=$false; url_match=$false; synced_count=$null; last_sync_ok=$false }
  repairable = @()
  needs_user_action = @()
  blocked = @()
}

if (-not $result.config_present) {
  $result.needs_user_action += "Remote GROWTH has not been installed yet."
}
if (-not $result.auth_present) {
  $result.blocked += "Remote GROWTH access credential is missing."
}
if ($result.disabled_marker) {
  $result.repairable += "Runtime is disabled by an OTAK-ATIK safety marker."
}

$config = $null
if ($result.config_present) {
  try { $config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json }
  catch { $result.blocked += "Runtime config is unreadable." }
}

if ($config) {
  $taskName = [string]$config.taskName
  if ($taskName) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
      $result.task.present = $true
      $result.task.state = [string]$task.State
    } else {
      $result.repairable += "Auto-start task is missing."
    }
  }

  $supervisorPath = Join-Path $InstallRoot "supervisor.ps1"
  $escapedSupervisor = [regex]::Escape($supervisorPath)
  $supervisor = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object {
      $_.Name -eq "powershell.exe" -and
      [string]$_.CommandLine -match $escapedSupervisor
    } | Select-Object -First 1)
  if ($supervisor.Count -gt 0) {
    $result.supervisor.running = $true
    $result.supervisor.pid = [int]$supervisor[0].ProcessId
  } else {
    $result.repairable += "Runtime supervisor is not running."
  }

  $result.upstream = Get-PortState -Port ([int]$config.upstreamPort) -ExpectedPatterns @(
    "windows-mcp",
    [regex]::Escape([string]$config.upstreamPort)
  )
  $result.gateway = Get-PortState -Port ([int]$config.gatewayPort) -ExpectedPatterns @(
    "gateway\.py",
    [regex]::Escape([string]$config.gatewayPort)
  )

  if ($result.upstream.state -eq "foreign") {
    $result.blocked += "Upstream port is owned by another application."
  } elseif ($result.upstream.state -eq "missing") {
    $result.repairable += "Windows-MCP upstream is not listening."
  }

  if ($result.gateway.state -eq "foreign") {
    $result.blocked += "Gateway port is owned by another application."
  } elseif ($result.gateway.state -eq "missing") {
    $result.repairable += "64-tool gateway is not listening."
  }

  $testScript = Join-Path $PSScriptRoot "test-runtime.ps1"
  if (
    -not $Quick -and
    (Test-Path -LiteralPath $testScript) -and
    $result.auth_present -and
    $result.gateway.state -eq "owned"
  ) {
    try {
      $line = (& $testScript -InstallRoot $InstallRoot -AsJson -NoExit 2>$null | Select-Object -Last 1)
      if ($line) {
        $accept = $line | ConvertFrom-Json
        $result.local.auth_guard_ok = [bool]$accept.local.auth_guard_ok
        $result.local.unauthenticated_status = $accept.local.unauthenticated_status
        $result.local.count = $accept.local.count
        $result.local.inventory_match = [bool]$accept.local.inventory_match
        $result.local.checked = [bool](
          $null -ne $accept.local.unauthenticated_status -or
          $null -ne $accept.local.count
        )
      }
    } catch {}
  }

  if (-not $result.local.inventory_match -or [int]$result.local.count -ne 64) {
    $result.repairable += "Local MCP inventory is not 64 tools."
  }
  if ($null -ne $result.local.unauthenticated_status -and -not $result.local.auth_guard_ok) {
    $result.blocked += "Local MCP authentication guard is not returning 401."
  }

  if (-not $LocalOnly) {
    $result.tailscale = Get-TailscaleHealth -Exe ([string]$config.tailscaleExe) -ExpectedDns ([string]$config.tailscaleDnsName)
    if (-not $result.tailscale.installed) {
      $result.needs_user_action += "Tailscale is not installed."
    } elseif ($result.tailscale.service -ne "Running") {
      $result.repairable += "Tailscale service is not running."
    } elseif (-not $result.tailscale.connected) {
      $result.needs_user_action += "Tailscale account login is required."
    } elseif (-not $result.tailscale.dns_match) {
      $result.needs_user_action += "Tailscale device identity changed; guided setup must refresh the public identity."
    }

    $result.funnel = Get-FunnelHealth -Config $config
    if ($result.funnel.conflict) {
      $result.blocked += "Tailscale Funnel is mapped to a different local target."
    } elseif (-not $result.funnel.expected) {
      $result.repairable += "Secure public route is missing."
    }

    if (
      -not $Quick -and
      $result.funnel.expected -and
      $result.tailscale.connected -and
      $result.auth_present -and
      $result.local.auth_guard_ok -and
      $result.local.inventory_match
    ) {
      try {
        $line = (& $testScript -InstallRoot $InstallRoot -IncludePublic -AsJson -NoExit 2>$null | Select-Object -Last 1)
        if ($line) {
          $accept = $line | ConvertFrom-Json
          $result.public.auth_guard_ok = [bool]$accept.public.auth_guard_ok
          $result.public.unauthenticated_status = $accept.public.unauthenticated_status
          $result.public.count = $accept.public.count
          $result.public.inventory_match = [bool]$accept.public.inventory_match
          $result.public.checked = [bool](
            $null -ne $accept.public.unauthenticated_status -or
            $null -ne $accept.public.count
          )
        }
      } catch {}
    }

    if ($result.public.checked) {
      if ($null -ne $result.public.unauthenticated_status -and -not $result.public.auth_guard_ok) {
        $result.blocked += "Public MCP authentication guard is not returning 401."
      }
      if (-not $result.public.inventory_match -or [int]$result.public.count -ne 64) {
        $result.repairable += "Public MCP inventory is not 64 tools."
      }
    }

    if (Test-Path -LiteralPath $composioPath) {
      try {
        $meta = Get-Content -Raw -LiteralPath $composioPath | ConvertFrom-Json
        $result.composio.metadata_present = $true
        $result.composio.synced_count = $meta.syncedCount
        $result.composio.url_match = ([string]$meta.publicMcpUrl -eq [string]$config.publicMcpUrl)
        $result.composio.last_sync_ok = [bool](
          $result.composio.url_match -and
          [int]$meta.syncedCount -eq 64
        )
      } catch {}
    }
    if (-not $result.composio.last_sync_ok) {
      $result.needs_user_action += "Composio needs guided reconnect or a fresh 64-tool sync."
    }
  }
}

$result.repairable = @($result.repairable | Select-Object -Unique)
$result.needs_user_action = @($result.needs_user_action | Select-Object -Unique)
$result.blocked = @($result.blocked | Select-Object -Unique)

if ($result.blocked.Count -gt 0) {
  $result.overall = "BLOCKED"
} elseif ($result.needs_user_action.Count -gt 0) {
  $result.overall = "USER_ACTION"
} elseif ($result.repairable.Count -gt 0) {
  $result.overall = "REPAIR_NEEDED"
} else {
  $result.overall = "READY"
  $result.ok = $true
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 10 -Compress
} else {
  $result
}
