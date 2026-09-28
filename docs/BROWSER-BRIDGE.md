# Browser bridge: MCP SuperAssistant

MCP SuperAssistant is an **optional** browser-side MCP bridge.

Chrome Web Store:

https://chromewebstore.google.com/detail/mcp-superassistant/kngiafgkdnlkgmefdafaibkibegkcaef

Upstream:

https://github.com/srbhptl39/MCP-SuperAssistant

Extension ID:

```text
kngiafgkdnlkgmefdafaibkibegkcaef
```

## What it does

The extension integrates with supported AI websites and can forward MCP tool execution through a local proxy.

```text
AI website
→ browser extension
→ localhost MCP proxy
→ local MCP server
→ computer/tool
```

## Why it existed in the original experiment

The setup that inspired otak-atik originally had:

```text
MCP SuperAssistant
→ localhost:3007 compatibility proxy
→ localhost:8789 local full agent
→ Windows
```

That experiment predates the author's normal use of the cleaner hosted Remote Desktop Commander path.

## Is it still used on the original machine?

Yes, but not as the main execution route.

During a September 28, 2026 inspection:

- MCP SuperAssistant v0.6.0 was installed in Chrome;
- the old localhost proxy was still listening;
- its log showed repeated MCP discovery traffic such as `tools/list`;
- no `tools/call` entry was found in the checked proxy log history;
- Remote Desktop Commander was the author's primary working path.

That is strong evidence that the extension remains an active/fallback experiment rather than the normal tool-execution route.

## Public setup

Public users should **not** reproduce the author's private legacy proxy.

otak-atik ships a cleaner config:

```text
config/browser-bridge/mcp-superassistant.json
```

It launches the standard local Desktop Commander MCP server.

Start it through:

```text
Desktop/OTAK-ATIK/04 - START BROWSER BRIDGE - OPTIONAL.bat
```

Under the upstream MCP SuperAssistant documentation, the proxy command is:

```powershell
npx -y @srbhptl39/mcp-superassistant-proxy@latest --config <config> --outputTransport sse
```

The standard SSE endpoint is:

```text
http://localhost:3006/sse
```

Streamable HTTP can instead use:

```text
http://localhost:3006/mcp
```

Always use the endpoint printed by the current proxy version.

## Known reliability caveat

MCP SuperAssistant is useful, but it is a browser-injection compatibility layer and has more moving parts than a native MCP connection.

As of 2026, its public issue tracker includes reports around:

- tools being detected by the proxy but not appearing correctly in the extension UI;
- ChatGPT function-call cards rendering while Run/Auto Execute does not reliably produce `tools/call`;
- SSE reconnect behavior.

That does not mean the project is unusable.

It does mean otak-atik should not present it as the default path when a native MCP route is available.

## Is this required with Remote Desktop Commander?

**No.**

Remote Desktop Commander remote MCP and MCP SuperAssistant are separate paths.

Use SuperAssistant only when it solves a browser-client limitation.

## Security note

A browser extension with access to AI chat pages is a meaningful trust decision.

Review its permissions and upstream project before installing.

The otak-atik installer opens the official store page but does not install or approve the extension automatically.
