# Contributing

Thanks for helping improve otak-atik.

## Before opening a PR

Run:

```bash
npm run check
```

## Good contributions

- small provider-neutral capabilities;
- compact reusable skills;
- deterministic validators;
- safer defaults;
- adapter mappings;
- test fixtures;
- documentation that reduces ambiguity.

## Skill contributions

A skill should:

- have clear trigger conditions;
- request only necessary capabilities;
- include verification guidance for mutating work;
- avoid provider lock-in unless explicitly provider-scoped;
- avoid personal/company-specific assumptions.

Add it to `registries/skills.json`.

## Architecture changes

Changes to capability semantics, policy behavior, or config formats should include an architecture decision record under `docs/decisions/`.

## Pull requests

Keep PRs reviewable.

One coherent change is better than a "while I was here I rebuilt civilization" patch.

## Code style

Prefer standard platform APIs and small modules.

A dependency needs to earn its place.
