# Changelog

All notable changes will be documented here.

## [Unreleased]

## [0.1.0-alpha.1] - 2026-09-28

### Added

- end-to-end Windows onboarding and Desktop launchers;
- Remote Desktop Commander start/status/stop helpers;
- one-click-assisted Codex local MCP setup;
- optional MCP SuperAssistant browser bridge;
- setup decision tree;
- usage/cost routing guide;
- real-world "what the author actually uses" notes;
- QuickDesk and Windows MCP Server alternatives;
- transport-selector skill;
- remote-usage-optimizer skill;
- local-mcp-bootstrap skill;
- remote/browser topology skills;
- Linux + Windows CI validation, including PowerShell parse/dry-run smoke tests.

### Changed

- Remote Desktop Commander is documented as the author's primary ChatGPT workflow.
- MCP SuperAssistant is explicitly optional and identified as a legacy/fallback path in the original setup.
- local MCP is recommended for Codex/local workloads to avoid unnecessary hosted remote usage.
- browser-bridge documentation now includes current reliability caveats instead of presenting the extension as equivalent to native MCP.

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
