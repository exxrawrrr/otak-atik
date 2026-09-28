# Changelog

All notable changes will be documented here.

## [Unreleased]

## [0.1.0-alpha.2] - 2026-09-28

### Added

- hybrid local/remote usage strategy;
- Remote Desktop Commander quota-aware routing guidance;
- Codex local Desktop Commander MCP setup launcher;
- transport-selector skill;
- remote-usage-optimizer skill;
- local-mcp-bootstrap skill;
- "what the author actually uses" evidence note;
- Windows CI smoke checks for installer parsing/dry-run;
- additional onboarding contract tests.

### Changed

- Remote Desktop Commander is explicitly documented as the author's primary day-to-day ChatGPT route.
- MCP SuperAssistant is documented as optional/legacy-fallback rather than a required companion to Remote Desktop Commander.
- local MCP is recommended for same-machine Codex/development work.
- browser-bridge docs now call out current public reliability caveats.
- onboarding explains when to choose local, remote, browser bridge, or GUI-control transport.

### Verified

- fresh public clone validator: PASS
- Node tests: 10/10 PASS
- CLI doctor: READY
- Windows GROWTH smoke test: PASS
- Windows PowerShell helper parse: PASS
- Windows installer dry-run: PASS

## [0.1.0-alpha.1] - 2026-09-28

### Added

- end-to-end Windows onboarding and Desktop launchers;
- Remote Desktop Commander start/status/stop helpers;
- optional MCP SuperAssistant browser bridge;
- setup decision tree;
- AI client notes;
- alternative provider documentation.

## [0.1.0-alpha.0] - 2026-09-28

### Added

- public project foundation;
- zero-runtime-dependency CLI;
- doctor command;
- capability, skill, recipe, and pack registries;
- default permission policy;
- Windows installer with dry-run;
- product and architecture documentation;
- initial validator and test contract.
