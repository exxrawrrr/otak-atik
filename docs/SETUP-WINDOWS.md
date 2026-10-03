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

The current CHAT 3 build implements the branded terminal wizard **and** the guided Tailscale + Remote GROWTH + Composio wiring. The flow still does not claim clean-machine release readiness until CHAT 5 reproduces it on a fresh Windows environment.

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

It performs real checks and guided actions for:

- Windows and PowerShell as core requirements, with Node.js 20+ and Git treated as optional developer/repository tools;
- Tailscale installation, Windows service state, user login, and device DNS identity;
- an isolated portable Remote GROWTH Stable runtime under LocalAppData;
- a local authenticated `tools/list` inventory of exactly **64 tools**;
- Tailscale Funnel mapping to the verified gateway only;
- public unauthenticated rejection with HTTP **401**;
- authenticated public `tools/list` inventory of exactly **64 tools**;
- asking for the user's **Composio Project API Key** only when first-time Custom MCP registration is required;
- keeping that project key in memory only, never persisting it;
- registering the Custom MCP through Composio's current v3.1 API;
- creating/reusing the required API-key auth config;
- opening Composio's hosted connection page with the Remote GROWTH access code copied to the clipboard;
- syncing the Custom MCP through Composio and requiring API-reported `synced_count = 64` before setup is marked complete.

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

The portable Remote GROWTH runtime is installed under:

```text
%LOCALAPPDATA%\otak-atik\remote-growth-stable\
```

The installed bearer credential remains local and is never printed by the wizard. The runtime source is also cached under LocalAppData so the guided setup does not depend on keeping the Git checkout forever.

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
- sign into Composio and provide their own Project API Key during first-time Custom MCP registration;
- sign into ChatGPT;
- approve OAuth;
- weaken authentication;
- expose an unverified local service to the public internet.

Account-owned login and approval steps remain explicit user actions.

### CHAT 3 validation boundary

CHAT 3 now has real-machine evidence beyond syntax and dry-run checks:

- an isolated portable runtime was built from the public source on GROWTH using separate test ports and returned exactly **64/64 tools**;
- the temporary acceptance runtime/processes were removed after verification;
- the production Funnel route was checked read-only and returned **HTTP 401 without authentication**;
- the authenticated production MCP route returned exactly **64/64 tools**;
- the portable runtime source is scanned to reject owner-specific paths, Windows usernames, and the original Tailscale hostname;
- Windows CI builds a fresh portable runtime on isolated ports and repeats the exact 64-tool acceptance gate.

This still does **not** claim arbitrary-device reproducibility, a complete reboot/recovery cycle, or first-time-user acceptance. Those remain CHAT 5 gates.

See [Composio + Tailscale User Setup UX](COMPOSIO-TAILSCALE-SETUP-UX.md) for the locked onboarding contract.
