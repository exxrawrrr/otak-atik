# Changelog

All notable changes will be documented here.

## [0.1.0-alpha.1] - 2026-09-28

### Added

- end-to-end Windows onboarding;
- automatic `Desktop\OTAK-ATIK` launcher folder;
- Remote Desktop Commander start/status/stop helpers;
- optional MCP SuperAssistant browser-bridge helper;
- setup decision tree;
- AI client compatibility notes;
- QuickDesk and Windows MCP Server alternatives documentation;
- five operator/bootstrap skills, bringing the official registry to 18 skills;
- ADR separating native remote MCP from browser-extension transport;
- Windows-native GitHub Actions onboarding workflow;
- deterministic onboarding contract tests.

### Changed

- Remote Desktop Commander is now documented as the recommended default remote path.
- MCP SuperAssistant is explicitly documented as optional, not a required dependency of Remote Desktop Commander.
- Windows onboarding is treated as a tested product contract instead of documentation-only guidance.

### Verified

- fresh-clone validator: PASS;
- Node tests: 9/9 PASS;
- CLI doctor: READY;
- Windows onboarding GitHub Actions run: SUCCESS.

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
