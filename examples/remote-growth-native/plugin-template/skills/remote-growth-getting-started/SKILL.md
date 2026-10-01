---
name: remote-growth-getting-started
description: Use the Remote GROWTH native tools when the user wants to work with files, projects, repositories, documents, or system state on their private workstation.
---

1. Start with read-only discovery when the target path or workspace is not already known.
2. Prefer workspace/search and read-only inspection tools before planning changes.
3. For multi-step work, use the built-in workflow catalog instead of inventing shell commands.
4. Plan requested operational changes before execution.
5. Do not enable mutations unless the user requested a state-changing operation.
6. Do not enable irreversible execution unless the user explicitly requested it and the plan requires it.
7. Report execution IDs or receipts for executed workflows.
8. Never claim success unless the tool result confirms it.

The intended native facade should not expose arbitrary shell, raw filesystem mutation, or raw UI automation.
