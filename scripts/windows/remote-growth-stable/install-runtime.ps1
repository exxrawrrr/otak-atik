[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$SourceRuntimeRoot,
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "otak-atik\remote-growth-stable"),
  [string]$TailscaleDnsName = "",
  [string]$TailscaleExe = "",
  [int]$GatewayPort = 18765,
  [int]$UpstreamPort = 18766,
  [ValidateSet(443,8443,10000)][int]$PublicHttpsPort = 443,
  [switch]$InstallPrerequisites,
  [switch]$Force,
  [switch]$DryRun,
  [switch]$NoStart
)

$ErrorActionPreference = "Stop"

function Resolve-Exe {
  param([string]$Name, [string[]]$Fallbacks = @())
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($item in $Fallbacks) {
    if ($item -and (Test-Path -LiteralPath $item)) {
      return (Resolve-Path -LiteralPath $item).Path
    }
  }
  return $null
}

function New-BearerKey {
  $bytes = New-Object byte[] 32
  $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
  return [Convert]::ToBase64String($bytes).Replace("+","-").Replace("/","_").TrimEnd("=")
}

function Protect-CurrentUserFile {
  param([string]$Path)
  $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  $acl = New-Object Security.AccessControl.FileSecurity
  $acl.SetAccessRuleProtection($true, $false)
  $rule = New-Object Security.AccessControl.FileSystemAccessRule(
    $identity,
    [Security.AccessControl.FileSystemRights]::FullControl,
    [Security.AccessControl.AccessControlType]::Allow
  )
  $acl.AddAccessRule($rule)
  Set-Acl -LiteralPath $Path -AclObject $acl
}

function Get-PublicUrl {
  param([string]$DnsName, [int]$HttpsPort)
  if (-not $DnsName) { return "" }
  if ($HttpsPort -eq 443) { return "https://$DnsName/mcp" }
  return "https://$($DnsName):$HttpsPort/mcp"
}

if ($env:OS -ne "Windows_NT") {
  throw "Remote GROWTH Stable portable runtime currently supports Windows only."
}

if (-not (Test-Path -LiteralPath $SourceRuntimeRoot)) {
  throw "Runtime source not found: $SourceRuntimeRoot"
}

$winget = Resolve-Exe "winget.exe"
$uvFallbacks = @(
  (Join-Path $env:USERPROFILE ".local\bin\uv.exe"),
  (Join-Path $env:APPDATA "Python\Scripts\uv.exe")
)
$uv = Resolve-Exe "uv.exe" $uvFallbacks

if (-not $uv -and $InstallPrerequisites) {
  if (-not $winget) { throw "winget is required for automatic uv installation." }
  & $winget install --id astral-sh.uv -e --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) { throw "uv installation failed." }
  $uv = Resolve-Exe "uv.exe" $uvFallbacks
}
if (-not $uv -and -not $DryRun) {
  throw "uv is required. Re-run with -InstallPrerequisites."
}

if (-not $TailscaleExe) {
  $programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
  $fallbacks = @((Join-Path $env:ProgramFiles "Tailscale\tailscale.exe"))
  if ($programFilesX86) { $fallbacks += (Join-Path $programFilesX86 "Tailscale\tailscale.exe") }
  $TailscaleExe = Resolve-Exe "tailscale.exe" $fallbacks
}
if (-not $TailscaleExe) { $TailscaleExe = "" }

$AppRoot = Join-Path $InstallRoot "app"
$VenvRoot = Join-Path $InstallRoot ".venv"
$PythonExe = Join-Path $VenvRoot "Scripts\python.exe"
$WindowsMcpExe = Join-Path $VenvRoot "Scripts\windows-mcp.exe"
$AuthFile = Join-Path $InstallRoot "auth.key"
$ConfigPath = Join-Path $InstallRoot "config.json"
$SupervisorPath = Join-Path $InstallRoot "supervisor.ps1"
$TaskName = "OtakAtik Remote GROWTH Stable"

if ($DryRun) {
  Write-Host "Remote GROWTH Stable runtime dry run" -ForegroundColor Cyan
  Write-Host ("Source runtime : " + $SourceRuntimeRoot)
  Write-Host ("Install root   : " + $InstallRoot)
  Write-Host ("Gateway port   : " + $GatewayPort)
  Write-Host ("Upstream port  : " + $UpstreamPort)
  Write-Host ("Public HTTPS   : " + $PublicHttpsPort)
  Write-Host ("Tailscale DNS  : " + $(if ($TailscaleDnsName) { "<provided>" } else { "<not provided>" }))
  Write-Host "Would create an isolated Python 3.14 environment and install pinned dependencies."
  Write-Host "Would generate/preserve a local bearer key without printing it."
  Write-Host "Would create a current-user auto-start task."
  Write-Host "Would require authenticated tools/list == 64 before reporting runtime ready."
  exit 0
}

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $InstallRoot "logs") | Out-Null

if ($Force -and (Test-Path -LiteralPath $AppRoot)) {
  Remove-Item -LiteralPath $AppRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $AppRoot | Out-Null
Copy-Item -Path (Join-Path $SourceRuntimeRoot "*") -Destination $AppRoot -Recurse -Force

if (-not (Test-Path -LiteralPath $PythonExe)) {
  & $uv venv --python 3.14 $VenvRoot
  if ($LASTEXITCODE -ne 0) { throw "Unable to create the isolated Python runtime." }
}

$requirements = Join-Path $AppRoot "requirements.txt"
& $uv pip install --python $PythonExe -r $requirements
if ($LASTEXITCODE -ne 0) { throw "Remote GROWTH dependency installation failed." }

if (-not (Test-Path -LiteralPath $WindowsMcpExe)) {
  throw "windows-mcp executable was not created in the isolated runtime."
}

if ($Force -or -not (Test-Path -LiteralPath $AuthFile)) {
  New-BearerKey | Set-Content -NoNewline -LiteralPath $AuthFile -Encoding ASCII
  Protect-CurrentUserFile -Path $AuthFile
}

$roots = @()
foreach ($candidate in @(
  $HOME,
  (Join-Path $HOME "Desktop"),
  (Join-Path $HOME "Documents"),
  (Join-Path $HOME "Downloads"),
  (Join-Path $HOME "OneDrive\Documents")
)) {
  if ($candidate -and (Test-Path -LiteralPath $candidate) -and $roots -notcontains $candidate) {
    $roots += $candidate
  }
}
if ($roots.Count -eq 0) { $roots = @($HOME) }

$fastLocalConfig = [ordered]@{
  version = 3
  roots = $roots
  cold_roots = @()
  exclude_dir_names = @(".git","node_modules",".venv","venv","__pycache__",".next","dist","build","coverage",".cache",'$RECYCLE.BIN',"System Volume Information")
  text_extensions = @(".txt",".md",".json",".jsonl",".csv",".tsv",".xml",".yaml",".yml",".toml",".ini",".cfg",".conf",".ps1",".bat",".cmd",".py",".js",".mjs",".cjs",".ts",".tsx",".jsx",".css",".scss",".html",".htm",".sql",".log")
  max_text_file_bytes = 1048576
  max_text_chars = 80000
  workspace_markers = @(".git","package.json","pyproject.toml","requirements.txt","go.mod","Cargo.toml","composer.json","pom.xml","build.gradle","build.gradle.kts","Gemfile")
}
$fastConfigPath = Join-Path $AppRoot "FAST_LOCAL_ENGINE\config.json"
$fastLocalConfig | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $fastConfigPath -Encoding UTF8

$publicUrl = Get-PublicUrl -DnsName $TailscaleDnsName -HttpsPort $PublicHttpsPort
$config = [ordered]@{
  schemaVersion = 1
  version = "0.7.0-portable"
  installRoot = $InstallRoot
  appRoot = $AppRoot
  pythonExe = $PythonExe
  windowsMcpExe = $WindowsMcpExe
  tailscaleExe = $TailscaleExe
  tailscaleDnsName = $TailscaleDnsName
  publicMcpUrl = $publicUrl
  gatewayPort = $GatewayPort
  upstreamPort = $UpstreamPort
  publicHttpsPort = $PublicHttpsPort
  taskName = $TaskName
  allowedRoots = $roots
  expectedTools = 64
  createdAt = if (Test-Path -LiteralPath $ConfigPath) {
    try { [string]((Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json).createdAt) } catch { (Get-Date).ToString("o") }
  } else { (Get-Date).ToString("o") }
  updatedAt = (Get-Date).ToString("o")
}
$config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8

Copy-Item -LiteralPath (Join-Path $AppRoot "supervisor.ps1") -Destination $SupervisorPath -Force

$identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $SupervisorPath + '"')
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $identity
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId $identity -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Starts the portable OTAK-ATIK Remote GROWTH Stable runtime at logon." -Force | Out-Null

if (-not $NoStart) {
  $escaped = [regex]::Escape($SupervisorPath)
  $existing = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -eq "powershell.exe" -and [string]$_.CommandLine -match $escaped
  })
  if ($existing.Count -eq 0) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @("-NoProfile","-ExecutionPolicy","Bypass","-File",$SupervisorPath)
  }

  $verified = $false
  $verifyScript = Join-Path $AppRoot "verify_inventory.py"
  for ($i = 0; $i -lt 18; $i++) {
    Start-Sleep -Seconds 2
    $json = (& $PythonExe $verifyScript --url ("http://127.0.0.1:" + $GatewayPort + "/mcp") --auth-file $AuthFile --expected 64 2>$null | Select-Object -Last 1)
    if ($LASTEXITCODE -eq 0) {
      try {
        $result = $json | ConvertFrom-Json
        if ($result.inventory_match -and [int]$result.count -eq 64) {
          $verified = $true
          break
        }
      } catch {}
    }
  }
  if (-not $verified) {
    throw "Remote GROWTH started, but authenticated tools/list did not verify exactly 64 tools. Check local logs before exposing it."
  }
}

Write-Host "Remote GROWTH Stable local runtime: READY (64 tools verified)" -ForegroundColor Green
Write-Host ("Install root: " + $InstallRoot)
Write-Host "Bearer key remains local and was not printed."
if ($publicUrl) {
  Write-Host ("Planned public MCP URL: " + $publicUrl)
}
