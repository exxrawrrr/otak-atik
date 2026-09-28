# Alternatives and complementary projects

otak-atik is intentionally not a full remote-desktop implementation.

## Remote Desktop Commander

https://github.com/desktop-commander/remote-desktop-commander

Best current fit for:

- remote filesystem;
- terminal;
- process management;
- search/edit operations;
- ChatGPT/Claude/Cursor/VS Code-style remote MCP clients.

**otak-atik default remote path.**

## MCP SuperAssistant

https://github.com/srbhptl39/MCP-SuperAssistant

Best fit for:

- browser AI interfaces;
- local MCP bridging;
- experimentation where a site has no convenient native MCP connector.

**Optional compatibility path.**

## QuickDesk

https://github.com/barry-ran/QuickDesk

QuickDesk focuses on AI-native remote desktop with a built-in MCP server and GUI-control capabilities such as screenshots, mouse, keyboard, and remote hosts.

Interesting when the task requires **computer-use/UI automation**, not just filesystem and shell operations.

otak-atik treats QuickDesk as an experimental complementary provider rather than the default remote transport.

## Windows MCP Server

https://github.com/deploymenttheory/windows-mcp-server

A Windows-focused MCP server with deep UI automation/system capabilities.

Useful for advanced Windows automation where accessibility-tree/UI operations matter.

It has a broader system-control surface, so security review and isolation matter even more.

## Selection rule

Prefer the smallest provider that satisfies the job.

```text
files + terminal remotely
→ Remote Desktop Commander

browser-site MCP bridge
→ MCP SuperAssistant

screenshots + mouse + keyboard
→ QuickDesk

deep Windows UI/system automation
→ Windows MCP Server
```
