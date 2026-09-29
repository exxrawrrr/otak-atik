# 2026-09-29 — Remote MCP from ChatGPT to Windows

Result: **SUCCESSFUL EXPERIMENT, PACKAGING NOT YET PROVEN**

## Goal

Find a practical second remote path from ChatGPT to a Windows workstation that can run terminal commands and inspect files/processes without consuming the hosted Remote Desktop Commander path for every operation.

## Chronology

1. Confirmed Remote Desktop Commander as the existing baseline.
2. Revisited local Desktop Commander MCP: useful for local clients, not sufficient for ChatGPT-cloud-to-PC transport.
3. Verified Windows-MCP as the local Windows tool engine.
4. Investigated TRIGGERcmd as a possible remote command bridge.
5. Confirmed Composio could consume a custom HTTP MCP endpoint.
6. Started Windows-MCP as an HTTP MCP service.
7. Built a Cloudflare Quick Tunnel POC.
8. Hit a port-collision failure: the first tunnel reached an unrelated WordPress MCP.
9. Killed that tunnel and moved Windows-MCP to a dedicated port.
10. Hit FastMCP host-header/origin protection.
11. Added explicit host handling while retaining bearer authentication.
12. Registered the endpoint as a Composio Custom MCP.
13. Successfully executed terminal, filesystem, and process actions from ChatGPT.
14. Replaced temporary Quick Tunnel with Tailscale Funnel for a stable hostname.
15. Enabled Funnel once in the user's Tailscale account.
16. Added explicit Tailscale hostname allowlisting.
17. Verified unauthenticated public traffic returns `401`.
18. Added a watchdog supervisor and intentionally killed the MCP listener.
19. Verified the supervisor recovered it.
20. Restarted the Tailscale Windows service.
21. Verified Funnel persisted.
22. Added Windows logon auto-start through Scheduled Task and a Startup fallback.
23. Created a second Composio Custom MCP for the stable Tailscale path.
24. Verified stable PowerShell, filesystem, process, and GUI-capable schema.
25. Retired the temporary Cloudflare path.
26. Removed plaintext temporary setup files containing machine-local values.
27. Moved local manual controls away from the Desktop into an app-data project folder.

## Failure notes

### Wrong service on the first tunnel

The first Cloudflare Quick Tunnel landed on a port already serving a different MCP.

This is a real failure, not a footnote.

A remote-control setup must verify **service identity**, not merely "HTTP answered".

### Host-origin protection

A working tunnel still returned `421` until the MCP server explicitly trusted the intended public hostname.

Disabling host protection globally would have been the easy answer.

It was not the selected answer.

The final experiment retained host-origin protection and narrowed the host allowlist.

### Temporary URL ergonomics

Quick Tunnel worked but produced a temporary endpoint.

That makes a Composio Custom MCP annoying because a new tunnel URL means reconfiguring the app.

Tailscale Funnel was selected because the experiment needed a stable HTTPS hostname and persistence across service restarts.

## What "success" means here

Success means the author proved this exact chain on one real Windows machine:

```text
ChatGPT
→ Composio
→ authenticated stable HTTPS MCP endpoint
→ Windows-MCP
→ PowerShell / files / processes / GUI tools
```

It does not yet mean another user can clone this repository and get the same result automatically.

That is the next phase.

## Curhat singkat

Awalnya cuma:

> "gue pengen terminal PC bisa dijalanin dari ChatGPT."

Terus ketemu quota.

Terus nyari alternatif.

Terus bikin MCP lokal.

Terus bikin tunnel.

Terus tunnel pertama malah nyasar ke service WordPress.

**Jancok.**

Terus hostname ditolak.

Terus bikin auth.

Terus ganti tunnel lagi.

Terus bikin supervisor.

Terus bikin auto-start.

Dan setelah muter sejauh itu:

> **lah anjing, malah beneran jalan.**

Ini persis alasan failure log perlu disimpan.

Kalau cuma lihat arsitektur final, kelihatannya lurus.

Aslinya ora lurus blas.
