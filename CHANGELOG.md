# Changelog

All notable changes will be documented here.

## [Unreleased]

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
