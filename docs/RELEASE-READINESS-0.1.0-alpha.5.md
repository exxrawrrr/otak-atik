# Release Readiness Ã¢â‚¬â€ v0.1.0-alpha.5

Date: 2026-09-30
Candidate branch: `feat/rafdi-remote-growth-stable`
Target branch: `main`

## Release intent

This candidate packages the existing otak-atik alpha line plus the verified Rafdi Remote experiment.

It is still an **alpha** release.

The release does not claim:

- production-grade remote desktop;
- universal clean-machine Rafdi Remote reproducibility;
- a hardened operating-system sandbox;
- unattended Tailscale or Composio account provisioning.

## Required gates before tagging

- [x] feature branch is not behind `main`;
- [x] working tree is clean;
- [x] `npm run check` passes;
- [x] `npm run release:check` passes;
- [x] Linux GitHub Actions job passes on the PR;
- [x] Windows GitHub Actions job passes on the PR;
- [x] Rafdi Remote PowerShell files parse on Windows CI;
- [x] rendered Rafdi Remote supervisor template parses on Windows CI;
- [x] secret hygiene returns zero high/medium findings;
- [x] package version and changelog agree on `0.1.0-alpha.5`;
- [x] packed tarball installs into an empty consumer project and its CLI reports `0.1.0-alpha.5`;
- [x] packaged `doctor` reports `READY` without Node `DEP0190`;
- [x] PR diff/private-value review confirms no bearer token, personal email, private tailnet hostname, or local user path leaked;
- [ ] merge to `main` completes without rewriting existing tags.

## Package audit

`npm pack --dry-run --json` was inspected before release preparation.

Observed candidate package footprint before alpha.5 metadata changes:

```text
compressed: ~99 KB
unpacked:   ~321 KB
entries:    172
```

The package intentionally carries the research/skill/config material needed by the project. No late-stage `files` whitelist is introduced for alpha.5 because accidentally excluding registries, labs, scripts, or skills would be a higher release risk than the current small package size.

## Tagging rule

Do **not** tag the feature branch before merge.

After the PR is merged and the resulting `main` commit passes its push CI:

```text
tag: v0.1.0-alpha.5
target: the verified main commit
```

Existing alpha tags must not be moved.

## Release notes source

Use the `0.1.0-alpha.5` section in `CHANGELOG.md`.

## Rollback

If the PR or post-merge CI fails:

1. do not create or move the alpha.5 tag;
2. fix forward on a feature branch;
3. rerun the same release gates;
4. only tag a verified `main` commit.

## Current release decision

**LOCAL + PR CI GATES PASS. READY FOR REVIEW/MERGE, NOT YET READY TO TAG.**

## PR CI evidence

PR: `#9`
GitHub Actions run: `22` (`validate`)

- Linux `linux-check`: PASS
- Windows `windows-smoke`: PASS
- Windows `Validate and test`: PASS
- Windows installer dry run: PASS
- Windows helper PowerShell parse: PASS
- Windows Rafdi Remote PowerShell + rendered supervisor parse: PASS
