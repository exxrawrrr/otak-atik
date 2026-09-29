[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote')
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$disableFlag = Join-Path $InstallRoot 'disabled.flag'
$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'

Write-RafdiHeading 'Safe disable / uninstall'

if ($PSCmdlet.ShouldProcess($disableFlag, 'Create cooperative disable marker')) {
    'disabled' | Set-Content -LiteralPath $disableFlag -Encoding ASCII
}

$task = Get-ScheduledTask -TaskName $config.taskName -ErrorAction SilentlyContinue
if ($task -and $PSCmdlet.ShouldProcess($config.taskName, 'Unregister this package Scheduled Task')) {
    Unregister-ScheduledTask -TaskName $config.taskName -Confirm:$false
}

Write-Host 'Waiting for the package supervisor to observe disabled.flag and stop its verified listener...'
$listenerStopped = $false
for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Seconds 2
    $supervisors = @(Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath)
    $listenerAlive = Test-RafdiTcpPort -Port ([int]$config.port)
    if ($supervisors.Count -eq 0 -and -not $listenerAlive) {
        $listenerStopped = $true
        break
    }
}

if ($listenerStopped) {
    Write-Host 'Supervisor/listener stopped cooperatively: PASS' -ForegroundColor Green
} else {
    Write-Warning 'Supervisor or listener is still present. Runtime files were preserved for inspection.'
}

$skipFunnel = ($config.PSObject.Properties.Name -contains 'skipFunnel') -and [bool]$config.skipFunnel
if (-not $skipFunnel) {
    Write-Host ''
    Write-Warning 'Tailscale Funnel configuration was intentionally left unchanged.'
    Write-Host 'The current Tailscale CLI exposes a global "funnel reset" command; this package will not run it because it could remove unrelated Funnel mappings.'
    Write-Host 'If this machine uses Funnel only for Rafdi Remote and you intentionally want to clear ALL Funnel config, review "tailscale funnel reset" yourself.'
}

Write-Host ''
Write-Host "Runtime files are preserved at: $InstallRoot"
Write-Host 'Tailscale and Windows-MCP packages are intentionally left installed because other workflows may use them.'
Write-Host 'To re-enable, run setup.ps1 again from the repository.'
