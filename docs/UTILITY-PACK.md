# Standalone Utility Pack

The fastest way to understand otak-atik is to use it **without any plugin at all**.

These commands only require Node.js 20+.

## Project snapshot

```bash
otak-atik snapshot .
```

Produces a compact machine-readable map containing:

- file/directory counts;
- top-level entries;
- dominant extensions;
- important manifests;
- Git branch/dirty state.

It intentionally does not dump source contents.

## Secret hygiene

```bash
otak-atik hygiene .
otak-atik hygiene . --strict
```

Looks for high-signal credential patterns and reports only:

- file;
- line;
- credential type;
- severity.

**Matched secret values are never printed.**

`--strict` exits non-zero when findings exist, useful in CI.

## MCP config audit

```bash
otak-atik mcp-check path/to/mcp.json
```

Checks common mistakes:

- invalid JSON;
- missing `mcpServers`;
- missing command/URL;
- malformed args/env;
- invalid URL;
- remote plain HTTP;
- suspicious inline secret values.

## Skill lint

```bash
otak-atik skill-check path/to/SKILL.md
```

Checks portable SKILL.md basics:

- frontmatter;
- name/description;
- kebab-case;
- recommended status/scope;
- size;
- folder/name mismatch;
- private Windows paths.

## AI handoff

```bash
otak-atik handoff . --task "continue fixing the build"
otak-atik handoff . --task "continue fixing the build" --out handoff.json
```

Creates a provider-neutral handoff with:

- workspace snapshot;
- Git state;
- package scripts;
- task;
- hygiene counts;
- operating notes.

No secret values are embedded.

## Why these exist

A visitor should not need to buy a service, install a browser extension, or configure a remote MCP just to get value from the repository.

These tools are also building blocks for the larger operator engine.
