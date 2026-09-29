# Composio Custom MCP example

After `setup.ps1` succeeds, get the URL from:

```powershell
.\status.ps1
```

Expected shape:

```text
https://<machine>.<tailnet>.ts.net:8443/mcp
```

Create a new Custom MCP in Composio.

Recommended fields:

```text
Name: Rafdi Remote <MACHINE>
Transport: HTTP / Streamable HTTP
MCP URL: https://<machine>.<tailnet>.ts.net:8443/mcp
Authentication: Bearer
Token: contents of %LOCALAPPDATA%\OtakAtik\RafdiRemote\auth.key
```

The token is intentionally not printed by the installer.

If you need it in your clipboard without displaying it:

```powershell
Get-Content -Raw "$env:LOCALAPPDATA\OtakAtik\RafdiRemote\auth.key" | Set-Clipboard
```

Then paste it directly into the Composio authentication field.

## Verify after connecting

The connected MCP should expose tools such as:

- PowerShell;
- FileSystem;
- Process;
- Screenshot;
- Snapshot;
- App;
- Clipboard;
- Click;
- Type;
- Scroll;
- Shortcut.

A harmless first smoke test:

```text
hostname
whoami
Get-Location
```

## Do not post

When opening issues, redact:

- bearer key;
- Composio account/connection credentials;
- Tailscale account invitation links;
- screenshots containing tokens;
- unrelated private machine/user data.

The stable Funnel hostname is not an authentication secret, but publishing it unnecessarily increases exposure. Redact it unless it is needed to diagnose routing.
