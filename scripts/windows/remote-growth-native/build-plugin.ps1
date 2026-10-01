param(
  [string]$AppId,
  [string]$Version = '1.0.0',
  [string]$DisplayName = 'Remote GROWTH Stable',
  [string]$DeveloperName = 'Local Operator'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($AppId)) {
  $AppId = Read-Host 'Your ChatGPT app technical ID (plugin_asdk_app_...)'
}
if ($AppId -notmatch '^plugin_asdk_app_[A-Za-z0-9]+$') {
  throw 'App ID format is invalid. Use your own verified plugin_asdk_app_... ID.'
}
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$') {
  throw 'Version must be a semantic version such as 1.0.0.'
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Template = Join-Path $RepoRoot 'examples\remote-growth-native\plugin-template'
if (-not (Test-Path (Join-Path $Template 'plugin.json'))) {
  throw 'Plugin template not found.'
}

$LocalRoot = Join-Path $env:LOCALAPPDATA 'otak-atik\remote-growth-native'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BuildParent = Join-Path $LocalRoot "builds\$Stamp"
$Build = Join-Path $BuildParent 'remote-growth-stable'
$Zip = Join-Path $BuildParent "remote-growth-stable-$Version.zip"

New-Item -ItemType Directory -Force -Path $BuildParent | Out-Null
Copy-Item $Template $Build -Recurse -Force

$App = [ordered]@{
  apps = [ordered]@{
    remote_growth_stable = [ordered]@{
      id = $AppId
    }
  }
}
$App | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $Build '.app.json') -Encoding UTF8
Remove-Item (Join-Path $Build '.app.json.template') -Force -ErrorAction SilentlyContinue

$ManifestPath = Join-Path $Build 'plugin.json'
$Manifest = Get-Content -Raw $ManifestPath | ConvertFrom-Json
$Manifest.version = $Version
$Manifest.extensions.'com.openai'.interface.displayName = $DisplayName
$Manifest.extensions.'com.openai'.interface.developerName = $DeveloperName
$Manifest.extensions.'com.openai' | Add-Member -NotePropertyName apps -NotePropertyValue './.app.json' -Force
$Manifest | ConvertTo-Json -Depth 12 | Set-Content $ManifestPath -Encoding UTF8

$Patterns = [ordered]@{
  openai_key = '\bsk-[A-Za-z0-9_-]{20,}'
  private_key = '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'
  bearer = '(?i)Bearer\s+[A-Za-z0-9._~+/=-]{24,}'
  tailscale_key = '\btskey-[A-Za-z0-9_-]{16,}'
  runtime_api = '(?i)(runtime[_ -]?api[_ -]?key|CONTROL_PLANE_API_KEY)\s*[:=]\s*["'']?(?!env:)[A-Za-z0-9._~+/=-]{20,}'
  tunnel_id = '\btunnel_[A-Za-z0-9_-]{20,}\b'
}
$Findings = @()
Get-ChildItem $Build -Recurse -File | Where-Object { $_.Length -lt 5000000 } | ForEach-Object {
  $Data = Get-Content -Raw $_.FullName -ErrorAction SilentlyContinue
  foreach ($Name in $Patterns.Keys) {
    if ($Data -match $Patterns[$Name]) {
      $Findings += [pscustomobject]@{file=$_.FullName;type=$Name}
    }
  }
}
if ($Findings.Count -gt 0) {
  $Findings | Select-Object file,type | Format-Table -AutoSize | Out-String | Write-Error
  throw 'Generated package failed secret scan.'
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $Zip) { Remove-Item $Zip -Force }
$Archive = [IO.Compression.ZipFile]::Open($Zip,[IO.Compression.ZipArchiveMode]::Create)
try {
  Get-ChildItem $Build -Recurse -File -Force | ForEach-Object {
    $Relative = $_.FullName.Substring($Build.Length).TrimStart('\').Replace('\','/')
    $EntryName = "remote-growth-stable/$Relative"
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
      $Archive,
      $_.FullName,
      $EntryName,
      [IO.Compression.CompressionLevel]::Optimal
    ) | Out-Null
  }
}
finally {
  $Archive.Dispose()
}

$ZipHash = (Get-FileHash $Zip -Algorithm SHA256).Hash

[pscustomobject]@{
  ok = $true
  version = $Version
  display_name = $DisplayName
  app_id_bound = $true
  app_id_printed = $false
  secret_findings = 0
  zip = $Zip
  zip_sha256 = $ZipHash
} | ConvertTo-Json -Depth 4
