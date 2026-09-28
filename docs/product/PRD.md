# Product Requirements Document

**Product:** otak-atik  
**Stage:** public alpha  
**Architecture:** local-first, MCP-native, skill-driven, client-agnostic

## Problem

AI clients are increasingly capable of reasoning and tool use, but operator workflows remain fragmented across desktop access, MCP tools, SaaS connectors, local commands, prompts, and provider-specific configuration.

Giving an AI "desktop access" solves only one layer.

Users also need:

- capability discovery;
- procedural skills;
- permission boundaries;
- reproducible workflows;
- diagnostics;
- verification;
- auditability.

## Core model

```text
CAPABILITY + SKILL + POLICY + VERIFICATION
```

### Capability

A provider-neutral action such as `filesystem.read`.

### Skill

A portable instruction module describing how a class of work should be performed.

### Policy

Rules defining whether, where, and under what approval level a capability may execute.

### Verification

Evidence that a mutating action produced the intended result.

## Primary users

- AI power users;
- software developers;
- digital operators;
- automation enthusiasts;
- teams experimenting with MCP and Agent Skills.

## Required V0.1 outcomes

A fresh user should be able to:

1. clone the repository;
2. run a dry-run installer;
3. install the local CLI;
4. run `otak-atik doctor`;
5. inspect capability, skill, and recipe registries;
6. understand the permission model;
7. author and validate a new skill;
8. connect a supported desktop/MCP provider without changing skill semantics.

## Functional requirements

### CLI

Commands at minimum:

- doctor
- capabilities
- skills
- recipes
- policy
- version

### Capability registry

Each capability declares:

- stable id;
- category;
- risk;
- mutating flag;
- reversibility;
- whether it can be path/resource scoped.

### Skill registry

Each official skill declares:

- name;
- status;
- scope;
- description;
- canonical path.

Official skills must be small enough to load selectively.

### Policy profiles

Profiles:

- observe;
- workspace;
- developer;
- operator;
- power.

Default: observe.

### Diagnostics

`doctor` must check at least:

- Node version;
- Git availability;
- required repository assets;
- valid registries;
- skill/recipe counts.

### Installation

The Windows installer must:

- support dry-run;
- preserve existing user config unless explicitly forced;
- avoid destructive system changes;
- produce a runnable CLI.

### Security

The project must document threats from:

- malicious skills;
- malicious MCP servers;
- prompt injection;
- filesystem escape;
- command injection;
- secret leakage;
- compromised dependencies.

## Non-functional requirements

- zero runtime dependencies for the alpha CLI;
- deterministic validation;
- no telemetry by default;
- no personal paths or credentials in public core;
- CI validation for every pull request;
- readable architecture documentation.

## Acceptance contract

A release candidate is not acceptable if:

- validation fails;
- built-in skill paths are broken;
- default policy grants broad mutation;
- private paths or credentials appear in tracked files;
- the documented quickstart does not work.

## Future requirements

Later releases may add:

- adapter SDK;
- recipe executor;
- local audit database;
- rollback/checkpoint support;
- macOS/Linux installers;
- local dashboard;
- signed community skills.

These are intentionally not blockers for the first public alpha.
