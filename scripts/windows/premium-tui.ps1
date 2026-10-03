$script:OtakTuiWidth = 78

function Get-OtakTuiWidth {
  try {
    $width = [Console]::WindowWidth
    if ($width -ge 72) {
      return [Math]::Min([Math]::Max($width - 4, 72), 96)
    }
  } catch {}
  return $script:OtakTuiWidth
}

function Initialize-OtakTui {
  param(
    [string]$Title = "OTAK-ATIK",
    [switch]$NoClear
  )

  try { [Console]::Title = $Title } catch {}
  try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch {}
  try { [Console]::CursorVisible = $true } catch {}
  if (-not $NoClear) {
    try { Clear-Host } catch {}
  }
}

function Write-OtakRule {
  param(
    [string]$Character = "-",
    [ConsoleColor]$Color = [ConsoleColor]::DarkGray
  )
  $width = Get-OtakTuiWidth
  Write-Host (" " + ($Character * ($width - 2))) -ForegroundColor $Color
}

function Write-OtakLogo {
  param(
    [string]$Subtitle = "REMOTE AI x COMPOSIO SETUP",
    [string]$Mode = "INSTALLER"
  )

  Write-Host ""
  Write-Host "   ___  _____  _   _   _  __       _  _____ ___ _  __" -ForegroundColor Cyan
  Write-Host "  / _ \|_   _|/ \ | | | |/ / _____| ||_   _|_ _| |/ /" -ForegroundColor Cyan
  Write-Host " | | | | | | / _ \| |_| ' / |_____| |  | |  | || ' / " -ForegroundColor White
  Write-Host " | |_| | | |/ ___ \  _  . \       | |  | |  | || . \ " -ForegroundColor White
  Write-Host "  \___/  |_/_/   \_\_| |_|\_\      |_|  |_| |___|_|\_\" -ForegroundColor DarkCyan
  Write-Host ""
  Write-Host ("                 " + $Subtitle) -ForegroundColor White
  Write-Host ("                 " + $Mode) -ForegroundColor DarkGray
  Write-Host ""
  Write-Host "              Created by Rafdi D. Ulhaq - exxrawrrr" -ForegroundColor Gray
  Write-Host ""
  Write-OtakRule -Character "=" -Color DarkCyan
}

function Write-OtakNotice {
  param(
    [string]$Title,
    [string[]]$Lines,
    [ValidateSet("INFO","WARN","ERROR","OK")][string]$Kind = "INFO"
  )

  $color = switch ($Kind) {
    "OK" { [ConsoleColor]::Green }
    "WARN" { [ConsoleColor]::Yellow }
    "ERROR" { [ConsoleColor]::Red }
    default { [ConsoleColor]::Cyan }
  }

  $width = Get-OtakTuiWidth
  $inner = $width - 6
  Write-Host ""
  Write-Host (" +" + ("-" * ($width - 4)) + "+") -ForegroundColor $color
  Write-Host (" | " + $Title.PadRight($inner) + " |") -ForegroundColor $color
  Write-Host (" | " + (" " * $inner) + " |") -ForegroundColor $color
  foreach ($line in $Lines) {
    $text = [string]$line
    if ($text.Length -gt $inner) { $text = $text.Substring(0,$inner) }
    Write-Host (" | " + $text.PadRight($inner) + " |") -ForegroundColor White
  }
  Write-Host (" +" + ("-" * ($width - 4)) + "+") -ForegroundColor $color
}

function Write-OtakProgress {
  param(
    [int]$Current,
    [int]$Total,
    [string]$Label = ""
  )

  if ($Total -lt 1) { $Total = 1 }
  $ratio = [Math]::Min([Math]::Max(($Current / [double]$Total),0),1)
  $pct = [int][Math]::Round($ratio * 100)
  $barWidth = 28
  $filled = [int][Math]::Round($barWidth * $ratio)
  if ($filled -gt $barWidth) { $filled = $barWidth }
  $empty = $barWidth - $filled
  $bar = ("#" * $filled) + ("-" * $empty)

  Write-Host ""
  Write-Host (" [" + $bar + "] " + $pct.ToString().PadLeft(3) + "%") -NoNewline -ForegroundColor Cyan
  if ($Label) { Write-Host ("  " + $Label) -ForegroundColor Gray }
  else { Write-Host "" }
}

function Write-OtakStep {
  param(
    [int]$Number,
    [int]$Total,
    [string]$Title
  )

  Write-OtakProgress -Current ($Number - 1) -Total $Total -Label ("Preparing step " + $Number + " of " + $Total)
  Write-Host ""
  Write-Host ("  STEP {0}/{1}" -f $Number,$Total) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
  Write-Host ("   " + $Title.ToUpperInvariant()) -ForegroundColor White
  Write-OtakRule
}

function Write-OtakStatus {
  param(
    [ValidateSet("OK","WAIT","FIX","INFO","FAIL")][string]$Kind,
    [string]$Message
  )

  $symbol = switch ($Kind) {
    "OK" { "[+]" }
    "WAIT" { "[>]" }
    "FIX" { "[~]" }
    "FAIL" { "[!]" }
    default { "[i]" }
  }
  $color = switch ($Kind) {
    "OK" { [ConsoleColor]::Green }
    "WAIT" { [ConsoleColor]::Yellow }
    "FIX" { [ConsoleColor]::Yellow }
    "FAIL" { [ConsoleColor]::Red }
    default { [ConsoleColor]::DarkGray }
  }

  Write-Host ("  " + $symbol) -NoNewline -ForegroundColor $color
  Write-Host (" " + $Message)
}

function Write-OtakActivity {
  param(
    [string]$Message,
    [int]$Frame = 0
  )
  $frames = @("|","/","-","\\")
  $glyph = $frames[$Frame % $frames.Count]
  try {
    Write-Host ("`r  [" + $glyph + "] " + $Message.PadRight(58)) -NoNewline -ForegroundColor Cyan
  } catch {
    Write-OtakStatus -Kind "WAIT" -Message $Message
  }
}

function Complete-OtakActivity {
  param(
    [string]$Message,
    [ValidateSet("OK","FAIL")][string]$Kind = "OK"
  )
  try { Write-Host "`r" -NoNewline } catch {}
  Write-OtakStatus -Kind $Kind -Message $Message
}

function Write-OtakFooter {
  param([string]$Brand = "Created by Rafdi D. Ulhaq - exxrawrrr")
  Write-Host ""
  Write-OtakRule -Character "-"
  Write-Host ("  " + $Brand) -ForegroundColor DarkGray
  Write-Host ""
}

function Write-OtakComplete {
  param(
    [string]$Title = "SETUP COMPLETE",
    [string[]]$Lines = @("OTAK-ATIK is ready.")
  )

  Write-OtakProgress -Current 1 -Total 1 -Label "All required checks passed"
  Write-OtakNotice -Title $Title -Lines $Lines -Kind "OK"
}

function Read-OtakAction {
  param(
    [string]$Prompt,
    [string]$Title = "ACTION REQUIRED"
  )

  Write-OtakNotice -Title $Title -Lines @(
    $Prompt,
    "",
    "Return to this terminal when you are finished.",
    "Press ENTER to continue, or Q to stop safely."
  ) -Kind "WARN"

  $answer = Read-Host " "
  return ($answer -notmatch "^[Qq]$")
}
