# Phase 2B Checkpoint — Public Funnel Reality Test

Date: 2026-09-29

Branch: `feat/rafdi-remote-growth-stable`

Status: **ENGINEERING COMPLETE — isolated public path verified; new Composio Custom MCP creation remains a manual dashboard action.**

## Goal

Prove that the sanitized Phase 2A installer works through a real public Tailscale Funnel without touching the live Rafdi Remote Stable endpoint.

The isolated test used:

- a separate runtime directory;
- a separate Scheduled Task;
- local MCP port `28765`;
- public Funnel port `10000`;
- the existing Stable endpoint remained on its own listener and public HTTPS mapping.

No real bearer token is recorded in this document.

## Clean public-path flow verified

1. Removed only the stale isolated Funnel listener on public port `10000`.
2. Confirmed the live Stable listener remained online.
3. Ran the sanitized installer without `-SkipFunnel`.
4. Confirmed first run created local runtime, key, task, and supervisor but **did not silently publish** the machine.
5. Ran the exact Tailscale Funnel command printed by setup.
6. Confirmed isolated Funnel mapping pointed to the isolated local port.
7. Reran setup.
8. Verified public unauthenticated request was rejected.
9. Verified authenticated MCP initialize through the public endpoint.
10. Ran the package `test.ps1` suite successfully.

## Phase 2B bug found

Initial public requests reached the Windows machine but returned:

```text
400 Invalid host header
```

A one-request HTTP probe behind the isolated Funnel proved that Tailscale preserved the external host header, including the public HTTPS port.

The original installer already knew the correct public hostname, so the failure was not a Tailscale rewrite problem.

## Root cause

The actual installed stack on the GROWTH test machine was inspected:

```text
Windows-MCP 0.8.6
FastMCP 4.0.10
MCP 2.2.0
```

Windows-MCP 0.8.6 automatically creates its own Starlette `TrustedHostMiddleware` for loopback binds and computes this allowlist internally:

```text
localhost
127.0.0.1
[::1]
```

That middleware runs independently of the explicit FastMCP host-origin settings used by the installer, so the valid Tailscale public Host header was rejected before MCP authentication/session handling.

## Fix

The supervisor now launches Windows-MCP with its official:

```text
--allow-insecure-remote
```

flag **while still binding only to `127.0.0.1` and still requiring bearer authentication**.

This flag is used only to suppress Windows-MCP's hardcoded loopback TrustedHost middleware for the reverse-proxy case.

The package simultaneously keeps FastMCP protection enabled:

```text
FASTMCP_HTTP_HOST_ORIGIN_PROTECTION=true
FASTMCP_HTTP_ALLOWED_HOSTS=<explicit public + loopback allowlist>
```

Allowed hosts include exact and wildcard-port forms for:

- the discovered Tailscale DNS hostname;
- `localhost`;
- `127.0.0.1`.

The recipe remains invalid if loopback binding, bearer authentication, or FastMCP host-origin protection is removed.

## Public verification after fix

After restarting only the isolated Phase 2B runtime:

```text
LocalIdentity                PASS
Supervisor                   PASS
ScheduledTask                PASS
Tailscale                    PASS
Funnel                       PASS
PublicRejectsNoAuth          PASS
PublicAuthenticatedMcp       PASS
TEST_EXIT                    0
```

Setup itself also verified:

```text
Tailscale Funnel mapping: PASS
Public unauthenticated request rejected with HTTP 401: PASS
```

## External cloud proof

A Hyperbrowser session outside GROWTH fetched the isolated public endpoint with a unique no-cache URL.

The live endpoint returned an authorization error indicating that a Bearer token was required.

This proved the public Funnel was reachable from an external cloud client while unauthenticated access remained blocked.

An earlier `ok` response was produced intentionally by the temporary one-request header probe used to capture the forwarded Host header. That probe was removed before the final external verification, which used a unique URL and returned the real bearer-auth rejection from Windows-MCP.

## Recovery proof

### Scheduled Task / logon-style recovery

The isolated runtime was stopped cooperatively while leaving Funnel configuration intact.

Then the package Scheduled Task was started directly, exercising the same start action registered for Windows logon.

Observed:

```text
listener before recovery: off
Funnel mapping: still configured
Scheduled Task manually started: yes
listener after task start: on
task state after start: Ready
supervisor log: restarted and reported Windows-MCP online
live Stable listener: still online
```

### Supervisor child recovery

The verified isolated Windows-MCP child process was terminated while leaving the supervisor alive.

Observed:

```text
child PID before: 15240
child PID after: 8616
child PID changed: true
new child authenticated identity: true
public test suite after recovery: PASS
live Stable listener: still online
```

The public `test.ps1` suite passed again after both recovery exercises.

### Tailscale reconnect persistence

Because the Remote Desktop Commander shell was not elevated, a direct Windows service restart was attempted and correctly failed with an access-denied service-control error. The test did **not** bypass UAC or elevate itself.

Instead, Tailscale connectivity was explicitly cycled through its supported CLI:

```text
tailscale down: exit 0
tailscale up: exit 0
backend after reconnect: Running
stable Funnel 443 -> 18765: restored
isolated Funnel 10000 -> 28765: restored
stable listener 18765: online
isolated listener 28765: online
```

This proves stored login/config plus background Funnel state survived a tailnet disconnect/reconnect.

It does **not** claim that an actual Windows service restart was executed in this test.

### Cross-shell Windows detection fix

Remote Desktop Commander exposed another portability bug: its PowerShell host did not populate `$env:OS`, so the original Windows assertion rejected a real Windows session.

The shared helper now detects Windows using:

- PowerShell's `$IsWindows` variable when available;
- `$PSVersionTable.PSEdition -eq 'Desktop'` for Windows PowerShell;
- `$env:OS -eq 'Windows_NT'` as a fallback.

After refreshing the runtime helper, the complete public `test.ps1` suite passed from Remote Desktop Commander as well.

## Composio boundary

The existing Rafdi Remote GROWTH Stable connection already proves the production architecture:

```text
ChatGPT -> Composio Custom MCP -> Tailscale Funnel -> Windows-MCP
```

For the isolated Phase 2B endpoint, current Composio tools available in chat do not expose creation/editing of Composio's own Custom MCP entries. The available flow points to the Composio dashboard for creating a new Custom MCP.

Therefore:

- endpoint compatibility was verified at HTTP/MCP protocol level;
- the existing Stable Custom MCP proves the same integration architecture in real use;
- creating a second temporary Custom MCP entry for the isolated endpoint is a manual UI action and was not automated or faked.

## Phase 2B exit state

Engineering acceptance:

```text
PUBLIC FUNNEL PATH          PASS
UNAUTHENTICATED REJECTION   PASS
AUTHENTICATED MCP INIT      PASS
EXTERNAL CLOUD REACHABILITY PASS
LOGON-TASK RECOVERY         PASS
SUPERVISOR RECOVERY         PASS
STABLE ENDPOINT PRESERVED   PASS
```

Still not claimed:

- universal clean-machine reproducibility;
- zero-trust hardening;
- unattended Tailscale account/Funnel approval;
- unattended creation of a Composio Custom MCP entry.

Those are not silently inferred from this test.

## Cleanup proof

After all Phase 2B tests completed:

```text
safe uninstall / cooperative stop: PASS
isolated Scheduled Task present: false
isolated listener 28765 present: false
tailscale funnel --https=10000 off: exit 0
isolated public port 10000 present: false
live Stable listener 18765 present: true
```

The isolated runtime directory was deleted only after its task, listener, and public mapping were confirmed inactive.

The live Stable endpoint remained the only Funnel mapping after cleanup.

## Final repository validation

After cleanup and after adding the reverse-proxy regression guard:

```text
PowerShell scripts: 6/6 parse PASS
rendered supervisor template: PASS
setup.ps1 -WhatIf: exit 0
Node tests: 37/37 passed
benchmark: 4/4 passed
hygiene scanned files: 169
hygiene high: 0
hygiene medium: 0
skill audit: 29 skills, 0 errors, 0 warnings
private hostname/email/path/key-hash scan: 0 matches
```

The new regression tests explicitly require:

- loopback binding;
- bearer authentication;
- FastMCP host-origin protection;
- explicit allowed-host configuration;
- Windows-MCP reverse-proxy compatibility flag;
- explicit first-time Funnel publication;
- public-mode-only activation of the Windows-MCP reverse-proxy compatibility flag;
- cross-shell Windows detection that does not depend only on `$env:OS`.
