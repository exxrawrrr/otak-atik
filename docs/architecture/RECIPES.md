# Recipes

Recipes are declarative workflow compositions.

A skill describes how to perform a class of work.

A recipe composes multiple skills/steps for a repeatable workflow.

Example:

```text
project-bootstrap
→ project-debugger
→ safe-file-editor
→ git-workflow
```

V0.1 stores recipe definitions but does not yet execute them automatically.

This is intentional: the format should stabilize before automation is trusted with mutation.
