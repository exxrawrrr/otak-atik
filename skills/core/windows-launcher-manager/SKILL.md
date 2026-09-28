---
name: windows-launcher-manager
description: Create maintainable Windows click-to-run launchers for recurring operator commands.
status: stable
scope: platform
---

# Windows Launcher Manager

Use when a user repeatedly runs terminal commands and wants safe desktop launchers.

## Design

Prefer:

```text
Desktop .bat
→ stable PowerShell helper
→ actual command
```

instead of embedding large logic directly into BAT files.

## Requirements

- launcher names explain what they do;
- working paths are stable;
- duplicate processes are detected where relevant;
- errors remain visible;
- destructive stop/reset launchers require confirmation;
- machine-specific paths live in user config, not public repo defaults.

## Verification

After installation:

1. inspect generated launcher files;
2. execute status/check-only paths;
3. confirm the expected process is detected;
4. confirm no unrelated process was started.
