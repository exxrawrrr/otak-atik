---
name: local-mcp-bootstrap
description: Configure Desktop Commander as a local stdio MCP server for local AI clients such as Codex.
status: stable
scope: provider
---

# Local MCP Bootstrap

Use when the AI client and target machine are local.

## Standard Desktop Commander command

```text
npx -y @wonderwhy-er/desktop-commander@latest
```

## Codex

Preferred setup:

```text
codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest
```

Equivalent TOML:

```toml
[mcp_servers.desktop-commander]
command = "npx"
args = ["-y", "@wonderwhy-er/desktop-commander@latest"]
```

## Why

The local MCP server is the appropriate path when remote relay provides no locality benefit.

It also avoids consuming hosted Remote Desktop Commander tool-call quota.

## Verification

After configuration, ask the local client to perform one safe read-only Desktop Commander operation.
