# What the original setup actually uses

This page exists because the first version of the setup accumulated multiple MCP components and it became easy to confuse **installed** with **required**.

## Primary path today

The author primarily uses:

```text
ChatGPT
→ Remote Desktop Commander
→ paired Windows machine
```

The device agent is started with:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

This is the path used most often.

## The Chrome extension

The installed extension is:

```text
MCP SuperAssistant
Extension ID:
kngiafgkdnlkgmefdafaibkibegkcaef
```

It belongs to the older browser-bridge experiment.

The original machine also has an older local stack that historically looked like:

```text
MCP SuperAssistant
→ localhost:3007 compatibility proxy
→ localhost:8789 local agent
→ Windows
```

## Is the extension actually doing anything?

On the original machine, the local proxy still receives repeated MCP discovery traffic such as `tools/list`.

However, during a September 28, 2026 inspection, the proxy log showed **no `tools/call` entries** in the checked log history.

Interpretation:

- the bridge is still alive enough to discover tools;
- it is not the primary path currently executing the author's normal work;
- Remote Desktop Commander is the active daily-use path.

This may change if the browser bridge is intentionally used again.

## Recommendation for new users

Start with Remote Desktop Commander only.

Add MCP SuperAssistant only if you have a browser-specific reason.

Do not recreate historical complexity for nostalgia.
