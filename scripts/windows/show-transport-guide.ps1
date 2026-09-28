[CmdletBinding()]
param()

Write-Host ""
Write-Host "Which otak-atik transport should I use?" -ForegroundColor Cyan
Write-Host "--------------------------------------"
Write-Host ""
Write-Host "FROM PHONE / AWAY FROM PC"
Write-Host "  Use Remote Desktop Commander remote MCP."
Write-Host "  https://mcp.desktopcommander.app/mcp"
Write-Host ""
Write-Host "CODEX / LOCAL AI CLIENT ON THIS PC"
Write-Host "  Use Desktop Commander local MCP."
Write-Host "  No hosted remote tool-call quota."
Write-Host ""
Write-Host "CHATGPT/GEMINI WEBSITE IN CHROME, LOCAL PC"
Write-Host "  MCP SuperAssistant is optional."
Write-Host "  Use it only if you need a browser bridge."
Write-Host ""
Write-Host "SCREENSHOT / CLICK / TYPE / FULL GUI"
Write-Host "  Evaluate a GUI-control MCP provider such as QuickDesk."
Write-Host ""
Read-Host "Press Enter to close"
