param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote')
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'

$task = Get-ScheduledTask -TaskName $config.taskName -ErrorAction SilentlyContinue
$supervisors = @(Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath)
$tailscaleStatus = Get-RafdiTailscaleStatus -TailscaleExe $config.tailscaleExe
$skipFunnel = ($config.PSObject.Properties.Name -contains 'skipFunnel') -and [bool]$config.skipFunnel

$localOk = Test-RafdiWindowsMcpIdentity -Port ([int]$config.port) -AuthKey $authKey
$funnelOk = $true
$publicGuard = $true

if (-not $skipFunnel) {
    $funnelText = Get-RafdiFunnelStatusText -TailscaleExe $config.tailscaleExe
    $expectedBase = $config.publicMcpUrl -replace '/mcp$',''
    $funnelOk = ($funnelText -match [regex]::Escape($expectedBase)) -and
        ($funnelText -match [regex]::Escape("127.0.0.1:$($config.port)"))
    $publicGuard = Test-RafdiPublicAuthGuard -Url $config.publicMcpUrl
}

Write-RafdiHeading 'Rafdi Remote status'
[pscustomobject]@{
    LocalWindowsMcp = if ($localOk) { 'ONLINE / VERIFIED' } else { 'OFFLINE OR UNVERIFIED' }
    Supervisor = if ($supervisors.Count -gt 0) { "RUNNING ($($supervisors.Count))" } else { 'OFFLINE' }
    ScheduledTask = if ($task) { [string]$task.State } else { 'MISSING' }
    TailscaleBackend = if ($tailscaleStatus) { [string]$tailscaleStatus.BackendState } else { 'UNKNOWN' }
    FunnelMapping = if ($skipFunnel) { 'SKIPPED BY CONFIG' } elseif ($funnelOk) { 'CONFIGURED' } else { 'MISSING OR DIFFERENT' }
    PublicAuthGuard = if ($skipFunnel) { 'SKIPPED BY CONFIG' } elseif ($publicGuard) { 'HTTP 401 / PROTECTED' } else { 'NOT VERIFIED' }
    StableUrl = [string]$config.publicMcpUrl
    InstallRoot = [string]$config.installRoot
} | Format-List

$tailscaleOk = $tailscaleStatus -and [string]$tailscaleStatus.BackendState -eq 'Running'
if ($localOk -and $supervisors.Count -gt 0 -and $task -and $tailscaleOk -and $funnelOk -and $publicGuard) {
    exit 0
}
exit 2
