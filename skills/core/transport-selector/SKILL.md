---
name: transport-selector
description: Choose the smallest AI-to-computer transport that satisfies locality, client, GUI, and quota requirements.
status: stable
scope: generic
---

# Transport Selector

Use when multiple MCP/remote/local paths are available.

## Decision order

1. Is the AI client already running locally on the target computer?
   - Prefer local MCP.
2. Is the user connecting from web/mobile/another device?
   - Prefer a remote MCP transport.
3. Is the AI only available through a browser site with no native connector?
   - Consider a browser bridge.
4. Does the task require screenshots, mouse, or keyboard interaction?
   - Select a GUI-control provider.

## Cost/usage rule

Do not spend quota-limited remote calls for local work unless there is a concrete reason.

## Reliability rule

Prefer fewer hops.

```text
local client → local MCP
```

is simpler than:

```text
local client → hosted relay → local device
```

when remote access provides no benefit.

## Output

State:

- selected transport;
- why;
- what alternative was rejected;
- any quota/security tradeoff.
