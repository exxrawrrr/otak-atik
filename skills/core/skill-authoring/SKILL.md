---
name: skill-authoring
description: Create compact portable SKILL.md modules with clear triggers, capability requirements, and verification.
status: incubating
scope: generic
---

# Skill Authoring

Use this skill to create or improve reusable Agent Skills.

## A good skill answers

- When should this be loaded?
- What capabilities does it require?
- What sequence or constraints matter?
- What must never happen silently?
- How is success verified?

## Authoring rules

1. Keep the core SKILL.md compact.
2. Move long references to `references/`.
3. Put deterministic repeated logic in scripts instead of prose.
4. Avoid project-specific names in generic skills.
5. Avoid provider-specific tool names unless the skill is provider-scoped.
6. State destructive or irreversible boundaries explicitly.
7. Include verification for mutation.
8. Do not turn a skill into a giant system prompt.

## Validation

Before publishing:

- frontmatter parses;
- name matches directory/registry;
- references exist;
- no secrets exist;
- no private workspace paths exist;
- capability requests are minimal.
