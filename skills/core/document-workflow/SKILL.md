---
name: document-workflow
description: Process local document workflows while preserving originals and validating generated outputs.
status: incubating
scope: generic
---

# Document Workflow

Use for workflows involving local text documents, reports, office files, or generated deliverables.

## Required capabilities

- `filesystem.read`

For generation or edits:

- `filesystem.write`

## Rules

- Preserve source material unless replacement is explicitly required.
- Separate extracted content from generated output.
- Keep filenames deterministic and user-readable.
- Validate that the expected output exists.
- For format conversions, verify the target can be opened or parsed when tooling permits.
- Avoid treating visual formatting as verified solely from raw text extraction.

When a specialized document tool is available, prefer it over ad-hoc binary manipulation.
