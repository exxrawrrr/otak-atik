[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote')
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$port = [int]$config.port
$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$startPath = Join-Path $InstallRoot 'start.ps1'
$tailscale = [string]$config.tailscaleExe

Write-RafdiHeading 'Repair'

$ownerPid = Get-RafdiPortOwnerPid -Port $port
if ($ownerPid -and -not (Test-RafdiWindowsMcpIdentity -Port $port -AuthKey $authKey)) {
    $cmdLine = Get-RafdiProcessCommandLine -Pid $ownerPid
    throw "Port $port is occupied by an unknown service (PID $ownerPid). Refusing destructive repair. Command line: $cmdLine"
}

if ($ownerPid -and (Test-RafdiWindowsMcpIdentity -Port $port -AuthKey $authKey)) {
    if ($PSCmdlet.ShouldProcess("PID $ownerPid", 'Restart owned Windows-MCP listener')) {
        Stop-Process -Id $ownerPid -Force
    }
}

foreach ($proc in (Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath)) {
    if ($PSCmdlet.ShouldProcess("PID $($proc.ProcessId)", 'Restart owned supervisor')) {
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

Start-Sleep -Seconds 2
if ($PSCmdlet.ShouldProcess($supervisorPath, 'Start supervisor')) {
    $supervisorArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$supervisorPath`""
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList $supervisorArgs
}

if ($PSCmdlet.ShouldProcess([string]$config.taskName, 'Re-register auto-start task')) {
    Register-RafdiAutoStartTask -TaskName ([string]$config.taskName) -StartScript $startPath
}

if (Test-Path -LiteralPath $tailscale) {
    $status = Get-RafdiTailscaleStatus -TailscaleExe $tailscale
    if ($status -and [string]$status.BackendState -eq 'Running') {
        if ($PSCmdlet.ShouldProcess([string]$config.publicMcpUrl, 'Re-assert owned Funnel configuration')) {
            $httpsArg = "--https=$([int]$config.publicHttpsPort)"
            $backendPort = "$([int]$config.port)"
            & $tailscale funnel --bg $httpsArg $backendPort
            if ($LASTEXITCODE -ne 0) { throw "tailscale funnel failed with exit code $LASTEXITCODE." }
        }
    } else {
        Write-Warning 'Tailscale is not running/logged in; Funnel was not changed.'
    }
}

$healthy = $false
for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Seconds 2
    if (Test-RafdiWindowsMcpIdentity -Port $port -AuthKey $authKey) {
        $healthy = $true
        break
    }
}

if (-not $healthy) { throw 'Repair completed but local Windows-MCP identity check still fails.' }
Write-Host 'Local Windows-MCP recovered.' -ForegroundColor Green
