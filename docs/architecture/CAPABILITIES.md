# Capability Contract

Capabilities are provider-neutral descriptions of actions.

Example:

```json
{
  "id": "filesystem.write",
  "category": "filesystem",
  "risk": "medium",
  "mutating": true,
  "reversible": true,
  "scopable": true
}
```

## Required fields

- `id` — stable dotted identifier.
- `category` — broad action family.
- `risk` — low, medium, high, or critical.
- `mutating` — whether external state may change.
- `reversible` — whether rollback is meaningfully possible.
- `scopable` — whether policy can constrain the capability to paths/resources.

## Rule

Skills depend on capabilities.

Adapters provide capabilities.

Policies decide whether capabilities may run.

That separation is intentional.
