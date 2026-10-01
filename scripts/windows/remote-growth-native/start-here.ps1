param(
  [switch]$PersistEncryptedRuntimeKey
)

$ErrorActionPreference = 'Stop'

Write-Host 'Remote GROWTH Native bootstrap' -ForegroundColor Cyan
Write-Host ''
Write-Host 'You will need your OWN OpenAI Secure MCP Tunnel ID and runtime API key.' -ForegroundColor Yellow
Write-Host 'Nothing from another user or maintainer is bundled with this repository.'
Write-Host ''

Start-Process 'https://developers.openai.com/api/docs/guides/secure-mcp-tunnels'
Read-Host 'Create/locate your tunnel credentials, then press Enter to continue'

$Setup = Join-Path $PSScriptRoot 'setup-tunnel.ps1'
$Run = Join-Path $PSScriptRoot 'run-tunnel.ps1'

if ($PersistEncryptedRuntimeKey) {
  & $Setup -PersistEncryptedRuntimeKey
} else {
  & $Setup
}
if ($LASTEXITCODE -ne 0) { throw 'Tunnel setup failed.' }

& $Run -Detached
if ($LASTEXITCODE -ne 0) { throw 'Tunnel start failed.' }

Write-Host ''
Write-Host 'Tunnel is ready. Opening ChatGPT Plugins...' -ForegroundColor Green
Start-Process 'https://chatgpt.com/plugins'

Write-Host ''
Write-Host 'Next:' -ForegroundColor Cyan
Write-Host '1. Create an MCP app using the Tunnel connection path.'
Write-Host '2. Scan and verify your tool surface.'
Write-Host '3. Copy your own plugin_asdk_app_... technical ID.'
Write-Host '4. Run build-plugin.ps1 to generate your private plugin ZIP.'
