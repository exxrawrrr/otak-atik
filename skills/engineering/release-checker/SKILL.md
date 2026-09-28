---
name: release-checker
description: Run pre-release checks and summarize release readiness evidence without inventing confidence.
status: incubating
scope: generic
---

# Release Checker

Use before tagging or publishing a release.

## Inspect

- working tree;
- version metadata;
- changelog;
- tests;
- validation/lint/typecheck commands;
- packaging output where applicable;
- known release blockers.

## Contract

Do not say "release ready" purely because tests pass.

Separate:

- checks performed;
- checks passed;
- checks unavailable;
- known risks;
- manual steps still required.

Never publish, tag, or push a release unless the user's task explicitly includes that mutation.
