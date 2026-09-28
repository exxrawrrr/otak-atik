param(
  [switch]$KeepConfig
)

$ErrorActionPreference = "Stop"
$Target = Join-Path $HOME ".otak-atik"

Write-Host "Removing CLI link..."
try {
  npm unlink -g otak-atik | Out-Null
} catch {
  Write-Warning "Global npm link may already be absent."
}

if ($KeepConfig) {
  Write-Host "Keeping $Target"
} elseif (Test-Path $Target) {
  Write-Host "Config/state directory was NOT deleted automatically."
  Write-Host "Remove manually after review: $Target"
}

Write-Host "Uninstall complete."
