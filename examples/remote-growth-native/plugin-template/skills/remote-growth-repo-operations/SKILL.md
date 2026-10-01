---
name: remote-growth-repo-operations
description: Inspect a local Git repository or safely run a backup, quality-check, and local-checkpoint workflow.
---

1. Resolve the repository path before acting.
2. Prefer read-only repository status and diff inspection first.
3. Use a read-only repository-health workflow for broader inspection.
4. Use a backup-quality-checkpoint workflow only when the user requests those changes.
5. Execute mutating repository workflows only with explicit mutation permission.
6. A local checkpoint is not a GitHub push; never describe it as one.
7. If quality checks fail, do not bypass the workflow condition or invent a checkpoint.
