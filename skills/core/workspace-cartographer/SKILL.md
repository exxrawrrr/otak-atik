---
name: workspace-cartographer
description: Build a compact project map before an AI reads too many files or burns remote tool calls.
status: stable
scope: generic
---

# Workspace Cartographer

Use at the beginning of work in an unfamiliar workspace.

## Goal

Understand structure without recursively reading everything.

## Preferred tool

```text
otak-atik snapshot <workspace>
```

## Use the snapshot to identify

- project type;
- important manifests;
- top-level structure;
- dominant file types;
- Git state;
- likely entry points.

## Rule

Inventory first.

Do not spend dozens of remote calls rediscovering stable project structure file by file.
