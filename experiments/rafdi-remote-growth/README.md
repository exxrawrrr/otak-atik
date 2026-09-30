# Rafdi Remote GROWTH — Experimental Windows Installer

> Status: **Phase 2B public path verified on one real Windows machine; clean-machine reproducibility is still pending.**
>
> This package is not claiming universal production readiness yet. It is the sanitized, reusable version of the real experiment documented in `docs/RAFDI-REMOTE-GROWTH.md`.

## What this installs

The target architecture is:

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Tailscale Funnel (stable HTTPS endpoint)
  ↓
Windows-MCP on 127.0.0.1
  ↓
PowerShell / files / processes / GUI tools
```

The installer creates only the local Windows side. First-time Tailscale login/Funnel approval and Composio Custom MCP connection still require explicit user action.

## Safety choices

This installer intentionally:

- binds Windows-MCP to `127.0.0.1` only;
- generates a fresh bearer key locally;
- never prints the bearer key during normal setup;
- locks `auth.key` to the current Windows user;
- enables FastMCP host-origin protection;
- allowlists only the discovered Tailscale hostname plus loopback hosts, including explicit wildcard-port forms required by reverse-proxy traffic;
- uses Windows-MCP's `--allow-insecure-remote` only in public/Funnel mode as a reverse-proxy compatibility shim while the server still binds to `127.0.0.1` and still requires bearer authentication;
- refuses to replace an unknown process already using the requested local port;
- refuses to overwrite an existing Tailscale Funnel public port;
- never runs global `tailscale funnel reset`;
- does not uninstall Tailscale or Windows-MCP because another workflow may use them;
- uses a narrowly named per-user Scheduled Task;
- uses a supervisor that only stops a listener after authenticated identity verification.

## Why `--allow-insecure-remote` appears here

Phase 2B found a real compatibility bug with the installed stack used for testing:

```text
Windows-MCP 0.8.6
FastMCP 4.0.10
MCP 2.2.0
```

Windows-MCP 0.8.6 automatically adds its own Trusted Host middleware for loopback binds and limits that middleware to loopback hostnames. Tailscale Funnel correctly preserves the external public `Host` header, so valid reverse-proxy requests were rejected with `Invalid host header` before MCP auth/session handling.

The package therefore launches Windows-MCP with its official `--allow-insecure-remote` flag **without changing the bind address**. The actual listener remains:

```text
127.0.0.1:<local-port>
```

Bearer authentication remains enabled, and FastMCP host-origin protection remains explicitly enabled with a narrow allowlist for the discovered Tailscale hostname plus loopback hosts.

In this recipe the flag means: *do not install Windows-MCP's hardcoded loopback TrustedHost middleware in front of the reverse proxy*. It does **not** mean: bind to `0.0.0.0`, expose an unauthenticated LAN service, or disable the package's FastMCP host checks.

If a future Windows-MCP release exposes a first-class public/reverse-proxy host allowlist, prefer that and remove this compatibility shim.

## Requirements

- Windows
- PowerShell 5.1+
- `winget` if you want automatic prerequisite installation
- a Tailscale account
- Composio Custom MCP if you want to use the endpoint from ChatGPT exactly like the original experiment

The setup can install:

- `uv` from winget package `astral-sh.uv`;
- Tailscale from winget package `Tailscale.Tailscale`;
- Windows-MCP as a persistent `uv tool`.

## 0. Dry run first

From this directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallPrerequisites -WhatIf
```

This must make no changes.

## 1. Install the local runtime

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -InstallPrerequisites
```

Default runtime directory:

```text
%LOCALAPPDATA%\OtakAtik\RafdiRemote
```

Defaults:

- local MCP port: `18765`
- public Tailscale HTTPS port: `8443`
- logon task: `OtakAtik Rafdi Remote AutoStart`

Port `8443` is used instead of `443` by default to reduce the chance of colliding with an existing Funnel on the machine.

## 2. If Tailscale is not logged in

Setup stops and prints the exact local `tailscale up` command.

Run it, finish browser login yourself, then rerun setup.

The installer will not attempt to automate account authentication.

## 3. Enable Funnel once

For safety, the installer does **not** silently publish the machine the first time.

After local setup succeeds it prints an exact command similar to:

```powershell
& "C:\Program Files\Tailscale\tailscale.exe" funnel --bg --yes --https=8443 18765
```

Run that command yourself.

If Tailscale gives you a one-time Funnel approval URL, approve it in your account, run the command again, then rerun `setup.ps1`.

On the second setup run, the installer verifies:

- expected Funnel hostname;
- expected local target;
- unauthenticated public request is rejected with HTTP 401.

## 4. Connect it to Composio

Setup prints the discovered MCP endpoint, for example:

```text
https://<your-machine>.<your-tailnet>.ts.net:8443/mcp
```

Create a **new Custom MCP** in Composio with:

- URL: the endpoint printed by setup;
- authentication: Bearer token;
- token: contents of the local `auth.key`.

To put the token on the Windows clipboard without printing it:

```powershell
Get-Content -Raw "$env:LOCALAPPDATA\OtakAtik\RafdiRemote\auth.key" | Set-Clipboard
```

Do not paste the token into issues, README screenshots, chat logs, or GitHub.

## Commands

### Status

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\OtakAtik\RafdiRemote\status.ps1"
```

Reports:

- local authenticated MCP state;
- supervisor state;
- Scheduled Task state;
- Tailscale backend state;
- Funnel mapping;
- public 401 auth guard;
- stable MCP URL.

### Test

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\OtakAtik\RafdiRemote\test.ps1"
```

Checks:

- local MCP identity;
- supervisor;
- Scheduled Task;
- Tailscale;
- Funnel mapping;
- public unauthenticated rejection;
- authenticated public MCP initialize.

The bearer token is kept in memory and is not printed.

### Repair

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\OtakAtik\RafdiRemote\repair.ps1"
```

Repair is conservative.

It can restore:

- missing supervisor;
- missing package Scheduled Task.

If Funnel is missing, repair prints the exact command for you to run manually instead of silently modifying global Tailscale Funnel state.

If the local port belongs to an unknown/unverified process, repair stops with an error.

### Safe disable / uninstall

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\OtakAtik\RafdiRemote\uninstall.ps1"
```

This:

- creates a cooperative `disabled.flag`;
- unregisters only this package's Scheduled Task;
- waits for the supervisor to stop its authenticated listener;
- preserves runtime files for inspection;
- leaves Tailscale installed;
- leaves Windows-MCP installed;
- leaves global Funnel configuration untouched.

Why not automatically call `tailscale funnel reset`?

Because the current CLI exposes `reset` as a global Funnel cleanup operation and the machine may have unrelated Funnel mappings. Nuking those would be a jancok installer design.

To re-enable, rerun `setup.ps1`.

## Diagnostic local-only mode

Maintainers can test local lifecycle without public exposure:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 \
  -Port 28767 \
  -PublicHttpsPort 10000 \
  -InstallRoot "$env:LOCALAPPDATA\OtakAtik\RafdiRemoteDogfood" \
  -TaskName "OtakAtik Rafdi Remote Dogfood" \
  -SkipFunnel
```

In this mode public/Funnel assertions are explicitly reported as skipped.

## What Phase 2A has actually proven

On the real GROWTH Windows machine:

- all public PowerShell artifacts parsed successfully;
- dry-run produced no mutations;
- fresh isolated install succeeded;
- generated bearer key had one ACL rule for the current user;
- authenticated local Windows-MCP identity check succeeded;
- rerunning setup preserved the same bearer key;
- rerunning setup kept one Scheduled Task;
- rerunning setup kept one supervisor;
- `status.ps1` passed;
- `test.ps1` passed in local-only diagnostic mode;
- `repair.ps1` passed without killing anything;
- safe uninstall removed the task and cooperatively stopped listener/supervisor;
- rerunning setup after uninstall re-enabled the install with the same key;
- real Stable endpoint on port `18765` remained online throughout dogfood testing.

## What Phase 2B has actually proven

On an isolated public test path, while the live Stable endpoint stayed online:

- the first installer run prepared local runtime but did not silently publish the machine;
- the exact Funnel command printed by setup successfully published only the isolated port;
- setup verified the expected Funnel mapping;
- unauthenticated public access was rejected with HTTP 401;
- authenticated MCP initialize through the public endpoint passed;
- an external Hyperbrowser cloud session reached the endpoint and was rejected without a bearer token;
- the registered Scheduled Task restored the runtime after a cooperative stop;
- the supervisor restarted a deliberately terminated, verified Windows-MCP child with a new PID;
- a `tailscale down` / `tailscale up` cycle restored both Stable and isolated Funnel mappings from stored state;
- a real Windows restart on 2026-09-30 restored the Stable listener, Tailscale Funnel, and ChatGPT -> Composio -> Windows-MCP command path automatically;
- the complete public test suite passed from Remote Desktop Commander after Windows-host detection was hardened for PowerShell hosts that do not populate `$env:OS`;
- the full package `test.ps1` suite passed again after recovery.

The existing Rafdi Remote GROWTH Stable connection already proves the same ChatGPT → Composio Custom MCP → Tailscale Funnel → Windows-MCP architecture in real daily use.

Creating a **second temporary Composio Custom MCP entry** for the isolated Phase 2B endpoint is not automated here because the Composio tools currently available in chat do not expose creation/editing of Composio's own Custom MCP entries. The package ships the exact dashboard setup fields instead of pretending that UI step happened.

## Still not claimed

Before calling this universally reproducible or release-hardened, the project still needs:

- a clean-machine install on another Windows PC/profile;
- explicit version-compatibility testing against newer Windows-MCP releases;
- a decision on whether to pin Windows-MCP/FastMCP versions;
- optional manual creation of a second Composio Custom MCP test entry if a UI-level duplicate test is desired;
- broader security review if this graduates beyond personal/experimental use.

Status: **public path proven; still experimental, but no longer local-only.**
