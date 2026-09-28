---
name: project-debugger
description: Diagnose, fix, and verify failures in software projects.
status: stable
scope: generic
---

# Project Debugger

Use when a project build, test, runtime, or integration is failing.

## Required capabilities

- `filesystem.read`
- `filesystem.write`
- `terminal.execute`

Optional:

- `git.read`

## Workflow

```text
reproduce
→ capture evidence
→ isolate cause
→ make smallest coherent fix
→ rerun targeted check
→ rerun broader relevant check
→ review diff
→ report
```

## Rules

- Reproduce before editing when practical.
- Do not "fix" a failing test by deleting or weakening the test unless the test is demonstrably incorrect and the task allows it.
- Avoid dependency upgrades unless the evidence points there.
- Preserve public APIs unless required.
- If multiple causes are plausible, test the cheapest discriminator first.
- Stop if the fix requires access outside the approved workspace.

## Verification

A fix is not complete until the previously failing behavior is checked again.
