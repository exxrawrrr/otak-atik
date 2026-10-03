# Composio + Tailscale User Setup UX

Status: **CHAT 3 — UX CONTRACT IMPLEMENTED; STATUS/REPAIR + FRESH-MACHINE RELEASE GATES PENDING**  
Owner branding: **Created by Rafdi D. Ulhaq — exxrawrrr**  
Target platform: **Windows 10/11**  
Primary route:

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Tailscale Funnel
  ↓
Remote GROWTH Stable Gateway
  ↓
64 tools
  ↓
Windows
```

## Goal

A non-technical user should be able to prepare the Remote GROWTH + Composio route without needing to understand MCP, ports, bearer headers, tunnels, host allowlists, or PowerShell internals.

The user may still perform account-owned actions that should remain human-controlled:

1. sign in to Tailscale;
2. sign in to Composio;
3. approve/connect the Custom MCP entry;
4. return to the setup wizard when asked.

Everything else should be detected, generated, opened, copied, validated, or repaired by the installer whenever it is safe to do so.

## Product rule

> If the user needs to read the repository README to know what to click next, onboarding has failed.

The default experience must be guided from the terminal itself.

## What the user should see

The setup should look like a small branded application running in the terminal, not like a raw PowerShell script.

Required brand header:

```text
╔══════════════════════════════════════════════╗
║                  OTAK-ATIK                   ║
║            Remote AI Setup Wizard            ║
║                                              ║
║   Created by Rafdi D. Ulhaq — exxrawrrr     ║
╚══════════════════════════════════════════════╝
```

Required status vocabulary:

```text
[OK]    completed
[WAIT]  waiting for the user
[FIX]   installer can repair it
[INFO]  explanatory only
[FAIL]  cannot safely continue
```

Do not expose internal stack traces or raw command output by default. Detailed diagnostics may be written to a local log and shown only through an advanced/details action.

## UX principles

### 1. Human words first

Do not say:

```text
Configure a bearer Authorization header for the MCP transport.
```

Say:

```text
Your secure access code is ready.
We will copy it when you need it.
```

Do not say:

```text
ECONNREFUSED 127.0.0.1:18768
```

Say:

```text
Remote GROWTH is not running yet.

[FIX] Repair automatically
```

### 2. One decision per screen

A user should never face a menu of transport choices during the normal Composio setup path.

The installer owns the known-good default architecture.

### 3. The user owns identity

The installer must never silently sign in to Tailscale, Composio, ChatGPT, or another account.

Browser login and OAuth approval remain user actions.

### 4. Secrets stay local

Credentials must not be printed permanently into logs, committed to Git, or embedded into public source files.

When a credential must be copied:

- show a masked form in the terminal;
- provide a copy action;
- avoid echoing plaintext again after the step is complete;
- store only according to the project security contract.

### 5. Verification before celebration

Do not show "Setup complete" because a browser page was opened or because a process exited with code 0.

The final screen requires real checks of the local gateway, transport, authentication boundary, and MCP tool discovery.

---

# Normal user journey

## STEP 0 — Welcome

User action:

```text
Double-click START.cmd
```

Screen:

```text
OTAK-ATIK
Remote AI Setup Wizard

Created by Rafdi D. Ulhaq — exxrawrrr

This setup will prepare your computer so ChatGPT can
reach approved Remote GROWTH tools through Composio.

You will only need to sign in to your own accounts
when we open them.

[ENTER] Start setup
[Q]     Exit
```

No technical architecture explanation is required on this screen.

## STEP 1 — Computer check

The wizard checks automatically:

- supported Windows version;
- PowerShell availability;
- Node.js requirement;
- Git availability when required by the chosen install route;
- Tailscale installation;
- required local Remote GROWTH files/runtime;
- whether an existing installation can be reused;
- port ownership before starting a gateway;
- whether another unrelated MCP/service is already using the intended port.

Example:

```text
STEP 1 OF 5 — Checking your computer

[OK] Windows 11
[OK] PowerShell
[OK] Node.js
[OK] Git
[FIX] Tailscale needs to be installed
[OK] Remote GROWTH files

We can fix 1 item automatically.

[ENTER] Continue
```

If a safe dependency can be installed automatically, the user should not be sent to hunt for downloads manually unless automation is unavailable or requires explicit elevation.

## STEP 2 — Connect Tailscale

The wizard must distinguish these states:

```text
NOT_INSTALLED
INSTALLED_NOT_RUNNING
RUNNING_NOT_LOGGED_IN
CONNECTED
FUNNEL_NOT_READY
READY
```

Normal screen:

```text
STEP 2 OF 5 — Secure connection

Tailscale needs your account login.

We will open the correct page/app.
Sign in, then return here.

[ENTER] Open Tailscale
```

After opening the login flow, the wizard should poll/re-check local Tailscale state instead of asking the user to diagnose it.

After login:

```text
Checking connection...

[OK] Tailscale running
[OK] Account connected
[OK] This device is available

Preparing the secure connection...

[OK] Remote GROWTH local service
[OK] Port ownership verified
[OK] Tailscale route prepared
```

The word **Funnel** does not need to appear in the default user view.

An advanced diagnostics view may show it.

## STEP 3 — Prepare Remote GROWTH

The wizard handles:

- selecting the project-owned local port;
- verifying the expected service identity on that port;
- generating or loading the user's own bearer credential;
- configuring the expected host/origin allowlist;
- starting/supervising the Remote GROWTH gateway;
- preparing Tailscale Funnel to the correct loopback target;
- deriving the user's own public MCP endpoint;
- ensuring secrets are outside Git.

Required pre-Composio checks:

```text
Local gateway responds               PASS
Expected service identity            PASS
Public endpoint reachable            PASS
Request without credential           DENIED
Request with credential              PASS
MCP protocol response                PASS
```

The unauthenticated denial is a success condition, not an error.

User-facing representation:

```text
STEP 3 OF 5 — Preparing Remote GROWTH

[OK] Local AI gateway
[OK] Secure internet route
[OK] Unauthorized access blocked
[OK] Authorized access verified

Your connection is ready.
```

Do not display raw bearer values on this screen.

## STEP 4 — Connect Composio

The wizard opens the exact Composio page required for Custom MCP setup.

The implementation should avoid asking the user to search menus manually where a direct or stable setup URL is available.

Screen:

```text
STEP 4 OF 5 — Connect Composio

We will open Composio now.

You will need to:
1. Sign in to your account.
2. Add the Custom MCP connection we prepared.
3. Click Connect.
4. Return to this window.

[ENTER] Open Composio
```

After the page opens, the wizard presents only the values the user currently needs.

Example:

```text
Connection address
[C] Copy address

Secure access code
[K] Copy code

Do not share the secure access code.

When Composio says the connection is ready:
[ENTER] Check my connection
```

Where technically possible in a later implementation, the setup may reduce manual copy/paste further. CHAT 1 does not assume that account-owned Composio configuration can be silently mutated.

## STEP 5 — Acceptance check

The wizard performs the final verification.

Required checks:

1. Remote GROWTH local gateway is healthy.
2. Tailscale service is healthy.
3. public endpoint resolves/reaches the expected service.
4. unauthenticated request remains blocked.
5. authenticated MCP request succeeds.
6. Composio-facing endpoint behaves as expected.
7. expected tool inventory is discovered.
8. target inventory for the current Remote GROWTH Stable release is **64 tools**.

Success screen:

```text
STEP 5 OF 5 — Final check

[OK] Remote GROWTH
[OK] Secure connection
[OK] Access protection
[OK] MCP connection
[OK] 64 tools detected

╔══════════════════════════════════════════════╗
║              SETUP COMPLETE                  ║
║                                              ║
║   Your computer is ready for ChatGPT.        ║
╚══════════════════════════════════════════════╝

Created by Rafdi D. Ulhaq — exxrawrrr
```

If the discovered tool count differs from the release contract, do not silently report success.

The wizard should explain that the connection exists but the expected capability set is incomplete.

---

# Required error experience

## Tailscale is not installed

```text
Tailscale is required for the secure remote connection.

[ENTER] Install Tailscale
[S]     Skip setup
```

## Tailscale is installed but logged out

```text
Tailscale is installed, but this computer is not connected yet.

[ENTER] Sign in
```

## Wrong process owns the Remote GROWTH port

This was a real historical failure mode and must fail closed.

```text
The connection port is already being used by another application.

For safety, OTAK-ATIK will not replace it automatically.

[ENTER] Run safe diagnosis
[A]     Advanced details
```

The wizard must not assume that "something answered on the port" means Remote GROWTH is healthy.

## Public endpoint returns success without authentication

This is a security failure.

```text
The secure connection is reachable, but access protection
is not behaving as expected.

Setup has been stopped before connecting Composio.

[ENTER] Repair protection
[A]     Advanced details
```

## Remote GROWTH is stopped

```text
Remote GROWTH is not running.

[ENTER] Repair automatically
```

## Composio is not connected yet

```text
Composio has not completed the connection yet.

No problem — your local setup is still safe.

[ENTER] Check again
[O]     Open Composio
```

## Tool count is not 64

```text
Connection established, but the Remote GROWTH tool set
is incomplete.

Expected: 64
Detected: <count>

[ENTER] Diagnose automatically
[A]     Advanced details
```

---

# Browser-opening contract

The normal setup wizard may automatically open:

- the Tailscale sign-in/setup surface when Tailscale requires user authentication;
- the relevant Tailscale administration surface only when user action is actually required;
- the Composio Custom MCP setup surface;
- project help/documentation only when the normal flow cannot continue.

Do not open a pile of browser tabs at startup.

Open the page exactly when the user needs it.

Browser opening is assistance, not proof of completion. Every external step must be followed by a local or remote verification check.

---

# What remains hidden from a normal user

These concepts remain implementation details unless advanced diagnostics are requested:

- Tailscale Funnel commands;
- internal port numbers;
- FastMCP host/origin rules;
- bearer Authorization header syntax;
- loopback binding details;
- supervisor process IDs;
- raw PowerShell commands;
- raw JSON configuration;
- raw MCP protocol payloads.

The installer may use all of them internally.

---

# Local files and persistence contract

CHAT 2 implementation should maintain a user-owned runtime/config directory outside the Git checkout.

Recommended model:

```text
%LOCALAPPDATA%\otak-atik\
  setup-state.json
  logs\
  runtime\
  secrets\
```

Rules:

- no live secret in the repository;
- no machine identity committed;
- no account-specific Tailscale hostname committed;
- no Composio credential committed;
- generated local values must be clearly separated from public templates.

The precise secure storage mechanism for the Composio/Remote GROWTH path is an implementation decision for later chats, but plaintext-in-Git is forbidden.

---

# Launcher contract

The user-facing end state should converge on three primary launchers:

```text
START.cmd
STATUS.cmd
REPAIR.cmd
```

## START.cmd

Responsibilities:

- first-run onboarding;
- resume interrupted onboarding safely;
- start already-configured services;
- route the user to the exact next required human action.

## STATUS.cmd

Default view:

```text
OTAK-ATIK STATUS

[OK] Remote GROWTH
[OK] Tailscale
[OK] Secure route
[OK] Authentication protection
[OK] MCP
[OK] 64 tools

Everything is ready.
```

No raw diagnostics unless requested.

## REPAIR.cmd

Repair should:

- inspect before mutating;
- restart project-owned runtime components when safe;
- re-check Tailscale service/state;
- revalidate the transport;
- never silently overwrite unrelated port owners;
- never weaken authentication to "make it work";
- finish with the same acceptance checks used by setup.

---

# Setup state machine

The implementation should persist enough non-secret progress to resume safely.

Suggested states:

```text
NEW
  ↓
PREFLIGHT_OK
  ↓
TAILSCALE_READY
  ↓
GATEWAY_READY
  ↓
PUBLIC_ROUTE_READY
  ↓
COMPOSIO_WAITING
  ↓
COMPOSIO_CONNECTED
  ↓
ACCEPTANCE_PASSED
```

Failure does not erase completed safe stages.

A rerun should detect reality instead of blindly replaying every step.

---

# Safety gates inherited from the existing project

The onboarding must preserve the already-proven principles:

- loopback-local service where intended;
- stable remote transport through Tailscale;
- authentication required;
- explicit expected-service verification;
- protected runtime components;
- no secrets in public Git;
- verification after mutation;
- fail closed when identity or security checks are ambiguous.

Onboarding convenience must not weaken the existing Remote GROWTH safety model.

---

# CHAT 1 acceptance criteria

CHAT 1 is complete when all of the following are true:

- [x] normal user journey is defined;
- [x] Tailscale is explicitly part of the architecture but hidden from unnecessary user complexity;
- [x] user-owned login steps are separated from installer-owned work;
- [x] Composio connection flow is defined;
- [x] 64-tool final acceptance target is defined;
- [x] wrong-port/service-identity failure is handled;
- [x] unauthenticated-access failure is handled;
- [x] browser-opening behavior is defined;
- [x] terminal branding and vocabulary are defined;
- [x] START / STATUS / REPAIR responsibilities are defined;
- [x] secret/public boundaries are defined;
- [x] resumable setup state is defined.

## CHAT 3 implementation evolution

The original CHAT 1 contract intentionally assumed a manual Composio connection because Custom MCP lifecycle details were not yet locked.

CHAT 3 now uses Composio's current experimental v3.1 API lifecycle instead:

```text
public Remote GROWTH accepted
  ↓
user provides Composio Project API Key once
  ↓
register/upsert Custom MCP toolkit
  ↓
create or reuse API-key auth config
  ↓
open hosted Composio connection page
  ↓
Remote GROWTH access code copied to clipboard
  ↓
connected account becomes ACTIVE
  ↓
Composio sync
  ↓
synced_count == 64
```

The Composio Project API Key is not stored. The Remote GROWTH bearer credential remains local except when the user explicitly pastes it into Composio's hosted connection flow. The local receipt stores only non-secret toolkit/account identifiers and the last verified synced tool count.

This replaces the earlier manual "type the tool count you see" acceptance step with an API-reported `synced_count == 64` gate.

## Explicitly not implemented in CHAT 1

CHAT 1 does **not** claim that the new wizard already exists.

Implementation status:

```text
CHAT 2 — Beautiful Terminal Wizard                    DONE
CHAT 3 — Tailscale + Composio Guided Wiring           DONE
CHAT 4 — STATUS + REPAIR                              PENDING
CHAT 5 — Fresh-User Acceptance + Release              PENDING
```

CHAT 3 implements the guided path but does not replace the final clean-machine acceptance gate in CHAT 5.
