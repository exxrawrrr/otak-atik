# Adapters

Adapters map provider-specific actions to canonical capabilities.

Example:

```text
provider.read_file
        ↓
filesystem.read
```

## Adapter responsibilities

An adapter declares:

- provider;
- transport;
- capability mappings;
- health strategy;
- provider limitations.

## Non-responsibilities

An adapter should not contain the full workflow logic for debugging, publishing, auditing, or other jobs.

That belongs in skills and recipes.

## Safety

Mutation mappings must be explicit.

The project should not infer that an unknown provider tool is equivalent to `filesystem.write` merely because its name sounds similar.
