# Phase 2A Checkpoint — Safe Public Installer Core

Date: 2026-09-29

Branch: `feat/rafdi-remote-growth-stable`

Status: **DONE — installer core dogfooded locally; public Funnel reality test reserved for Phase 2B.**

## Artifacts added

```text
experiments/rafdi-remote-growth/
├── README.md
├── setup.ps1
├── status.ps1
├── repair.ps1
├── test.ps1
├── uninstall.ps1
├── lib/
│   └── common.ps1
└── templates/
    └── supervisor.ps1.tmpl
```

## Safety properties implemented

- Windows-only preflight.
- `-WhatIf` dry-run path.
- optional prerequisite install through winget.
- Windows-MCP installed as persistent `uv tool`.
- fresh per-machine bearer key generated locally.
- bearer key is not printed during normal setup.
- bearer key ACL restricted to the current Windows user.
- Windows-MCP bound to `127.0.0.1` only.
- FastMCP host-origin protection enabled.
- explicit Tailscale hostname + localhost allowlist.
- local port ownership/identity check before any use.
- installer refuses to kill/replace an unknown listener.
- per-port supervisor mutex.
- idempotent per-user Scheduled Task.
- bounded supervisor logs.
- conservative repair: no broad process kill.
- safe uninstall uses cooperative disable marker.
- uninstall removes only this package's Scheduled Task.
- uninstall does not remove shared Tailscale or Windows-MCP packages.
- uninstall does not call global `tailscale funnel reset`.
- first-time Funnel publication remains an explicit user action.

## Dogfood bugs caught and fixed

The first implementation was not accepted blindly.

Dogfood found:

1. `uv.exe` discovery missed versioned Python script directories.
2. local health check parsed SSE response content too strictly.
3. helper parameter `$Pid` collided with PowerShell's built-in `$PID`.
4. supervisor mutex was global, blocking multiple isolated test instances.
5. repeated substring patching corrupted four PowerShell scripts.
6. diagnostic `-SkipFunnel` output initially implied a public endpoint was active when it was not.

Each issue was fixed before commit.

## Verified lifecycle on GROWTH

An isolated install used a separate runtime folder, task, and port so the live Stable connection was not touched.

Verified:

- fresh isolated setup exit `0`;
- authenticated local Windows-MCP identity PASS;
- one Scheduled Task created;
- one supervisor created;
- bearer key ACL had one rule owned by the current user;
- setup rerun preserved bearer key SHA-256;
- setup rerun kept exactly one task;
- setup rerun kept exactly one supervisor;
- `status.ps1` exit `0`;
- `test.ps1` exit `0` in local-only mode;
- `repair.ps1` exit `0`;
- safe uninstall created disable marker;
- package task was removed;
- supervisor exited cooperatively;
- isolated listener stopped;
- setup rerun after uninstall re-enabled successfully;
- bearer key remained preserved after re-enable;
- all dogfood listeners/tasks were cleaned after testing;
- real Rafdi Remote Stable listener on port `18765` remained online.

## Static validation

PowerShell parse gate:

```text
setup.ps1                       PASS
status.ps1                      PASS
repair.ps1                      PASS
test.ps1                        PASS
uninstall.ps1                   PASS
lib/common.ps1                  PASS
templates/supervisor.ps1.tmpl   PASS
TOTAL_BAD=0
```

Hardcoded private-value scan:

```text
growth-rafdi                 0
tail39bf37                   0
trycloudflare                0
<hardcoded-user-profile-path>  0
rafdiulhaq001@gmail.com      0
```

Dry run:

```text
WHATIF_EXIT=0
No changes were made.
```

## Repository validation

```text
Validation passed.
Tests: 34/34 passed
Benchmark: 4/4 passed
Hygiene scanned_files: 165
Hygiene high: 0
Hygiene medium: 0
Skill audit: 29 skills, 0 errors, 0 warnings
```

## Intentional Phase 2A boundary

The sanitized installer has **not yet** been used to publish a second public Funnel endpoint end-to-end.

That is Phase 2B.

Phase 2B must verify:

- explicit Funnel enable with the sanitized installer flow;
- public unauthenticated HTTP 401;
- authenticated public MCP initialize;
- restart/login persistence;
- Composio Custom MCP hookup using sanitized instructions;
- final cleanup and reproducibility claim.

Until Phase 2B passes, package status remains:

**experimental installer core, dogfooded locally, not yet broadly reproducible.**
