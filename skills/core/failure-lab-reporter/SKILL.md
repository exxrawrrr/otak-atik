---
name: failure-lab-reporter
description: Turn failed or partially successful integration experiments into reproducible evidence reports instead of hiding them.
status: stable
scope: generic
---

# Failure Lab Reporter

Use when an integration, provider, transport, installer, or workflow did not work reliably.

## Record

- intended topology;
- versions;
- environment;
- what was attempted;
- what objectively worked;
- what objectively failed;
- what remained unproven;
- logs/evidence;
- workaround;
- replacement path;
- lessons incorporated into architecture.

## Status vocabulary

Prefer:

- PASS
- FAIL
- PARTIAL_FAILURE
- COULD_NOT_VERIFY

Avoid vague language such as:

- seems fine;
- probably broken;
- should work;
- maybe fixed.

## Rule

A failed experiment is project knowledge.

Do not delete it merely because a newer provider works better.
