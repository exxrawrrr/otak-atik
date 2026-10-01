# otak-atik

> **A public lab about one question: how far can ChatGPT safely operate a real Windows computer?**
>
> The project started as a messy attempt to make ChatGPT reach the author's PC from chat.
> It failed several times, changed direction, and eventually produced a working remote operator path called **Remote GROWTH Stable**.

## Current status — 1 October 2026

The original idea was simple:

```text
ChatGPT
  ↓
reach my Windows PC
  ↓
find files / inspect projects / run tools
  ↓
make controlled changes
  ↓
verify what actually happened
```

That idea is no longer architecture-only.

### Working operator path

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Remote GROWTH Stable Gateway v0.7.0
  ↓
64 tools
  ↓
GROWTH Windows workstation
```

The Composio connection currently exposes **64 available actions**.

Those 64 tools are not just raw desktop primitives. The gateway now contains layered engines for:

- local search / persistent workspace index;
- document inspection and controlled document operations;
- Git / repository inspection and quality workflows;
- safe file and workspace operations;
- Windows system / process / network inspection;
- planned system mutations with protected targets;
- high-level workflow orchestration with receipts and rollback.

### Native ChatGPT plugin track

A second surface is now registered as a private ChatGPT plugin/MCP app and can call the focused native facade directly:

```text
ChatGPT native plugin / MCP app
  ↓
OpenAI Secure MCP Tunnel
  ↓
127.0.0.1:18768
  ↓
Remote GROWTH Native Facade
  ↓
12 focused high-level tools
  ↓
trusted local engines
```

The native facade intentionally does **not** expose raw PowerShell, raw filesystem mutation, or raw UI automation.

Current native package status:

- native facade: **12 tools verified**;
- loopback-only listener: **verified**;
- private plugin package: **v1.0.0 finalized locally with the verified app binding**;
- five plugin skills: **validated**;
- secret scan: **PASS**;
- official OpenAI tunnel-client: **installed and checksum verified**;
- Secure MCP Tunnel session: **healthy / ready**;
- private ChatGPT MCP app/plugin: **registered**;
- direct native calls from ChatGPT: **verified**;
- public reusable native bootstrap: **validated from a fresh clone**;
- full behavioral acceptance suite: **in progress**.

See:

- [Current Remote GROWTH / Native ChatGPT architecture](docs/REMOTE-GROWTH-NATIVE-CHATGPT.md)
- [Reusable native setup/bootstrap](examples/remote-growth-native/README.md)
- [Historical Rafdi Remote evidence](docs/RAFDI-REMOTE-GROWTH.md)
- [Project State](PROJECT_STATE.md)
- [Roadmap](ROADMAP.md)

---

## Where this started

Originally, this repository was basically:

> “why can't the AI in my chat just enter my computer, read the project, run the terminal, fix something, and prove the result?”

That led to experiments with:

- MCP;
- remote MCP;
- local MCP;
- browser bridges;
- launchers;
- skills and capability registries;
- approvals and security boundaries;
- evidence and verification;
- provider routing;
- tunnels;
- desktop control;
- and a lot of failed assumptions.

The first practical answer was simply:

```text
ChatGPT
  ↓
Remote Desktop Commander
  ↓
Windows
```

That still works and remains useful.

But the self-built path kept evolving.

---

## Architecture evolution

### Stage 1 — use an existing remote plugin

```text
ChatGPT
  ↓
Remote Desktop Commander
  ↓
GROWTH
```

Simple and practical.

### Stage 2 — build a second remote MCP path

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Tailscale Funnel
  ↓
Windows-MCP
  ↓
GROWTH
```

This survived:

- authentication tests;
- public reachability tests;
- host/origin protection;
- supervisor recovery;
- Tailscale reconnect;
- Scheduled Task recovery;
- an actual Windows reboot;
- post-reboot commands from ChatGPT.

### Stage 3 — stop treating Windows-MCP primitives as the final API

The gateway grew into:

```text
Remote GROWTH Stable Gateway
  ├─ Windows primitives
  ├─ Fast Local Engine
  ├─ Document Engine
  ├─ Developer / Git Engine
  ├─ Safe FileOps Engine
  ├─ SystemOps Engine
  └─ Workflow Engine
```

Current gateway version:

```text
v0.7.0
64 tools
```

### Stage 4 — make it usable as a ChatGPT-native plugin

Instead of giving a native ChatGPT app all 64 operator tools, the project now uses a deliberately smaller facade:

```text
Native Facade
  12 focused tools
  ↓
Workflow Engine / trusted engines
```

This lets the public/operator gateway remain powerful while the ChatGPT-native surface stays easier to reason about.

---

## The 64-tool gateway

Current tool groups:

| Layer | Count | Purpose |
|---|---:|---|
| Windows primitives | 15 | PowerShell, files, process, screenshot, selected GUI control |
| Fast Local | 6 | indexed local search, files, workspaces, index health |
| Document Engine | 6 | inspect, extract, search, compare, controlled replace |
| Developer / Git | 9 | repo discovery/status/search/diff/checkpoint/quality |
| Safe FileOps | 10 | storage, duplicates, hashes, archive, batch plan/execute/rollback, backup |
| SystemOps | 12 | health, process/port/service/network/task inspection + planned safe mutations |
| Workflow Engine | 6 | catalog, plan, execute, status, rollback |
| **Total** | **64** | |

The project moved from “give AI a shell” toward:

```text
inspect
  ↓
plan
  ↓
permission gate
  ↓
execute
  ↓
verify
  ↓
receipt
  ↓
rollback when supported
```

---

## Native ChatGPT facade

The native surface currently exposes only these high-level tools:

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

Raw operator primitives are intentionally absent from this surface.

The plugin package also includes focused skills for:

- onboarding / routing;
- repository operations;
- safe file operations;
- safe system operations;
- document work.

No API key, bearer token, tunnel runtime key, or private key belongs in the package or repository.

---

## What is actually verified

On the original GROWTH machine, the project has verified:

- loopback-only MCP bindings;
- authenticated public gateway transport;
- unauthenticated request rejection;
- supervisor and startup recovery;
- Tailscale persistence;
- real Windows reboot recovery;
- 64-tool MCP gateway inventory;
- persistent local workspace index;
- document / developer / file / system engines;
- protected runtime targets;
- irreversible-action gates;
- FileOps and SystemOps receipts;
- high-level workflows;
- workflow mutation gate;
- duplicate execution guard;
- workflow rollback;
- native 12-tool facade;
- native tool safety annotations;
- raw primitive exclusion from the native facade;
- plugin package secret scan;
- plugin ZIP integrity;
- Secure MCP Tunnel health/readiness;
- private ChatGPT plugin registration;
- direct native tool calls from ChatGPT.

This is still evidence from a real primary machine, not a claim of universal production readiness.

---

## What is still in progress

The current finalization track is:

```text
Remote GROWTH Native Facade
  ↓
OpenAI Secure MCP Tunnel ✅
  ↓
ChatGPT MCP app / private plugin ✅
  ↓
private app-ID package binding ✅ (local only)
  ↓
read-only acceptance
  ↓
plan-only acceptance
  ↓
isolated write + rollback acceptance
  ↓
protected-negative acceptance
  ↓
release lock
```

The public repo must never include the author's tunnel credentials, bearer keys, machine secrets, or generated private app credentials.

---

## Remote Desktop Commander did not become useless

This repo is not trying to rewrite history.

Remote Desktop Commander is still valuable for direct interactive computer work.

The useful lesson became:

```text
use an existing tool when it is the best tool

AND

build your own path when you need different reliability,
control, quota, safety, or workflow semantics
```

Both can be true.

---

## Standalone utilities

The repo still includes provider-neutral utilities:

```powershell
otak-atik snapshot .
otak-atik hygiene . --strict
otak-atik mcp-check path\to\mcp.json
otak-atik skill-check path\to\SKILL.md
otak-atik handoff . --task "continue this project" --out handoff.json
otak-atik diff-risk .
```

The npm package itself remains a separate alpha research package from the machine-specific Remote GROWTH runtime.

Current npm package line:

```text
0.1.0-alpha.5
```

---

## Research principles

```text
Reality > roadmap.
Evidence > vibes.
Verification > "should work".
Failure documented > failure forgotten.
High-level safe operations > unnecessary raw shell access.
Local > remote when the task is local.
Secrets stay local.
Working paths may coexist.
```

The repository started as a failed attempt to replace a convenient remote plugin.

It evolved into something more interesting:

> **a documented AI-to-computer control lab with a real 64-tool remote operator path and an actively tested native ChatGPT plugin path.**

---

## Documentation

### Current architecture

- [Remote GROWTH Native ChatGPT](docs/REMOTE-GROWTH-NATIVE-CHATGPT.md)
- [Project State](PROJECT_STATE.md)
- [Roadmap](ROADMAP.md)
- [What I actually use](docs/WHAT-I-ACTUALLY-USE.md)

### Historical evidence

- [Rafdi Remote GROWTH](docs/RAFDI-REMOTE-GROWTH.md)
- [Phase 2A checkpoint](docs/RAFDI-REMOTE-GROWTH-PHASE-2A-CHECKPOINT.md)
- [Phase 2B checkpoint](docs/RAFDI-REMOTE-GROWTH-PHASE-2B-CHECKPOINT.md)
- [Transport/security ADR](docs/decisions/ADR-RAFDI-REMOTE-TRANSPORT.md)

### Security / contribution

- [Security](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Sources](SOURCES.md)

---

## For everyone else

**otak-atik is an AI-to-computer control research lab.**

It documents the path from:

```text
"Can ChatGPT reach my computer?"
```

to a verified experimental stack with:

- a real Windows machine;
- a stable remote MCP gateway;
- 64 operator tools;
- safety-gated engines and workflows;
- and a focused native ChatGPT plugin surface in final integration testing.

It is not a universal remote-desktop product.

It is a public record of what actually worked, what failed, and why the architecture changed.
