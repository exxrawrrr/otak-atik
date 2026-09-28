# Roadmap

## V0.1 — Foundation / onboarding

- [x] public repository
- [x] zero-dependency CLI skeleton
- [x] capability registry
- [x] skill registry
- [x] recipe registry
- [x] conservative default policy
- [x] Windows installer + dry-run
- [x] automatic Desktop launcher folder
- [x] Remote Desktop Commander click-to-run launcher
- [x] MCP SuperAssistant optional browser-bridge launcher
- [x] setup decision tree
- [x] doctor command
- [x] validator
- [x] 23 official starter/operator skills
- [x] Linux-side contract tests
- [x] Windows-native onboarding CI
- [x] Desktop Commander reference adapter manifest
- [x] generic MCP reference adapter manifest

## V0.2 — Native operator engine

- [x] transport router
- [x] quota-aware route selection
- [x] operator plan compiler
- [x] capability inference
- [x] risk / approval contract
- [x] evidence status contract
- [x] provider scorecard
- [x] failed-experiment lab
- [x] routing benchmark scenarios
- [x] CLI route / plan / providers / lab commands
- [ ] executable adapter interface
- [ ] provider health probing
- [ ] user skill discovery from `~/.otak-atik/skills`
- [ ] project skill discovery from `.otak-atik/skills`
- [ ] declarative recipe executor
- [ ] persistent local evidence/audit ledger
- [ ] checkpoint model

## V0.3 — Provider lab + portability

- stronger provider benchmark harness
- execution/discovery/verification compatibility matrix
- macOS installer
- Linux installer
- client adapter generators
- Claude/Cursor/VS Code/Gemini verification matrix
- optional GUI-control provider experiments

## V0.4 — Ecosystem

- community registry
- signed skill packages
- trust metadata
- adapter SDK stabilization
- import/exportable operator plans
- reproducible experiment bundles

## V1.0

Requires:

- stable config format;
- stable capability and plan schemas;
- stable evidence contract;
- migration strategy;
- Windows/macOS/Linux support;
- security review;
- reliable upgrade path;
- production-quality docs;
- enough real-world use to know what the project actually wants to be.

## Research rule

The project is allowed to change direction.

Failed experiments are retained as evidence.

Real usage outranks roadmap aesthetics.
