# Remote Desktop Commander

Remote Desktop Commander is the recommended remote transport for otak-atik.

Official project:

https://github.com/desktop-commander/remote-desktop-commander

Remote MCP endpoint:

```text
https://mcp.desktopcommander.app/mcp
```

## Device side

Run on the computer the AI should reach:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

The command starts the device agent and may open an OAuth device-pairing flow.

Keep the process running while remote access is required.

## Why the launcher exists

Typing the npx command every time is technically simple and operationally annoying.

The Windows installer creates:

```text
01 - START REMOTE DESKTOP.bat
```

The underlying PowerShell script:

- detects an existing matching process;
- avoids starting duplicates;
- verifies Node/npx availability;
- starts the same official npx command.

No private fork of Desktop Commander is required.

## ChatGPT

For ChatGPT versions/plans that support custom remote MCP connectors, add:

```text
https://mcp.desktopcommander.app/mcp
```

and complete OAuth.

The Chrome MCP SuperAssistant extension is not required for this route.

## Codex

Codex can use local engineering tools directly and can also participate in MCP-based workflows depending on the selected environment/configuration.

The author has used otak-atik-style workflows with both ChatGPT and Codex.

The browser extension is irrelevant to a non-browser Codex workflow.

## Trust boundary

Desktop tools execute with the user's machine permissions.

Treat the connected AI account and remote-MCP authorization as privileged access.

Use a restricted workspace profile unless broader access is actually required.
