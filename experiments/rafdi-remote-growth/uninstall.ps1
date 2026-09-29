[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote'),
    [switch]$KeepLocalFiles
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$port = [int]$config.port
$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$tailscale = [string]$config.tailscaleExe

Write-RafdiHeading 'Uninstall Rafdi Remote'

$ownerPid = Get-RafdiPortOwnerPid -Port $port
if ($ownerPid) {
    if (Test-RafdiWindowsMcpIdentity -Port $port -AuthKey $authKey) {
        if ($PSCmdlet.ShouldProcess("PID $ownerPid", 'Stop owned Windows-MCP listener')) {
            Stop-Process -Id $ownerPid -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Warning "Port $port is occupied by an unknown service. It will NOT be terminated."
    }
}

foreach ($proc in (Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath)) {
    if ($PSCmdlet.ShouldProcess("PID $($proc.ProcessId)", 'Stop owned supervisor')) {
        Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

$task = Get-ScheduledTask -TaskName ([string]$config.taskName) -ErrorAction SilentlyContinue
if ($task -and $PSCmdlet.ShouldProcess([string]$config.taskName, 'Remove owned Scheduled Task')) {
    Unregister-ScheduledTask -TaskName ([string]$config.taskName) -Confirm:$false
}

if (Test-Path -LiteralPath $tailscale) {
    $baseUrl = [string]$config.publicMcpUrl -replace '/mcp$',''
    $funnelText = Get-RafdiFunnelStatusText -TailscaleExe $tailscale
    if ($funnelText -match [regex]::Escape($baseUrl)) {
        if ($PSCmdlet.ShouldProcess($baseUrl, 'Disable owned Tailscale Funnel HTTPS listener')) {
            $httpsArg = "--https=$([int]$config.publicHttpsPort)"
            & $tailscale funnel $httpsArg off
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Could not disable Funnel cleanly (exit $LASTEXITCODE). Tailscale account/config was otherwise left untouched."
            }
        }
    } else {
        Write-Host 'Owned Funnel URL not present; no Funnel configuration changed.' -ForegroundColor DarkGray
    }
}

if (-not $KeepLocalFiles) {
    if ($PSCmdlet.ShouldProcess($InstallRoot, 'Remove Rafdi Remote local files including bearer key')) {
        $parent = Split-Path -Parent $InstallRoot
        $leaf = Split-Path -Leaf $InstallRoot
        Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
            '-NoProfile','-Command',
            "Start-Sleep -Seconds 2; Remove-Item -LiteralPath '$($InstallRoot.Replace("'","''"))' -Recurse -Force -ErrorAction SilentlyContinue"
        )
        Write-Host "Local removal scheduled for: $InstallRoot"
    }
} else {
    Write-Host "Local files preserved: $InstallRoot"
}

Write-Host 'Tailscale itself and Windows-MCP itself were NOT uninstalled.' -ForegroundColor Green
