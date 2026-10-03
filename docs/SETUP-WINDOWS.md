# Windows setup

This is the primary Windows onboarding path for OTAK-ATIK.

The user-facing direction is intentionally simple:

```text
START.cmd
  ↓
guided preflight
  ↓
Tailscale / secure-route step
  ↓
Remote GROWTH
  ↓
Composio
  ↓
acceptance checks
```

The current CHAT 2 build implements the branded terminal wizard, real preflight checks, and resumable local setup state. The secure-route and Composio wiring is intentionally not reported as complete until the later implementation phases make those checks real.

## 1. Requirements

- Windows 10 or 11
- Node.js 20+
- Git recommended
- Tailscale is part of the guided remote path

## 2. Clone

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik
```

A user can preview the setup experience immediately with:

```text
START.cmd
```

## 3. Installer dry run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
```

## 4. Install

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer:

- creates `~/.otak-atik/`;
- preserves an existing config unless `-Force` is used;
- copies Windows helper scripts to the user config directory;
- links the `otak-atik` CLI;
- creates a Desktop folder named `OTAK-ATIK`;
- creates one primary user launcher: `START.cmd`;
- keeps historical/advanced launchers in `OTAK-ATIK\ADVANCED\`;
- does **not** open a pile of browser tabs automatically.

## 5. Start the guided setup

On the Desktop open:

```text
OTAK-ATIK
└── START.cmd
```

The wizard is branded:

```text
OTAK-ATIK
Remote AI Setup Wizard
Created by Rafdi D. Ulhaq - exxrawrrr
```

It currently performs real checks for:

- Windows;
- PowerShell;
- Node.js 20+;
- Git;
- Tailscale installation/service/account state.

It uses human-readable statuses:

```text
[OK]
[WAIT]
[FIX]
[INFO]
[FAIL]
```

## Resumable setup state

Safe, non-secret progress is stored outside the Git checkout under:

```text
%LOCALAPPDATA%\otak-atik\setup-state.json
```

Setup logs live under:

```text
%LOCALAPPDATA%\otak-atik\logs\
```

A rerun re-checks the real machine state instead of blindly replaying previous steps.

## Advanced utilities

Older provider-specific helpers remain available under:

```text
OTAK-ATIK\ADVANCED\
```

They are intentionally removed from the main launcher surface so a new user does not need to understand historical transport choices.

## Installer switches

```powershell
# preview only
.\scripts\install.ps1 -DryRun

# replace the stored default config
.\scripts\install.ps1 -Force

# do not create Desktop launchers
.\scripts\install.ps1 -NoDesktopLaunchers

# explicitly open historical setup/provider pages
.\scripts\install.ps1 -OpenSetupPages

# compatibility switch: suppress browser pages
.\scripts\install.ps1 -NoOpenSetupPages
```

## Important

The installer and wizard do not silently:

- sign into Tailscale;
- sign into Composio;
- sign into ChatGPT;
- approve OAuth;
- weaken authentication;
- expose an unverified local service to the public internet.

Account-owned login and approval steps remain explicit user actions.

See [Composio + Tailscale User Setup UX](COMPOSIO-TAILSCALE-SETUP-UX.md) for the locked onboarding contract.
