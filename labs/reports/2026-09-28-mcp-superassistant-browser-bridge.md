# Experiment report — MCP SuperAssistant browser bridge

**Date:** 2026-09-28  
**Machine:** original Windows GROWTH setup  
**Result:** **PARTIAL FAILURE / NOT RELIABLE ENOUGH AS PRIMARY PATH**

## Why this report exists

The author originally experimented with a Chrome browser-extension path so normal web AI could reach local MCP tools.

The experiment was useful, but it did not become the dependable daily path.

This repo records that failure instead of rewriting history after a cleaner solution appeared.

## Topology tested

```text
AI website in Chrome
→ MCP SuperAssistant
→ localhost:3007 compatibility proxy
→ localhost:8789 local full agent
→ Windows
```

Installed extension:

```text
MCP SuperAssistant v0.6.0
Chrome extension ID:
kngiafgkdnlkgmefdafaibkibegkcaef
```

## What worked

Direct inspection on the original machine confirmed:

- extension installed;
- compatibility proxy listening on port 3007;
- local full agent listening on port 8789;
- MCP `initialize` requests reached the proxy;
- repeated `tools/list` requests reached the proxy;
- the local MCP stack advertised 53 tools.

So this was not a completely dead setup.

Discovery worked.

## What failed or remained unproven

The inspected proxy log contained repeated discovery traffic but no `tools/call` entry in the checked history.

That means we could prove:

```text
browser/client
→ discovery
→ proxy
→ local agent
```

but we could not prove from the inspected history that this path was reliably executing the author's actual day-to-day tool actions.

Operationally, the author also stopped choosing this path for normal work and moved to Remote Desktop Commander.

## Honest conclusion

This is a **partial failure**, not a universal verdict on MCP SuperAssistant.

The failure is:

> the author's specific browser-bridge experiment did not become reliable/simple enough to serve as the primary workflow.

It still has research value and remains useful as a fallback for browser-only clients.

## What replaced it

```text
ChatGPT / remote client
→ Remote Desktop Commander hosted Remote MCP
→ paired device agent
→ Windows
```

This reduced custom proxy plumbing and became the author's normal route.

## Lessons incorporated into otak-atik

1. Installed does not mean required.
2. Tool discovery does not prove tool execution.
3. Every transport needs an end-to-end verification check.
4. Fewer hops are usually easier to debug.
5. Failed experiments belong in the repository.
6. Provider integration should be replaceable.
7. The project's value must live above the provider layer.

## Current status

Keep MCP SuperAssistant as:

- optional;
- experimental;
- browser-compatibility fallback;
- a useful test target for the transport lab.

Do not require it in the default onboarding path.
