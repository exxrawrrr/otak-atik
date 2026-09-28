---
name: remote-desktop-bootstrap
description: Set up and verify a Remote Desktop Commander device-agent path without duplicating processes or confusing it with browser bridges.
status: stable
scope: provider
---

# Remote Desktop Bootstrap

Use when a user wants an AI client to reach a computer through Remote Desktop Commander.

## Required concepts

Remote path:

```text
AI client
→ hosted Remote MCP
→ paired device agent
→ computer
```

## Procedure

1. Confirm Node/npx availability on the target computer.
2. Check whether a Desktop Commander remote device-agent process is already running.
3. If not running, start the official command:
   `npx @wonderwhy-er/desktop-commander@latest remote`
4. Complete device pairing/OAuth if prompted.
5. Keep the agent process running.
6. Configure the AI client with:
   `https://mcp.desktopcommander.app/mcp`
7. Verify with a read-only operation first.

## Boundary

Do not tell the user MCP SuperAssistant is required for this path.

It is a separate optional browser bridge.
