# Rafdi Remote GROWTH — reusable experiment

> **Experimental. Real-world verified on one Windows machine; clean-machine reproducibility is still being proven.**

This package turns the successful `Rafdi Remote GROWTH` experiment into a safer reusable setup.

Architecture:

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Tailscale Funnel (stable HTTPS)
  ↓
Windows-MCP on 127.0.0.1
  ↓
PowerShell / files / processes / GUI tools
```

## Why this exists

The original problem was not "how do I remote desktop like a human?"

It was:

> how can ChatGPT reach my Windows machine, run terminal commands, inspect files/processes, and optionally control the GUI without spending my hosted remote-plugin quota on every tiny operation?

The final experiment worked with:

- Windows-MCP as the local tool engine;
- Tailscale Funnel as the stable public HTTPS transport;
- Composio Custom MCP as the ChatGPT integration layer;
- a local bearer key;
- explicit host allowlisting;
- an auto-restarting supervisor;
- a per-user Scheduled Task at logon.

## Safety choices

This public installer deliberately differs from the author's live setup in a few places.

### Public HTTPS defaults to 8443

Tailscale Funnel currently supports public ports `443`, `8443`, and `10000`.

This package defaults to **8443** so it is less likely to overwrite an existing Funnel already using 443.

If 8443 already appears occupied by a Funnel, setup refuses to continue.

### MCP stays on loopback

Windows-MCP binds to:

```text
127.0.0.1:18765
```

It is not opened directly to the LAN.

### Bearer secret is machine-local

`setup.ps1` generates a fresh random key and stores it under:

```text
%LOCALAPPDATA%\OtakAtik\RafdiRemote\auth.key
```

The value is not printed during setup.

### Unknown port owners are not killed

If the chosen local port is occupied but the service does not authenticate and identify as Windows-MCP, setup/repair abort.

That rule exists because the real experiment once tunneled the wrong local MCP service. Yes. Jancok.

## Quick start

Open PowerShell in this folder.

First, inspect what setup would do:

```powershell
.\setup.ps1 -InstallPrerequisites -WhatIf
```

Then install:

```powershell
.\setup.ps1 -InstallPrerequisites
```

`-InstallPrerequisites` may install:

- `uv` via winget;
- Tailscale via winget;
- Windows-MCP via `uv tool install windows-mcp`.

The script does **not** create your Tailscale account for you.

If Tailscale is not logged in, setup stops and tells you to run:

```powershell
tailscale up
```

Finish login in your browser, then run setup again.

If Funnel needs one-time approval, setup captures the prompt/approval URL, stops safely, and asks you to approve Funnel before running setup again.

## Composio step

After setup succeeds, it prints a stable URL shaped like:

```text
https://your-machine.your-tailnet.ts.net:8443/mcp
```

Create a **Custom MCP** in Composio:

- transport: HTTP / Streamable HTTP;
- URL: the stable URL printed by setup;
- authentication: Bearer;
- token: contents of the local `auth.key` file.

Do not paste the key into GitHub issues, screenshots, logs, or this repository.

See [`examples/composio-custom-mcp.example.md`](examples/composio-custom-mcp.example.md).

## Operations

Status:

```powershell
.\status.ps1
```

Machine-readable status:

```powershell
.\status.ps1 -Json
```

Repair:

```powershell
.\repair.ps1
```

Verify:

```powershell
.\test.ps1
```

Uninstall only this bridge:

```powershell
.\uninstall.ps1
```

The uninstall script intentionally leaves Tailscale itself and Windows-MCP itself installed. It removes only the task, owned listener/supervisor, owned Funnel port, and local bridge files.

## What the supervisor does

The supervisor:

- watches the local MCP endpoint;
- authenticates to verify the service identity;
- refuses to kill an unknown process on the configured port;
- starts Windows-MCP when it is missing;
- requires bearer auth;
- uses stateless HTTP;
- keeps FastMCP host-origin protection enabled;
- allowlists only the discovered Tailscale hostname + localhost;
- disables Windows-MCP anonymous telemetry for this runtime;
- bounds log growth by trimming large logs.

## Supported public Funnel ports

Use one of:

```text
443
8443
10000
```

Default: `8443`.

## Current status

```text
REAL-WORLD VERIFIED: one Windows machine
PUBLIC INSTALLER: implemented
CLEAN-MACHINE REPRODUCIBILITY: not yet proven
```

Do not upgrade that last line to "production ready" until the Phase 4 clean-machine test actually passes.
