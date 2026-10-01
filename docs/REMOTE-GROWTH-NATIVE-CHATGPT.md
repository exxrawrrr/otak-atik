# Remote GROWTH Stable — Current Architecture and Native ChatGPT Track

Status: **ACTIVE / REAL-MACHINE VERIFIED / NATIVE PLUGIN FINALIZATION IN PROGRESS**  
Snapshot date: **2026-10-01**

## Why this exists

The original otak-atik question was:

> Can ChatGPT reach a real Windows computer, understand the local workspace, perform useful work, and verify the result?

Remote GROWTH Stable is the most concrete answer produced by the repository so far.

The project began with remote desktop and Windows-MCP primitives.

It now has two deliberately different surfaces:

1. a **64-tool operator gateway** used through Composio;
2. a **12-tool focused native facade** intended for direct ChatGPT MCP/plugin use.

## Current operator architecture

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Remote GROWTH Stable Gateway v0.7.0
  ↓
┌────────────────────────────────────────────┐
│ 15 Windows primitives                      │
│  6 Fast Local tools                        │
│  6 Document tools                          │
│  9 Developer / Git tools                   │
│ 10 Safe FileOps tools                      │
│ 12 SystemOps tools                         │
│  6 Workflow tools                          │
└────────────────────────────────────────────┘
  ↓
GROWTH Windows workstation
```

Composio currently reports **64 available actions**.

## Why the system grew beyond Windows-MCP

Raw primitives are useful but expensive to reason about.

For example, “find the latest proposal, back up the workspace, modify files, run checks, checkpoint the repository, and show evidence” should not require a chat agent to improvise dozens of shell commands every time.

The newer engines move common work upward into typed operations.

### Fast Local Engine

Purpose:

- persistent local index;
- fast content/path search;
- workspace discovery;
- workspace summary;
- incremental refresh / health.

### Document Engine

Purpose:

- inspect documents;
- extract structured content;
- search inside documents;
- compare documents;
- controlled replacements.

### Developer / Git Engine

Purpose:

- locate repositories;
- inspect branch / working tree;
- summarize repositories;
- search code;
- inspect diffs;
- create local checkpoints;
- execute bounded checks;
- run repository quality workflows.

### Safe FileOps Engine

Purpose:

- storage analysis;
- duplicate discovery;
- hash manifests;
- archive creation/extraction;
- file batch planning;
- file batch execution;
- rollback;
- workspace backup.

Important semantics:

- destination conflict fails closed;
- mutations execute from a saved plan;
- preconditions are rechecked;
- delete uses quarantine semantics;
- rollback exists for supported operations.

### SystemOps Engine

Purpose:

- system health;
- process inspection;
- port ownership;
- service inspection;
- network inspection;
- Tailscale inspection;
- scheduled-task inspection;
- startup inspection;
- bounded planned system mutations.

Protected targets include Remote GROWTH runtime components, important connectivity services, Tailscale, and protected scheduled tasks.

### Workflow Engine

Purpose:

compose trusted local engines into higher-level tasks.

Current templates include:

- repo health;
- repo backup → quality → checkpoint;
- safe file batch;
- storage cleanup assessment;
- system health report;
- safe system action.

Workflow model:

```text
PLAN
  ↓
dependency / reference resolution
  ↓
mutation gate
  ↓
irreversible-action gate
  ↓
execute
  ↓
verify
  ↓
receipt
  ↓
rollback where supported
```

Arbitrary shell steps are intentionally not accepted inside workflow specifications.

## Native ChatGPT facade

The operator gateway is powerful, but it is intentionally not the API surface selected for the native ChatGPT plugin track.

The native facade instead exposes 12 high-level tools:

```text
remote_growth_health
search_local
find_workspace
summarize_workspace
inspect_document
inspect_repo
inspect_system_health
list_workflows
plan_workflow
execute_workflow
get_workflow_status
rollback_workflow
```

Deliberately absent:

- raw PowerShell;
- raw FileSystem mutation;
- raw process control;
- raw Click / Type / GUI automation.

The facade binds loopback-only on the GROWTH machine.

## Native plugin architecture

```text
ChatGPT private plugin / MCP app
       ↓
OpenAI Secure MCP Tunnel
       ↓
loopback-only native facade
       ↓
trusted Remote GROWTH engines
       ↓
GROWTH
```

This design avoids exposing the native facade as another public inbound service.

## Plugin package

A pre-registration package has been built with:

- plugin manifest;
- five focused skills;
- onboarding metadata;
- local-development MCP metadata;
- compatibility metadata;
- evaluation cases;
- registration runbook.

Validation already performed:

- JSON parsing;
- skill count/frontmatter;
- onboarding path;
- secret scan;
- archive integrity.

No runtime API key, bearer token, private key, or private ChatGPT technical app credential belongs in the repository.

## Secure MCP Tunnel preparation

The official OpenAI tunnel client has been installed on the test machine and its downloaded archive was checksum verified.

The public repository should document the pattern, not the author's private tunnel ID or runtime API key.

## Current Phase 10 acceptance target

Registration is now proven from the ChatGPT side:

- Secure MCP Tunnel session healthy/ready;
- private ChatGPT MCP app/plugin registered;
- exactly 12 native tools exposed;
- direct native calls from ChatGPT verified for health, workflow catalog, system health, and workspace discovery.

Remaining test-driven work:

1. capture the generated app technical ID for final package mapping;
2. finalize the private plugin package mapping;
3. run the full read-only acceptance suite;
4. run plan-only acceptance;
5. run isolated file write + rollback acceptance;
6. verify a protected system target fails closed;
7. verify no regression to the 64-tool operator gateway;
8. run reconnect/reboot acceptance and lock the final release evidence.

## Acceptance philosophy

The project does not call “the plugin exists” a success by itself.

The useful success condition is:

```text
ChatGPT chooses the right high-level tool
+
read-only work stays read-only
+
mutation requires an explicit plan/gate
+
rollback works on a disposable fixture
+
protected targets fail closed
+
the original production operator path still works
```

## Security / publication rules

Never commit:

- bearer keys;
- tunnel runtime API keys;
- private keys;
- local credential stores;
- generated private app credentials;
- private machine-specific endpoint credentials.

Public documentation may describe architecture, safety semantics, tool classes, and verification evidence without publishing secrets.

## Relationship to historical docs

The original [RAFDI-REMOTE-GROWTH.md](RAFDI-REMOTE-GROWTH.md) is intentionally retained as a frozen transport-era evidence record.

This document is the current architecture snapshot.
