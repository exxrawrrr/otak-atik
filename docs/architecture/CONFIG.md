# Configuration

User state belongs under:

```text
~/.otak-atik/
```

The repository default is intentionally conservative.

## Resolution model

Future configuration resolution should follow:

```text
built-in defaults
→ user config
→ project overlay
→ explicit session override
```

An override may tighten permissions freely.

Permission expansion must remain visible and deliberate.

## Profiles

Reference profiles live under `config/profiles/`.

They are policy presets, not operating-system sandboxes.
