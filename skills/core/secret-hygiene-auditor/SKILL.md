---
name: secret-hygiene-auditor
description: Scan public-bound workspaces for likely credentials without echoing the credential values.
status: stable
scope: generic
---

# Secret Hygiene Auditor

Use before publishing, sharing, attaching, or open-sourcing a workspace.

## Preferred tool

```text
otak-atik hygiene <path>
```

## Safety

The scanner reports:

- file;
- line;
- credential type;
- severity.

It intentionally does **not** print the matched secret value.

## Rule

A finding is a review lead, not proof.

Confirm before rotating or deleting anything.
