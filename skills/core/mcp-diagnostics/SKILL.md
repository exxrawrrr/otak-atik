---
name: mcp-diagnostics
description: Diagnose MCP connectivity, discovery, authentication, and tool availability failures.
status: stable
scope: generic
---

# MCP Diagnostics

Use when an MCP integration connects incorrectly, tools do not appear, authentication fails, or calls fail unexpectedly.

## Procedure

Diagnose in layers:

```text
client
→ configuration
→ transport
→ authentication
→ server health
→ tools/list or discovery
→ tool invocation
```

## Rules

- Separate transport failure from tool-schema failure.
- Do not rotate credentials merely because a tool call failed.
- Prefer health/status endpoints and read-only discovery first.
- Capture exact error categories without exposing secrets.
- Distinguish local endpoint, remote relay, and SaaS connector issues.
- Test one minimal tool invocation after discovery succeeds.

## Output

Report:

- failing layer;
- evidence;
- likely cause;
- lowest-risk correction;
- post-fix verification step.
