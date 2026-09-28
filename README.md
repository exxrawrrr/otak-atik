# otak-atik

> **AI-ne wes pinter. Saiki tangane sing dirapekno.**
>
> Your AI can think. **otak-atik** gives it a workspace, tools, skills, safety rails, and a way to verify its work.

```text
AI client
   │
   ├── ChatGPT
   ├── Codex
   ├── Claude
   ├── Cursor
   ├── VS Code
   └── any MCP-capable client
          │
          ▼
      otak-atik
          │
   ┌──────┼───────────┐
   ▼      ▼           ▼
 tools   skills     recipes
   │      │           │
   └──────┴─────┬─────┘
                ▼
          policy engine
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
    desktop    MCP      local CLI
```

## Ngene loh, cak.

The problem was never that AI could not write enough words.

The problem was that a normal chat often stops exactly where real work begins:

> "Cool. Now can you actually inspect the folder, run the test, fix the file, verify it, and tell me what changed?"

That gap is what this repo is about.

**otak-atik is a local-first operator layer for connecting existing AI clients to desktop tools, MCP connectors, reusable Agent Skills, policy rules, recipes, and verification.**

It is **not another LLM**.  
It is **not a subscription bypass**.  
It is **not a magical unrestricted computer-control bot**.

It is the boring-important layer between:

```text
"I want this done"
        ↓
what capabilities are available?
        ↓
which skill should be loaded?
        ↓
what is this action allowed to touch?
        ↓
execute
        ↓
verify
        ↓
show me the evidence
```

Because this is less funny:

```text
load 63 tools
load 41 skills
pray to the context window
edit random files
"done bro"
```

## Why the weird name?

"Otak-atik" in Indonesian roughly means tinkering, fiddling, adjusting things until they work.

That is basically the entire project.

Except we are trying to make the tinkering:

- inspectable;
- portable;
- recoverable;
- permission-aware;
- and slightly less cursed.

## What makes this different?

Desktop access alone is not enough.

A useful operator stack needs four independent concepts:

```text
CAPABILITY  → what can be done
SKILL       → how the work should be done
POLICY      → where the agent must stop
VERIFY      → proof that the result actually worked
```

Those four ideas are the architectural center of this repository.

## Status

**Early public alpha / architecture-first implementation.**

The current repo already includes:

- a zero-runtime-dependency Node CLI;
- capability and skill registries;
- local-first config defaults;
- permission profiles;
- a Windows installer with dry-run;
- an `otak-atik doctor` health check;
- official starter skills;
- declarative workflow recipes;
- validators and tests;
- security and contribution documentation;
- CI for repository validation.

It does **not** yet pretend to be a finished production operator platform.

Good. Pretending would be faster, but less useful.

## 60-second quick start

Requirements:

- Node.js 20+
- Git
- Windows for the current installer path

Clone:

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik
```

Inspect what the installer would do:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
```

Install the local config and link the CLI:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

Then:

```powershell
otak-atik doctor
otak-atik capabilities
otak-atik skills
otak-atik recipes
otak-atik policy
```

Without installing anything globally:

```powershell
node .\bin\otak-atik.mjs doctor
```

## Example operator loop

User:

> Inspect my project, find why the build fails, fix only files inside the workspace, run the tests again, and show me what changed.

Expected conceptual flow:

```text
task
 ↓
capability discovery
 ↓
project-debugger skill
 ↓
workspace policy check
 ↓
inspect
 ↓
modify
 ↓
test
 ↓
verification result
 ↓
audit trail
```

The AI client still performs the reasoning.

otak-atik provides the reusable operating contract around that reasoning.

## Architecture

```text
                  ┌─────────────────────┐
                  │      AI CLIENT      │
                  └──────────┬──────────┘
                             │
                  ┌──────────▼──────────┐
                  │   CLIENT ADAPTER    │
                  └──────────┬──────────┘
                             │
               ┌─────────────▼─────────────┐
               │        OPERATOR CORE      │
               │                           │
               │ capability resolver       │
               │ skill router              │
               │ recipe engine             │
               └───────┬────────┬──────────┘
                       │        │
            ┌──────────▼─┐   ┌──▼───────────┐
            │   POLICY   │   │ AUDIT / STATE│
            │   ENGINE   │   │ VERIFICATION │
            └──────┬─────┘   └──────────────┘
                   │
        ┌──────────▼──────────┐
        │     TOOL ADAPTERS   │
        └──────┬──────┬───────┘
               │      │
       ┌───────▼─┐ ┌──▼─────────┐
       │ DESKTOP │ │ SaaS / MCP │
       └─────────┘ └────────────┘
```

The important design choice:

> Desktop Commander, GitHub, Drive, WordPress, or any other provider should be an **adapter**, not the identity of the project.

Skills should request generic capabilities such as `filesystem.read` or `terminal.execute`, not vendor-specific tool names.

## The rules

```text
Evidence > vibes.
Clear > clever.
Recoverable > magical.
Useful > impressive.
Traceable > mysterious.
Safe > ganas tapi ngawur.
```

And one more:

> **Mutation without verification is incomplete work.**

## Repository map

```text
.
├── bin/                    # executable CLI
├── config/                 # default configuration
├── docs/                   # product + architecture documentation
├── registries/             # machine-readable capabilities, skills, recipes
├── skills/                 # official SKILL.md modules
├── recipes/                # declarative workflow compositions
├── scripts/                # installer, doctor, validators
├── src/                    # small reusable core modules
├── tests/                  # contract tests
├── templates/              # templates for community extensions
└── .github/                # CI and contribution templates
```

## Skills are not tools

A tool is something an agent **can do**:

```text
read_file
run_command
git_status
create_issue
```

A skill describes **how to do a job properly**:

```text
project-debugger
safe-file-editor
mcp-diagnostics
git-workflow
```

Presence is not endorsement, and availability is not an instruction to load everything.

> Use the smallest skill set that can do the job well.

## Permission profiles

Built-in policy profiles:

| Profile | Intent |
| --- | --- |
| `observe` | read/inspect only |
| `workspace` | mutate approved workspace paths |
| `developer` | workspace writes + terminal + Git |
| `operator` | broader automation with approval gates |
| `power` | intentionally broad, still policy-bound |

The default config is conservative.

## The flagship command

```powershell
otak-atik doctor
```

It checks the local environment, config, registries, skills, Git, Node, and expected project assets.

If this command is red, fix the system.

Do not emotionally negotiate with the validator.

## Documentation

Start here:

- [Product vision](docs/product/VISION.md)
- [PRD](docs/product/PRD.md)
- [Product principles](docs/product/PRINCIPLES.md)
- [Non-goals](docs/product/NON_GOALS.md)
- [System architecture](docs/architecture/SYSTEM.md)
- [Capability contract](docs/architecture/CAPABILITIES.md)
- [Skill architecture](docs/architecture/SKILLS.md)
- [Security model](SECURITY.md)
- [Roadmap](ROADMAP.md)
- [Project state](PROJECT_STATE.md)

## Public project, private overlay

Do not put personal company paths, credentials, or private workflows into this repository.

Personal/operator-specific material belongs in:

```text
~/.otak-atik/
```

or a separate private repository.

Public core. Private overlay.

Simple.

## Contributing

Contributions are welcome for:

- skills;
- adapters;
- recipes;
- client integrations;
- tests;
- security improvements;
- documentation.

Read [CONTRIBUTING.md](CONTRIBUTING.md) first.

## License

Apache-2.0.

Third-party integrations retain their own licenses and trademarks. See [NOTICE](NOTICE).

---

## Pesan buat gue nanti

Kalau repo ini suatu hari punya 100 adapters, 400 skills, UI hologram, autonomous swarm, dan tiga dashboard yang tidak ada yang buka:

**woco README iki meneh.**

The original goal is still:

```text
understand
→ choose capability
→ choose skill
→ act within policy
→ verify
→ remember what happened
```

If the project stops making that loop clearer, it is probably adding features faster than it is adding value.

**Oke. lanjut otak-atik.**
