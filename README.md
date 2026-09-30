# otak-atik

> **Status: gagal sebagai tujuan awal. Berhasil sebagai eksperimen.**
>
> Awalnya gue pengen bikin jalur sendiri supaya AI bisa remote komputer gue tanpa akhirnya bergantung ke plugin orang lain.
>
> Kenyataannya?
>
> Untuk kerja harian, **Remote Desktop Commander masih paling praktis**.
>
> Tapi karena kesel sama limit, eksperimen, tunnel, MCP, dan segala tetek bengek itu, akhirnya lahir juga jalur sendiri yang sekarang beneran jalan:
>
> **Rafdi Remote.**
>
> Jadi repo ini bukan cerita "gue bikin produk sempurna".
>
> Ini cerita:
>
> **gagal â†’ nyatet kegagalan â†’ kesel â†’ otak-atik lagi â†’ djiancok wes limit cok â†’ ternyata jadi sesuatu yang kepake.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/feels-bad-man.jpg" width="290" alt="feels bad man meme" />
</p>

## TL;DR

Kalau cuma mau tahu hasil akhirnya:

```text
DAILY / PALING PRAKTIS
ChatGPT
  â†“
Remote Desktop Commander
  â†“
GROWTH
```

Kalau mau jalur buatan sendiri yang sekarang sudah terbukti bekerja:

```text
ChatGPT
  â†“
Composio Custom MCP
  â†“
Tailscale Funnel
  â†“
Windows-MCP on 127.0.0.1
  â†“
PowerShell / files / processes / selected GUI tools
```

Dan kalau kerja lokal:

```text
Codex / local AI
  â†“
Desktop Commander local MCP
  â†“
Windows
```

Jadi jawabannya bukan "satu tool mengalahkan semuanya".

Jawabannya sekarang:

> **pakai jalur yang paling waras buat konteksnya.**

---

## Rencanane awal e iki

Awalnya sederhana.

Gue sering pakai ChatGPT dari HP.

Komputernya ada di tempat lain.

Terus kepikiran:

> **"kenapa AI gue nggak sekalian bisa masuk ke komputer, baca file, jalanin terminal, benerin project, terus kasih bukti kalau kerjaannya bener?"**

Dari situ mulai otak-atik:

- MCP, remote MCP, local MCP;
- browser bridge;
- launcher;
- skill dan capability;
- approval dan security boundary;
- evidence dan verification;
- router dan CLI;
- tunnel;
- remote desktop;
- dan tentu saja: **kebanyakan ide**.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/disaster-girl.jpg" width="300" alt="disaster girl meme" />
</p>

Di kepala, diagramnya cakep:

```text
ChatGPT / AI
      â†“
otak-atik
      â†“
pilih transport
      â†“
pilih capability
      â†“
jalankan kerjaan
      â†“
verify
      â†“
done
```

Di dunia nyata?

Ya nggak sebersih itu, cak.

---

## Terus kenyataannya gimana?

Versi pertama dari kenyataan:

```text
ChatGPT
   â†“
Remote Desktop Commander
   â†“
komputer gue
```

Setelah bikin router, adapter concept, launcher, skill registry, benchmark, provider scorecard, failure lab, dan macam-macam...

**jalur yang paling sering gue pakai justru plugin yang sudah ada.**

Kalau ukuran suksesnya:

> "apakah otak-atik menggantikan plugin?"

Jawabannya tetap:

## **nggak.**

Dan itu gue biarin tertulis.

Karena repo yang pura-pura sukses cuma bikin orang lain ngulang kesalahan yang sama.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/ship-your-machine.jpg" width="305" alt="ship your machine meme" />
</p>

---

# Plot twist: terus quota mulai bikin emosi

Remote Desktop Commander enak.

Masalahnya, remote call itu bukan sumber daya tak terbatas.

Sampai pada titik workflow gue mulai terasa seperti:

> **"djiancok wes limit cok, masa cuma mau nyentuh PowerShell kudu mikir sisa call."**

Nah, dari sini arah repo berubah.

Bukan lagi:

> "gue harus mengganti plugin."

Tapi:

> **"gue butuh jalur cadangan yang beneran usable, bisa auto-start, bisa direcover, dan nggak bikin gue setup ulang tunnel tiap laptop restart."**

Dari situlah eksperimen **Rafdi Remote GROWTH** mulai serius.

---

# Rafdi Remote: eksperimen yang akhirnya beneran hidup

Arsitektur final yang diuji:

```text
ChatGPT
  â†“
Composio Custom MCP
  â†“
Tailscale Funnel
  â†“
Windows-MCP
  â†“
127.0.0.1 on GROWTH
  â†“
PowerShell / FileSystem / Process / selected computer-use tools
```

Bukan sekadar diagram.

Di GROWTH, jalur ini sudah diuji terhadap:

- bearer authentication;
- public HTTPS Funnel;
- rejection untuk request tanpa token;
- authenticated MCP initialize;
- supervisor recovery;
- Scheduled Task recovery;
- Tailscale reconnect;
- actual Windows reboot;
- dan command nyata dari ChatGPT sesudah reboot.

Bukti lengkapnya ada di:

- [Rafdi Remote overview](docs/RAFDI-REMOTE-GROWTH.md)
- [Phase 2A checkpoint](docs/RAFDI-REMOTE-GROWTH-PHASE-2A-CHECKPOINT.md)
- [Phase 2B reality test](docs/RAFDI-REMOTE-GROWTH-PHASE-2B-CHECKPOINT.md)
- [Transport/security ADR](docs/decisions/ADR-RAFDI-REMOTE-TRANSPORT.md)
- [Reusable installer](experiments/rafdi-remote-growth/README.md)

---

## Yang paling penting: survive restart beneran

Bukan cuma "task kelihatannya ada".

GROWTH benar-benar restart.

Sesudah boot:

```text
Windows boot
  â†“
Scheduled Task
  â†“
Rafdi Remote supervisor
  â†“
Windows-MCP 127.0.0.1:18765
  â†“
Tailscale Funnel restored
  â†“
ChatGPT via Composio
  â†“
PowerShell on GROWTH
```

Dan itu terbukti jalan.

Jadi sekarang gue punya dua kenyataan yang sama-sama benar:

```text
Remote Desktop Commander
= masih paling praktis
```

dan:

```text
Rafdi Remote
= jalur buatan sendiri yang sudah terbukti bekerja
```

Itu jauh lebih berguna daripada maksa satu pihak jadi "pemenang".

---

## Bug paling nyebelin yang ketemu

Public Funnel sempat hidup, request sampai ke Windows, tapi MCP balas:

```text
400 Invalid host header
```

Awalnya keliatan kayak masalah Tailscale.

Ternyata bukan.

Kita sampai pasang one-request HTTP probe di belakang Funnel buat lihat Host header yang benar-benar datang.

Tailscale ternyata meneruskan host yang benar.

Root cause-nya ada di **Windows-MCP 0.8.6** yang memasang Trusted Host middleware loopback sendiri.

Akhirnya public mode pakai compatibility shim resmi Windows-MCP:

```text
--allow-insecure-remote
```

Tapi ini **bukan** berarti service dibuka ngawur.

Recipe repo ini tetap mensyaratkan:

```text
bind = 127.0.0.1
bearer auth = ON
FastMCP host-origin protection = ON
allowed hosts = explicit
public transport = Tailscale Funnel
```

Kalau salah satu boundary itu dibuang, itu bukan lagi recipe yang diuji di repo ini.

---

## Hal-hal yang gagal di jalan

### MCP SuperAssistant browser bridge

Discovery pernah jalan.

`initialize` jalan.

`tools/list` muncul.

Tapi jalur itu **nggak terbukti jadi daily execution path yang reliable**.

Statusnya tetap:

```text
PARTIAL_FAILURE
```

Laporan tetap disimpan:

[Experiment report â€” MCP SuperAssistant browser bridge](labs/reports/2026-09-28-mcp-superassistant-browser-bridge.md)

### Installer Rafdi Remote versi awal

Dogfood nangkep banyak hal yang kalau langsung dipublish bakal ngeselin:

- resolver `uv.exe` terlalu sempit;
- health check SSE false-negative;
- parameter `$Pid` bentrok dengan `$PID` bawaan PowerShell;
- mutex supervisor terlalu global;
- patch substring sempat merusak empat script;
- output local-only sempat misleading;
- Windows detection lama terlalu bergantung pada `$env:OS`;
- test residue sempat ikut auto-start setelah reboot.

Semua itu alasan kenapa gue sekarang lebih percaya:

> **dogfood dulu, baru ngoceh "works".**

---

## Yang sebenarnya gue pakai sekarang

### Remote harian dari ChatGPT / HP

**Remote Desktop Commander**

Masih paling gampang ketika gue cuma pengen:

- buka file;
- jalanin PowerShell;
- inspect process;
- edit project;
- troubleshooting mesin secara langsung.

### Backup / jalur buatan sendiri

**Rafdi Remote GROWTH**

Dipakai lewat:

```text
ChatGPT â†’ Composio Custom MCP â†’ Tailscale â†’ Windows-MCP
```

Ini sekarang bukan lagi konsep doang.

Tapi statusnya tetap **experimental**, bukan produk remote-access universal.

### Kerja lokal

**Desktop Commander local MCP**

Kalau AI dan Windows ada di mesin yang sama, muter lewat internet ya ngapain.

```powershell
codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest
```

---

## Jadi repo ini gagal total?

Nggak.

Tapi gue juga nggak mau rewrite sejarah seolah dari awal semuanya sesuai roadmap.

Status paling jujurnya:

```text
FAILED AS THE ORIGINAL "REPLACE THE PLUGIN" IDEA

BUT

SUCCESSFUL AS:
- a research lab
- a failure log
- a routing/operator experiment
- a standalone utility pack
- a real remote-MCP backup path
```

Repo ini sekarang lebih berharga karena ada bagian yang gagal **dan** ada bagian yang akhirnya works.

---

## Biar mampir nggak cuma bawa cerita gagal

Walaupun lu nggak pakai remote setup apa pun, CLI repo ini tetap punya utilitas standalone.

### Snapshot project

```powershell
otak-atik snapshot .
```

Bikin peta project tanpa nge-dump semua source.

### Secret hygiene

```powershell
otak-atik hygiene .
otak-atik hygiene . --strict
```

Nilai secret sengaja tidak dicetak.

### Audit MCP config

```powershell
otak-atik mcp-check path\to\mcp.json
```

### Lint SKILL.md

```powershell
otak-atik skill-check path\to\SKILL.md
```

### Handoff ke AI lain

```powershell
otak-atik handoff . --task "lanjut benerin project ini" --out handoff.json
```

### Review risiko Git diff

```powershell
otak-atik diff-risk .
```

Detail: [Standalone Utility Pack](docs/UTILITY-PACK.md).

---

## Native engine / lab

Bagian eksperimen native masih ada:

```powershell
otak-atik doctor
otak-atik capabilities
otak-atik skills
otak-atik route --local
otak-atik route --remote
otak-atik plan "fix failing project and run tests" --local
otak-atik providers
otak-atik lab
```

Validation penuh:

```powershell
npm run check
```

Current package:

```text
0.1.0-alpha.4
```

Node:

```text
>= 20
```

---

## Kandidat yang masih menarik buat dieksplor

Repo ini tetap nyimpen pertanyaan yang belum selesai:

> bisakah kita punya remote graphical computer-use yang open source, Windows-friendly, MCP-native, aman, dan nggak bikin lima service cuma untuk klik Start Menu?

Beberapa kandidat yang pernah dicatat:

- [QuickDesk](https://github.com/barry-ran/QuickDesk)
- [RustDesk](https://github.com/rustdesk/rustdesk)
- [MCPComputerUse](https://github.com/kblood/MCPComputerUse)
- [Remote Desktop Commander](https://github.com/desktop-commander/remote-desktop-commander)

Gue nggak menganggap kandidat sebagai solusi final sebelum ada bukti real usage di mesin sendiri.

---

## Prinsip repo ini sekarang

```text
Reality > roadmap.
Evidence > vibes.
Working plugin > homemade architecture yang nggak kepakai.
Homemade path yang sudah terbukti > homemade path yang cuma cakep di diagram.
Local > remote kalau task-nya memang lokal.
Verification > "harusnya sudah".
Failure documented > failure dilupakan.
Useful > gengsi bikin sendiri.
```

Pelajaran paling mahalnya:

> **nggak semua masalah perlu diselesaikan dengan bikin produk baru.**

Tapi kadang, setelah cukup banyak gagal, sesuatu yang awalnya cuma "otak-atik" malah berubah jadi backup system yang beneran hidup.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/friday-deploy.jpg" width="300" alt="friday deploy meme" />
</p>

---

## Docs yang paling relevan

### Remote / transport

- [What I actually use](docs/WHAT-I-ACTUALLY-USE.md)
- [Rafdi Remote overview](docs/RAFDI-REMOTE-GROWTH.md)
- [Rafdi Remote Phase 2B](docs/RAFDI-REMOTE-GROWTH-PHASE-2B-CHECKPOINT.md)
- [Remote Desktop Commander](docs/REMOTE-DESKTOP-COMMANDER.md)
- [Alternatives](docs/ALTERNATIVES.md)

### Engineering / research

- [Research status](docs/RESEARCH-STATUS.md)
- [Provider matrix](docs/PROVIDER-MATRIX.md)
- [Browser bridge](docs/BROWSER-BRIDGE.md)
- [Setup decision tree](docs/SETUP-DECISION-TREE.md)
- [Project state](PROJECT_STATE.md)
- [Roadmap](ROADMAP.md)

### Security / contribution

- [Security](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Rafdi Remote transport ADR](docs/decisions/ADR-RAFDI-REMOTE-TRANSPORT.md)

---

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/git-force-push.jpg" width="300" alt="git force push meme" />
</p>

# For everyone else

**otak-atik is a public AI-to-computer control research lab that started as a failed attempt to replace a convenient remote plugin and evolved into a mix of routing experiments, standalone developer utilities, documented failures, and a working experimental remote-MCP backup path.**

The primary daily remote route is still:

```text
ChatGPT
â†’ Remote Desktop Commander
â†’ Windows
```

A separately built experimental path has also been verified:

```text
ChatGPT
â†’ Composio Custom MCP
â†’ Tailscale Funnel
â†’ Windows-MCP
â†’ Windows
```

That path survived authentication tests, public reachability tests, supervisor recovery, Tailscale reconnect, and an actual Windows restart on the original GROWTH machine.

This does **not** make the repository a production remote-desktop replacement.

It does make the failure story more interesting than "we gave up."

## Contributions

Real usage reports are more valuable than architecture opinions.

If you know a better approach, open an issue with what you personally verified.

Especially useful:

- remote transport model;
- license;
- supported operating systems;
- MCP integration;
- screenshot/mouse/keyboard support;
- self-hosting model;
- authentication/security boundary;
- actual test evidence.

---

**The original idea failed to replace the plugin. The experiment did not stop there.**
