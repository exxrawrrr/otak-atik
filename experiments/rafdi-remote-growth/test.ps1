[CmdletBinding()]
param(
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote'),
    [switch]$SkipPublic
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

$config = Read-RafdiConfig -InstallRoot $InstallRoot
$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$failures = New-Object Collections.Generic.List[string]

function Check([bool]$Condition, [string]$Message) {
    if ($Condition) {
        Write-Host "PASS  $Message" -ForegroundColor Green
    } else {
        Write-Host "FAIL  $Message" -ForegroundColor Red
        $script:failures.Add($Message)
    }
}

Write-RafdiHeading 'Rafdi Remote verification'

Check ((Test-Path -LiteralPath (Join-Path $InstallRoot 'supervisor.ps1'))) 'supervisor exists'
Check ((Test-Path -LiteralPath (Join-Path $InstallRoot 'auth.key'))) 'auth key exists locally'
Check (([string]$config.tailscaleDnsName -notmatch '[<>]')) 'Tailscale DNS value is rendered'
Check (([string]$config.publicMcpUrl -match '^https://')) 'public URL uses HTTPS'
Check (([string]$config.windowsMcpExe -and (Test-Path -LiteralPath ([string]$config.windowsMcpExe)))) 'Windows-MCP executable exists'
Check (Test-RafdiWindowsMcpIdentity -Port ([int]$config.port) -AuthKey $authKey) 'local authenticated MCP identity is Windows-MCP'

$supervisorText = Get-Content -Raw -LiteralPath (Join-Path $InstallRoot 'supervisor.ps1')
Check ($supervisorText -notmatch '\{\{[A-Z0-9_]+\}\}') 'supervisor has no unresolved placeholders'
Check ($supervisorText -match [regex]::Escape([string]$config.tailscaleDnsName)) 'supervisor allowlist contains discovered Tailscale DNS name'
Check ($supervisorText -match '127\.0\.0\.1') 'supervisor is configured for loopback backend'

$task = Get-ScheduledTask -TaskName ([string]$config.taskName) -ErrorAction SilentlyContinue
Check ([bool]$task) 'auto-start Scheduled Task exists'

if (-not $SkipPublic) {
    Check (Test-RafdiPublicAuthGuard -Url ([string]$config.publicMcpUrl)) 'public endpoint rejects unauthenticated traffic with 401'
}

if ($failures.Count -gt 0) {
    throw "$($failures.Count) verification check(s) failed."
}

Write-Host ''
Write-Host 'All requested checks passed.' -ForegroundColor Green
