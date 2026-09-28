# otak-atik

> **AI-ne wes pinter. Saiki tangane sing dirapekno.**
>
> A local-first operator kit for giving AI clients structured access to your computer, MCP tools, reusable skills, and repeatable workflows — without making first-time setup a small religious ceremony.

```text
ChatGPT / Codex / Claude / Cursor / VS Code / other MCP clients
                              │
                              ▼
                          otak-atik
                    ┌─────────┼─────────┐
                    ▼         ▼         ▼
                 skills    policy    recipes
                    │         │         │
                    └─────────┼─────────┘
                              ▼
                           adapters
                    ┌─────────┼───────────┐
                    ▼         ▼           ▼
              Remote MCP   Local MCP   SaaS tools
                    │
                    ▼
               your computer
```

## The 30-second answer: what do I install?

For most people, **one path is enough**.

### Path A — Remote Desktop Commander — recommended

Use this when you want ChatGPT or another remote-MCP-capable AI to reach your computer from web/mobile/another device.

On the computer you want the AI to reach:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

Then connect your AI client to:

```text
https://mcp.desktopcommander.app/mcp
```

This is the primary path.

### Path B — MCP SuperAssistant browser bridge — optional compatibility mode

Use this when the AI website itself does **not** give you a convenient native MCP connector and you want a browser extension to bridge tool calls into a local MCP proxy.

Chrome extension:

**MCP SuperAssistant**  
Extension ID: `kngiafgkdnlkgmefdafaibkibegkcaef`

This path uses a local proxy and is separate from Remote Desktop Commander's hosted remote relay.

### Do I need both?

**No.**

They can coexist, and the original setup that inspired this repo did use both, but they solve different transport problems.

```text
REMOTE PATH
AI client
  → https://mcp.desktopcommander.app/mcp
  → Remote Desktop Commander device agent
  → computer

BROWSER BRIDGE PATH
AI website in Chrome
  → MCP SuperAssistant extension
  → local MCP proxy
  → local MCP server(s)
  → computer
```

Installing both does not magically stack their power.

It gives you **two ways in**.

See [Which setup should I use?](docs/SETUP-DECISION-TREE.md).

---

## One-command-ish Windows onboarding

Requirements:

- Windows 10/11
- Node.js 20+
- Git recommended

Clone:

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik
```

Preview:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
```

Install:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer creates:

```text
~/.otak-atik/
└── windows/

Desktop/
└── OTAK-ATIK/
    ├── 01 - START REMOTE DESKTOP.bat
    ├── 02 - STATUS.bat
    ├── 03 - OPEN SETUP PAGES.bat
    ├── 04 - START BROWSER BRIDGE - OPTIONAL.bat
    └── 05 - STOP REMOTE DESKTOP.bat
```

So after setup, the normal Windows experience is basically:

> double-click **01 - START REMOTE DESKTOP.bat**

Not:

> remember the sacred npm incantation from six Tuesdays ago.

On first install the setup helper can also open the relevant Remote Desktop Commander and MCP SuperAssistant pages. Browser security still requires **you** to approve Chrome extension installation and OAuth pairing; this project does not silently install browser extensions or authorize accounts.

Full guide: [Windows setup](docs/SETUP-WINDOWS.md).

---

## What was the original setup behind this repo?

The author originally experimented with two parallel approaches.

### 1. Native/remote Desktop Commander

```text
ChatGPT
→ Remote Desktop Commander connector
→ hosted Remote MCP relay
→ local device agent
→ Windows
```

The local device agent is started with:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

### 2. Browser-extension MCP bridge

```text
ChatGPT/Gemini/etc in Chrome
→ MCP SuperAssistant
→ localhost MCP proxy
→ local agent
→ Windows
```

The experimental private setup used a compatibility proxy because the local agent and browser bridge did not always agree on transport/response details.

That historical topology is documented in [Browser bridge notes](docs/BROWSER-BRIDGE.md), but public users do **not** need to reproduce the custom legacy proxy.

Use the standard paths first.

---

## Tested where?

The workflow behind this repository has been exercised primarily with:

- **ChatGPT** — including remote desktop access through Remote Desktop Commander;
- **Codex** — for local engineering/project workflows.

Other MCP-capable clients are documented as compatibility targets, not claimed as personally battle-tested by the author.

If you use Claude, Cursor, VS Code, Gemini CLI, or something more exotic: semangat, gess. Open an issue with what actually worked instead of pretending every client behaves identically.

See [AI client notes](docs/AI-CLIENTS.md).

---

## Why not just use one existing project?

For raw desktop access, you often should.

This repo does not try to reimplement every remote-control stack.

Current integrations/alternatives worth knowing:

| Project | Best fit | otak-atik position |
| --- | --- | --- |
| Remote Desktop Commander | remote files + shell from remote-MCP clients | **default remote path** |
| MCP SuperAssistant | browser AI sites that need a local MCP bridge | optional compatibility path |
| QuickDesk | AI-driven GUI remote desktop, screenshots/click/type | experimental GUI-control alternative |
| Windows MCP Server | deep Windows UI/PowerShell/system automation | advanced Windows option |

See [Alternatives](docs/ALTERNATIVES.md).

otak-atik's job is the layer above transport:

```text
CAPABILITY  → what can be done
SKILL       → how work should be done
POLICY      → where the agent must stop
VERIFY      → evidence that the result worked
```

---

## Built-in local skills

The official registry now includes operator-oriented skills such as:

- `remote-desktop-bootstrap`
- `browser-mcp-bridge`
- `mcp-topology-diagnoser`
- `operator-healthcheck`
- `windows-launcher-manager`
- `desktop-inspector`
- `safe-file-editor`
- `mcp-diagnostics`
- `connector-doctor`
- `project-bootstrap`
- `project-debugger`
- `dependency-doctor`
- `git-workflow`
- `document-workflow`
- `workspace-organizer`
- `web-project-maintainer`
- `release-checker`
- `skill-authoring`

Use the smallest relevant set.

Do not load everything just because everything exists.

---

## CLI

```powershell
otak-atik doctor
otak-atik capabilities
otak-atik skills
otak-atik recipes
otak-atik packs
otak-atik policy
```

Without global linking:

```powershell
node .\bin\otak-atik.mjs doctor
```

---

## Safety defaults

The default profile is `observe`.

Broad mutation is not implicitly enabled.

```text
Evidence > vibes.
Clear > clever.
Recoverable > magical.
Useful > impressive.
Traceable > mysterious.
Safe > ganas tapi ngawur.
```

And:

> **Mutation without verification is incomplete work.**

---

## Docs

Start here:

- [Setup decision tree](docs/SETUP-DECISION-TREE.md)
- [Windows setup](docs/SETUP-WINDOWS.md)
- [Remote Desktop Commander](docs/REMOTE-DESKTOP-COMMANDER.md)
- [Browser bridge / MCP SuperAssistant](docs/BROWSER-BRIDGE.md)
- [AI client compatibility](docs/AI-CLIENTS.md)
- [Alternatives](docs/ALTERNATIVES.md)
- [Product vision](docs/product/VISION.md)
- [PRD](docs/product/PRD.md)
- [System architecture](docs/architecture/SYSTEM.md)
- [Security model](SECURITY.md)
- [Roadmap](ROADMAP.md)

---

## Public core, private overlay

Keep personal paths, credentials, company data, and private automation outside this repository.

```text
public repo
  → generic skills
  → generic adapters
  → generic launchers

~/.otak-atik/
  → your config
  → your private skills
  → your machine-specific state
```

Simple.

---

## License

Apache-2.0.

Third-party projects retain their own licenses and trademarks.

---

## Pesan buat gue nanti

Kalau suatu hari repo ini punya 300 adapters, 900 skills, empat dashboards, agent swarm, animated hologram, dan user masih harus buka PowerShell buat nginget command pertama:

**berarti onboarding-nya gagal.**

The user experience should keep moving toward:

```text
install
→ click launcher
→ connect AI
→ work
→ verify
```

**Oke. lanjut otak-atik.**
