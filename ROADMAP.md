# Roadmap

Updated: **2026-10-03**

## V0.1 — Foundation / onboarding

- [x] public repository
- [x] zero-dependency CLI skeleton
- [x] capability registry
- [x] skill registry
- [x] recipe registry
- [x] conservative default policy
- [x] Windows installer + dry-run
- [x] Remote Desktop Commander onboarding
- [x] optional browser-bridge experiments
- [x] setup decision tree
- [x] doctor / validators
- [x] official starter/operator skills
- [x] Windows-native onboarding CI

## V0.2 — Native operator research engine

- [x] transport router
- [x] quota-aware route selection
- [x] operator plan compiler
- [x] capability inference
- [x] risk / approval contract
- [x] evidence status contract
- [x] provider scorecard
- [x] failure / research lab
- [x] routing benchmark scenarios
- [x] CLI route / plan / providers / lab commands
- [ ] stabilize executable adapter interface as a public package
- [ ] portable user/project skill discovery
- [ ] portable declarative recipe executor
- [ ] portable persistent audit ledger

## Remote GROWTH — real-machine operator track

### Historical transport milestone

- [x] Windows-MCP loopback binding
- [x] bearer authentication
- [x] Tailscale Funnel transport
- [x] supervisor recovery
- [x] Scheduled Task recovery
- [x] Tailscale reconnect
- [x] actual Windows reboot test
- [x] post-reboot ChatGPT command execution

### Gateway / engines

- [x] gateway compatibility layer
- [x] preserve 15 Windows primitive tools
- [x] Fast Local persistent search/index engine
- [x] Document Engine
- [x] Developer / Git Engine
- [x] Safe File & Workspace Operations Engine
- [x] System / Process / Network Operations Engine
- [x] Smart Workflow / Batch Orchestrator
- [x] gateway v0.7.0
- [x] 64-tool server inventory
- [x] Composio catalog synced to 64 available actions

### Safety

- [x] protected runtime targets
- [x] plan-before-mutation model
- [x] irreversible-action gate
- [x] precondition verification
- [x] FileOps receipts / rollback
- [x] SystemOps receipts / rollback
- [x] workflow receipts
- [x] workflow rollback
- [x] duplicate workflow execution guard
- [x] no arbitrary shell inside workflow specs

## Native ChatGPT plugin track

### Prepared

- [x] focused native facade
- [x] 12-tool native inventory
- [x] raw operator primitives excluded
- [x] read/write/destructive tool annotations
- [x] loopback-only native listener
- [x] five plugin skills
- [x] plugin manifest
- [x] pre-registration plugin ZIP
- [x] secret scan
- [x] ZIP integrity verification
- [x] official OpenAI tunnel-client installed and checksum verified
- [x] secure helper scripts prepared
- [x] reusable public native bootstrap with LocalAppData isolation
- [x] optional current-user DPAPI credential cache
- [x] identity-neutral public plugin template + builder

### Phase 10 — final private registration / acceptance

- [x] establish the private Secure MCP Tunnel session
- [x] create ChatGPT MCP app through the Tunnel path
- [x] verify exactly 12 native tools
- [x] capture and verify the real generated app technical ID privately
- [x] finalize private app mapping locally (not committed)
- [x] build final private plugin archive v1.0.0 with secret scan
- [x] create/update PRIVATE Remote GROWTH Stable plugin
- [x] read-only acceptance suite
- [x] plan-only acceptance
- [x] isolated write + rollback acceptance
- [x] protected-negative acceptance
- [x] reconnect acceptance — warm native-backend recovery through existing Secure MCP Tunnel
- [ ] optional zero-touch cold tunnel restart / reboot enrollment
- [x] final release/checkpoint lock with manual cold-start limitation documented

## Guided Composio onboarding — user-ready track

### CHAT 1 — UX + setup flow

- [x] define the non-technical user journey
- [x] keep Tailscale in the architecture while hiding unnecessary transport jargon
- [x] separate user-owned login/approval actions from installer-owned automation
- [x] define Remote GROWTH identity/auth verification before Composio connection
- [x] define Composio guided connection and copy/open behavior
- [x] define 64-tool acceptance target
- [x] define START / STATUS / REPAIR launcher responsibilities
- [x] define resumable onboarding state and human-readable error states
- [x] lock branding: `Created by Rafdi D. Ulhaq — exxrawrrr`

UX contract: [docs/COMPOSIO-TAILSCALE-SETUP-UX.md](docs/COMPOSIO-TAILSCALE-SETUP-UX.md)

### Remaining implementation

- [x] CHAT 2 — Beautiful Terminal Wizard
- [x] CHAT 3 — Tailscale + Composio Guided Wiring
- [ ] CHAT 4 — STATUS + REPAIR
- [ ] CHAT 5 — Fresh-User Acceptance + Release

## Portability / public reproduction

After the private Phase 10 acceptance is complete:

- [ ] remove remaining machine-specific assumptions from public installer docs
- [ ] clean-machine reproduction on a second Windows profile/device
- [ ] compatibility matrix for Windows-MCP / FastMCP / gateway dependencies
- [ ] reproducible engine packaging
- [ ] public sample configuration without machine identity
- [ ] installer/uninstaller regression on clean VM
- [ ] public threat-model review

## Longer-term research

- macOS/Linux operator experiments;
- provider benchmark harness;
- community adapters;
- signed skill/package metadata;
- import/exportable operator plans;
- stronger evidence ledger;
- optional GUI-control provider research.

## V1.0 criteria

V1.0 requires more than “it works on GROWTH”.

It requires:

- stable config and migration formats;
- reproducible installation;
- security review;
- clean-machine validation;
- upgrade/rollback strategy;
- explicit private/public boundaries;
- production-quality docs;
- enough multi-machine use to know which machine-specific decisions should become product contracts.

## Research rule

Failed experiments remain evidence.

Real usage outranks roadmap aesthetics.

Do not call a milestone complete until its acceptance test actually passes.
