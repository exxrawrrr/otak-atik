
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [int]$Port = 18765,

    [ValidateSet(443,8443,10000)]
    [int]$PublicHttpsPort = 8443,

    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'OtakAtik\RafdiRemote'),

    [string]$TaskName = 'OtakAtik Rafdi Remote AutoStart',

    [switch]$InstallPrerequisites,

    [switch]$ForceRotateKey,

    [switch]$SkipFunnel
)

. (Join-Path $PSScriptRoot 'lib\common.ps1')
Assert-RafdiWindows

Write-RafdiHeading 'Rafdi Remote safe setup'
Write-Host "Install root      : $InstallRoot"
Write-Host "Local MCP port    : $Port"
Write-Host "Public HTTPS port : $PublicHttpsPort"
Write-Host "Task name         : $TaskName"

$winget = Get-RafdiWingetPath
$uv = Get-RafdiUvPath
$tailscale = Get-RafdiTailscalePath
$windowsMcp = Get-RafdiWindowsMcpPath

if ($WhatIfPreference) {
    Write-RafdiHeading 'Dry run'
    Write-Host ('winget      : ' + $(if ($winget) { $winget } else { 'MISSING' }))
    Write-Host ('uv          : ' + $(if ($uv) { $uv } else { 'MISSING' }))
    Write-Host ('Tailscale   : ' + $(if ($tailscale) { $tailscale } else { 'MISSING' }))
    Write-Host ('Windows-MCP : ' + $(if ($windowsMcp) { $windowsMcp } else { 'MISSING' }))
    if (-not $uv -and $InstallPrerequisites) {
        Write-Host 'Would install uv with winget: astral-sh.uv'
    }
    if (-not $tailscale -and $InstallPrerequisites) {
        Write-Host 'Would install Tailscale with winget: Tailscale.Tailscale'
    }
    if (-not $windowsMcp) {
        Write-Host 'Would install Windows-MCP as a persistent uv tool.'
    }
    Write-Host 'Would generate or preserve a local bearer key without printing it.'
    Write-Host 'Would render a loopback-only supervisor with explicit host allowlist.'
    Write-Host 'Would register a per-user logon Scheduled Task.'
    if (-not $SkipFunnel) {
        Write-Host "Would configure Tailscale Funnel on HTTPS port $PublicHttpsPort after verifying Tailscale login and port ownership."
    }
    Write-Host ''
    Write-Host 'Dry run complete. No changes were made.' -ForegroundColor Green
    return
}

if (-not $uv -and -not $windowsMcp) {
    if (-not $InstallPrerequisites) {
        throw 'uv is missing. Re-run with -InstallPrerequisites or install uv manually.'
    }
    if (-not $winget) {
        throw 'winget is required for automatic uv installation.'
    }
    if ($PSCmdlet.ShouldProcess('astral-sh.uv', 'Install prerequisite with winget')) {
        & $winget install --id astral-sh.uv -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "uv installation failed with exit code $LASTEXITCODE."
        }
    }
    $uv = Get-RafdiUvPath
    if (-not $uv) {
        throw 'uv installation completed but uv.exe could not be located. Open a new PowerShell session and re-run setup.'
    }
}

if (-not $tailscale) {
    if (-not $InstallPrerequisites) {
        throw 'Tailscale is missing. Re-run with -InstallPrerequisites or install Tailscale manually.'
    }
    if (-not $winget) {
        throw 'winget is required for automatic Tailscale installation.'
    }
    if ($PSCmdlet.ShouldProcess('Tailscale.Tailscale', 'Install prerequisite with winget')) {
        & $winget install --id Tailscale.Tailscale -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Tailscale installation failed with exit code $LASTEXITCODE."
        }
    }
    $tailscale = Get-RafdiTailscalePath
    if (-not $tailscale) {
        throw 'Tailscale installation completed but tailscale.exe could not be located. Open a new PowerShell session and re-run setup.'
    }
}

if (-not $windowsMcp) {
    if ($PSCmdlet.ShouldProcess('windows-mcp', 'Install persistent uv tool')) {
        & $uv tool install windows-mcp
        if ($LASTEXITCODE -ne 0) {
            throw "Windows-MCP installation failed with exit code $LASTEXITCODE."
        }
    }
    $windowsMcp = Get-RafdiWindowsMcpPath
    if (-not $windowsMcp) {
        throw 'Windows-MCP could not be located after installation.'
    }
}

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot 'lib') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot 'logs') | Out-Null

$disabledFlag = Join-Path $InstallRoot 'disabled.flag'
if (Test-Path -LiteralPath $disabledFlag) {
    if ($PSCmdlet.ShouldProcess($disabledFlag, 'Re-enable Rafdi Remote by removing disable marker')) {
        Remove-Item -LiteralPath $disabledFlag -Force
    }
}

Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'lib\common.ps1') -Destination (Join-Path $InstallRoot 'lib\common.ps1') -Force
foreach ($name in @('status.ps1','repair.ps1','uninstall.ps1','test.ps1')) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $InstallRoot $name) -Force
}

$authFile = Join-Path $InstallRoot 'auth.key'
if ($ForceRotateKey -or -not (Test-Path -LiteralPath $authFile)) {
    if ($PSCmdlet.ShouldProcess($authFile, 'Generate a fresh bearer key')) {
        New-RafdiBearerKey | Set-Content -NoNewline -LiteralPath $authFile -Encoding ASCII
        Protect-RafdiSecretFile -Path $authFile
        Write-Host 'Generated a fresh bearer key. The value was not printed.' -ForegroundColor Green
    }
} else {
    Write-Host 'Existing bearer key preserved.' -ForegroundColor DarkGray
}

$status = Get-RafdiTailscaleStatus -TailscaleExe $tailscale
if (-not $status -or [string]$status.BackendState -ne 'Running') {
    Write-Warning 'Tailscale is installed but not authenticated/running.'
    Write-Host ''
    Write-Host 'Run this once, finish browser login, then re-run setup:' -ForegroundColor Yellow
    Write-Host ('  & "' + $tailscale + '" up')
    throw 'Tailscale login is required before remote exposure can be configured.'
}

$dnsName = Get-RafdiTailscaleDnsName -StatusObject $status
if (-not $dnsName) {
    throw 'Tailscale is running but did not return a MagicDNS name. Funnel requires a tailnet DNS name.'
}

$publicUrl = Get-RafdiPublicMcpUrl -DnsName $dnsName -PublicHttpsPort $PublicHttpsPort

$existingConfig = $null
$configPath = Join-Path $InstallRoot 'config.json'
if (Test-Path -LiteralPath $configPath) {
    try {
        $existingConfig = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
    } catch {
        throw "Existing config is invalid JSON: $configPath"
    }
}

$expectedBaseUrl = $publicUrl -replace '/mcp$',''
$funnelText = Get-RafdiFunnelStatusText -TailscaleExe $tailscale
$ourExistingFunnel = ($funnelText -match [regex]::Escape($expectedBaseUrl)) -and ($funnelText -match [regex]::Escape("127.0.0.1:$Port"))

if (-not $SkipFunnel -and -not $ourExistingFunnel -and (Test-RafdiFunnelPublicPortInUse -TailscaleExe $tailscale -PublicHttpsPort $PublicHttpsPort)) {
    throw "Tailscale Funnel HTTPS port $PublicHttpsPort is already in use by another configuration. Refusing to overwrite it. Choose 443, 8443, or 10000 explicitly."
}

$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot

$ownerPid = Get-RafdiPortOwnerPid -Port $Port
if ($ownerPid -and -not (Test-RafdiWindowsMcpIdentity -Port $Port -AuthKey $authKey)) {
    $cmdLine = Get-RafdiProcessCommandLine -ProcessId $ownerPid
    throw "Local port $Port is already owned by PID $ownerPid and did not identify as this authenticated Windows-MCP. Refusing to kill or replace it. Command line: $cmdLine"
}

$tools = 'PowerShell,FileSystem,Process,Snapshot,Screenshot,DisplayInventory,App,Clipboard,Click,Type,Scroll,Move,Shortcut,Wait,WaitFor'
$allowedHostItems = @($dnsName,'localhost','127.0.0.1')
if ($PublicHttpsPort -ne 443) { $allowedHostItems += ($dnsName + ':' + $PublicHttpsPort) }
$allowedHosts = $allowedHostItems | ConvertTo-Json -Compress

$templatePath = Join-Path $PSScriptRoot 'templates\supervisor.ps1.tmpl'
$template = Get-Content -Raw -LiteralPath $templatePath
$rendered = $template
$rendered = $rendered.Replace('{{INSTALL_ROOT}}', $InstallRoot.Replace("'","''"))
$rendered = $rendered.Replace('{{PORT}}', [string]$Port)
$rendered = $rendered.Replace('{{WINDOWS_MCP_EXE}}', $windowsMcp.Replace("'","''"))
$rendered = $rendered.Replace('{{ALLOWED_HOSTS_JSON}}', $allowedHosts.Replace("'","''"))
$rendered = $rendered.Replace('{{TOOLS}}', $tools)
$rendered = $rendered.Replace('{{MUTEX_NAME}}', ('Local\OtakAtikRafdiRemoteSupervisor-' + $Port))

$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$rendered | Set-Content -LiteralPath $supervisorPath -Encoding UTF8

$startPath = Join-Path $InstallRoot 'start.ps1'
$startContent = @'
$ErrorActionPreference = 'SilentlyContinue'
$configPath = Join-Path $PSScriptRoot 'config.json'
if (-not (Test-Path -LiteralPath $configPath)) { exit 2 }
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
$supervisor = Join-Path $PSScriptRoot 'supervisor.ps1'
$escaped = [regex]::Escape($supervisor)
$existing = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -eq 'powershell.exe' -and [string]$_.CommandLine -match $escaped
}
if (-not $existing) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy','Bypass',
        '-File',$supervisor
    )
}
'@
$startContent | Set-Content -LiteralPath $startPath -Encoding UTF8

$config = [ordered]@{
    schemaVersion = 1
    installRoot = $InstallRoot
    port = $Port
    publicHttpsPort = $PublicHttpsPort
    taskName = $TaskName
    tailscaleDnsName = $dnsName
    publicMcpUrl = $publicUrl
    windowsMcpExe = $windowsMcp
    tailscaleExe = $tailscale
    tools = $tools
    skipFunnel = [bool]$SkipFunnel
    createdAt = if ($existingConfig -and $existingConfig.createdAt) { [string]$existingConfig.createdAt } else { (Get-Date).ToString('o') }
    updatedAt = (Get-Date).ToString('o')
}
Write-RafdiConfig -InstallRoot $InstallRoot -Config $config

if ($PSCmdlet.ShouldProcess($TaskName, 'Register per-user logon auto-start task')) {
    Register-RafdiAutoStartTask -TaskName $TaskName -StartScript $startPath
}

$supervisors = @(Get-RafdiSupervisorProcesses -SupervisorPath $supervisorPath)
if ($supervisors.Count -eq 0) {
    if ($PSCmdlet.ShouldProcess($supervisorPath, 'Start supervisor')) {
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
    if (Test-RafdiWindowsMcpIdentity -Port $Port -AuthKey $authKey) {
        $healthy = $true
        break
    }
}
if (-not $healthy) {
    throw 'Windows-MCP did not pass authenticated identity verification after setup.'
}

Write-Host 'Local authenticated Windows-MCP identity: PASS' -ForegroundColor Green

if (-not $SkipFunnel -and -not $ourExistingFunnel) {
    Write-RafdiHeading 'One-time Tailscale Funnel step'
    Write-Host 'Local MCP is installed and protected. Public exposure is intentionally not enabled automatically.' -ForegroundColor Yellow
    Write-Host 'Run this command yourself:'
    Write-Host ('  & "' + $tailscale + '" funnel --bg --yes --https=' + $PublicHttpsPort + ' ' + $Port)
    Write-Host ''
    Write-Host 'If Tailscale prints an approval URL, approve Funnel once, run the command again, then rerun setup.ps1.'
    return
}
Write-RafdiHeading 'Verification'
if (-not $SkipFunnel) {
    $funnelText = Get-RafdiFunnelStatusText -TailscaleExe $tailscale
    if ($funnelText -notmatch [regex]::Escape($expectedBaseUrl) -or $funnelText -notmatch [regex]::Escape("127.0.0.1:$Port")) {
        throw 'Funnel command returned, but the expected URL/target was not found in Tailscale Funnel status.'
    }
    Write-Host 'Tailscale Funnel mapping: PASS' -ForegroundColor Green

    $guardOk = $false
    for ($i = 0; $i -lt 6; $i++) {
        if (Test-RafdiPublicAuthGuard -Url $publicUrl) {
            $guardOk = $true
            break
        }
        Start-Sleep -Seconds 5
    }

    if ($guardOk) {
        Write-Host 'Public unauthenticated request rejected with HTTP 401: PASS' -ForegroundColor Green
    } else {
        Write-Warning 'Funnel is configured, but the public 401 check is not ready yet. Public DNS/TLS provisioning can take time. Run test.ps1 later.'
    }
}

Write-RafdiHeading 'Ready'
if ($SkipFunnel) {
    Write-Host 'Local-only diagnostic mode: Funnel was intentionally skipped.' -ForegroundColor Yellow
    Write-Host "Planned MCP URL if Funnel is later enabled: $publicUrl"
} else {
    Write-Host "Stable MCP URL: $publicUrl" -ForegroundColor Green
}
Write-Host ''
Write-Host 'The bearer key was intentionally NOT printed.'
Write-Host "Secret file: $authFile"
if (-not $SkipFunnel) {
    Write-Host ''
    Write-Host 'Composio Custom MCP:'
    Write-Host "  URL  : $publicUrl"
    Write-Host '  Auth : Bearer token from auth.key'
}
Write-Host ''
Write-Host 'To put the token on your clipboard without printing it:'
Write-Host ('  Get-Content -Raw "' + $authFile + '" | Set-Clipboard')
Write-Host ''
Write-Host ('Status: powershell -ExecutionPolicy Bypass -File "' + (Join-Path $InstallRoot 'status.ps1') + '"')
