# otak-atik

> **A public AI-to-computer control lab: how far can ChatGPT safely operate a real Windows machine without turning the whole setup into an untraceable shell?**

`otak-atik` is an experimental, local-first repository for building and documenting practical AI operator workflows. It started from a simple problem — letting ChatGPT inspect and operate a real Windows workstation — and grew into a safety-gated remote operator stack with evidence, permissions, verification, receipts, and rollback.

This repository is both:

- a **working engineering lab** for AI-to-computer control;
- a **public record** of what actually worked, failed, changed direction, and why.

It is **not** presented as a universal remote-desktop product or as proof that arbitrary AI agents can safely control arbitrary computers.

---

## Current status

Snapshot: **3 October 2026**

| Surface | Current state |
| --- | --- |
| Remote GROWTH Stable gateway | **v0.7.0** |
| Gateway inventory | **64 tools** |
| Guided Composio + Tailscale onboarding | **CHAT 5 complete; Windows prerelease published** |
| Native ChatGPT facade | **12 focused tools** |
| Private native plugin package | **v1.0.0 finalized locally** |
| Public reusable native bootstrap | **validated from a fresh clone** |
| Core Phase 10 acceptance | **COMPLETE VERIFIED** |
| Warm native reconnect | **verified** |
| Cold reboot / lost tunnel process | **manual tunnel start required unless optional local auto-start enrollment is configured** |
| Standalone npm package line | **0.1.0-alpha.6** |
| License | **Apache-2.0** |

The current release lock is intentionally honest about the remaining cold-start limitation. The public repository does not contain the owner's tunnel runtime key, bearer token, generated private app ID, local credential store, or machine secrets.

---

## Current public prerelease

**v0.1.0-alpha.6** is published as a GitHub prerelease with:

- `OTAK-ATIK-Windows-v0.1.0-alpha.6.zip`
- `OTAK-ATIK-Windows-v0.1.0-alpha.6.zip.sha256`

Release bundle SHA-256:

`2d613c92884ca69532bd86a6c435702a484549901a958ee155b756918ca58fef`

The release tag is immutable and dereferences to commit `7bbb62e4ebc75ba86ecc7cac3973600aa294d0ca`.

---

## Windows quick start

For the guided Windows path, normal users do not need to clone the repository.

```text
1. Download OTAK-ATIK-Windows-v0.1.0-alpha.6.zip
2. Extract it
3. Double-click START.cmd
4. Follow the terminal when Tailscale or Composio asks you to sign in
```

The first START creates a durable `Desktop\OTAK-ATIK\` launcher set and caches the required helpers/runtime source under the current Windows profile. `STATUS.cmd` checks health; `REPAIR.cmd` only repairs OTAK-ATIK-owned components and fails closed on ambiguous ownership.

See [Windows guided setup](docs/SETUP-WINDOWS.md) for the complete flow.

---

## Architecture

There are two practical operator surfaces.

Remote Desktop Commander **still works and remains useful** as a practical interactive route; this repository documents the self-built Remote GROWTH path rather than pretending every existing operator route became obsolete.

### 1. Full remote operator path

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Tailscale Funnel
  ↓
Remote GROWTH Stable Gateway v0.7.0
  ↓
64 tools
  ↓
Windows workstation
```

The 64-tool gateway combines:

| Layer | Count | Purpose |
| --- | ---: | --- |
| Windows primitives | 15 | selected PowerShell, file, process, screenshot, and GUI operations |
| Fast Local | 6 | local search, indexed files, workspaces, index health |
| Document Engine | 6 | inspect, extract, search, compare, controlled replace |
| Developer / Git | 9 | repository inspection, diff, search, checkpoint, quality |
| Safe FileOps | 10 | hashes, duplicates, archive, plan/execute/rollback, backup |
| SystemOps | 12 | system, process, port, service, network, task inspection and safe planned mutation |
| Workflow Engine | 6 | catalog, plan, execute, status, rollback |
| **Total** | **64** | |

### 2. Native ChatGPT plugin path

```text
ChatGPT native plugin / MCP app
  ↓
OpenAI Secure MCP Tunnel
  ↓
127.0.0.1:18768
  ↓
Remote GROWTH Native Facade
  ↓
12 focused high-level tools
  ↓
trusted local engines
```

The native facade deliberately exposes a much smaller surface:

```text
remote_growth_health
search_local
find_workspace
summarize_workspace
inspect_document
inspect_repo
inspect_system_health
list_workflows
plan_workflow
execute_workflow
get_workflow_status
rollback_workflow
```

Raw PowerShell, raw filesystem mutation, and raw UI automation are intentionally absent from the native facade.

---

## The design idea

The project moved away from:

```text
AI
↓
here is a shell
↓
good luck
```

toward:

```text
inspect
  ↓
plan
  ↓
permission gate
  ↓
execute
  ↓
verify
  ↓
receipt
  ↓
rollback when supported
```

The important part is not the number of tools. The important part is that higher-impact operations are meant to remain inspectable, permission-scoped, evidence-backed, and recoverable.

---

## What is actually verified

On the primary Windows machine, the project has verified:

- authenticated remote transport and unauthenticated rejection;
- isolated STATUS + REPAIR acceptance: missing recovery task + stopped runtime was detected, repaired, and reverified at HTTP 401 + 64/64 tools;
- loopback-only native bindings;
- real Windows reboot recovery on the earlier remote path;
- 64-tool gateway inventory;
- persistent local workspace indexing;
- document, developer, file, system, and workflow engines;
- protected runtime targets;
- irreversible-action gates;
- FileOps and SystemOps receipts;
- high-level workflow execution;
- duplicate-execution protection;
- workflow rollback;
- native 12-tool facade;
- native safety annotations;
- exclusion of raw primitives from the native facade;
- public package secret scans;
- Secure MCP Tunnel readiness;
- private ChatGPT plugin registration;
- direct native calls from ChatGPT;
- read-only acceptance;
- permission-gate acceptance;
- isolated write + rollback acceptance;
- protected-negative and regression acceptance;
- warm native-backend reconnect.

CHAT 5 additionally verifies the packaged first-run contract on a clean Windows runner: the release ZIP builds, `START.cmd` bootstraps without Node.js or Git, the extracted source can be deleted, and the installed launchers continue from the cached user-profile copy.

That is real evidence from the primary machine plus clean Windows CI. It is **not** a claim of universal production readiness.

---

## Known limitation

The current native private tunnel has one documented operational limitation:

> If Windows fully reboots or the tunnel-client process is lost, the tunnel currently needs a manual start/runtime-key entry unless the user explicitly enrolls the optional Windows Credential Manager + Scheduled Task auto-start path.

The project prefers that limitation over silently committing, extracting, or weakening the handling of a private runtime credential.

---

## Standalone utilities

The repository also contains provider-neutral utilities that can be useful independently of the private Remote GROWTH setup:

```powershell
otak-atik snapshot .
otak-atik hygiene . --strict
otak-atik mcp-check path\to\mcp.json
otak-atik skill-check path\to\SKILL.md
otak-atik handoff . --task "continue this project" --out handoff.json
otak-atik diff-risk .
```

The standalone package remains an alpha research package. It is separate from the machine-specific private runtime.

Requirements for repository tooling:

```text
Node.js >= 20
```

Useful repository checks:

```bash
npm run validate
npm test
npm run check
npm run release:check
```

---

## Repository map

| Path | Purpose |
| --- | --- |
| `docs/` | architecture, decisions, evidence, historical project notes |
| `examples/remote-growth-native/` | reusable native ChatGPT bootstrap example |
| `src/` | core reusable package implementation |
| `adapters/` | integration/adaptation surfaces |
| `clients/` | client-side integration helpers |
| `registries/` | machine-readable capability/registry data |
| `schemas/` | structured contracts |
| `scripts/` | validation, audit, benchmark, and release helpers |
| `tests/` | regression and safety tests |
| `experiments/` / `labs/` | intentionally experimental work |
| `PROJECT_STATE.md` | current factual project state |
| `ROADMAP.md` | active and historical roadmap |
| `SECURITY.md` | security expectations and disclosure guidance |

---

## Documentation

Start here:

- [Project State](PROJECT_STATE.md)
- [Roadmap](ROADMAP.md)
- [Current Remote GROWTH / Native ChatGPT architecture](docs/REMOTE-GROWTH-NATIVE-CHATGPT.md)
- [Reusable native setup/bootstrap](examples/remote-growth-native/README.md)
- [Windows guided setup](docs/SETUP-WINDOWS.md)
- [Composio + Tailscale user setup UX](docs/COMPOSIO-TAILSCALE-SETUP-UX.md)
- [Historical Rafdi Remote GROWTH evidence](docs/RAFDI-REMOTE-GROWTH.md)
- [What I actually use](docs/WHAT-I-ACTUALLY-USE.md)
- [Security](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Sources](SOURCES.md)
- [Attribution](ATTRIBUTION.md)

---

## Security boundary

This repository should never require publishing the owner's:

- tunnel runtime keys;
- bearer tokens;
- generated private ChatGPT app identifiers;
- workstation secrets;
- private credentials;
- local credential-store contents.

A public example should remain identity-neutral and reproducible without pretending that private machine state belongs in source control.

If you are evaluating this project, treat `PROJECT_STATE.md`, committed evidence, and test results as stronger authority than optimistic prose.

---

## Contributing

This is primarily a working research lab, but issues and focused contributions are welcome.

Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)

Keep experimental claims narrow. A test that passed once is evidence for that test — not a universal guarantee.

---

## License

Apache-2.0. See [LICENSE](LICENSE).

Third-party material retains its original ownership/licensing; see [NOTICE](NOTICE), [SOURCES.md](SOURCES.md), and [ATTRIBUTION.md](ATTRIBUTION.md).

---

# Owner's Notes — catatan gue sendiri

> Bagian atas buat orang yang baru datang dan pengen ngerti repo ini tanpa perlu ikut terseret ke seluruh sejarah kekacauannya.
>
> Bagian bawah ini buat gue sendiri.

## Awalnya sesimpel: “kok ChatGPT nggak bisa masuk PC gue?”

Kurang lebih pertanyaan awalnya:

```text
gue chat
↓
AI masuk komputer
↓
cari file
↓
cek project
↓
ngerjain sesuatu
↓
kasih bukti
```

Di kepala: sederhana.

Di kenyataan: authentication, transport, tunnel, MCP, permission, Windows, restart, secret, process, provider, timeout, rollback, dan segala makhluk yang sebelumnya tidak diundang ikut rapat.

<p align="center">
  <img src="docs/assets/readme-notes/ew-wat.png" width="330" alt="confused reaction meme" />
</p>

Kurang lebih ekspresi gue waktu sadar “AI masuk PC” ternyata bukan satu fitur. Itu satu kecamatan.

## Fase awal: yang penting nyambung dulu

Sempat ada beberapa jalur:

```text
ChatGPT → Remote Desktop Commander → Windows
```

lalu eksperimen:

```text
ChatGPT → Composio → Tailscale Funnel → Windows-MCP → GROWTH
```

Beberapa bagian gagal. Beberapa ternyata jalan. Beberapa jalan tapi bikin pertanyaan baru: **kalau bisa mengeksekusi, terus siapa yang memastikan eksekusinya aman dan benar?**

<p align="center">
  <img src="docs/assets/readme-notes/test-in-prod.jpg" width="350" alt="testing in production meme" />
</p>

Ada masa di mana rasanya semua pengujian memang secara spiritual dilakukan di production.

Tidak ideal. Sangat mendidik.

## Terus gue sadar: raw shell bukan tujuan akhirnya

Punya akses PowerShell itu keren kira-kira lima menit.

Setelah itu pertanyaannya berubah:

- target mana yang boleh disentuh?
- tindakan mana yang perlu approval?
- kalau gagal, bukti gagalnya mana?
- kalau sukses, benar sukses atau cuma proses exit 0?
- kalau mutasi, bisa rollback nggak?
- AI boleh lihat secret nggak?
- dua eksekusi identik bisa kejadian dua kali nggak?

Dari situ arsitekturnya berubah dari kumpulan primitive menjadi engine, workflow, receipt, permission gate, dan verification.

<p align="center">
  <img src="docs/assets/readme-notes/mostly-dead.jpg" width="350" alt="mostly dead reaction meme" />
</p>

Banyak eksperimen tidak benar-benar “mati”. Mereka cuma cukup hidup untuk ngajarin kenapa desain berikutnya harus beda.

## Dari 64 tools malah balik bikin 12

Ini salah satu bagian yang paling lucu.

Setelah susah payah bikin gateway **64 tools**, pas bikin native ChatGPT plugin malah keputusan terbaiknya adalah:

> **jangan kasih semua 64.**

Native facade dipangkas jadi 12 high-level tools supaya lebih mudah diaudit, lebih sulit dipakai ngawur, dan tidak perlu expose raw shell/file mutation/UI automation.

Ternyata kadang progress engineering itu bukan “fiturnya nambah”.

Kadang progress itu:

```text
64 kemampuan tersedia
↓
pikir ulang boundary
↓
12 kemampuan yang memang layak diekspos
```

## Phase 10 akhirnya kekunci

Read-only ✅  
Permission gate ✅  
Isolated write + rollback ✅  
Protected negative ✅  
Regression ✅  
Warm reconnect ✅

Cold reboot auto-start?

Belum gue paksa otomatis karena caranya menyentuh private runtime credential. Untuk sekarang manual start setelah kehilangan tunnel process lebih jujur dan lebih aman daripada bikin README sok bilang “full autonomous recovery”.

<p align="center">
  <img src="docs/assets/readme-notes/at-last.gif" width="350" alt="at last reaction meme" />
</p>

Akhirnya sampai juga di titik di mana kalimat yang bisa ditulis bukan “harusnya works”, tapi **“ini yang sudah benar-benar dites.”**

## Hal yang jangan gue lupain

```text
Reality > roadmap.
Evidence > vibes.
Verification > "harusnya".
Recoverable > magical.
High-level safe operations > unnecessary raw shell access.
Secrets stay local.
Working paths may coexist.
```

Remote Desktop Commander masih berguna. Remote GROWTH juga berguna. Native ChatGPT facade juga punya tempat sendiri.

Tidak semua hal harus diganti hanya karena gue berhasil bikin benda baru.

Dan kalau suatu hari repo ini mulai sok kelihatan “production-grade universal autonomous computer operator”, baca lagi sejarahnya.

Repo ini lebih menarik justru karena dia jujur soal batasannya.
