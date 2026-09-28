---
name: connector-doctor
description: Diagnose external connector configuration, authentication state, and missing capability mappings.
status: stable
scope: generic
---

# Connector Doctor

Use when an external app integration exists but the workflow cannot access the expected data or action.

## Procedure

1. Identify the intended capability, not just the provider name.
2. Check whether the connector is installed/configured.
3. Check authentication state without exposing credentials.
4. Inspect available tools/actions.
5. Compare available actions to the workflow requirement.
6. Test the smallest safe read-only action.
7. Only then test mutation if the task requires it.

## Distinguish

- connector missing;
- connector unauthenticated;
- account mismatch;
- permission insufficient;
- capability unavailable;
- tool schema mismatch;
- upstream/provider failure.

Do not invent a missing tool or silently substitute a different account.
