---
name: skill-quality-auditor
description: Lint SKILL.md files for portable naming, metadata, size, and private-path problems before sharing.
status: stable
scope: generic
---

# Skill Quality Auditor

Use before publishing or installing community skills.

## Preferred tool

```text
otak-atik skill-check path/to/SKILL.md
```

## Checks

- frontmatter presence;
- name;
- description;
- kebab-case naming;
- recommended status/scope;
- oversized SKILL.md;
- folder/name mismatch;
- user-specific Windows paths.

A lint pass is not a security audit, but it catches avoidable packaging mistakes.
