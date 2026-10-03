# Project State

**Updated:** 2026-10-03  
**Current milestone:** Guided Composio onboarding CHAT 5 complete; v0.1.0-alpha.6 release lock
**Repository maturity:** active public research lab / real-machine operator experiment  
**npm package:** 0.1.0-alpha.6  
**machine runtime:** Remote GROWTH Stable gateway v0.7.0

## Project thesis

The original question remains the best description of the project:

> Can ChatGPT safely access and operate a real computer from chat, with enough verification to trust what happened?

The project no longer has only one answer.

## Current working paths

### Existing remote operator path

```text
ChatGPT
→ Composio Custom MCP
→ Remote GROWTH Stable
→ GROWTH
```

Current Composio catalog:

```text
64 available actions
```

### Direct interactive path

```text
ChatGPT
→ Remote Desktop Commander
→ GROWTH
```

Still useful for direct interactive work.

### Native ChatGPT plugin track

```text
ChatGPT MCP app / private plugin
→ OpenAI Secure MCP Tunnel
→ 127.0.0.1:18768
→ Remote GROWTH Native Facade
→ trusted local engines
```

The native facade currently exposes **12 focused tools**.

The private ChatGPT MCP app/plugin is registered, the Secure MCP Tunnel session is healthy, direct native calls from ChatGPT are verified, and a private v1.0.0 package has been finalized locally with the verified app binding. Phase 10 core acceptance is release-locked. Warm native-backend reconnect is verified. Cold reboot/tunnel-process recovery remains a documented manual-start limitation until optional local Credential Manager + Scheduled Task enrollment is performed.

## Remote GROWTH Stable v0.7

The production gateway exposes **64 tools**:

- 15 Windows primitive tools;
- 6 Fast Local tools;
- 6 Document Engine tools;
- 9 Developer/Git tools;
- 10 Safe FileOps tools;
- 12 SystemOps tools;
- 6 Workflow tools.

The architecture is no longer simply Windows-MCP behind a tunnel.

```text
ChatGPT / Composio
        ↓
Remote GROWTH Gateway
        ├─ Windows primitives
        ├─ Fast Local Engine
        ├─ Document Engine
        ├─ Developer / Git Engine
        ├─ Safe FileOps Engine
        ├─ SystemOps Engine
        └─ Workflow Engine
```

## Safety model now implemented

### File operations

- plan before execution;
- destination conflicts fail closed;
- delete uses quarantine semantics;
- preconditions are rechecked;
- receipts are written;
- rollback is supported where safe.

### System operations

- protected Remote GROWTH runtime processes;
- protected ports and connectivity services;
- protected Tailscale;
- protected Microsoft and Remote GROWTH scheduled tasks;
- irreversible actions require explicit permission;
- planned actions are revalidated before execution.

### Workflow orchestration

- built-in templates only;
- arbitrary shell workflow steps are not accepted;
- mutation gate;
- irreversible-action gate;
- dependency graph;
- duplicate execution guard;
- per-step results;
- receipt hash;
- rollback integration for supported underlying engines.

## Native ChatGPT package

Current prepared native surface:

```text
12 tools
5 plugin skills
loopback-only facade
secret-free package
official Secure MCP Tunnel client prepared
```

Native facade tools:

- remote_growth_health
- search_local
- find_workspace
- summarize_workspace
- inspect_document
- inspect_repo
- inspect_system_health
- list_workflows
- plan_workflow
- execute_workflow
- get_workflow_status
- rollback_workflow

Raw PowerShell, raw filesystem mutation, and raw UI automation are deliberately not exposed through this native surface.

## Verified evidence

The original GROWTH machine has verified:

- bearer/auth boundaries on the operator gateway;
- public transport via Tailscale Funnel;
- unauthenticated rejection;
- supervisor recovery;
- scheduled startup recovery;
- Tailscale reconnect;
- actual Windows reboot persistence;
- post-reboot remote execution;
- 64-tool gateway inventory;
- persistent local index;
- engine smoke tests;
- protected system targets;
- file operation rollback;
- workflow mutation gates;
- workflow rollback;
- 12-tool native facade inventory;
- native read/write annotations;
- raw primitive exclusion;
- plugin package secret scan and ZIP integrity;
- Secure MCP Tunnel health/readiness;
- private ChatGPT plugin registration;
- direct native calls for health, workflow catalog, system health, and workspace discovery;
- full native read-only acceptance across local search, workspace summary, repository status, system health, workflow catalog, and document inspection;
- plan-only acceptance plus mutation and irreversible-action denial gates;
- isolated native file copy with hash-equivalence verification and successful rollback;
- protected-negative acceptance for gateway/Tailscale/native/tunnel targets plus post-patch regression verification;
- controlled native-backend outage/restart with tunnel process retained and direct ChatGPT plugin calls recovering afterward.

## Guided public onboarding status

CHAT 5 carries the **identity-neutral portable 64-tool runtime, user-facing STATUS + REPAIR recovery controls, and the user-first Windows release ZIP**.

The guided Windows flow now has implementation for:

- Tailscale install/login detection;
- device DNS discovery;
- isolated Remote GROWTH runtime installation under LocalAppData;
- local authenticated 64-tool verification before any public exposure;
- Tailscale Funnel with conflict detection and fail-closed behavior;
- HTTP 401 verification for unauthenticated public access;
- authenticated public 64-tool verification;
- API-managed Custom MCP registration using a user-supplied Composio Project API Key held in memory only;
- creation/reuse of the required API-key auth config for the Custom MCP;
- hosted Composio connection flow with the Remote GROWTH credential copied to the clipboard;
- Composio API sync with `synced_count == 64` required before setup is marked complete;
- `STATUS.cmd` with READY / REPAIR_NEEDED / USER_ACTION / BLOCKED classification;
- `REPAIR.cmd` with project-owned task/runtime/Tailscale-route recovery and fail-closed security behavior;
- repo-independent LocalAppData copies of nested helpers and the portable runtime source.

CHAT 3 established the portable/runtime/transport evidence: an isolated runtime built from public source returned **64/64 tools**, while the production public route returned **HTTP 401 without authentication** and **64/64 tools with authentication**.

CHAT 4 then performed destructive-but-isolated recovery acceptance on separate test ports: the test recovery task was removed and all test runtime processes were stopped. STATUS correctly returned **REPAIR_NEEDED** with no false security blocker. REPAIR recreated the current-user task, restarted the supervisor/upstream/gateway, and finished **READY** with local **HTTP 401 + 64/64 tools**. The production ports remained untouched.

The Windows CI workflow repeats fresh runtime setup plus STATUS/REPAIR self-healing on isolated ports. CHAT 5 also builds the Windows ZIP on a clean Windows runner, runs first START without Node.js or Git, removes the extracted source, reruns the installed START from cached files, verifies the first-run status contract, and uploads the release bundle artifact. This is evidence for the tested Windows runner and package path; it is not a claim of universal arbitrary-device production readiness or unattended account provisioning.

## Important distinction

The **npm package** and the **GROWTH machine runtime** are related experiments but not the same release artifact.

Do not describe gateway v0.7.0 as npm version 0.7.0.

Current:

```text
npm package: 0.1.0-alpha.6
Remote GROWTH gateway runtime: 0.7.0
native private package: 1.0.0 (local-only app binding)
public native template: identity-neutral
```

## What is not claimed

The repository does not claim:

- universal production readiness;
- zero-trust certification;
- clean-machine reproducibility across arbitrary Windows devices;
- multi-user production support;
- public availability of the author's private ChatGPT plugin;
- permission to publish machine credentials.

## Current milestone

**Guided Composio onboarding — CHAT 5 COMPLETE / v0.1.0-alpha.6 release lock**

Verified release gates include:

1. user-first Windows ZIP build with bundle-specific identity/secret scanning;
2. first START on a clean Windows runner with Node.js and Git unavailable to the user path;
3. Desktop `START.cmd`, `STATUS.cmd`, and `REPAIR.cmd` generation;
4. installed START still works after the extracted source is removed;
5. fresh portable runtime acceptance at HTTP 401 + 64/64 tools;
6. destructive STATUS/REPAIR recovery back to READY + HTTP 401 + 64/64;
7. foreign-port fail-closed behavior without terminating the unrelated process;
8. post-merge `main` validation and Windows onboarding jobs passing.

Account sign-in remains intentionally user-owned. CHAT 5 does not claim unattended Tailscale/Composio enrollment or universal production readiness. Historical real reboot evidence remains documented separately; the release process does not reboot the owner's active workstation.

## Research rule

Reality outranks roadmap aesthetics.

A failed experiment stays documented.

A new architecture is only promoted after it survives real-machine verification.
