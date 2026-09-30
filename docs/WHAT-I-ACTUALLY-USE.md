# What I actually use

This page exists because the machine accumulated multiple MCP, browser, tunnel, and remote-control experiments. Installed does not mean required.

## 1. Primary remote path — Remote Desktop Commander

Most day-to-day remote work still uses:

```text
ChatGPT
→ Remote Desktop Commander
→ GROWTH
```

This remains the quickest route when the job is simply:

- inspect files;
- run PowerShell;
- inspect processes;
- patch a project;
- troubleshoot the Windows machine.

That convenience is also why the original "replace the plugin" goal is still considered failed.

## 2. Backup / self-built path — Rafdi Remote

The self-built route is now:

```text
ChatGPT
→ Composio Custom MCP
→ Tailscale Funnel
→ Windows-MCP
→ GROWTH
```

This started as a quota-pressure backup experiment and became a usable second path.

It has been verified against:

- bearer auth;
- public Funnel transport;
- unauthenticated rejection;
- authenticated MCP initialize;
- supervisor recovery;
- Scheduled Task recovery;
- Tailscale reconnect;
- real Windows reboot;
- post-restart ChatGPT command execution.

The Stable runtime listens locally on loopback and is not intended to expose Windows-MCP directly to the LAN.

See:

- `RAFDI-REMOTE-GROWTH.md`
- `RAFDI-REMOTE-GROWTH-PHASE-2B-CHECKPOINT.md`
- `../experiments/rafdi-remote-growth/README.md`

## 3. Local engineering — Desktop Commander local MCP

When the AI client and Windows machine are already local:

```text
Codex / local AI
→ Desktop Commander local MCP
→ Windows
```

There is little value in sending a local task through a remote relay when a local MCP path is available.

Example:

```powershell
codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest
```

## 4. MCP SuperAssistant — historical / partial failure

The Chrome-extension experiment remains documented because it taught useful lessons.

The historical stack looked roughly like:

```text
MCP SuperAssistant
→ local compatibility proxy
→ local agent
→ Windows
```

During inspection, discovery traffic worked, but reliable normal `tools/call` execution was not proven as a daily path.

Status:

```text
PARTIAL_FAILURE
```

Do not rebuild this historical complexity unless you specifically need the browser experiment.

## Current decision rule

Use:

```text
REMOTE + FASTEST PATH
→ Remote Desktop Commander

REMOTE + SELF-BUILT BACKUP
→ Rafdi Remote

LOCAL ENGINEERING
→ Desktop Commander local MCP

BROWSER EXPERIMENT
→ MCP SuperAssistant only when intentionally testing it
```

## Why keep multiple paths?

Because each one solves a different failure mode.

Remote Desktop Commander is convenient but has hosted-service/quota considerations.

Rafdi Remote reduces dependence on that single path, but it adds Tailscale, Windows-MCP, authentication, and operational responsibility.

Local MCP is simpler when the work is already local.

The rule is not "always use the custom thing."

The rule is:

> use the least complicated path that still gives the required capability and verification.

## Current recommendation for new users

If you only want practical remote control, start with the simplest provider that already works for you.

If you specifically want to reproduce the Rafdi Remote experiment, read the installer README and security ADR first.

Do not copy private machine names, bearer keys, Tailscale identities, or local paths from somebody else's setup.

And do not recreate every historical experiment just because it exists in this repository.
