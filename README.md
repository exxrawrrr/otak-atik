# otak-atik

> **AI-ne wes pinter. Saiki tangane sing dirapekno.**
>
> A local-first operator kit for connecting AI clients to your computer, MCP tools, reusable skills, and repeatable workflows — with an onboarding path normal humans can actually finish.

## What the author actually uses

The setup that inspired this project experimented with **two MCP paths**.

Today, the author uses **Remote Desktop Commander much more often** for ChatGPT → Windows work.

The old **MCP SuperAssistant** Chrome-extension path is still installed as a fallback/experiment, but it is not the normal daily execution path.

So for new users:

> **Start with Remote Desktop Commander. Add the browser bridge only if you actually need it.**

Full evidence/history: [What I actually use](docs/WHAT-I-ACTUALLY-USE.md).

## Pick the right mode

| Situation | Recommended path |
| --- | --- |
| ChatGPT from phone / away from PC | **Remote Desktop Commander remote MCP** |
| Codex / local AI on the same PC | **Desktop Commander local MCP** |
| ChatGPT/Gemini website in Chrome needs local MCP | MCP SuperAssistant, optional |
| Need screenshot + click + type GUI control | evaluate QuickDesk / Windows UI MCP |

### Remote — easiest for ChatGPT web/mobile

On the target computer:

```powershell
npx @wonderwhy-er/desktop-commander@latest remote
```

Remote MCP endpoint:

```text
https://mcp.desktopcommander.app/mcp
```

The Windows installer creates a Desktop launcher so users do not need to retype that command.

### Local — best for Codex and quota-heavy engineering

Official Codex setup:

```powershell
codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest
```

This runs Desktop Commander as **local MCP**, not through the hosted Remote MCP service.

That matters because the hosted free Remote Desktop Commander plan currently has a monthly tool-call ceiling, while the local MCP server is free/open-source without that monthly ceiling.

See [Usage and cost strategy](docs/USAGE-AND-COST.md).

## Wait — do I need the Chrome extension too?

**No.**

The installed extension in the original setup is:

**MCP SuperAssistant**  
Chrome extension ID: `kngiafgkdnlkgmefdafaibkibegkcaef`

It is a separate browser bridge.

```text
REMOTE PATH
ChatGPT / remote MCP client
→ Remote Desktop Commander hosted relay
→ paired device agent
→ computer

OPTIONAL BROWSER PATH
AI website in Chrome
→ MCP SuperAssistant
→ local proxy
→ local MCP server
→ computer
```

Both can coexist.

One does not require the other.

The original machine's old browser proxy still receives MCP discovery traffic, but an inspection of its current log found repeated `tools/list` requests and no `tools/call` entries in the checked history. In practice, Remote Desktop Commander has become the main path.

## Windows: install once, click later

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik

powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer creates:

```text
Desktop/
└── OTAK-ATIK/
    ├── 01 - START REMOTE DESKTOP.bat
    ├── 02 - STATUS.bat
    ├── 03 - OPEN SETUP PAGES.bat
    ├── 04 - START BROWSER BRIDGE - OPTIONAL.bat
    ├── 05 - STOP REMOTE DESKTOP.bat
    ├── 06 - SETUP CODEX LOCAL MCP - NO REMOTE QUOTA.bat
    └── 07 - WHICH MODE SHOULD I USE.bat
```

The normal remote workflow becomes:

```text
double-click 01
→ authenticate once if needed
→ connect AI
→ work
```

The normal Codex/local workflow becomes:

```text
double-click 06
→ approve Codex MCP config
→ use local Desktop Commander
→ no hosted remote quota for that path
```

Browser extension and OAuth installation still require explicit user approval. The project does not silently install extensions or authorize accounts.

## Why this repo exists

Desktop access alone is only the transport.

otak-atik adds the operator layer:

```text
CAPABILITY  → what can be done
SKILL       → how the work should be done
POLICY      → where the agent must stop
VERIFY      → evidence that the result worked
```

And now also:

```text
TRANSPORT   → which path should carry the work
```

Because routing a local Codex task through a quota-limited hosted relay just because it exists is... technically valid and operationally ngapain.

## Tested where?

The author's real workflows have primarily been exercised with:

- **ChatGPT + Remote Desktop Commander**
- **Codex + local project/engineering workflows**

Other clients are compatibility targets, not magically certified.

Claude, Cursor, VS Code, Gemini CLI, etc. are welcome — **semangat, gess** — but report actual behavior so docs can distinguish documented support from battle-tested support.

## If Remote Desktop Commander quota becomes a problem

Do this before paying or panicking:

```text
Is the task local?
    yes → local MCP / Codex

Are you actually remote?
    yes → Remote Desktop Commander remote

Do you need browser-only bridging?
    yes → MCP SuperAssistant optional

Do you need GUI computer-use?
    yes → evaluate QuickDesk
```

Desktop Commander's current published plan lists Free at 10,000 remote tool calls/month and Pro as unlimited; its local MCP server is separately documented as free/open-source with no monthly limit.

otak-atik does not bypass quotas.

It tries to stop wasting them.

## Skills

The registry includes operator skills for:

- transport selection;
- remote quota optimization;
- local MCP bootstrap;
- Remote Desktop bootstrap;
- browser bridge setup;
- MCP topology diagnosis;
- operator health checks;
- Windows launcher management;
- repository debugging;
- safe file editing;
- dependency repair;
- Git workflows;
- document workflows;
- skill authoring;
- and more.

Use the smallest set that can do the job.

Context is a resource too.

## CLI

```powershell
otak-atik doctor
otak-atik capabilities
otak-atik skills
otak-atik recipes
otak-atik packs
otak-atik policy
```

## Docs

Start with:

- [Windows setup](docs/SETUP-WINDOWS.md)
- [Setup decision tree](docs/SETUP-DECISION-TREE.md)
- [Usage and cost](docs/USAGE-AND-COST.md)
- [What the original setup actually uses](docs/WHAT-I-ACTUALLY-USE.md)
- [Remote Desktop Commander](docs/REMOTE-DESKTOP-COMMANDER.md)
- [MCP SuperAssistant browser bridge](docs/BROWSER-BRIDGE.md)
- [AI clients](docs/AI-CLIENTS.md)
- [Alternatives](docs/ALTERNATIVES.md)
- [PRD](docs/product/PRD.md)
- [Security](SECURITY.md)
- [Roadmap](ROADMAP.md)

## Alternatives

otak-atik does not pretend every computer-control problem needs the same provider.

**QuickDesk** is especially interesting for tasks requiring screenshot/mouse/keyboard computer use. It is open source, exposes an MCP server, supports local stdio and HTTP/SSE modes, and can be self-hosted.

For pure remote filesystem/terminal work, Remote Desktop Commander remains the simpler default in this project.

## Rules

```text
Evidence > vibes.
Local work > unnecessary remote relay.
Clear > clever.
Recoverable > magical.
Useful > impressive.
Traceable > mysterious.
Safe > ganas tapi ngawur.
```

> **Mutation without verification is incomplete work.**

## License

Apache-2.0.

Third-party products keep their own licenses and trademarks.

---

If someday the onboarding still starts with:

> "first open PowerShell and remember this exact command..."

while seven launchers, three adapters, and twenty skills exist:

**berarti kita gagal ngurus UX.**

**Oke. lanjut otak-atik.**
