[CmdletBinding()]
param(
  [switch]$Yes
)

$ErrorActionPreference = "Stop"

$codex = Get-Command codex -ErrorAction SilentlyContinue
$npx = Get-Command npx.cmd -ErrorAction SilentlyContinue

if (-not $npx) {
  throw "npx was not found. Install Node.js first."
}

Write-Host ""
Write-Host "otak-atik: Codex local MCP setup" -ForegroundColor Cyan
Write-Host "--------------------------------"
Write-Host "This configures Desktop Commander LOCAL MCP for Codex."
Write-Host "It does not use the hosted Remote Desktop Commander quota."
Write-Host ""

if (-not $codex) {
  Write-Host "Codex CLI was not detected." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "When Codex is installed, run:"
  Write-Host "codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest" -ForegroundColor Cyan
  Read-Host "Press Enter to close"
  return
}

Write-Host "Command to run:"
Write-Host "codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest" -ForegroundColor Cyan

if (-not $Yes) {
  $answer = Read-Host "Apply this Codex MCP configuration? Type YES to continue"
  if ($answer -ne "YES") {
    Write-Host "Cancelled."
    return
  }
}

& $codex.Source mcp add desktop-commander -- npx -y "@wonderwhy-er/desktop-commander@latest"

if ($LASTEXITCODE -ne 0) {
  throw ("CODEX_MCP_ADD_EXIT_" + $LASTEXITCODE)
}

Write-Host ""
Write-Host "Codex local Desktop Commander MCP configured." -ForegroundColor Green
Write-Host "Open/restart Codex if required, then test with a read-only operation."
