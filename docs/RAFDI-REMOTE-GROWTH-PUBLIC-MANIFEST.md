# Rafdi Remote GROWTH — Public Artifact Manifest

Status: **FROZEN FOR PHASE 2 IMPLEMENTATION**

The real machine setup is the evidence source.

The repository package must be a **sanitized generator/reimplementation**, not a dump of the live files.

## Intended public tree

```text
experiments/rafdi-remote-growth/
├── README.md
├── setup.ps1
├── status.ps1
├── repair.ps1
├── uninstall.ps1
├── test.ps1
├── lib/
│   └── common.ps1
├── templates/
│   └── supervisor.ps1.tmpl
└── examples/
    └── composio-custom-mcp.example.md
```

## Responsibilities

### setup.ps1

Must:

- detect Windows;
- detect PowerShell environment;
- locate or install `uv`;
- install Windows-MCP locally;
- locate/install Tailscale;
- stop before account-auth steps that require the user;
- generate a random bearer key locally;
- write machine-local config outside the repo;
- discover Tailscale DNS name after login;
- render supervisor template with discovered values;
- configure Funnel;
- create auto-start;
- run smoke checks.

Must be rerunnable.

### status.ps1

Must report, without printing secrets:

- Windows-MCP local listener state;
- supervisor state;
- Tailscale service state;
- Tailscale login/backend state;
- Funnel state;
- discovered stable URL;
- auto-start registration state.

### repair.ps1

May restart only:

- this experiment's supervisor;
- this experiment's listener;
- this experiment's Funnel configuration.

It must not kill unrelated tunnels or generic `cloudflared`/Tailscale resources by broad process name.

### uninstall.ps1

Must remove only resources created by the package.

It must preserve:

- the user's Tailscale account;
- unrelated Tailscale configuration;
- unrelated scheduled tasks;
- unrelated MCPs;
- user data outside the install directory.

### test.ps1

Must verify:

- local listener exists;
- unauthenticated public request is rejected;
- MCP identity is Windows-MCP;
- generated config contains no placeholder values;
- stable endpoint format is sane;
- auto-start entry exists.

Authenticated tests must avoid leaking the bearer token into console logs.

### templates/supervisor.ps1.tmpl

Must:

- be machine-agnostic;
- receive paths/hostname/port from setup;
- bind loopback only;
- set host-origin protection;
- set explicit allowed hosts;
- read bearer key from a local file;
- restart the listener after failure;
- write bounded/rotatable logs if practical.

### examples/composio-custom-mcp.example.md

Must document:

- URL form `https://<machine>.<tailnet>.ts.net/mcp`;
- bearer authentication;
- how to create a new Custom MCP instead of exposing credentials;
- how to verify the connected tools;
- that screenshots/account identifiers should be redacted before posting issues.

## Files intentionally NOT copied from the live machine

Do not commit direct copies of:

- `auth.key`;
- generated local supervisor containing the real hostname;
- user-specific BAT files;
- logs;
- Tailscale output files;
- local setup notes;
- account screenshots;
- Composio connection exports.

The public package should reproduce their behavior safely.

## Phase 2 exit criteria

Phase 2 implementation is complete only when:

- intended tree exists;
- scripts parse successfully;
- no real machine hostname is hardcoded in executable templates;
- no hardcoded user-profile path dependency exists;
- no real bearer token exists;
- setup supports dry-run;
- status/repair/uninstall share common discovery logic;
- repo hygiene still passes.
