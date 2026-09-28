---
name: operator-healthcheck
description: Verify that an AI-to-desktop operator stack is actually ready before performing work.
status: stable
scope: generic
---

# Operator Healthcheck

Use before high-value work or when a user says the operator stack "should be connected."

## Check

- target device identity;
- client/tool availability;
- desktop transport process;
- relevant MCP endpoint;
- workspace scope;
- required runtime;
- requested skill availability;
- write permission only when needed.

## Verification

Run the smallest safe read-only operation that proves the requested path is alive.

"Process exists" is not the same as "end-to-end path works."
