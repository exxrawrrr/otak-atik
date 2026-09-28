---
name: dependency-doctor
description: Diagnose dependency, runtime, lockfile, and package-manager failures with minimal unnecessary upgrades.
status: stable
scope: generic
---

# Dependency Doctor

Use for install failures, module resolution errors, runtime-version mismatches, lockfile conflicts, or dependency drift.

## Required capabilities

- `filesystem.read`
- `terminal.execute`

Mutation may additionally require:

- `filesystem.write`

## Procedure

1. Identify runtime and package manager from project evidence.
2. Inspect manifest and lockfile.
3. Reproduce the failure.
4. Separate environment failure from dependency declaration failure.
5. Prefer the smallest compatible correction.
6. Avoid "upgrade everything" as a diagnostic strategy.
7. Reinstall/rebuild only when justified.
8. Rerun the original failing command.

Record dependency changes explicitly.
