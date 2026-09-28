---
name: safe-file-editor
description: Perform controlled file edits with preflight, minimal diffs, and verification.
status: stable
scope: generic
---

# Safe File Editor

Use for targeted file modifications.

## Required capabilities

- `filesystem.read`
- `filesystem.write`

## Procedure

1. Confirm the intended file is inside the allowed workspace.
2. Read the relevant surrounding content before editing.
3. Preserve existing structure and style unless the task explicitly requires a redesign.
4. Prefer the smallest coherent patch.
5. Never overwrite unknown binary content as text.
6. After writing, re-read the changed region.
7. When a project provides tests, parsers, linters, or validators relevant to the file, run them.
8. Summarize exactly what changed.

## High-risk behavior

Do not:

- bulk-delete;
- recursively rewrite unrelated files;
- modify secrets;
- edit operating-system paths;
- use a destructive command when a direct file edit is available.

Mutation without verification is incomplete.
