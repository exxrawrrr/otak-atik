# Rafdi Remote GROWTH — Experiment Evidence

Status: **REAL-WORLD VERIFIED ON ONE WINDOWS MACHINE**

Date frozen: **2026-09-29**

This document records what was actually attempted while trying to reach a Windows PC from ChatGPT without burning the hosted Remote Desktop Commander quota for every terminal/file task.

It is not a claim that the setup is universally production-ready.

## The problem

The daily requirement was simple to say and annoyingly non-simple to implement:

```text
ChatGPT on another device
        ↓
reach Windows PC over the internet
        ↓
run PowerShell / terminal
read and edit files
inspect processes
optionally interact with the GUI
        ↓
survive restart/login without rebuilding the tunnel
```

Remote Desktop Commander already handled much of this well, but the hosted remote path had a usage limit. The experiment started as an attempt to preserve that quota and find a second usable path.

## What was tried

### 1. Remote Desktop Commander

Status: **WORKING / EXISTING BASELINE**

This was the known-good baseline.

It provided remote filesystem and terminal access from ChatGPT to the Windows machine.

The problem was not that it failed. The problem was that relying on it for every local operation consumed the hosted remote quota.

### 2. Local Desktop Commander MCP

Status: **WORKING LOCALLY / NOT THE CHATGPT REMOTE ANSWER**

A local Desktop Commander MCP was tested successfully.

That solves:

```text
local AI client
→ local MCP
→ local Windows machine
```

It does not, by itself, solve:

```text
ChatGPT cloud chat
→ internet
→ local Windows MCP
```

Useful component. Wrong transport boundary for this exact problem.

### 3. Windows-MCP

Status: **WORKING COMPONENT**

CursorTouch/Windows-MCP was installed and tested on Windows.

Verified capabilities included:

- PowerShell;
- filesystem;
- process inspection;
- screenshots/snapshots;
- app/window operations;
- clipboard;
- later, click/type/scroll/move/shortcut/wait tools.

This became the local computer-control engine.

### 4. TRIGGERcmd

Status: **CONSIDERED / NOT SELECTED**

TRIGGERcmd was investigated as a remote-command alternative.

It could have provided command triggering through a connected agent, but the model was less direct than exposing a real MCP toolset and had rate-limit/command-registration tradeoffs for this workflow.

It was not selected as the final path.

### 5. Windows-MCP + Cloudflare Quick Tunnel + Composio Custom MCP

Status: **WORKED AS A PROOF OF CONCEPT / RETIRED**

This was the first end-to-end success:

```text
ChatGPT
→ Composio
→ Custom MCP
→ Cloudflare Quick Tunnel
→ Windows-MCP
→ Windows PC
```

Verified from ChatGPT through the custom MCP:

- `hostname`;
- `whoami`;
- PowerShell execution;
- filesystem listing;
- process listing.

#### Failure worth keeping

The first Quick Tunnel attempt targeted a port already occupied by an unrelated WordPress MCP.

Result: the public tunnel reached the wrong service.

That tunnel was immediately killed.

This failure is important because it demonstrates why remote MCP publication needs explicit port ownership checks and service identity verification before considering an endpoint safe.

A second issue appeared when FastMCP host-origin protection rejected the external tunnel hostname. That was fixed with an explicit hostname allowlist while keeping bearer authentication enabled.

Quick Tunnel proved the architecture but had an operational problem: the generated hostname was temporary. Restarting/recreating the tunnel could require a new URL and another Composio configuration.

### 6. Tailscale Funnel

Status: **SELECTED FINAL TRANSPORT FOR THIS EXPERIMENT**

Tailscale was installed and authenticated once.

A Funnel was configured in background mode to proxy HTTPS traffic to the loopback-only Windows-MCP listener.

Final architecture:

```text
ChatGPT
   ↓
Composio Custom MCP
   ↓
stable Tailscale Funnel HTTPS endpoint
   ↓
Windows-MCP bound to 127.0.0.1
   ↓
PowerShell / filesystem / process / GUI tools
   ↓
Windows PC
```

The public hostname from the real test machine is intentionally not published here. Public setup must discover the user's own Tailscale DNS name.

## Security controls actually verified

The experiment ended with these controls:

- Windows-MCP bound to `127.0.0.1`, not a public LAN interface;
- public ingress provided by Tailscale Funnel;
- bearer authentication required by Windows-MCP;
- FastMCP host-origin protection enabled;
- explicit allowlist containing the machine's Tailscale hostname plus localhost;
- bearer key stored in a machine-local file excluded from publication;
- no bearer key embedded in repository templates;
- unauthenticated public endpoint test returned HTTP `401`;
- temporary Cloudflare Quick Tunnel was removed after migration;
- plaintext setup note containing the key was deleted.

## Reliability checks actually performed

The following were not hypothetical:

- Windows-MCP listener was intentionally killed;
- supervisor detected the failure and brought it back;
- Tailscale Windows service was restarted;
- Funnel remained configured and returned;
- stable Custom MCP executed PowerShell after migration;
- stable Custom MCP listed files;
- stable Custom MCP listed processes;
- Windows Scheduled Task auto-start was manually invoked;
- Scheduled Task returned result `0`;
- supervisor remained running;
- Funnel remained on.

## Final verified tool surface

The stable custom MCP exposed:

- PowerShell;
- FileSystem;
- Process;
- Snapshot;
- Screenshot;
- DisplayInventory;
- App;
- Clipboard;
- Click;
- Type;
- Scroll;
- Move;
- Shortcut;
- Wait;
- WaitFor.

## Evidence labels

| Component | Result |
|---|---|
| Remote Desktop Commander | working baseline |
| Local Desktop Commander MCP | working locally |
| Windows-MCP | working |
| TRIGGERcmd | investigated, not selected |
| Cloudflare Quick Tunnel | working POC, retired |
| Composio Custom MCP | working |
| Tailscale Funnel | working, selected |
| Bearer auth | verified |
| Host allowlist | verified |
| Supervisor recovery | verified |
| Tailscale service persistence | verified |
| Windows Scheduled Task startup | verified |
| Generic clean-machine installer | **not yet built** |
| Multi-user reproducibility | **not yet proven** |

## The useful conclusion

The original repo used to end with:

```text
ChatGPT
→ Remote Desktop Commander
→ Windows
```

After this experiment, there is now a second path that was actually exercised:

```text
ChatGPT
→ Composio
→ Tailscale Funnel
→ Windows-MCP
→ Windows
```

That is a meaningful result.

It does **not** mean the project should pretend the hard parts disappeared.

The remaining work is packaging the machine-specific experiment into a safe, idempotent setup that another person can run without copying the author's hostname, paths, or secrets.
