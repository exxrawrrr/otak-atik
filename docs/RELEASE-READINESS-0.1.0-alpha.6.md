# Release Readiness — v0.1.0-alpha.6

Date: 2026-10-03
Candidate branch: `chat5-fresh-user-release`
Target branch: `main`

## Release intent

This alpha release turns the guided Windows Remote GROWTH experiment into a user-first downloadable flow:

```text
download ZIP
→ extract
→ START.cmd
→ guided Tailscale / Remote GROWTH / Composio flow
→ STATUS.cmd
→ REPAIR.cmd
```

It does not rename the Remote GROWTH gateway runtime. The npm/repository release remains `0.1.0-alpha.6`; the gateway runtime remains `0.7.0`.

## Required gates before tagging

- [ ] package version and changelog agree on `0.1.0-alpha.6`;
- [ ] PowerShell scripts parse;
- [ ] workflow YAML parses;
- [ ] `npm run check` passes;
- [ ] `npm run release:check` passes;
- [ ] strict repository hygiene returns zero high/medium findings;
- [ ] Windows release ZIP builds successfully;
- [ ] ZIP-specific private identity / secret scan passes;
- [ ] ZIP has a SHA-256 sidecar;
- [ ] clean Windows CI runs first `START.cmd` from the extracted ZIP without Node.js or Git;
- [ ] clean Windows CI creates Desktop `START.cmd`, `STATUS.cmd`, and `REPAIR.cmd`;
- [ ] clean Windows CI deletes the extracted source and reruns installed `START.cmd` from cached files;
- [ ] clean Windows CI reports a guided first-run STATUS rather than crashing when account/runtime setup is incomplete;
- [ ] existing fresh portable runtime acceptance returns HTTP 401 + 64/64;
- [ ] existing STATUS/REPAIR destructive recovery acceptance returns READY + HTTP 401 + 64/64;
- [ ] foreign-port fail-closed acceptance leaves the foreign process alive;
- [ ] PR Linux/Windows validation passes;
- [ ] PR fresh-user-bundle job passes;
- [ ] merge to `main` completes;
- [ ] post-merge `main` validation passes;
- [ ] post-merge `main` fresh-user-bundle job passes;
- [ ] release ZIP is rebuilt from the verified `main` commit;
- [ ] Git tag `v0.1.0-alpha.6` points to that verified `main` commit;
- [ ] GitHub release includes the Windows ZIP and SHA-256 sidecar.

## Account-owned boundary

A clean CI runner cannot and must not impersonate a new human account for Tailscale or Composio.

The release therefore verifies the user-owned boundary this way:

- setup detects when Tailscale is absent or signed out;
- the wizard explicitly hands sign-in back to the user;
- Composio Project API Key input is explicit and memory-only;
- hosted Composio connection remains an explicit user action;
- no account credential is shipped in the release bundle;
- public exposure is blocked until local authentication and exact 64-tool inventory pass.

This is a deliberate product boundary, not a test bypass.

## Reboot boundary

The project already has historical real Windows reboot evidence for the same Remote GROWTH/Tailscale transport family. CHAT 4 adds destructive task/process recovery acceptance for the current portable guided runtime.

CHAT 5 does not silently reboot the owner's active workstation as part of release automation. The alpha release may cite:

- historical real reboot persistence evidence;
- current fresh Windows runner installation evidence;
- current isolated Scheduled Task/runtime recovery evidence.

It must not claim that a brand-new human account/device has completed an unattended real reboot unless that exact test is later performed.

## Rollback

If any candidate or post-merge gate fails:

1. do not create or move `v0.1.0-alpha.6`;
2. fix forward on a branch;
3. rerun the same gates;
4. rebuild the release ZIP from the final verified `main` commit.

Existing tags must never be moved.

## Current decision

**CANDIDATE — DO NOT TAG YET.**
