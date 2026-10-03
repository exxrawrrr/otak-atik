[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"

$InstallRoot = $PSScriptRoot
$ConfigPath = Join-Path $InstallRoot "config.json"
$AuthFile = Join-Path $InstallRoot "auth.key"
$LogRoot = Join-Path $InstallRoot "logs"
$SupervisorLog = Join-Path $LogRoot "supervisor.log"
$UpstreamOut = Join-Path $LogRoot "windows-mcp.out.log"
$UpstreamErr = Join-Path $LogRoot "windows-mcp.err.log"
$GatewayOut = Join-Path $LogRoot "gateway.out.log"
$GatewayErr = Join-Path $LogRoot "gateway.err.log"

New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null

function Write-SupervisorLog {
  param([string]$Message)
  Add-Content -LiteralPath $SupervisorLog -Value ("{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message) -Encoding UTF8
}

function Trim-Log {
  param([string]$Path, [int]$MaxBytes = 2097152)
  if (-not (Test-Path -LiteralPath $Path)) { return }
  $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
  if (-not $item -or $item.Length -le $MaxBytes) { return }
  $tail = Get-Content -LiteralPath $Path -Tail 800 -ErrorAction SilentlyContinue
  $tail | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-PortOwner {
  param([int]$Port)
  $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($conn) { return [int]$conn.OwningProcess }
  return $null
}

function Get-CommandLine {
  param([int]$ProcessId)
  $proc = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $ProcessId) -ErrorAction SilentlyContinue
  if ($proc) { return [string]$proc.CommandLine }
  return ""
}

function Test-OwnedPort {
  param(
    [int]$Port,
    [string[]]$Patterns
  )

  $pidValue = Get-PortOwner -Port $Port
  if (-not $pidValue) { return $false }

  $cmd = Get-CommandLine -ProcessId $pidValue
  foreach ($pattern in $Patterns) {
    if ($cmd -notmatch $pattern) { return $false }
  }
  return $true
}

function Start-Upstream {
  param($Config, [string]$AuthKey)

  $port = [int]$Config.upstreamPort
  $owner = Get-PortOwner -Port $port
  if ($owner) {
    if (Test-OwnedPort -Port $port -Patterns @("windows-mcp", [regex]::Escape([string]$port))) {
      return $true
    }
    Write-SupervisorLog "ERROR: upstream port $port is owned by an unrelated process; refusing to replace it."
    return $false
  }

  $env:WINDOWS_MCP_AUTH_KEY = $AuthKey
  $env:WINDOWS_MCP_STATELESS_HTTP = "true"
  $env:ANONYMIZED_TELEMETRY = "false"
  $env:FASTMCP_HTTP_HOST_ORIGIN_PROTECTION = "true"
  $env:FASTMCP_HTTP_ALLOWED_HOSTS = '["localhost","localhost:*","127.0.0.1","127.0.0.1:*"]'

  $tools = "PowerShell,FileSystem,Process,Snapshot,Screenshot,DisplayInventory,App,Clipboard,Click,Type,Scroll,Move,Shortcut,Wait,WaitFor"
  $args = @(
    "serve",
    "--transport","streamable-http",
    "--host","127.0.0.1",
    "--port",[string]$port,
    "--tools",$tools
  )

  Write-SupervisorLog "Starting Windows-MCP upstream on 127.0.0.1:$port."
  Start-Process -FilePath ([string]$Config.windowsMcpExe) -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $UpstreamOut -RedirectStandardError $UpstreamErr | Out-Null
  return $true
}

function Start-Gateway {
  param($Config, [string]$AuthKey)

  $port = [int]$Config.gatewayPort
  $owner = Get-PortOwner -Port $port
  if ($owner) {
    if (Test-OwnedPort -Port $port -Patterns @("gateway\.py", [regex]::Escape([string]$port))) {
      return $true
    }
    Write-SupervisorLog "ERROR: gateway port $port is owned by an unrelated process; refusing to replace it."
    return $false
  }

  $appRoot = [string]$Config.appRoot
  $gateway = Join-Path $appRoot "MCP_GATEWAY\gateway.py"

  $env:REMOTE_GROWTH_ROOT = $appRoot
  $env:REMOTE_GROWTH_AUTH_FILE = $AuthFile
  $env:REMOTE_GROWTH_PYTHON = [string]$Config.pythonExe
  $env:REMOTE_GROWTH_TAILSCALE_EXE = [string]$Config.tailscaleExe
  $env:REMOTE_GROWTH_ALLOWED_HOSTS = ((@([string]$Config.tailscaleDnsName, "localhost", "127.0.0.1") | Where-Object { $_ }) -join ",")
  $env:REMOTE_GROWTH_ALLOWED_ROOTS_JSON = ($Config.allowedRoots | ConvertTo-Json -Compress)
  $env:REMOTE_GROWTH_PROTECTED_ROOTS_JSON = (@(
    $env:WINDIR,
    $env:ProgramFiles,
    $env:ProgramData,
    $InstallRoot
  ) | Where-Object { $_ } | ConvertTo-Json -Compress)

  $args = @(
    $gateway,
    "--host","127.0.0.1",
    "--port",[string]$port,
    "--upstream-port",[string]$Config.upstreamPort
  )

  Write-SupervisorLog "Starting 64-tool gateway on 127.0.0.1:$port."
  Start-Process -FilePath ([string]$Config.pythonExe) -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput $GatewayOut -RedirectStandardError $GatewayErr | Out-Null
  return $true
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
  Write-SupervisorLog "ERROR: config.json missing."
  exit 2
}
if (-not (Test-Path -LiteralPath $AuthFile)) {
  Write-SupervisorLog "ERROR: auth.key missing."
  exit 2
}

try {
  $config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
  $authKey = (Get-Content -Raw -LiteralPath $AuthFile).Trim()
} catch {
  Write-SupervisorLog ("ERROR: unable to load local configuration: " + $_.Exception.Message)
  exit 2
}

$mutex = New-Object Threading.Mutex($false, "Local\OtakAtikRemoteGrowthStableSupervisor")
if (-not $mutex.WaitOne(0, $false)) { exit 0 }

Write-SupervisorLog "Supervisor started."

while ($true) {
  foreach ($path in @($SupervisorLog,$UpstreamOut,$UpstreamErr,$GatewayOut,$GatewayErr)) {
    Trim-Log -Path $path
  }

  if (Test-Path -LiteralPath (Join-Path $InstallRoot "disabled.flag")) {
    Write-SupervisorLog "Supervisor disabled by local marker."
    exit 0
  }

  if (-not (Test-Path -LiteralPath ([string]$config.windowsMcpExe))) {
    Write-SupervisorLog ("ERROR: Windows-MCP executable missing: " + [string]$config.windowsMcpExe)
    Start-Sleep -Seconds 20
    continue
  }
  if (-not (Test-Path -LiteralPath ([string]$config.pythonExe))) {
    Write-SupervisorLog ("ERROR: Python runtime missing: " + [string]$config.pythonExe)
    Start-Sleep -Seconds 20
    continue
  }

  $upstreamReady = Start-Upstream -Config $config -AuthKey $authKey
  if ($upstreamReady) {
    Start-Sleep -Seconds 2
    [void](Start-Gateway -Config $config -AuthKey $authKey)
  }

  Start-Sleep -Seconds 8
}
