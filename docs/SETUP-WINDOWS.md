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

The CHAT 5 candidate adds a user-first Windows release ZIP on top of the branded terminal wizard, guided Tailscale + Remote GROWTH + Composio wiring, and the user-facing STATUS + REPAIR recovery path. Clean-runner and post-merge release gates determine whether the candidate may be tagged.

## 1. Requirements

- Windows 10 or 11
- PowerShell
- Tailscale and Composio accounts are used by the guided remote path
- Node.js 20+ is optional and only needed for repository/developer CLI commands
- Git is optional and only needed for cloning/updating the developer repository

## 2. Recommended user install — release ZIP

For a normal Windows user, Git is not the starting point.

1. Download the `OTAK-ATIK-Windows-v0.1.0-alpha.6.zip` release asset.
2. Extract the ZIP to a normal folder.
3. Double-click `START.cmd`.
4. Follow the terminal and sign in only when Tailscale or Composio asks you.

The first START automatically:

- installs the durable helper copy under the current Windows profile;
- caches the portable 64-tool runtime source outside the downloaded folder;
- creates the Desktop `OTAK-ATIK` folder with `START.cmd`, `STATUS.cmd`, and `REPAIR.cmd`;
- then launches the guided setup from the installed copy.

After that bootstrap, normal operation does not depend on keeping the downloaded ZIP folder.

The release ZIP includes `README-FIRST.txt` and a SHA-256 sidecar.

### Developer / repository install

Developers can still clone the repository:

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik
```

Running the repository-root `START.cmd` uses the same bootstrap path.

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
- links the `otak-atik` developer CLI when Node.js 20+ is available; guided Windows setup does not depend on that link;
- creates a Desktop folder named `OTAK-ATIK`;
- creates three primary user launchers: `START.cmd`, `STATUS.cmd`, and `REPAIR.cmd`;
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

The installed bearer credential remains local and is never printed by the wizard. The runtime source and nested Windows helpers are also cached outside the Git checkout so normal setup, status, and repair do not depend on keeping the cloned repository forever.

A rerun re-checks the real machine state instead of blindly replaying previous steps.

## STATUS.cmd

`STATUS.cmd` is the normal health-check entrypoint after setup. It presents the system in human language while checking the real components underneath:

- runtime supervisor and current-user auto-start task;
- ownership of the upstream and gateway ports;
- local unauthenticated request rejected with HTTP **401**;
- local authenticated inventory exactly **64 tools**;
- Tailscale service, account state, and device identity;
- expected Funnel mapping;
- public **401** guard and public **64-tool** inventory;
- last recorded Composio Custom MCP sync.

Status states are intentionally small:

```text
READY          everything verified
REPAIR_NEEDED  project-owned component can be repaired safely
USER_ACTION    an account login/reconnect is required
BLOCKED        a safety boundary prevents automatic repair
```

## REPAIR.cmd

`REPAIR.cmd` follows a strict three-stage contract:

```text
diagnose
  ↓
repair only OTAK-ATIK-owned components
  ↓
verify again
```

It may safely:

- recreate the OTAK-ATIK current-user auto-start task;
- restart the OTAK-ATIK supervisor;
- restore a missing Windows-MCP upstream or 64-tool gateway;
- start the Tailscale Windows service;
- restore the expected Tailscale Funnel mapping when the target is unambiguous;
- verify local/public authentication and 64-tool inventory again.

It will **not**:

- kill an unrelated process that owns a configured port;
- overwrite a conflicting Funnel mapping;
- weaken or bypass bearer authentication;
- invent a missing Remote GROWTH credential;
- silently sign in to Tailscale or Composio;
- silently replace a changed Tailscale identity.

If public authentication protection fails, repair fails closed and disables the expected Funnel exposure instead of leaving a questionable public route online.

CHAT 4 real-machine acceptance deliberately broke an isolated test runtime by removing its recovery task and stopping its processes. `STATUS` correctly reported `REPAIR_NEEDED`, then `REPAIR` rebuilt the recovery task, restarted the runtime, and returned to **HTTP 401 + 64/64 tools + READY**.

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
