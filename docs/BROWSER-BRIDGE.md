# Browser bridge: MCP SuperAssistant

MCP SuperAssistant is an optional browser-side MCP bridge.

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

Conceptually:

```text
AI website
→ browser extension
→ localhost MCP proxy
→ local MCP server
→ computer/tool
```

## Why it existed in the original experiment

The setup that inspired otak-atik originally had a custom local stack:

```text
MCP SuperAssistant
→ localhost compatibility proxy
→ local full agent
→ Windows
```

That experiment proved that normal browser AI could be given local tools before the cleaner hosted Remote Desktop Commander path became the preferred route.

## Public setup

Public users should not reproduce the author's old private proxy.

otak-atik instead ships an example config for the upstream MCP SuperAssistant proxy:

```text
config/browser-bridge/mcp-superassistant.json
```

The config launches the normal local Desktop Commander MCP server.

Start the optional bridge with:

```text
Desktop/OTAK-ATIK/04 - START BROWSER BRIDGE - OPTIONAL.bat
```

The launcher uses:

```powershell
npx -y @srbhptl39/mcp-superassistant-proxy@latest --config <config> --outputTransport sse
```

The standard SSE endpoint is normally:

```text
http://localhost:3006/sse
```

Use the endpoint displayed by the proxy if upstream behavior changes.

## Is this required with Remote Desktop Commander?

No.

Remote Desktop Commander remote MCP and MCP SuperAssistant are separate access paths.

Use SuperAssistant when it solves a browser-client limitation.

Do not add it just because more MCP sounds more powerful.

## Security note

A browser extension with access to AI chat pages is a meaningful trust decision.

Review its permissions and upstream project before installing.

The otak-atik installer opens the official store page but does not install or approve the extension automatically.
