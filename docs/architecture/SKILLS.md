# Skill Architecture

Skills use a portable `SKILL.md`-first structure.

```text
skill-name/
├── SKILL.md
├── references/
├── scripts/
├── templates/
└── tests/
```

Only `SKILL.md` is required.

## Progressive loading

The registry exposes only lightweight metadata first.

The skill body is loaded when relevant.

Supporting references or scripts are loaded only when needed.

## Status

- `stable`
- `incubating`
- `experimental`
- `reference`
- `deprecated`

## Scope

- `generic`
- `platform`
- `provider`
- `project`
- `personal`

Public core should mainly contain generic, platform, and carefully scoped provider skills.

Project/personal skills belong in overlays.

## Design rule

A skill should make an agent more precise without becoming a second system prompt.
