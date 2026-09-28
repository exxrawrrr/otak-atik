# Usage and cost strategy

otak-atik is designed to avoid routing every task through a quota-limited remote transport.

Official current references:

- Desktop Commander pricing: https://desktopcommander.app/pricing/
- Desktop Commander local MCP: https://github.com/wonderwhy-er/DesktopCommanderMCP
- Remote Desktop Commander: https://github.com/desktop-commander/remote-desktop-commander

## Desktop Commander remote limits

As of September 2026, Desktop Commander's published pricing lists:

- **Free:** 10,000 remote tool calls per month
- **Pro:** $20/month, unlimited remote tool calls
- **Local MCP server:** free/open-source, no account and no monthly tool-call limit

Pricing can change. Check the official page before purchasing.

## Recommended hybrid model

```text
Away from the computer / mobile ChatGPT
→ Remote Desktop Commander remote MCP

At the computer / Codex / local MCP client
→ Desktop Commander local MCP

Browser AI with no convenient MCP connector
→ optional MCP SuperAssistant bridge

GUI/screenshot/mouse automation
→ evaluate QuickDesk or another computer-use MCP provider
```

## Author's current practice

The original setup now uses **Remote Desktop Commander more often** than the browser-extension route.

That convenience has a tradeoff: the hosted free remote path has a monthly tool-call ceiling.

So the recommended evolution is not to abandon Remote Desktop Commander.

It is to stop using remote relay for work that is already local.

## Quota-saving rules

1. **Codex/local client → local MCP.**
2. **Phone/outside PC → remote MCP.**
3. Prefer targeted search over giant recursive listings.
4. Read relevant ranges instead of repeatedly rereading whole large files.
5. Batch independent reads when available.
6. Run deterministic bulk processing locally in one script.
7. Avoid repeated status checks without a state change.
8. Use skill routing so the agent explores less blindly.
9. Keep the browser bridge off unless you actually need it.
10. Do not weaken verification just to save calls.

## What this does not do

otak-atik does not bypass, spoof, or evade provider quotas.

It chooses a more appropriate transport.

## When Pro makes sense

Pro can be rational when most of your real work begins from ChatGPT/Claude web or mobile and remote access itself is the value.

If the majority of the workload is coding on the same PC, local MCP is usually the first optimization to make.
