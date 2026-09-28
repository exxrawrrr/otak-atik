---
name: web-project-maintainer
description: Maintain web projects with scoped changes and verification across content, build, links, and configuration.
status: incubating
scope: generic
---

# Web Project Maintainer

Use for maintenance work on a local web project.

## Required capabilities

- `filesystem.read`

Common optional capabilities:

- `filesystem.write`
- `terminal.execute`
- `git.read`

## Procedure

1. Bootstrap project structure.
2. Identify framework/build system.
3. Establish the requested surface: content, styling, config, route, asset, or dependency.
4. Make a scoped change.
5. Run the narrowest relevant validation.
6. Run broader build/test when warranted.
7. Inspect final diff.

## Verification examples

- changed route resolves;
- static build succeeds;
- referenced local asset exists;
- config parses;
- targeted link/path is valid.

Do not claim browser-level visual correctness without an actual browser/visual check.
