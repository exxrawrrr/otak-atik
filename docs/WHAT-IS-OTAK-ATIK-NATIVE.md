# What is actually native to otak-atik?

This question matters.

A repository that only says "install plugin X, then load skills Y" is an integration guide, not a distinct operator system.

otak-atik deliberately uses existing providers for the low-level hands.

Its original contribution is moving upward into the **control layer**.

## Provider-owned

Examples:

- Remote Desktop Commander transport and desktop tools;
- Desktop Commander local MCP implementation;
- MCP SuperAssistant browser extension/proxy;
- QuickDesk GUI-control implementation;
- GitHub/Drive/other SaaS APIs.

otak-atik does not claim to have invented those.

## otak-atik-owned

### 1. Transport router

Given locality, browser constraints, GUI requirements, and remote quota state, choose the lowest-cost appropriate path.

Implementation:

```text
src/transport-router.mjs
```

### 2. Operator plan compiler

Turn a natural-language task plus environment context into a portable plan:

```text
task
→ transport
→ capabilities
→ skills
→ risk
→ execution contract
→ verification contract
```

Implementation:

```text
src/plan-compiler.mjs
```

### 3. Evidence contract

Results are not just "done".

otak-atik defines explicit evidence states:

- PASS
- FAIL
- CHANGED
- COULD_NOT_VERIFY

Implementation:

```text
src/evidence.mjs
```

### 4. Failure lab

Failed integrations are first-class data.

```text
labs/
├── experiments.json
└── reports/
```

A provider can therefore be:

- installed;
- detected;
- discovery-working;
- execution-working;
- verified;
- or partially failed.

Those are different states.

### 5. Portable policy/capability vocabulary

Skills ask for generic capabilities rather than vendor tool names.

Providers can change without rewriting every workflow.

## Direction

The end goal is not:

> one more plugin launcher.

The end goal is:

> a portable operator control plane that can decide how work should travel, what it may use, how risky it is, what evidence is required, and how provider failures are recorded.

That is the part that should remain valuable even if every underlying MCP provider changes.
