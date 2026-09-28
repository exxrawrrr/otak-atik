---
name: desktop-inspector
description: Inspect a desktop, machine, or workspace without modifying it.
status: stable
scope: generic
---

# Desktop Inspector

Use this skill when the task is to understand a machine or workspace before making changes.

## Required capabilities

- `filesystem.read`
- `process.inspect` when available

## Operating contract

1. Start read-only.
2. Establish the target workspace before traversing broadly.
3. Prefer metadata, directory listings, manifests, and known entry points over reading every file.
4. Identify runtimes, package managers, repository state, and likely project boundaries.
5. Do not mutate files, processes, Git state, or system configuration.
6. Report unavailable capabilities explicitly.

## Output

Return:

- environment summary;
- relevant workspace structure;
- detected runtimes/tools;
- likely next actions;
- any safety or access limitation.

## Stop condition

If the user asks to modify something, hand off to a mutation-capable skill rather than silently expanding scope.
