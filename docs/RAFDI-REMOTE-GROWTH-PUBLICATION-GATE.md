# Rafdi Remote GROWTH — Publication Gate

This file is the safety contract for turning the successful one-machine experiment into reusable automation.

Phase 2 must not cross this gate by copying the author's live machine configuration verbatim.

## NEVER publish

The following are machine-local secrets or identifiers and must never be copied into the repository:

- `auth.key` contents;
- bearer tokens;
- Tailscale auth keys or reusable login keys;
- tunnel credentials;
- OAuth tokens/cookies;
- Composio private connection credentials;
- private connector exports;
- private IPs when not needed for an example;
- the author's live Tailscale hostname as a hardcoded runtime value;
- user-specific Windows profile paths as fixed defaults;
- screenshots containing visible secrets.

## May publish only as placeholders/examples

Use discovered/generated values at install time for:

- Windows username/profile directory;
- machine hostname;
- Tailscale DNS/Funnel hostname;
- MCP port;
- installation directory;
- Scheduled Task user;
- bearer token.

Example documentation may use:

```text
https://<machine>.<tailnet>.ts.net/mcp
%LOCALAPPDATA%\RafdiRemoteMCP
<generated-bearer-key>
```

Do not ship the real values from the test machine.

## Phase 2 installer requirements

The public installer must:

1. support `-WhatIf` or an equivalent dry-run path;
2. detect Windows rather than assuming paths;
3. detect/install prerequisites explicitly;
4. generate a fresh random bearer token locally;
5. never print the token in normal logs;
6. store the token outside the repository;
7. configure Windows-MCP to bind loopback only;
8. enable host-origin protection;
9. discover the user's own Tailscale DNS hostname;
10. create the allowed-host list from discovered values;
11. require the user to authenticate Tailscale themselves;
12. enable Funnel only after Tailscale reports a usable state;
13. create an idempotent supervisor;
14. create an idempotent Scheduled Task;
15. provide status, repair, and uninstall commands;
16. verify the endpoint without sending the secret to third-party logs;
17. fail closed if identity/service checks are ambiguous;
18. avoid touching unrelated Cloudflare/Tailscale/WordPress tunnels.

## Proof required before claiming reusable

A public setup may be documented as `EXPERIMENTAL` after static validation.

It may only be called `REPRODUCIBLE` after:

- clean or disposable Windows installation test;
- install succeeds;
- restart/login recovery succeeds;
- public endpoint rejects unauthenticated traffic;
- authenticated MCP initialize succeeds;
- PowerShell smoke test succeeds;
- filesystem smoke test succeeds;
- uninstall removes created resources;
- reinstall succeeds;
- repository hygiene scan finds no real secrets.

## Files planned for Phase 2

Proposed public package:

```text
experiments/rafdi-remote-growth/
├── README.md
├── setup.ps1
├── status.ps1
├── repair.ps1
├── uninstall.ps1
├── lib/
│   └── common.ps1
└── templates/
    └── supervisor.ps1.tmpl
```

Names may change during implementation, but responsibilities should remain separated.

## Publication rule

The repository should contain **automation that generates a local configuration**, not a copy of the author's local configuration.

That distinction is the whole safety boundary.
