# Release Readiness - v0.1.0-alpha.7

Date: 2026-10-03
Candidate branch: `chat6-premium-terminal-tui`

## Intent

CHAT 6 is a presentation-layer release over the verified CHAT 1-5 runtime/security contract.

It upgrades the Windows user experience to a premium live terminal installer while preserving:

- Tailscale and Funnel ownership checks;
- bearer authentication;
- HTTP 401 unauthenticated rejection;
- exact 64-tool inventory gates;
- Composio API sync requirements;
- STATUS JSON/exit-code behavior;
- REPAIR fail-closed ownership rules.

## Required gates

- [x] PowerShell parse clean
- [x] premium TUI contract tests pass
- [x] all Node tests pass
- [x] routing benchmark passes
- [x] strict hygiene returns 0 high / 0 medium
- [x] skill audit returns 0 errors / 0 warnings
- [x] `npm run release:check` passes
- [x] alpha.7 Windows ZIP builds
- [x] bundle identity/secret scan passes
- [x] premium TUI and premium launcher are included in the ZIP
- [ ] clean Windows fresh-user START still works with Node/Git unavailable to the user path
- [ ] installed START survives source removal
- [x] STATUS headless JSON contract passes
- [ ] fresh 64-tool runtime acceptance passes
- [ ] STATUS / REPAIR destructive recovery passes
- [ ] foreign-port fail-closed test passes
- [ ] PR validate passes
- [ ] PR Windows onboarding + fresh-user bundle pass
- [ ] post-merge main validation passes
- [ ] post-merge Windows onboarding + fresh-user bundle pass
- [ ] final ZIP rebuilt from exact verified main commit
- [ ] immutable annotated tag `v0.1.0-alpha.7` points to that commit
- [ ] GitHub prerelease publishes ZIP + SHA-256 sidecar

## GUI boundary

GitHub runners verify the launcher contract and headless behavior. The primary GROWTH Windows machine is used for a read-only Windows Terminal smoke to confirm that the interactive wrapper can launch the native terminal surface.

The release does not automate keystrokes or force fullscreen F11. It uses supported Windows Terminal maximized + focus mode and falls back to PowerShell when Windows Terminal is unavailable.

Primary GROWTH read-only GUI smoke: PASS. Windows Terminal opened with window title `OTAK-ATIK STATUS`, the smoke window was closed gracefully, and production ports 18765/18766 remained listening.

Local candidate bundle before GitHub CI: 46 files, 110,663 bytes, SHA-256 `b281cae94b1140df2716020f32dba5ab0558f86daa6c37439bb3ae7a75a3693f`.

## Current decision

**CANDIDATE - DO NOT TAG YET.**

## Local candidate evidence

- premium Windows Terminal read-only smoke: PASS; native window title observed as `OTAK-ATIK STATUS`;
- smoke window closed gracefully afterward;
- production ports 18765 / 18766 remained listening after the GUI smoke;
- candidate Windows ZIP contains 46 files including `premium-tui.ps1` and `premium-launcher.ps1`;
- candidate ZIP size at the latest local build: 110,663 bytes; final release digest is intentionally deferred until rebuild from the exact verified `main` commit.
