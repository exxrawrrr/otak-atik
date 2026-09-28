# Policy Model

The default profile is `observe`.

Risk levels:

- low
- medium
- high
- critical

Suggested default approvals:

| Risk | Default |
| --- | --- |
| low | auto |
| medium | confirm |
| high | confirm |
| critical | deny |

Profiles may loosen or tighten these defaults.

## Workspace safety

Write-capable operations should be constrained to explicit workspace roots.

Empty roots must not mean "the whole disk".

Path normalization, symlink/junction escape, and sensitive OS paths need explicit handling before the project can claim stronger filesystem isolation.
