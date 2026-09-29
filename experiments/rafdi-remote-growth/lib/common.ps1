Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RafdiRemoteDefaultInstallRoot = Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote'
$script:RafdiRemoteDefaultTaskName = 'OtakAtik Rafdi Remote AutoStart'
$script:RafdiRemoteDefaultPort = 18765
$script:RafdiRemoteDefaultPublicHttpsPort = 8443

function Assert-RafdiWindows {
    if ($env:OS -ne 'Windows_NT') {
        throw 'Rafdi Remote currently supports Windows only.'
    }
}

function Get-RafdiCurrentIdentity {
    return [Security.Principal.WindowsIdentity]::GetCurrent().Name
}

function Resolve-RafdiExecutable {
    param(
        [Parameter(Mandatory)][string]$Name,
        [string[]]$Fallbacks = @()
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($candidate in $Fallbacks) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Get-RafdiWingetPath {
    return Resolve-RafdiExecutable -Name 'winget.exe'
}

function Get-RafdiUvPath {
    return Resolve-RafdiExecutable -Name 'uv.exe' -Fallbacks @(
        (Join-Path $env:USERPROFILE '.local\bin\uv.exe'),
        (Join-Path $env:APPDATA 'Python\Scripts\uv.exe')
    )
}

function Get-RafdiWindowsMcpPath {
    return Resolve-RafdiExecutable -Name 'windows-mcp.exe' -Fallbacks @(
        (Join-Path $env:USERPROFILE '.local\bin\windows-mcp.exe')
    )
}

function Get-RafdiTailscalePath {
    $programFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
    $fallbacks = @((Join-Path $env:ProgramFiles 'Tailscale\tailscale.exe'))
    if ($programFilesX86) {
        $fallbacks += (Join-Path $programFilesX86 'Tailscale\tailscale.exe')
    }
    return Resolve-RafdiExecutable -Name 'tailscale.exe' -Fallbacks $fallbacks
}

function New-RafdiBearerKey {
    $bytes = New-Object byte[] 32
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes).Replace('+','-').Replace('/','_').TrimEnd('=')
}

function Protect-RafdiSecretFile {
    param([Parameter(Mandatory)][string]$Path)

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object Security.AccessControl.FileSystemAccessRule(
        $identity,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow
    )
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
}

function Test-RafdiTcpPort {
    param([int]$Port, [int]$TimeoutMs = 800)

    try {
        $client = New-Object Net.Sockets.TcpClient
        $async = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs)) {
            $client.Close()
            return $false
        }
        $client.EndConnect($async)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

function Get-RafdiPortOwnerPid {
    param([int]$Port)
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($conn) { return [int]$conn.OwningProcess }
    return $null
}

function Get-RafdiProcessCommandLine {
    param([int]$Pid)
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$Pid" -ErrorAction SilentlyContinue
    if ($p) { return [string]$p.CommandLine }
    return ''
}

function Test-RafdiWindowsMcpIdentity {
    param(
        [Parameter(Mandatory)][int]$Port,
        [Parameter(Mandatory)][string]$AuthKey
    )

    if (-not (Test-RafdiTcpPort -Port $Port)) { return $false }

    $payload = @{
        jsonrpc = '2.0'
        id = 1
        method = 'initialize'
        params = @{
            protocolVersion = '2025-06-18'
            capabilities = @{}
            clientInfo = @{
                name = 'otak-atik-rafdi-remote-healthcheck'
                version = '1.0'
            }
        }
    } | ConvertTo-Json -Depth 8 -Compress

    try {
        $headers = @{
            Authorization = "Bearer $AuthKey"
            Accept = 'application/json, text/event-stream'
            Host = 'localhost'
        }
        $response = Invoke-WebRequest `
            -Uri "http://127.0.0.1:$Port/mcp" `
            -Method Post `
            -Headers $headers `
            -ContentType 'application/json' `
            -Body $payload `
            -TimeoutSec 8
        return ([string]$response.Content -match 'windows-mcp')
    } catch {
        return $false
    }
}

function Get-RafdiTailscaleStatus {
    param([Parameter(Mandatory)][string]$TailscaleExe)
    try {
        $raw = (& $TailscaleExe status --json 2>$null) -join [Environment]::NewLine
        if (-not $raw) { return $null }
        return $raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

function Get-RafdiTailscaleDnsName {
    param([Parameter(Mandatory)]$StatusObject)
    $dns = [string]$StatusObject.Self.DNSName
    if ([string]::IsNullOrWhiteSpace($dns)) { return $null }
    return $dns.TrimEnd('.')
}

function Get-RafdiPublicMcpUrl {
    param(
        [Parameter(Mandatory)][string]$DnsName,
        [Parameter(Mandatory)][int]$PublicHttpsPort
    )
    if ($PublicHttpsPort -eq 443) { return "https://$DnsName/mcp" }
    return "https://$DnsName`:$PublicHttpsPort/mcp"
}

function Read-RafdiConfig {
    param([Parameter(Mandatory)][string]$InstallRoot)
    $path = Join-Path $InstallRoot 'config.json'
    if (-not (Test-Path -LiteralPath $path)) { throw "Config not found: $path" }
    return (Get-Content -Raw -LiteralPath $path | ConvertFrom-Json)
}

function Write-RafdiConfig {
    param(
        [Parameter(Mandatory)][string]$InstallRoot,
        [Parameter(Mandatory)]$Config
    )
    New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
    $path = Join-Path $InstallRoot 'config.json'
    $Config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
}

function Get-RafdiAuthKey {
    param([Parameter(Mandatory)][string]$InstallRoot)
    $path = Join-Path $InstallRoot 'auth.key'
    if (-not (Test-Path -LiteralPath $path)) { throw "Auth key not found: $path" }
    return (Get-Content -Raw -LiteralPath $path).Trim()
}

function Get-RafdiFunnelStatusText {
    param([Parameter(Mandatory)][string]$TailscaleExe)
    try {
        return ((& $TailscaleExe funnel status 2>&1) -join [Environment]::NewLine)
    } catch {
        return [string]$_
    }
}

function Test-RafdiFunnelPortInUse {
    param(
        [Parameter(Mandatory)][string]$TailscaleExe,
        [Parameter(Mandatory)][int]$PublicHttpsPort
    )

    $text = Get-RafdiFunnelStatusText -TailscaleExe $TailscaleExe
    if ($text -match 'No serve config') { return $false }
    if ($PublicHttpsPort -eq 443) { return ($text -match 'https://[^\s/]+(?:/|\s)') }
    return ($text -match [regex]::Escape(":$PublicHttpsPort"))
}

function Test-RafdiPublicAuthGuard {
    param([Parameter(Mandatory)][string]$Url)
    try {
        Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec 15 | Out-Null
        return $false
    } catch {
        $response = $_.Exception.Response
        if ($response -and [int]$response.StatusCode -eq 401) { return $true }
        return $false
    }
}

function Get-RafdiSupervisorProcesses {
    param([Parameter(Mandatory)][string]$SupervisorPath)
    $escaped = [regex]::Escape($SupervisorPath)
    return @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -eq 'powershell.exe' -and
            [string]$_.CommandLine -match $escaped
        })
}

function Register-RafdiAutoStartTask {
    param(
        [Parameter(Mandatory)][string]$TaskName,
        [Parameter(Mandatory)][string]$StartScript
    )

    $identity = Get-RafdiCurrentIdentity
    $argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$StartScript`""
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argument
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    $principal = New-ScheduledTaskPrincipal `
        -UserId $identity `
        -LogonType Interactive `
        -RunLevel Limited

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description 'Starts the otak-atik Rafdi Remote MCP bridge at Windows logon.' `
        -Force | Out-Null
}

function Write-RafdiHeading {
    param([string]$Text)
    Write-Host ''
    Write-Host "=== $Text ===" -ForegroundColor Cyan
}
