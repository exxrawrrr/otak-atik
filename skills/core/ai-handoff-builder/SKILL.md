---
name: ai-handoff-builder
description: Produce a compact provider-neutral project handoff so work can move between ChatGPT, Codex, Claude, or another agent.
status: stable
scope: generic
---

# AI Handoff Builder

Use when moving a task between AI clients or starting a fresh session.

## Preferred tool

```text
otak-atik handoff <workspace> --task "what needs to happen"
```

## Handoff includes

- compact workspace snapshot;
- Git state;
- package scripts;
- task;
- hygiene counts;
- safety notes.

It intentionally excludes secret values.

## Goal

Make continuity portable across AI vendors without pasting the entire repository into context.
