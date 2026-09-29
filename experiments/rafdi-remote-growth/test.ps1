param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote')
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$skipFunnel = ($config.PSObject.Properties.Name -contains 'skipFunnel') -and [bool]$config.skipFunnel

$results = [ordered]@{}
$results.Config = $true
$results.LocalIdentity = Test-RafdiWindowsMcpIdentity -Port ([int]$config.port) -AuthKey $authKey

$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$results.Supervisor = @(Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath).Count -gt 0
$results.ScheduledTask = $null -ne (Get-ScheduledTask -TaskName $config.taskName -ErrorAction SilentlyContinue)

$tailscaleStatus = Get-RafdiTailscaleStatus -TailscaleExe $config.tailscaleExe
$results.Tailscale = $tailscaleStatus -and [string]$tailscaleStatus.BackendState -eq 'Running'

if ($skipFunnel) {
    $results.Funnel = $true
    $results.PublicRejectsNoAuth = $true
    $results.PublicAuthenticatedMcp = $true
} else {
    $funnelText = Get-RafdiFunnelStatusText -TailscaleExe $config.tailscaleExe
    $expectedBase = $config.publicMcpUrl -replace '/mcp$',''
    $results.Funnel = ($funnelText -match [regex]::Escape($expectedBase)) -and
        ($funnelText -match [regex]::Escape("127.0.0.1:$($config.port)"))

    $results.PublicRejectsNoAuth = Test-RafdiPublicAuthGuard -Url $config.publicMcpUrl

    $payload = @{
        jsonrpc = '2.0'
        id = 1
        method = 'initialize'
        params = @{
            protocolVersion = '2025-06-18'
            capabilities = @{}
            clientInfo = @{
                name = 'otak-atik-public-test'
                version = '1.0'
            }
        }
    } | ConvertTo-Json -Depth 8 -Compress

    $publicStatus = Get-RafdiHttpStatusCode -Url $config.publicMcpUrl -Method POST -BearerToken $authKey -Body $payload
    $results.PublicAuthenticatedMcp = ($publicStatus -eq 200)
}

Write-RafdiHeading 'Rafdi Remote test'
foreach ($key in $results.Keys) {
    $value = [bool]$results[$key]
    $label = if ($value) { 'PASS' } else { 'FAIL' }
    $color = if ($value) { 'Green' } else { 'Red' }
    Write-Host ("{0,-28} {1}" -f $key,$label) -ForegroundColor $color
}

if ($skipFunnel) {
    Write-Host ''
    Write-Host 'NOTE: Funnel/public checks are intentionally skipped by this local-only diagnostic install.' -ForegroundColor Yellow
}

$failed = @($results.GetEnumerator() | Where-Object { -not [bool]$_.Value })
if ($failed.Count -gt 0) {
    exit 2
}
exit 0
