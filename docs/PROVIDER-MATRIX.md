# Provider matrix

otak-atik does not treat "mentioned in the README" as equivalent to "works."

## Status vocabulary

| Status | Meaning |
| --- | --- |
| AUTHOR_PRIMARY | used as a normal real workflow by the author |
| SUPPORTED_PATH | implemented/tested enough to be a recommended path |
| PARTIAL_FAILURE | some layers work, but end-to-end reliability was not proven |
| CANDIDATE_UNVERIFIED | interesting provider, not yet author-verified |
| DEPRECATED | retained for history/migration only |

## Current matrix

The machine-readable source is:

```text
registries/providers.json
```

Current highlights:

- Remote Desktop Commander — **AUTHOR_PRIMARY**
- Desktop Commander local MCP — **SUPPORTED_PATH**
- MCP SuperAssistant — **PARTIAL_FAILURE**
- QuickDesk — **CANDIDATE_UNVERIFIED**
- Windows MCP Server — **CANDIDATE_UNVERIFIED**

## Why this matters

An integration can pass several different milestones:

```text
installed
→ detected
→ connected
→ discovery works
→ execution works
→ verification works
→ reliable enough for daily use
```

Those states must not be collapsed into a single green checkmark.

This matrix is intended to become a compatibility lab rather than a marketing list.
