# otak-atik

> **Status: gagal. Iyo, gagal.**
>
> Bukan repo rusak.
>
> Bukan karena test merah semua.
>
> Tapi kalau tujuan awalnya adalah:
>
> **"bikin jalur sendiri supaya AI bisa remote komputer gue tanpa akhirnya bergantung ke plugin orang lain"**
>
> ...ya kenyataannya sekarang gue malah paling sering pakai **Remote Desktop Commander**.
>
> Jadi secara tujuan awal:
>
> **wes, kalah. 😭**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/feels-bad-man.jpg" width="290" alt="feels bad man meme" />
</p>

## Rencanane awal e iki

Awalnya sederhana.

Gue sering pakai ChatGPT dari HP.

Komputernya ada di tempat lain.

Terus kepikiran:

> **"kenapa AI gue nggak sekalian bisa masuk ke komputer, baca file, jalanin terminal, benerin project, terus kasih bukti kalau kerjaannya bener?"**

Dari situ mulai otak-atik:

- MCP;
- remote MCP;
- local MCP;
- browser bridge;
- launcher;
- skill;
- capability;
- approval;
- evidence;
- verification;
- router;
- CLI;
- dan tentu saja...

**kebanyakan ide.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/disaster-girl.jpg" width="300" alt="disaster girl meme" />
</p>

Rencana kasarnya waktu itu:

```text
ChatGPT / AI
      ↓
otak-atik
      ↓
pilih transport
      ↓
pilih capability
      ↓
pilih skill
      ↓
jalanin kerjaan
      ↓
verify
      ↓
done
```

Cakep.

Di diagram.

---

## Terus kenyataannya gimana?

Kenyataannya:

```text
ChatGPT
   ↓
Remote Desktop Commander plugin
   ↓
komputer gue
```

😭

Dan buat kerja lokal:

```text
Codex / local AI
   ↓
Desktop Commander local MCP
   ↓
komputer gue
```

Jadi setelah bikin router, adapter concept, launcher, skill registry, benchmark, provider scorecard, failure lab, dan tetek bengek lainnya...

**jalur yang paling sering gue pakai justru plugin yang sudah ada.**

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/ship-your-machine.jpg" width="305" alt="ship your machine meme" />
</p>

Kalau ukuran suksesnya:

> "apakah otak-atik menggantikan plugin?"

Jawabannya:

## **nggak.**

Setidaknya belum.

---

## Jadi repo ini gagal total?

Nggak juga.

Ini justru salah satu alasan gue nggak hapus repo ini.

Karena dari eksperimen ini gue jadi ngerti bedanya:

```text
REMOTE DESKTOP
≠
REMOTE MCP
≠
LOCAL MCP
≠
BROWSER BRIDGE
≠
GUI COMPUTER USE
≠
SKILL
≠
PERMISSION
≠
VERIFICATION
```

Sebelumnya semua terasa seperti:

> "pokoknya AI bisa ngontrol komputer."

Ternyata ya ora sesimpel kuwi.

Ada transport.

Ada capability.

Ada security boundary.

Ada approval.

Ada masalah GUI.

Ada quota.

Ada provider yang discovery-nya hidup tapi execution-nya belum tentu.

Ada tool yang bisa terminal tapi nggak bisa lihat tombol di layar.

Ada remote desktop yang bisa klik-klik tapi nggak ngerti MCP blas.

Dan ada gue di tengah-tengah:

> **"lah kok dadi ngene."**

---

## Salah satu eksperimen memang beneran gagal

Browser bridge lewat **MCP SuperAssistant** pernah dicoba.

Discovery jalan.

`initialize` jalan.

`tools/list` muncul.

Puluhan tool kelihatan.

Tapi dari inspection yang gue lakukan, jalur itu **nggak terbukti jadi daily execution path yang reliable**.

Jadi statusnya gue tulis terang-terangan:

```text
PARTIAL_FAILURE
```

Laporan eksperimennya tetap disimpan:

[Experiment report — MCP SuperAssistant browser bridge](labs/reports/2026-09-28-mcp-superassistant-browser-bridge.md)

Karena failed experiment yang dibuang cuma bikin kita gagal dua kali.

Sekali waktu eksperimennya gagal.

Sekali lagi waktu kita lupa **kenapa** dia gagal.

---

## Yang sebenarnya gue pakai sekarang

### 1. ChatGPT dari HP / jauh dari komputer

**Remote Desktop Commander**

```text
ChatGPT
→ Remote Desktop Commander
→ paired Windows machine
```

Ini paling praktis buat gue sekarang.

Remote Desktop Commander punya remote MCP untuk AI web seperti ChatGPT/Claude, sementara Desktop Commander local MCP bisa dipakai lokal oleh Codex dan client MCP lain.

**Tapi ini juga alasan repo ini gue sebut gagal.**

Karena ujung-ujungnya:

> **gue pakai plugin.**

Bukan bikin penggantinya sendiri.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/friday-deploy.jpg" width="300" alt="friday deploy meme" />
</p>

### 2. Kerja lokal

Kalau AI dan komputer ada di mesin yang sama:

```powershell
codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest
```

Ini lebih masuk akal daripada memutar kerja lokal lewat remote relay.

Local Desktop Commander MCP sendiri open source.

---

# Gais, gue justru lagi nyari solusi 😭

Nah.

Kalau lu nemu project yang lebih cocok, **please kasih tahu**.

Yang gue cari kurang lebih begini:

```text
FREE / OPEN SOURCE kalau bisa
+
Windows
+
bisa remote lewat internet
+
AI bisa screenshot
+
AI bisa click / type / scroll
+
MCP native atau gampang dijadikan MCP
+
kalau bisa muncul sebagai plugin/connector di ChatGPT
+
nggak harus bayar API tiap gerak mouse
+
self-hostable = bonus besar
```

Kalau ada benda yang memenuhi itu semua:

**mas, mbak, cak, suhu — issue repo ini terbuka.**

---

## Kandidat yang sejauh ini paling menarik

### 1. QuickDesk — paling dekat dengan yang gue cari

https://github.com/barry-ran/QuickDesk

Ini yang paling bikin gue:

> **"lah, iki toh sing tak goleki?"**

QuickDesk mendeskripsikan dirinya sebagai AI-native remote desktop yang:

- open source;
- gratis;
- punya **built-in MCP Server**;
- bisa screenshot;
- click;
- type;
- drag;
- scroll;
- clipboard;
- remote ke device lain;
- punya stdio dan HTTP/SSE MCP transport;
- bisa self-host signaling/TURN.

Jadi secara konsep:

```text
AI
↓ MCP
QuickDesk
↓
remote desktop
↓
screenshot / mouse / keyboard
```

**Ini kandidat nomor satu buat eksperimen berikutnya.**

Belum gue anggap pengganti final sebelum gue tes sendiri.

Karena README orang lain boleh bilang "works".

Gue tetap pengen lihat:

> **works neng komputerku ora?**

---

### 2. RustDesk — remote desktop-nya mantap, MCP-nya belum native

https://github.com/rustdesk/rustdesk

RustDesk itu open-source remote desktop dan bisa self-host server sendiri.

Buat manusia remote komputer:

**bagus banget sebagai kandidat.**

Masalah buat use case repo ini:

> dia bukan MCP-native remote computer-use layer.

Jadi kemungkinan arsitekturnya malah:

```text
AI
↓
MCP computer-use bridge
↓
RustDesk / remote transport
↓
Windows
```

Menarik.

Tapi berarti ada satu lapisan lagi yang harus gue otak-atik.

Dan kita tahu biasanya kalimat:

> "cuma tambah satu layer"

berakhir bagaimana.

---

### 3. MCPComputerUse — MCP GUI Windows, tapi bukan remote transport

https://github.com/kblood/MCPComputerUse

Ini menarik karena memang bikin MCP server Windows untuk:

- screenshot;
- window management;
- mouse;
- keyboard;
- macro/automation.

Jadi buat:

```text
AI
↓ MCP
Windows GUI
```

masuk.

Tapi problem **remote lewat internet** masih perlu lapisan lain.

Berarti mungkin perlu tunnel/VPN/relay yang aman.

Masih eksperimen territory.

---

### 4. Remote Desktop Commander — yang akhirnya gue pakai 😭

https://github.com/desktop-commander/remote-desktop-commander

Ya.

Ironis memang.

Remote Desktop Commander sekarang adalah jalur harian gue.

Dia bagus untuk:

- file system;
- terminal;
- process;
- editing;
- development workflow;
- remote MCP dari ChatGPT.

Tapi dia bukan full graphical remote desktop computer-use.

Jadi untuk:

> "lihat layar → cari tombol → klik → drag → interaksi GUI arbitrary"

gue masih pengen sesuatu yang lebih native.

Hosted Remote MCP-nya juga beda dengan local Desktop Commander MCP: local server-nya open source, sementara hosted remote service implementation-nya bukan open source.

Jadi masih ada alasan buat terus mencari.

---

## Yang gue pengen komunitas bantu jawab

Kalau lu nyasar ke repo ini dan ngerti area beginian, gue pengen jawaban konkret:

### Apakah ada solusi yang:

1. gratis atau open source;
2. bisa jalan di Windows;
3. bisa remote lewat internet;
4. punya screenshot + mouse + keyboard;
5. MCP-native **atau** gampang dijadikan MCP;
6. aman buat ditinggal running;
7. bisa dikontrol ChatGPT/Claude/Codex dari device lain;
8. nggak butuh lima service tambahan hanya untuk klik Start Menu?

Kalau ada:

**open an issue.**

Serius.

Karena mungkin solusi terbaik repo ini bukan nambah 12 ribu baris code.

Mungkin cukup:

> **"bro, pakai ini aja."**

Dan kalau memang begitu:

ya dipakai.

Gengsi engineering tidak lebih penting dari benda yang bekerja.

<p align="center">
  <img src="https://raw.githubusercontent.com/exxrawrrr/exxrawrrr/main/assets/readme-memes/git-force-push.jpg" width="300" alt="git force push meme" />
</p>

---

## Biar mampir nggak cuma bawa cerita gagal 🙏🏼😭

Nah ini yang sekarang gue paksa ada di repo.

Walaupun lu **nggak install Remote Desktop Commander**, **nggak pakai MCP SuperAssistant**, dan bahkan belum punya MCP client sama sekali, clone repo ini tetap harus ngasih sesuatu yang kepake.

Cukup Node.js 20+.

### Peta project buat AI

```powershell
otak-atik snapshot .
```

Bikin ringkasan project tanpa nge-dump semua source:

- jumlah file/folder;
- file penting;
- extension dominan;
- top-level structure;
- branch Git;
- working tree dirty atau nggak.

Berguna sebelum AI kalap baca 200 file satu-satu.

### Cek kemungkinan secret sebelum publish

```powershell
otak-atik hygiene .
otak-atik hygiene . --strict
```

Scanner ini nyari pola credential berisiko dan cuma laporan:

```text
file
line
jenis credential
severity
```

**Nilai secret-nya sengaja nggak dicetak.**

### Audit config MCP

```powershell
otak-atik mcp-check path\to\mcp.json
```

Bisa nangkep hal-hal receh tapi ngeselin:

- JSON invalid;
- `mcpServers` hilang;
- command/url nggak jelas;
- args/env bentuknya salah;
- URL invalid;
- remote MCP masih plain HTTP;
- kemungkinan token ditulis inline di config.

### Lint SKILL.md

```powershell
otak-atik skill-check path\to\SKILL.md
```

Buat ngecek skill sebelum dilempar ke repo publik:

- frontmatter;
- name;
- description;
- kebab-case;
- status/scope;
- file terlalu gendut;
- folder/name mismatch;
- path Windows pribadi nyangkut.

### Bikin handoff ke AI lain

```powershell
otak-atik handoff . --task "lanjut benerin project ini" --out handoff.json
```

Jadi kalau mau pindah:

```text
ChatGPT
→ Codex
→ Claude
→ AI lain
```

nggak harus mulai dari:

> "jadi gini bro dari awal ya..."

Handoff-nya bawa snapshot project, Git state, package scripts, task, hygiene counts, dan operating notes — **tanpa embed nilai secret**.

### Review risiko Git diff

```powershell
otak-atik diff-risk .
```

Buat kasih perhatian ekstra kalau diff nyentuh:

- delete file;
- auth/security;
- `.env`;
- migration;
- workflow GitHub Actions;
- dependency/lockfile;
- config/schema;
- perubahan teks gede;
- binary.

Ini **bukan vonis** bahwa perubahan HIGH itu jelek.

Maksudnya:

> **"cak, sing iki ojo asal pencet commit."**

Detail lengkap: [Standalone Utility Pack](docs/UTILITY-PACK.md).

---

## Terus isi repo ini sekarang buat apa?

Walaupun produk awalnya gagal, beberapa bagian masih berguna sebagai bahan eksperimen:

- transport router;
- operator plan compiler;
- capability inference;
- approval/risk contract;
- evidence contract;
- provider scorecard;
- failed-experiment lab;
- benchmark scenarios;
- Windows launcher;
- provider manifests;
- skill registry;
- setup decision tree;
- docs tentang remote/local/browser paths.

CLI-nya juga masih hidup:

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

Validation:

```powershell
npm run check
```

Current package:

```text
0.1.0-alpha.3
```

Node:

```text
>= 20
```

---

## Status project sekarang

Gue lebih suka menyebut statusnya:

```text
FAILED AS THE ORIGINAL SOLUTION
ACTIVE AS A RESEARCH / FAILURE LAB
```

Bukan production-ready operator.

Bukan remote desktop replacement.

Bukan pesaing TeamViewer.

Bukan pesaing plugin yang sekarang malah gue pakai.

Repo ini sekarang adalah tempat buat:

> **nyatet apa yang dicoba, apa yang works, apa yang goblok, apa yang gagal, dan apa yang mungkin layak dicoba berikutnya.**

---

## Prinsip yang masih gue pertahankan

```text
Reality > roadmap.
Evidence > vibes.
Working plugin > homemade architecture yang nggak kepakai.
Local > remote kalau memang task-nya lokal.
Verification > "harusnya sudah".
Failure documented > failure dilupakan.
Useful > gengsi bikin sendiri.
```

Dan mungkin pelajaran paling mahal dari repo ini:

> **nggak semua masalah perlu diselesaikan dengan bikin produk baru.**

Kadang jawabannya memang:

> "install plugin iki."

😭

---

## Docs yang masih relevan

- [What I actually use](docs/WHAT-I-ACTUALLY-USE.md)
- [Research status](docs/RESEARCH-STATUS.md)
- [Alternatives](docs/ALTERNATIVES.md)
- [Remote Desktop Commander](docs/REMOTE-DESKTOP-COMMANDER.md)
- [MCP SuperAssistant browser bridge](docs/BROWSER-BRIDGE.md)
- [Provider matrix](docs/PROVIDER-MATRIX.md)
- [Failure report](labs/reports/2026-09-28-mcp-superassistant-browser-bridge.md)
- [Security](SECURITY.md)
- [Roadmap](ROADMAP.md)

---

<br/>

# For everyone else

**otak-atik is a documented failed experiment that remains active as a research lab for AI-to-computer control, MCP transports, routing, skills, evidence, and verification.**

The original goal was to create a practical operator layer that could help AI clients reach and operate the author's computer without depending on a single third-party plugin or transport.

In real daily use, that goal has not been achieved.

The author's current primary remote workflow is:

```text
ChatGPT
→ Remote Desktop Commander
→ Windows machine
```

For local MCP work, Desktop Commander is used directly with clients such as Codex.

The repository is retained because it contains useful experiments around transport selection, capability modeling, approval boundaries, evidence contracts, provider evaluation, onboarding, and failure documentation.

## Current research question

The project is particularly interested in a free/open-source path that combines:

- remote desktop transport;
- graphical computer use;
- screenshots;
- mouse and keyboard control;
- Windows support;
- MCP compatibility;
- remote AI-client access;
- safe user-controlled authorization.

QuickDesk currently appears to be the closest public project to that requirement set and is the next obvious candidate for evaluation.

RustDesk is a strong open-source remote-desktop candidate but does not provide the same built-in MCP computer-use interface.

MCPComputerUse provides a Windows-native MCP GUI-control layer but is not itself the remote transport.

## Contributions

Reports from real usage are more valuable than architecture opinions.

If you know a project that better satisfies the requirements above, open an issue with:

- project/repository link;
- license;
- supported operating systems;
- remote transport model;
- MCP integration method;
- screenshot/mouse/keyboard support;
- self-hosting status;
- what you personally verified.

---

**The experiment failed to replace the plugin. The documentation does not need to pretend otherwise.**
