---
name: remote-usage-optimizer
description: Reduce unnecessary remote MCP tool calls without weakening verification or hiding provider limits.
status: stable
scope: generic
---

# Remote Usage Optimizer

Use when a remote MCP service has a tool-call quota or when latency makes exploratory calls expensive.

## Principles

- Optimize workflow shape, not provider accounting.
- Do not bypass or evade provider limits.
- Preserve verification.

## Techniques

1. Prefer targeted search to broad recursive listing.
2. Read relevant ranges instead of entire large files.
3. Batch independent reads when the tool supports it.
4. Use one local script for repeated deterministic transformations.
5. Cache stable project facts inside the working session.
6. Avoid checking the same status repeatedly without a state change.
7. Route local-client work to local MCP.
8. Reserve remote transport for actual remote-access value.

## Bad optimization

Do not skip required checks merely to save calls.

Fewer wrong calls are better than fewer total calls.
