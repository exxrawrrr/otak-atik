[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$npx = (Get-Command npx.cmd -ErrorAction Stop).Source
$UserRoot = Join-Path $HOME ".otak-atik"
$Config = Join-Path $UserRoot "mcp-superassistant.json"

if (-not (Test-Path $Config)) {
  throw "Browser bridge config not found: $Config. Run scripts/install.ps1 first."
}

$existing = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -match 'mcp-superassistant-proxy' }

if ($existing) {
  Write-Host "MCP SuperAssistant proxy already appears to be running." -ForegroundColor Green
  Write-Host "Expected local endpoint: http://localhost:3006/sse"
  $existing | Select-Object ProcessId, Name, CommandLine | Format-Table -AutoSize
  Read-Host "Press Enter to close"
  return
}

Write-Host ""
Write-Host "Starting OPTIONAL MCP SuperAssistant browser bridge..." -ForegroundColor Yellow
Write-Host "This is separate from Remote Desktop Commander remote MCP."
Write-Host ""
Write-Host "After startup, configure the extension with the endpoint printed by the proxy."
Write-Host "Common SSE endpoint: http://localhost:3006/sse"
Write-Host ""

& $npx "-y" "@srbhptl39/mcp-superassistant-proxy@latest" "--config" $Config "--outputTransport" "sse"

if ($LASTEXITCODE -ne 0) {
  throw ("MCP_SUPERASSISTANT_PROXY_EXIT_" + $LASTEXITCODE)
}
