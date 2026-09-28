---
name: mcp-topology-diagnoser
description: Map a multi-hop MCP setup and identify exactly which transport layer is failing.
status: stable
scope: generic
---

# MCP Topology Diagnoser

Use when a setup contains multiple MCP servers, proxies, relays, extensions, or clients and the user no longer knows which component is actually in use.

## Method

Draw the real topology first.

Example:

```text
client
→ extension?
→ proxy?
→ remote relay?
→ local MCP server?
→ operating system
```

For each hop record:

- process or service;
- transport;
- endpoint;
- authentication boundary;
- expected health signal;
- whether the hop is required or optional.

Then test one hop at a time.

## Output

Return:

- active path;
- redundant path;
- failed hop;
- evidence;
- smallest correction.

Never assume that two installed MCP components depend on each other merely because both are running.
