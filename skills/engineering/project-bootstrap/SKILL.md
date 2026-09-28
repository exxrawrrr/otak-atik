---
name: project-bootstrap
description: Understand an unfamiliar software repository before implementation or debugging.
status: stable
scope: generic
---

# Project Bootstrap

Use at the start of work in an unfamiliar codebase.

## Required capabilities

- `filesystem.read`
- `git.read` when the workspace is a Git repository

## Inspect in this order

1. top-level files and directories;
2. README and contributor instructions;
3. package/build manifests;
4. workspace/monorepo configuration;
5. test configuration;
6. current Git status;
7. only then relevant source files.

## Produce a compact model

Identify:

- project type;
- package manager;
- entry points;
- package ownership boundaries;
- important scripts;
- test command;
- generated/vendor directories to avoid;
- repository-specific instructions.

Do not modify the project during bootstrap.
