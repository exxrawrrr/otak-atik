---
name: change-risk-reviewer
description: Review a Git diff for deletions, dependency changes, workflow edits, config/schema changes, and other high-review surfaces before commit or push.
status: stable
scope: generic
---

# Change Risk Reviewer

Use before committing, pushing, releasing, or handing a large patch to another agent.

## Preferred tool

```text
otak-atik diff-risk .
```

## Heuristics

Raise attention for:

- deleted files;
- auth/security paths;
- environment files;
- migrations;
- GitHub Actions workflows;
- dependency manifests/lockfiles;
- config/schema changes;
- large diffs;
- binary changes.

## Rule

Risk is a **review priority signal**, not a correctness verdict.

HIGH means "review this carefully", not "this change is bad."
