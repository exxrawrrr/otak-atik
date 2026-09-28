# Roadmap

## V0.1 — Foundation

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
- [x] 18 official starter/operator skills
- [x] Linux-side contract tests
- [x] Windows-native onboarding CI
- [ ] executable adapter interface
- [x] Desktop Commander reference adapter manifest
- [x] generic MCP reference adapter manifest
- [ ] user skill discovery from `~/.otak-atik/skills`
- [ ] project skill discovery from `.otak-atik/skills`

## V0.2 — Operator engine

- declarative recipe executor
- capability resolution against installed adapters
- policy evaluation before execution
- structured verification results
- local audit ledger
- checkpoint model

## V0.3 — Portability

- macOS installer
- Linux installer
- client adapter generators
- expanded Claude/Cursor/VS Code/Gemini verification matrix
- optional GUI-control provider experiments

## V0.4 — Ecosystem

- community registry
- signed skill packages
- trust metadata
- adapter SDK stabilization

## V1.0

Requires:

- stable config format;
- stable capability schema;
- migration strategy;
- Windows/macOS/Linux support;
- security review;
- reliable upgrade path;
- production-quality docs.
