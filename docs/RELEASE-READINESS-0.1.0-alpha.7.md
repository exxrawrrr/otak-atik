# Release Readiness - v0.1.0-alpha.7

Date: 2026-10-03
Candidate branch: `release-lock-alpha7`

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
- [x] clean Windows fresh-user START still works with Node/Git unavailable to the user path
- [x] installed START survives source removal
- [x] STATUS headless JSON contract passes
- [x] fresh 64-tool runtime acceptance passes
- [x] STATUS / REPAIR destructive recovery passes
- [x] foreign-port fail-closed test passes
- [x] PR validate passes
- [x] PR Windows onboarding + fresh-user bundle pass
- [x] post-merge main validation passes
- [x] post-merge Windows onboarding + fresh-user bundle pass
- [x] final ZIP rebuilt from exact verified main commit
- [x] immutable annotated tag `v0.1.0-alpha.7` points to that commit
- [x] GitHub prerelease publishes ZIP + SHA-256 sidecar

## GUI boundary

GitHub runners verify the launcher contract and headless behavior. The primary GROWTH Windows machine is used for a read-only Windows Terminal smoke to confirm that the interactive wrapper can launch the native terminal surface.

The release does not automate keystrokes or force fullscreen F11. It uses supported Windows Terminal maximized + focus mode and falls back to PowerShell when Windows Terminal is unavailable.

Primary GROWTH read-only GUI smoke: PASS. Windows Terminal opened with window title `OTAK-ATIK STATUS`, the smoke window was closed gracefully, and production ports 18765/18766 remained listening.

Local candidate bundle before GitHub CI: 46 files, 110,663 bytes, SHA-256 `b281cae94b1140df2716020f32dba5ab0558f86daa6c37439bb3ae7a75a3693f`.

## Current decision

**RELEASED - v0.1.0-alpha.7 published as a GitHub prerelease.**

## Local candidate evidence

- premium Windows Terminal read-only smoke: PASS; native window title observed as `OTAK-ATIK STATUS`;
- smoke window closed gracefully afterward;
- production ports 18765 / 18766 remained listening after the GUI smoke;
- candidate Windows ZIP contains 46 files including `premium-tui.ps1` and `premium-launcher.ps1`;
- candidate ZIP size at the latest local build: 110,663 bytes; final release digest is intentionally deferred until rebuild from the exact verified `main` commit.


## Verified PR evidence

- PR #29 final head: `eb206e606d746b94908cc77bfbcc366275de74ea`.
- `validate` run #79: PASS.
- `windows-onboarding` run #35: PASS.
- fresh-user-bundle: PASS, including first START without Node/Git, source removal, installed launcher survival, and guided first-run STATUS.
- onboarding: PASS, including fresh 64-tool runtime, missing-task detection, stopped-runtime simulation, REPAIR recovery, READY status, and foreign-port fail-closed acceptance.
- implementation merged to `main` as `934e6e2f092cc6a239613ae69e830275b88df74c`.

The first PR run exposed a trailing-backslash quoting bug in the root first-start launcher. The release was held, `START.cmd` was corrected to pass `%~dp0.`, a regression test was added, and the replacement PR head passed both workflows.


## Published release evidence

- final release commit: `50e7b1bd737daa13f03d1a19a3e725b450a23f23`;
- final `validate` push run: PASS;
- final manually dispatched `windows-onboarding` run: PASS;
- fresh-user-bundle: PASS;
- annotated tag: `v0.1.0-alpha.7`;
- tag dereference: `v0.1.0-alpha.7^{} -> 50e7b1bd737daa13f03d1a19a3e725b450a23f23`;
- release state: prerelease, not draft;
- final Windows ZIP files: 46;
- final Windows ZIP size: 110,743 bytes;
- final Windows ZIP SHA-256: `ffdff59a94f37243ed957c3f83728502b1257850094079412788d8c8482822de`;
- published assets: Windows ZIP + SHA-256 sidecar.
