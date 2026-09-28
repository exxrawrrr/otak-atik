---
name: browser-mcp-bridge
description: Configure and diagnose the optional MCP SuperAssistant browser-extension path to local MCP servers.
status: incubating
scope: provider
---

# Browser MCP Bridge

Use when an AI website is being extended through MCP SuperAssistant.

## Topology

```text
AI website
→ MCP SuperAssistant extension
→ local proxy
→ local MCP server
```

## Procedure

1. Confirm the browser extension is installed.
2. Confirm the local proxy process is running.
3. Confirm the proxy's actual endpoint.
4. Confirm its config launches or connects to the intended MCP server.
5. Configure the extension with the displayed endpoint.
6. Run a read-only tool first.
7. Separate extension problems from proxy problems from MCP-server problems.

## Boundary

Do not represent this path as mandatory when the AI client already supports the required MCP connection natively.
