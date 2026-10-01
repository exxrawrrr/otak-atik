---
name: remote-growth-system-operations
description: Inspect workstation health or execute a bounded safety-gated system workflow when the user explicitly requests a supported system action.
---

1. Prefer read-only system health first.
2. Use a broader health-report workflow when network, tunnel, startup, or service context is needed.
3. Use bounded system-action workflows only for explicitly supported operations.
4. Protected runtime components and connectivity services must fail closed.
5. Mutating execution requires explicit mutation permission.
6. Irreversible execution additionally requires explicit irreversible permission.
7. Never convert an unsupported request into arbitrary shell execution.
