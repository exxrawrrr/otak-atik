# Project State

**Updated:** 2026-10-01  
**Current milestone:** Remote GROWTH Stable v0.7 + Native ChatGPT plugin finalization  
**Repository maturity:** active public research lab / real-machine operator experiment  
**npm package:** 0.1.0-alpha.5  
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

The private ChatGPT MCP app/plugin is registered, the Secure MCP Tunnel session is healthy, direct native calls from ChatGPT are verified, and a private v1.0.0 package has been finalized locally with the verified app binding. The public repository contains only identity-neutral templates/bootstrap code. The remaining work is behavioral acceptance and recovery testing.

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
- direct native calls for health, workflow catalog, system health, and workspace discovery.

## Important distinction

The **npm package** and the **GROWTH machine runtime** are related experiments but not the same release artifact.

Do not describe gateway v0.7.0 as npm version 0.7.0.

Current:

```text
npm package: 0.1.0-alpha.5
Remote GROWTH gateway runtime: 0.7.0
native private package: 1.0.0 (local-only app binding)\npublic native template: identity-neutral
```

## What is not claimed

The repository does not claim:

- universal production readiness;
- zero-trust certification;
- clean-machine reproducibility across arbitrary Windows devices;
- multi-user production support;
- public availability of the author's private ChatGPT plugin;
- permission to publish machine credentials.

## Current next milestone

**Phase 10 — Native registration and final acceptance**

Acceptance target:

1. keep Composio at 64/64 — **verified**;
2. keep production gateway healthy — **verified**;
3. connect native facade through OpenAI Secure MCP Tunnel — **verified**;
4. create the private ChatGPT MCP app and verify the 12-tool surface — **verified**;
5. bind the real generated technical app ID into the private plugin package — **verified locally, not published**;
6. run the full read-only acceptance suite;
7. run plan-only test;
8. run isolated write + rollback test;
9. run protected-negative test;
10. create a release/checkpoint only after all gates pass.

## Research rule

Reality outranks roadmap aesthetics.

A failed experiment stays documented.

A new architecture is only promoted after it survives real-machine verification.
