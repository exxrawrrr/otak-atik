---
name: mcp-config-auditor
description: Validate MCP JSON configuration structure and highlight common command, URL, args, env, and inline-secret mistakes.
status: stable
scope: generic
---

# MCP Config Auditor

Use when an MCP server "should be configured" but the client fails to load it.

## Preferred tool

```text
otak-atik mcp-check <config.json>
```

## Checks

- valid JSON;
- mcpServers object;
- command or URL presence;
- args shape;
- env shape;
- invalid URL;
- remote plain HTTP warning;
- likely sensitive inline env values.

Use this before blaming the MCP server itself.
