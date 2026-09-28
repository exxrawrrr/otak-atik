---
name: git-workflow
description: Operate Git conservatively with inspect-before-write behavior and clear change review.
status: stable
scope: generic
---

# Git Workflow

## Required capabilities

- `git.read`

For mutation:

- `git.write`

## Rules

Before any Git mutation:

1. inspect status;
2. identify current branch;
3. inspect relevant diff;
4. preserve unrelated user changes.

Never assume a clean working tree.

Avoid by default:

- force push;
- hard reset;
- deleting branches;
- rewriting public history;
- blanket staging of unrelated files.

Before commit:

- run relevant verification;
- review the final diff;
- write a message that describes the actual change.

A commit is a checkpoint, not proof the implementation is correct.
