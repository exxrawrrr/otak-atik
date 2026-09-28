# Which setup should I use?

Do not install every integration by default.

Use the smallest transport that solves your access problem.

## Decision tree

```text
Do you want AI access to the computer from ChatGPT web/mobile
or another client that supports remote MCP?
    |
    +-- YES --> Remote Desktop Commander
    |
    +-- NO
         |
         |-- Are you using a browser AI site with no convenient MCP connector?
         |      |
         |      +-- YES --> MCP SuperAssistant browser bridge
         |
         |-- Do you need screenshots + mouse/keyboard GUI control?
                |
                +-- YES --> evaluate QuickDesk or a Windows UI MCP server
```

## Recommended default

Use **Remote Desktop Commander**.

It is the cleanest path for remote filesystem, terminal, search, editing, and process operations from clients that support remote MCP.

## When MCP SuperAssistant is useful

MCP SuperAssistant is useful when:

- the AI experience lives in a browser;
- the site itself does not expose the MCP connector you want;
- you want the extension to detect/execute tool calls and bridge them to a local proxy.

It is **not required** simply because Remote Desktop Commander is installed.

## Can both run together?

Yes.

They are independent paths.

Running both can be useful for experimentation or multi-client access, but it also increases the number of moving parts.

If one path already works, adding the second path should solve a concrete need.
