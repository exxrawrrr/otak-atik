# ADR 0002 — Skills load on demand

## Status

Accepted.

## Decision

Skill metadata may be indexed broadly, but full skill bodies should be loaded only when relevant.

## Why

Context is finite.

Loading every available instruction degrades clarity and can create instruction conflicts.

## Consequence

Registry metadata must be useful enough for routing without requiring every SKILL.md body.
