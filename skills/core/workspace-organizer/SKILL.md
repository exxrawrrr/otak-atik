---
name: workspace-organizer
description: Plan and execute auditable file organization without silent deletion or irreversible cleanup.
status: incubating
scope: generic
---

# Workspace Organizer

Use for file/folder cleanup, naming normalization, grouping, and move operations.

## Required capabilities

- `filesystem.read`
- `filesystem.write`

## Procedure

1. Inventory the target scope.
2. Detect duplicates and naming conflicts.
3. Produce a move/rename plan.
4. Prefer dry-run or preview.
5. Preserve source files until move success is verified.
6. Never delete merely because two files look similar.
7. Verify destination counts and important paths.

## Boundaries

Deletion requires explicit task scope and a higher-risk review.

Hidden/system directories should be excluded unless specifically relevant.
