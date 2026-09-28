# Project State

**Current milestone:** V0.2 Native operator/control layer  
**Repository maturity:** active public experiment  
**Current package:** 0.1.0-alpha.3

## Important honesty

otak-atik is **not finished**, and its final destination is not locked.

It began as a practical wrapper around existing MCP providers, launchers, and skills.

It is now deliberately growing its own provider-neutral control layer.

## Implemented

### Onboarding / transports

- Windows installer + dry-run;
- automatic Desktop launcher generation;
- Remote Desktop Commander remote start/status/stop helpers;
- optional MCP SuperAssistant browser bridge;
- Codex local Desktop Commander MCP setup helper;
- quota-aware local/remote transport guidance.

### Native otak-atik engine

- transport router;
- operator plan compiler;
- capability inference;
- risk/approval contract;
- evidence contract;
- provider scorecard;
- failure/research lab;
- executable routing benchmark;
- CLI commands: route, plan, providers, lab.

### Registry / skills

- 10 canonical capabilities;
- 23 official skills;
- 4 skill packs;
- 3 recipes;
- 5 provider states;
- explicit PARTIAL_FAILURE record for the MCP SuperAssistant experiment.

### Quality

- deterministic validators;
- Node contract/unit tests;
- benchmark scenarios;
- Windows PowerShell smoke validation;
- security/contribution/ADR documentation.

## Real-world evidence

Primary current route:

```text
ChatGPT
→ Remote Desktop Commander
→ GROWTH
```

Local engineering direction:

```text
Codex / local AI
→ Desktop Commander local MCP
→ GROWTH
```

Browser-extension experiment:

```text
MCP SuperAssistant
→ discovery works
→ reliable daily tool execution not proven
→ PARTIAL_FAILURE
```

## Next native milestones

1. executable adapter runtime;
2. provider capability health probing;
3. automatic user/project skill discovery;
4. declarative recipe executor;
5. persistent evidence/audit ledger;
6. checkpoints/rollback contract;
7. stronger provider benchmark harness;
8. optional GUI-control adapter experiments.

## Possible future shapes

The project may become:

- an operator CLI;
- a transport router;
- an Agent Skills runtime;
- an evidence/verification layer;
- a provider benchmark lab;
- a local control plane;
- or a hybrid of those.

The roadmap is a direction, not a promise that today's architecture survives unchanged.
