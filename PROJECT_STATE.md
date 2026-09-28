# Project State

**Current milestone:** V0.1 Foundation / onboarding hardening  
**Repository maturity:** public alpha

## Implemented

- public repository identity and product documentation;
- zero-runtime-dependency CLI skeleton;
- doctor command;
- capability/skill/recipe/pack registries;
- 18 official skills;
- default policy profiles;
- deterministic validator;
- Windows installer;
- automatic `Desktop\OTAK-ATIK` launcher folder;
- Remote Desktop Commander start/status/stop helpers;
- optional MCP SuperAssistant browser-bridge helper;
- explicit two-transport decision tree;
- Desktop Commander and generic MCP reference adapter manifests;
- Linux-side contract tests;
- Windows-native onboarding CI;
- security model, ADRs, roadmap, contribution templates.

## Verified

Fresh public clone:

- validator: PASS;
- Node tests: 9/9 PASS;
- CLI doctor: READY.

GitHub Actions Windows onboarding:

- PowerShell parse: PASS;
- installer dry run: PASS;
- real install on ephemeral Windows runner: PASS;
- generated launchers: PASS;
- CLI doctor: PASS.

## Important architecture clarification

Remote Desktop Commander remote MCP and MCP SuperAssistant are **separate access paths**.

Remote Desktop Commander is the recommended default.

MCP SuperAssistant is an optional browser compatibility bridge.

## Next

1. executable adapter interface;
2. user/project skill discovery;
3. recipe executor prototype;
4. audit ledger design;
5. structured capability health reporting;
6. cross-platform installers.

## Deliberately deferred

- dashboard;
- cloud control plane;
- marketplace;
- autonomous scheduling;
- large dependency graph.

The architecture is being expanded from contracts outward, not UI inward.
