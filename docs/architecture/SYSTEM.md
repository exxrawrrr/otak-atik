# System Architecture

## Logical layers

```text
AI client
  ↓
client adapter
  ↓
operator core
  ├─ capability resolver
  ├─ skill router
  ├─ recipe engine
  └─ verification contract
  ↓
policy engine
  ↓
tool adapters
  ├─ desktop
  ├─ MCP
  ├─ SaaS
  └─ local CLI
```

## Architectural boundary

otak-atik does not need to own the model or the desktop transport.

A provider is replaceable when it maps onto the same capability contract.

For example:

```text
Desktop provider A ─┐
Desktop provider B ─┼─> filesystem.read
Local MCP server  ──┘
```

A skill can then request `filesystem.read` without caring which transport provides it.

## State

V0.1 keeps the architecture state-light.

User-specific configuration belongs under `~/.otak-atik/`.

Future audit state may use a local SQLite database, but the schema should remain independent from an AI vendor.

## Reasoning boundary

The AI client performs reasoning.

otak-atik supplies structure, contracts, registries, and execution boundaries around that reasoning.

This separation keeps the project useful across different AI clients.
