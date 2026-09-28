[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

$urls = @(
  "https://github.com/exxrawrrr/otak-atik/blob/main/docs/SETUP-WINDOWS.md",
  "https://github.com/desktop-commander/remote-desktop-commander",
  "https://mcp.desktopcommander.app",
  "https://chromewebstore.google.com/detail/mcp-superassistant/kngiafgkdnlkgmefdafaibkibegkcaef"
)

foreach ($url in $urls) {
  Start-Process $url
  Start-Sleep -Milliseconds 300
}

Write-Host "Opened otak-atik setup, Remote Desktop Commander, and the optional MCP SuperAssistant page."
