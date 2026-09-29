[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote')
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$startPath = Join-Path $InstallRoot 'start.ps1'
$port = [int]$config.port

if (Test-Path -LiteralPath (Join-Path $InstallRoot 'disabled.flag')) {
    throw 'This installation is disabled. Re-run setup.ps1 to explicitly re-enable it.'
}

Write-RafdiHeading 'Rafdi Remote repair'

$ownerPid = Get-RafdiPortOwnerPid -Port $port
if ($ownerPid -and -not (Test-RafdiWindowsMcpIdentity -Port $port -AuthKey $authKey)) {
    $cmd = Get-RafdiProcessCommandLine -ProcessId $ownerPid
    throw "Port $port is occupied by an unverified process. Repair refuses to touch it. PID=$ownerPid CommandLine=$cmd"
}

$supervisors = @(Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath)
if ($supervisors.Count -eq 0) {
    if ($PSCmdlet.ShouldProcess($supervisorPath, 'Start Rafdi Remote supervisor')) {
        Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
            '-NoProfile',
            '-ExecutionPolicy','Bypass',
            '-File',$supervisorPath
        )
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
if (-not $healthy) {
    throw 'Windows-MCP did not become healthy. Check logs before retrying.'
}

if (-not (Get-ScheduledTask -TaskName $config.taskName -ErrorAction SilentlyContinue)) {
    if ($PSCmdlet.ShouldProcess($config.taskName, 'Recreate logon Scheduled Task')) {
        Register-RafdiAutoStartTask -TaskName $config.taskName -StartScript $startPath
    }
}

$tailscaleStatus = Get-RafdiTailscaleStatus -TailscaleExe $config.tailscaleExe
if (-not $tailscaleStatus -or [string]$tailscaleStatus.BackendState -ne 'Running') {
    throw 'Tailscale is not running/logged in. Repair will not attempt account login.'
}

$skipFunnel = ($config.PSObject.Properties.Name -contains 'skipFunnel') -and [bool]$config.skipFunnel
if (-not $skipFunnel) {
    $funnelText = Get-RafdiFunnelStatusText -TailscaleExe $config.tailscaleExe
    $expectedBase = $config.publicMcpUrl -replace '/mcp$',''
    $funnelOk = ($funnelText -match [regex]::Escape($expectedBase)) -and
        ($funnelText -match [regex]::Escape("127.0.0.1:$port"))

    if (-not $funnelOk) {
        Write-Warning 'Local runtime is healthy, but the expected Tailscale Funnel mapping is missing.'
        Write-Host 'For safety, repair.ps1 will not create or reset Funnel configuration automatically.'
        Write-Host 'Run the exact command below yourself, then rerun repair.ps1:'
        Write-Host ('  & "' + $config.tailscaleExe + '" funnel --bg --yes --https=' + $config.publicHttpsPort + ' ' + $port)
        exit 2
    }
}

Write-Host 'Repair complete. No unknown process or global Funnel configuration was modified.' -ForegroundColor Green
exit 0
