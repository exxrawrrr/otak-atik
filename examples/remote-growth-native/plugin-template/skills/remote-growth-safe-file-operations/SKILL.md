---
name: remote-growth-safe-file-operations
description: Safely assess storage or plan and execute batch file operations with verification, receipts, quarantine semantics, and rollback.
---

1. Resolve uncertain paths before planning changes.
2. Use storage assessment for read-only size and duplicate analysis.
3. Use safe batch workflows for copy, move, rename, mkdir, or delete-to-quarantine operations.
4. Treat delete as quarantine semantics when the underlying engine supports that contract.
5. Plan before execution.
6. Preserve the workflow execution ID so rollback can be used when supported.
7. Never bypass destination-conflict, protected-path, plan-hash, or precondition failures.
