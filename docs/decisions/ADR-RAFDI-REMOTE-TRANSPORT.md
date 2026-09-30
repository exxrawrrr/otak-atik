# ADR: Use Composio + Tailscale Funnel + Windows-MCP for the remote ChatGPT experiment

Status: **Accepted for the experimental public recipe**

Date: 2026-09-29

## Context

The project needed a remote path from ChatGPT to a user-owned Windows machine with terminal, filesystem, process, and optional GUI control.

The solution also needed to avoid depending on a temporary public URL after each restart.

## Considered paths

### Remote Desktop Commander

Pros:

- already works from ChatGPT;
- minimal setup;
- strong terminal/filesystem workflow.

Cons for this specific experiment:

- hosted remote usage is quota-constrained;
- does not answer the research question of building an alternate path.

Decision: keep as baseline/fallback, not the new experimental transport.

### Local Desktop Commander MCP

Pros:

- good local terminal/filesystem MCP;
- open-source local server;
- useful for Codex/local clients.

Cons:

- not itself a ChatGPT-cloud-to-local-PC transport.

Decision: useful component in the wider repo, but not selected here.

### TRIGGERcmd

Pros:

- remote command execution model;
- Windows agent.

Cons:

- command-trigger model is less direct than exposing a normal MCP tool surface;
- not selected after the full custom MCP path became viable.

Decision: not selected.

### Cloudflare Quick Tunnel

Pros:

- easy proof of concept;
- no router port forwarding;
- proved that an HTTP MCP endpoint could be reached through Composio.

Cons:

- temporary hostname;
- endpoint churn is annoying for a Custom MCP definition;
- first test exposed the danger of tunneling the wrong local port.

Decision: POC only; retired after migration.

### Tailscale Funnel

Pros:

- stable HTTPS hostname;
- Windows service integration;
- background Funnel configuration persisted through service restart in the real test;
- does not require direct inbound router configuration;
- works with a loopback-bound MCP backend.

Cons:

- user must authenticate Tailscale;
- Funnel must be enabled for the user's tailnet;
- public internet exposure still requires application-level authentication and host checks.

Decision: selected transport for the reusable experiment.

### Composio Custom MCP

Pros:

- made the remote MCP tool surface callable from ChatGPT;
- worked with PowerShell, filesystem, process, and GUI-capable Windows-MCP schema;
- separates ChatGPT integration from the Windows transport.

Cons:

- custom MCP app configuration is an external dependency;
- endpoint/auth onboarding still requires user interaction;
- changing an existing custom MCP endpoint was not available in the tested management flow, so migration used a second app definition.

Decision: selected ChatGPT integration layer for this experiment.

## Accepted architecture

```text
ChatGPT
  ↓
Composio Custom MCP
  ↓
Tailscale Funnel (stable HTTPS hostname)
  ↓
Windows-MCP on 127.0.0.1
  ↓
Windows tools
```

## Reverse-proxy host validation decision (Phase 2B)

Public Funnel testing exposed a layered host-validation conflict in the installed Windows-MCP stack.

Observed test stack:

```text
Windows-MCP 0.8.6
FastMCP 4.0.10
MCP 2.2.0
```

Windows-MCP 0.8.6 computes a loopback-only Trusted Host allowlist when the server binds to loopback. A one-request probe behind Tailscale Funnel confirmed that Funnel preserves the real external `Host` header, including the public HTTPS port. That valid public host was rejected by Windows-MCP's own Trusted Host middleware before the explicit FastMCP host allowlist could handle the request.

Decision:

- keep Windows-MCP bound to `127.0.0.1`;
- keep bearer authentication mandatory;
- launch Windows-MCP with its official `--allow-insecure-remote` flag only to suppress its hardcoded loopback Trusted Host middleware;
- keep FastMCP host-origin protection explicitly enabled;
- explicitly allow only the discovered Tailscale DNS hostname and loopback hostnames, including wildcard-port forms;
- never pair this compatibility flag with an unauthenticated `0.0.0.0` bind in this recipe.

This is a compatibility shim, not a relaxation of the architecture's authentication or loopback-binding requirements.

Revisit this decision when Windows-MCP exposes a first-class configurable public/reverse-proxy host allowlist.

## Required security properties

The recipe is invalid if any of these are removed without an explicit new ADR:

- Windows-MCP binds loopback only;
- bearer authentication remains enabled;
- bearer key is generated per machine;
- host-origin protection remains enabled;
- if `--allow-insecure-remote` is used for Windows-MCP reverse-proxy compatibility, loopback binding + bearer authentication + explicit FastMCP host allowlisting remain mandatory;
- allowed hosts are discovered/configured explicitly;
- credentials stay outside the repository;
- setup verifies service identity before declaring success;
- uninstall/recovery target only resources created by the recipe.

## Non-goals

This ADR does not claim:

- hardened zero-trust endpoint security;
- unattended first-time Tailscale account creation;
- universal compatibility with every ChatGPT plan/account/workspace;
- reproducibility before the clean-machine test exists;
- replacement of normal remote desktop software for human use.

## Revisit if

Re-evaluate this choice if:

- Composio custom MCP changes materially;
- Tailscale Funnel behavior/pricing/availability changes;
- ChatGPT gains a simpler direct custom-MCP path suitable for this workflow;
- another open-source transport provides stable authenticated remote MCP with fewer external dependencies.
