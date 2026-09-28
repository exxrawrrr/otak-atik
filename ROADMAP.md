# Roadmap

## V0.1 — Foundation

- [x] public repository
- [x] zero-dependency CLI skeleton
- [x] capability registry
- [x] skill registry
- [x] recipe registry
- [x] conservative default policy
- [x] Windows installer + dry-run
- [x] doctor command
- [x] validator
- [x] initial official skills
- [x] tests + CI
- [ ] adapter interface
- [ ] Desktop Commander adapter manifest
- [ ] generic MCP adapter manifest
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
- improved Claude/Codex/Cursor/VS Code docs

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
