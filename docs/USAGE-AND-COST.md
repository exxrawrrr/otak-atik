# Usage and cost strategy

otak-atik is designed to avoid routing every task through a paid or quota-limited remote transport.

## Desktop Commander remote limits

As of September 2026, Desktop Commander's published pricing lists:

- Free: 10,000 remote tool calls per month
- Pro: unlimited remote tool calls
- Local MCP server: free, open source, no monthly limit

Always verify the current pricing page before making a purchasing decision.

## Recommended hybrid model

```text
Away from the computer / mobile ChatGPT
→ Remote Desktop Commander remote MCP

At the computer / Codex / local MCP client
→ Desktop Commander local MCP

Browser AI with no convenient MCP connector
→ optional MCP SuperAssistant bridge

GUI/screenshot/mouse automation
→ evaluate QuickDesk or a Windows UI MCP provider
```

## Why this matters

Remote tool calls are most valuable when locality is the problem.

If both the AI client and the target project are already on the same computer, relaying every file read, directory listing, or test command through a hosted remote service is unnecessary overhead.

Use remote access for remote work.

Use local MCP for local work.

## Author's current practice

The setup that inspired this repository currently uses **Remote Desktop Commander much more often** than the older browser-extension bridge.

The browser bridge remains installed as an experimental/fallback path, but the cleaner Remote Desktop Commander flow became the normal ChatGPT workflow.

## Practical quota-saving rules

1. Use Codex/local MCP for repository-heavy work.
2. Use Remote Desktop Commander for phone/web access when you are away from the machine.
3. Avoid repeatedly listing huge folders remotely when one targeted search will do.
4. Read only the relevant file range instead of rereading entire large files.
5. Batch independent file reads when the provider supports it.
6. Prefer local scripts for repeated deterministic processing.
7. Do not keep an optional transport polling merely because it is installed.
8. Use skills to reduce exploratory tool-call thrashing.

## When Pro may be worth it

The paid remote tier becomes rational when:

- most work starts from web/mobile;
- 10,000 calls is routinely exhausted;
- the time saved is worth more than the subscription;
- a local-client workflow is not practical.

The project does not attempt to bypass provider limits.

It makes transport selection explicit so the limited remote path is used where it creates actual value.
