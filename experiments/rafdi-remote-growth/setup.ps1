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
Write-Host "Install root       : $InstallRoot"
Write-Host "Local MCP port     : $Port"
Write-Host "Public HTTPS port  : $PublicHttpsPort"
Write-Host "Task name          : $TaskName"

if ($PublicHttpsPort -eq 443) {
    Write-Warning 'Port 443 is common. The public package defaults to 8443 to reduce collisions with an existing Funnel.'
}

$winget = Get-RafdiWingetPath
$uv = Get-RafdiUvPath
$tailscale = Get-RafdiTailscalePath
$windowsMcp = Get-RafdiWindowsMcpPath

if (-not $uv) {
    if (-not $InstallPrerequisites) {
        throw 'uv is missing. Re-run with -InstallPrerequisites or install uv manually.'
    }
    if (-not $winget) { throw 'winget is required to install uv automatically.' }

    if ($PSCmdlet.ShouldProcess('astral-sh.uv', 'Install prerequisite with winget')) {
        & $winget install --id astral-sh.uv -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { throw "uv installation failed with exit code $LASTEXITCODE." }
    }
    $uv = Get-RafdiUvPath
    if (-not $uv -and -not $WhatIfPreference) {
        throw 'uv was installed but could not be located. Open a new PowerShell session and re-run setup.'
    }
}

if (-not $tailscale) {
    if (-not $InstallPrerequisites) {
        throw 'Tailscale is missing. Re-run with -InstallPrerequisites or install Tailscale manually.'
    }
    if (-not $winget) { throw 'winget is required to install Tailscale automatically.' }

    if ($PSCmdlet.ShouldProcess('Tailscale.Tailscale', 'Install prerequisite with winget')) {
        & $winget install --id Tailscale.Tailscale -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { throw "Tailscale installation failed with exit code $LASTEXITCODE." }
    }
    $tailscale = Get-RafdiTailscalePath
    if (-not $tailscale -and -not $WhatIfPreference) {
        throw 'Tailscale was installed but could not be located. Open a new PowerShell session and re-run setup.'
    }
}

if (-not $windowsMcp) {
    if (-not $uv) {
        if ($WhatIfPreference) {
            Write-Host '[WhatIf] Would install Windows-MCP with uv tool install windows-mcp.'
        } else {
            throw 'Cannot install Windows-MCP because uv is unavailable.'
        }
    } elseif ($PSCmdlet.ShouldProcess('windows-mcp', 'Install persistent uv tool')) {
        & $uv tool install windows-mcp
        if ($LASTEXITCODE -ne 0) { throw "Windows-MCP installation failed with exit code $LASTEXITCODE." }
    }

    $windowsMcp = Get-RafdiWindowsMcpPath
    if (-not $windowsMcp -and -not $WhatIfPreference) {
        throw 'Windows-MCP could not be located after installation.'
    }
}

if ($WhatIfPreference) {
    Write-Host ''
    Write-Host 'Dry-run completed before account-specific changes.' -ForegroundColor Green
    Write-Host 'A real run requires an authenticated Tailscale session before the stable Funnel can be created.'
    return
}

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$libRoot = Join-Path $InstallRoot 'lib'
New-Item -ItemType Directory -Force -Path $libRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'lib\common.ps1') -Destination (Join-Path $libRoot 'common.ps1') -Force
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
    Write-Warning 'Tailscale is installed but not logged in/running.'
    Write-Host ''
    Write-Host 'Run this once, finish browser login, then re-run setup:' -ForegroundColor Yellow
    Write-Host "  & `"$tailscale`" up"
    throw 'Tailscale login is required before remote exposure can be configured.'
}

$dnsName = Get-RafdiTailscaleDnsName -StatusObject $status
if (-not $dnsName) {
    throw 'Tailscale is running but no MagicDNS name was returned. Funnel requires a Tailscale DNS name.'
}

$publicUrl = Get-RafdiPublicMcpUrl -DnsName $dnsName -PublicHttpsPort $PublicHttpsPort
$existingConfig = $null
$configPath = Join-Path $InstallRoot 'config.json'
if (Test-Path -LiteralPath $configPath) {
    try { $existingConfig = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json } catch {}
}

$funnelText = Get-RafdiFunnelStatusText -TailscaleExe $tailscale
$ourBaseUrl = $publicUrl -replace '/mcp$',''
$ourUrlAlreadyPresent = $funnelText -match [regex]::Escape($ourBaseUrl)

if (-not $ourUrlAlreadyPresent -and (Test-RafdiFunnelPortInUse -TailscaleExe $tailscale -PublicHttpsPort $PublicHttpsPort)) {
    throw "Tailscale Funnel already appears to use HTTPS port $PublicHttpsPort. Refusing to overwrite an unrelated Funnel. Choose another supported public port."
}

$tools = 'PowerShell,FileSystem,Process,Snapshot,Screenshot,DisplayInventory,App,Clipboard,Click,Type,Scroll,Move,Shortcut,Wait,WaitFor'
$allowedHosts = @($dnsName,'localhost','127.0.0.1') | ConvertTo-Json -Compress

$templatePath = Join-Path $PSScriptRoot 'templates\supervisor.ps1.tmpl'
$template = Get-Content -Raw -LiteralPath $templatePath
$rendered = $template
$rendered = $rendered.Replace('{{INSTALL_ROOT}}', $InstallRoot.Replace("'","''"))
$rendered = $rendered.Replace('{{PORT}}', [string]$Port)
$rendered = $rendered.Replace('{{WINDOWS_MCP_EXE}}', $windowsMcp.Replace("'","''"))
$rendered = $rendered.Replace('{{ALLOWED_HOSTS_JSON}}', $allowedHosts.Replace("'","''"))
$rendered = $rendered.Replace('{{TOOLS}}', $tools)

$supervisorPath = Join-Path $InstallRoot 'supervisor.ps1'
$rendered | Set-Content -LiteralPath $supervisorPath -Encoding UTF8

$startScript = @"
`$ErrorActionPreference = 'SilentlyContinue'
`$installRoot = '$($InstallRoot.Replace("'","''"))'
`$supervisor = Join-Path `$installRoot 'supervisor.ps1'
`$tailscale = '$($tailscale.Replace("'","''"))'
`$port = $Port
`$publicHttpsPort = $PublicHttpsPort

`$existing = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { `$_.Name -eq 'powershell.exe' -and [string]`$_.CommandLine -match [regex]::Escape(`$supervisor) }

if (-not `$existing) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
        '-NoProfile','-ExecutionPolicy','Bypass','-File',`$supervisor
    )
}

if (Test-Path -LiteralPath `$tailscale) {
    `$raw = (& `$tailscale status --json 2>`$null) -join [Environment]::NewLine
    try { `$state = (`$raw | ConvertFrom-Json).BackendState } catch { `$state = '' }
    if (`$state -eq 'Running') {
        `$httpsArg = "--https=`$publicHttpsPort"
        & `$tailscale funnel --bg `$httpsArg "`$port" *> `$null
    }
}
"@
$startPath = Join-Path $InstallRoot 'start.ps1'
$startScript | Set-Content -LiteralPath $startPath -Encoding UTF8

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
    createdAt = if ($existingConfig -and $existingConfig.createdAt) { [string]$existingConfig.createdAt } else { (Get-Date).ToString('o') }
    updatedAt = (Get-Date).ToString('o')
}
Write-RafdiConfig -InstallRoot $InstallRoot -Config $config

if ($PSCmdlet.ShouldProcess($TaskName, 'Register per-user logon auto-start task')) {
    Register-RafdiAutoStartTask -TaskName $TaskName -StartScript $startPath
}

$authKey = Get-RafdiAuthKey -InstallRoot $InstallRoot
$ownerPid = Get-RafdiPortOwnerPid -Port $Port
if ($ownerPid -and -not (Test-RafdiWindowsMcpIdentity -Port $Port -AuthKey $authKey)) {
    $cmdLine = Get-RafdiProcessCommandLine -Pid $ownerPid
    throw "Local port $Port is already owned by PID $ownerPid and did not identify as this Windows-MCP instance. Refusing to kill or replace it. Command line: $cmdLine"
}

if (-not (Test-RafdiWindowsMcpIdentity -Port $Port -AuthKey $authKey)) {
    if ($PSCmdlet.ShouldProcess($supervisorPath, 'Start supervisor')) {
        Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
            '-NoProfile','-ExecutionPolicy','Bypass','-File',$supervisorPath
        )
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
        throw 'Supervisor started but Windows-MCP did not pass identity verification.'
    }
}

if (-not $SkipFunnel) {
    Write-RafdiHeading 'Enabling Tailscale Funnel'
    $tmpOut = Join-Path $env:TEMP ("rafdi-funnel-{0}.out" -f [guid]::NewGuid().ToString('N'))
    $tmpErr = Join-Path $env:TEMP ("rafdi-funnel-{0}.err" -f [guid]::NewGuid().ToString('N'))

    try {
        $args = @('funnel','--bg',"--https=$PublicHttpsPort","$Port")
        $proc = Start-Process -FilePath $tailscale -ArgumentList $args -PassThru -WindowStyle Hidden `
            -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr

        $finished = $proc.WaitForExit(15000)
        if (-not $finished) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            $text = @(
                (Get-Content -Raw -LiteralPath $tmpOut -ErrorAction SilentlyContinue),
                (Get-Content -Raw -LiteralPath $tmpErr -ErrorAction SilentlyContinue)
            ) -join [Environment]::NewLine

            Write-Warning 'Funnel command is waiting for one-time account approval.'
            if ($text) { Write-Host $text.Trim() }
            Write-Host 'Complete the Tailscale Funnel approval in your browser, then re-run setup.' -ForegroundColor Yellow
            return
        }

        if ($proc.ExitCode -ne 0) {
            $text = @(
                (Get-Content -Raw -LiteralPath $tmpOut -ErrorAction SilentlyContinue),
                (Get-Content -Raw -LiteralPath $tmpErr -ErrorAction SilentlyContinue)
            ) -join [Environment]::NewLine
            throw "tailscale funnel failed with exit code $($proc.ExitCode). $text"
        }
    } finally {
        Remove-Item -LiteralPath $tmpOut,$tmpErr -Force -ErrorAction SilentlyContinue
    }
}

Write-RafdiHeading 'Verification'
if (-not (Test-RafdiWindowsMcpIdentity -Port $Port -AuthKey $authKey)) {
    throw 'Local authenticated Windows-MCP identity check failed.'
}
Write-Host 'Local Windows-MCP identity: PASS' -ForegroundColor Green

if (-not $SkipFunnel) {
    if (-not (Test-RafdiPublicAuthGuard -Url $publicUrl)) {
        throw "Public endpoint did not produce the expected unauthenticated 401 guard: $publicUrl"
    }
    Write-Host 'Public unauthenticated request rejected with 401: PASS' -ForegroundColor Green
}

Write-RafdiHeading 'Ready'
Write-Host "Stable MCP URL: $publicUrl" -ForegroundColor Green
Write-Host ''
Write-Host 'The bearer key was intentionally NOT printed.'
Write-Host "Secret file: $authFile"
Write-Host ''
Write-Host 'For Composio Custom MCP:'
Write-Host "  URL  : $publicUrl"
Write-Host '  Auth : Bearer token from auth.key'
Write-Host ''
Write-Host "Run status with: powershell -ExecutionPolicy Bypass -File `"$InstallRoot\status.ps1`""
