[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote'),
    [switch]$Json
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$tailscale = [string]$config.tailscaleExe
$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$task = Get-ScheduledTask -TaskName ([string]$config.taskName) -ErrorAction SilentlyContinue
$taskInfo = if ($task) { Get-ScheduledTaskInfo -TaskName ([string]$config.taskName) -ErrorAction SilentlyContinue } else { $null }
$tsStatus = if (Test-Path -LiteralPath $tailscale) { Get-RafdiTailscaleStatus -TailscaleExe $tailscale } else { $null }
$funnelText = if (Test-Path -LiteralPath $tailscale) { Get-RafdiFunnelStatusText -TailscaleExe $tailscale } else { '' }

$result = [ordered]@{
    installRoot = $InstallRoot
    localMcpPort = [int]$config.port
    localIdentityOk = Test-RafdiWindowsMcpIdentity -Port ([int]$config.port) -AuthKey $authKey
    supervisorRunning = (Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath).Count -gt 0
    tailscaleInstalled = Test-Path -LiteralPath $tailscale
    tailscaleState = if ($tsStatus) { [string]$tsStatus.BackendState } else { 'Unavailable' }
    tailscaleDnsName = if ($tsStatus) { Get-RafdiTailscaleDnsName -StatusObject $tsStatus } else { $null }
    publicMcpUrl = [string]$config.publicMcpUrl
    publicAuthGuardOk = Test-RafdiPublicAuthGuard -Url ([string]$config.publicMcpUrl)
    funnelConfigured = $funnelText -match [regex]::Escape(([string]$config.publicMcpUrl -replace '/mcp$',''))
    taskInstalled = [bool]$task
    taskState = if ($task) { [string]$task.State } else { 'Missing' }
    lastTaskResult = if ($taskInfo) { [int]$taskInfo.LastTaskResult } else { $null }
}

if ($Json) {
    $result | ConvertTo-Json -Depth 5
    return
}

Write-RafdiHeading 'Rafdi Remote status'
$result.GetEnumerator() | ForEach-Object {
    '{0,-22} {1}' -f ($_.Key + ':'), $_.Value
}
