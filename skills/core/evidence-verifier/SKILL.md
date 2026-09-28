---
name: evidence-verifier
description: Convert execution results into explicit verification evidence and prevent unsupported done/success claims.
status: stable
scope: generic
---

# Evidence Verifier

Use after mutating or high-value workflows.

## Evidence states

- PASS
- FAIL
- CHANGED
- COULD_NOT_VERIFY

## Procedure

1. Identify the claimed outcome.
2. Identify the observable check that proves or disproves it.
3. Run the narrowest reliable verification.
4. Record the source and relevant artifacts.
5. Separate tool output from interpretation.
6. If verification is unavailable, report COULD_NOT_VERIFY.

## Rule

"Command returned exit code 0" proves command completion.

It does not automatically prove the user's goal was achieved.
