# Changelog

All notable changes will be documented here.

## [Unreleased]

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
- packed-tarball smoke install verifies `doctor` and `version` from the distributable artifact.

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
- Codex local MCP setup path.

## [0.1.0-alpha.1] - 2026-09-28

- end-to-end Windows onboarding;
- Desktop launchers;
- optional browser bridge.

## [0.1.0-alpha.0] - 2026-09-28

- initial public foundation.
