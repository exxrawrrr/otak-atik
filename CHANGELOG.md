# Changelog

All notable changes will be documented here.

## [Unreleased]

## [0.1.0-alpha.7] - 2026-10-03

### Premium terminal installer

Upgraded the guided Windows installer presentation without weakening the CHAT 1–5 safety contract:

- added a shared premium terminal renderer for START, STATUS, and REPAIR;
- added a branded OTAK-ATIK ASCII header with `Created by Rafdi D. Ulhaq - exxrawrrr`;
- added step progress, live activity indicators, human-readable status rows, action-required panels, success panels, and safety-boundary panels;
- interactive launches automatically reopen in Windows Terminal when available;
- Windows Terminal launches maximized and in focus mode for a clean installer-like experience;
- systems without Windows Terminal fall back to the current PowerShell console;
- non-interactive, JSON, dry-run, and GitHub Actions paths remain headless and automation-safe;
- failed or resumable interactive setup keeps the terminal visible instead of disappearing immediately.

### Safety / compatibility

- Tailscale, Funnel, bearer authentication, Composio, and exact 64-tool acceptance logic are unchanged;
- STATUS JSON/exit-code behavior remains compatible;
- REPAIR remains fail-closed and still refuses unrelated port owners;
- Desktop START / STATUS / REPAIR launchers use the same premium wrapper after the downloaded source folder is removed;
- onboarding contract regression expanded to cover the premium human-vs-headless boundary.

## [0.1.0-alpha.6] - 2026-10-03

### Guided Windows onboarding

Added a user-first Windows release path for the 64-tool Remote GROWTH + Tailscale + Composio experiment:

- branded terminal setup wizard;
- user-owned Tailscale and Composio login/approval flow;
- portable identity-neutral 64-tool runtime;
- local HTTP 401 + exact 64-tool acceptance before public exposure;
- Tailscale Funnel conflict detection and fail-closed publication;
- Composio Custom MCP API sync requiring exactly 64 tools;
- `START.cmd`, `STATUS.cmd`, and `REPAIR.cmd` as the primary user surface;
- safe recovery that only restarts project-owned components and refuses foreign port owners.

### Fresh-user distribution

- added a Windows ZIP release builder with its own secret/machine-identity scan;
- first `START.cmd` bootstraps the local installation automatically;
- Git and Node.js are not required for the guided Windows user path;
- installed Desktop launchers run from cached helpers/runtime source and remain usable after the downloaded ZIP is removed;
- release bundle includes a SHA-256 sidecar and a short non-technical `README-FIRST.txt`.

### Acceptance

- isolated real-machine recovery returned READY with HTTP 401 + 64/64 tools;
- foreign-port negative test remained BLOCKED without terminating the foreign process;
- clean Windows CI builds the user ZIP, runs first START without Node/Git, deletes the extracted source, and reruns the installed START from cached files;
- existing repository regression remains 43/43 tests with strict hygiene clean.

This remains an **alpha** release. Account sign-in is intentionally user-owned, and universal multi-machine production readiness is not claimed.

### Remote GROWTH Stable v0.7 operator stack

The original Rafdi Remote transport experiment has grown into a layered local operator gateway.

Current real-machine gateway state:

- gateway runtime v0.7.0;
- 64 MCP tools;
- Composio catalog showing 64 available actions;
- existing Windows primitive tools retained for compatibility.

Added engine layers:

- Fast Local persistent workspace/file search;
- Document Engine;
- Developer / Git Engine;
- Safe File & Workspace Operations Engine;
- System / Process / Network Operations Engine;
- Smart Workflow / Batch Orchestrator Engine.

### Safety model

Added:

- protected Remote GROWTH runtime targets;
- protected connectivity/system services;
- protected scheduled tasks;
- plan-before-mutation semantics;
- irreversible-action permission gate;
- precondition revalidation;
- integrity-hashed plans / receipts;
- FileOps rollback;
- SystemOps rollback;
- workflow rollback;
- duplicate workflow execution guard;
- workflow dependency graph;
- no arbitrary shell actions inside workflow specs.

### Native ChatGPT plugin track

Prepared a separate native facade for direct ChatGPT MCP/plugin integration.

Verified:

- loopback-only native endpoint;
- 12 focused high-level tools;
- raw PowerShell / raw filesystem mutation / raw UI automation excluded;
- read-only vs write/destructive tool annotations;
- five plugin skills;
- pre-registration plugin package;
- package secret scan;
- ZIP integrity;
- official OpenAI Secure MCP Tunnel client installation with checksum verification;
- Secure MCP Tunnel health/readiness;
- private ChatGPT MCP app/plugin registration;
- direct native calls from ChatGPT to the 12-tool facade;
- private v1.0.0 package finalized locally with the verified app binding;
- public identity-neutral plugin template;
- Windows native bootstrap for tunnel setup/run/status/doctor/plugin build;
- optional current-user DPAPI-encrypted runtime-key cache outside the Git checkout;
- generated private app bindings/builds stored below LocalAppData rather than the repository;
- native read-only acceptance passed for health, local search, workspace discovery/summary, Git status, system health, workflow catalog, and DOCX inspection;
- plan-only acceptance passed;
- mutating workflow execution is denied without allow_mutations=true;
- irreversible SystemOps execution is denied without allow_irreversible=true before the action runs;
- isolated native FileOps write acceptance passed with receipt/hash verification and rollback restoring the pre-test destination state;
- SystemOps protected-negative acceptance passed for gateway and Tailscale targets;
- SystemOps service planner Python string bug fixed in the private machine runtime;
- runtime protection expanded to the native facade and Secure MCP Tunnel processes/ports;
- post-patch regression reverified 64-tool production gateway, 12-tool native facade, tunnel health/readiness, and public unauthenticated HTTP 401;
- warm native-backend reconnect verified: facade stopped/restarted while the Secure MCP Tunnel process remained alive, followed by successful direct ChatGPT native-plugin calls;
- cold tunnel restart/reboot remains a documented limitation until one-time Windows Credential Manager + Scheduled Task enrollment is completed.

Phase 10 core acceptance is now release-locked. Warm native reconnect is verified. Zero-touch cold tunnel restart/reboot remains an optional follow-up; the current private machine requires a manual tunnel start/runtime-key entry after a true cold loss of the tunnel process unless local credential/task enrollment is enabled.

### Documentation

- updated README around the actual AI-to-computer project thesis;
- updated project state and roadmap;
- added current Remote GROWTH / Native ChatGPT architecture document;
- preserved the September Rafdi Remote document as historical evidence instead of rewriting it.

## [0.1.0-alpha.5] - 2026-09-30

### Rafdi Remote experiment

Added a reusable Windows remote-MCP experiment built around:

- Composio Custom MCP;
- Tailscale Funnel;
- Windows-MCP bound to loopback;
- locally generated bearer authentication;
- FastMCP host-origin protection;
- per-user Scheduled Task startup;
- a supervisor with bounded logs and conservative recovery;
- status, test, repair, and safe-disable scripts.

### Reality testing

Verified on the original GROWTH Windows machine:

- public Funnel reachability;
- unauthenticated public requests rejected with HTTP 401;
- authenticated MCP initialize through the public endpoint;
- supervisor recovery;
- Scheduled Task/logon-style recovery;
- Tailscale reconnect persistence;
- actual Windows reboot persistence;
- post-reboot ChatGPT -> Composio -> Windows-MCP command execution.

### Safety / hardening

- Windows-MCP remains bound to `127.0.0.1`;
- bearer keys are generated locally and not printed by normal setup;
- setup refuses ambiguous local-port ownership;
- first-time Funnel publication remains explicit;
- repair avoids broad process termination;
- uninstall does not run global `tailscale funnel reset`;
- proxy compatibility is enabled only for public mode while bearer auth and FastMCP host checks remain active.

### Documentation

- rewrote the main README around the real failure-to-working-backup story;
- documented the current daily, backup, and local workflows;
- added Phase 1.5, Phase 2A, and Phase 2B evidence checkpoints;
- added the Rafdi Remote transport/security ADR and public manifest/gate.

### Quality

Current release-candidate validation target:

- Node tests: **39/39 PASS**;
- routing benchmark: **4/4 PASS**;
- strict self-hygiene: **0 findings**;
- skill audit: **29 skills, 0 errors, 0 warnings**;
- Windows PowerShell parse checks include the Rafdi Remote scripts and rendered supervisor template;
- removed the unnecessary `shell: true` Git probe so `doctor` no longer emits Node `DEP0190`, with a regression test covering it;
- packed-tarball smoke install verifies `doctor` and `version` from the distributable artifact;
- switched the test script to cross-platform `node --test` discovery after GitHub Windows CI showed shell globs were not expanded.

## [0.1.0-alpha.4] - 2026-09-28

### Standalone Utility Pack

Useful without any MCP provider:

- `otak-atik snapshot` — compact project map;
- `otak-atik hygiene` — secret hygiene scan without printing secret values;
- `otak-atik mcp-check` — MCP JSON config audit;
- `otak-atik skill-check` — portable SKILL.md lint;
- `otak-atik handoff` — provider-neutral project handoff;
- `otak-atik diff-risk` — Git diff review-priority heuristic.

### Skills

Added:

- workspace-cartographer
- secret-hygiene-auditor
- mcp-config-auditor
- skill-quality-auditor
- ai-handoff-builder
- change-risk-reviewer

Total official skills: **29**.

### Dogfooding

`npm run check` now runs:

1. repository validation;
2. tests;
3. routing benchmark;
4. the repo's own secret-hygiene scanner in strict mode;
5. linting across every registered SKILL.md.

### Verified

Fresh public clone:

- validator: PASS
- tests: **34/34 PASS**
- routing benchmark: **4/4 PASS**
- self hygiene strict: **0 findings**
- doctor: **READY**

## [0.1.0-alpha.3] - 2026-09-28

- native transport router;
- operator plan compiler;
- evidence contract;
- provider scorecard;
- failure lab;
- provider routing benchmarks.

## [0.1.0-alpha.2] - 2026-09-28

- hybrid local/remote usage strategy;
- quota-aware Remote Desktop Commander guidance;
- Codex local Desktop Commander MCP setup path.

## [0.1.0-alpha.1] - 2026-09-28

- end-to-end Windows onboarding;
- Desktop launchers;
- optional browser bridge.

## [0.1.0-alpha.0] - 2026-09-28

- initial public foundation.
