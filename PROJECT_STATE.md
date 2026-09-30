# Project State

**Current milestone:** V0.2 native operator/control layer + Rafdi Remote experimental transport
**Repository maturity:** active public experiment / research lab
**Current package:** 0.1.0-alpha.5

## Honest status

otak-atik did **not** replace the author's primary remote plugin workflow.

The daily remote path is still usually:

```text
ChatGPT
â†’ Remote Desktop Commander
â†’ GROWTH
```

That original goal therefore remains a failure.

But the project also produced a separate experimental path that now works in real use:

```text
ChatGPT
â†’ Composio Custom MCP
â†’ Tailscale Funnel
â†’ Windows-MCP
â†’ GROWTH
```

This path is called **Rafdi Remote**.

It is not presented as a production remote-desktop replacement, but it has moved beyond architecture-only status.

## Rafdi Remote evidence

On the original GROWTH Windows machine, the experiment has verified:

- loopback-only Windows-MCP binding;
- bearer authentication;
- FastMCP host-origin protection;
- real public Tailscale Funnel transport;
- rejection of unauthenticated public requests;
- authenticated MCP initialize;
- supervisor child recovery;
- Scheduled Task/logon-style recovery;
- Tailscale down/up persistence;
- actual Windows restart persistence;
- post-restart ChatGPT â†’ Composio â†’ GROWTH command execution.

Detailed evidence:

- `docs/RAFDI-REMOTE-GROWTH.md`
- `docs/RAFDI-REMOTE-GROWTH-PHASE-2A-CHECKPOINT.md`
- `docs/RAFDI-REMOTE-GROWTH-PHASE-2B-CHECKPOINT.md`
- `docs/decisions/ADR-RAFDI-REMOTE-TRANSPORT.md`

## Implemented project areas

### Onboarding / transports

- Windows installer + dry-run;
- Remote Desktop Commander onboarding/helpers;
- optional MCP SuperAssistant browser bridge experiment;
- Codex local Desktop Commander MCP setup helper;
- quota-aware local/remote guidance;
- Rafdi Remote reusable Windows installer experiment.

### Native otak-atik engine

- transport router;
- operator plan compiler;
- capability inference;
- risk/approval contract;
- evidence contract;
- provider scorecard;
- failure/research lab;
- executable routing benchmark;
- CLI route / plan / providers / lab commands.

### Registry / skills

- canonical capability registry;
- official skills and packs;
- recipes;
- provider states;
- explicit PARTIAL_FAILURE record for MCP SuperAssistant.

### Standalone utility pack

Useful without any remote provider:

- workspace snapshot;
- secret hygiene scanner;
- MCP config auditor;
- SKILL.md quality auditor;
- provider-neutral AI handoff builder;
- Git diff risk reviewer.

### Quality

- deterministic validators;
- self-hygiene in `npm run check`;
- skill audit in `npm run check`;
- Node contract/unit tests;
- benchmark scenarios;
- Windows PowerShell smoke validation;
- Rafdi Remote regression tests;
- security/contribution/ADR documentation.

## Current real workflows

Remote daily:

```text
ChatGPT
â†’ Remote Desktop Commander
â†’ GROWTH
```

Remote backup / self-built path:

```text
ChatGPT
â†’ Composio Custom MCP
â†’ Tailscale Funnel
â†’ Windows-MCP
â†’ GROWTH
```

Local engineering:

```text
Codex / local AI
â†’ Desktop Commander local MCP
â†’ GROWTH
```

Browser-extension experiment:

```text
MCP SuperAssistant
â†’ discovery works
â†’ reliable daily execution not proven
â†’ PARTIAL_FAILURE
```

## What is not claimed

The repository is not claiming:

- production-grade remote desktop;
- universal clean-machine reproducibility;
- zero-trust remote access;
- unattended Tailscale account approval;
- unattended Composio Custom MCP creation;
- a finished V1 operator platform.

## Next useful milestones

1. clean-machine Rafdi Remote reproduction on another Windows profile/device;
2. version compatibility / pinning decision for Windows-MCP and FastMCP;
3. executable adapter runtime;
4. provider health probing;
5. automatic user/project skill discovery;
6. declarative recipe executor;
7. persistent evidence/audit ledger;
8. optional GUI-control experiments.

## Research rule

The project is allowed to change direction.

Failed experiments stay documented.

Real usage outranks roadmap aesthetics.

A working plugin is better than a homemade architecture that is not used.

A homemade path becomes interesting only after it survives reality.
