# Security Policy

otak-atik deals with a dangerous category of software: systems that can connect AI reasoning to local tools and external services.

The project therefore treats safety boundaries as product architecture, not disclaimer text.

## Supported versions

During public alpha, only the latest main branch and latest tagged alpha release are supported.

## Report a vulnerability

Do not open a public issue containing exploitable details or secrets.

Use GitHub's private security reporting when available.

## Threat model

The project must assume that any of the following may be hostile or compromised:

- a downloaded third-party skill;
- an MCP server;
- tool output;
- web content;
- repository instructions;
- copied shell commands;
- dependencies;
- external connector data.

Important threat classes include:

- prompt injection;
- command injection;
- path traversal;
- symlink/junction escape;
- secret exfiltration;
- unsafe shell execution;
- malicious skill scripts;
- compromised MCP endpoints;
- accidental destructive mutation;
- dependency/supply-chain compromise.

## Default stance

- telemetry off;
- observe profile;
- no implicit full-disk write scope;
- critical actions denied by default;
- mutation should be followed by verification.

## Secrets

Never commit:

- API keys;
- OAuth tokens;
- cookies;
- private keys;
- production credentials;
- personal connector exports.

Use operating-system credential stores, provider OAuth, or environment variables.

## Third-party skills

A skill is executable guidance.

Treat unknown skills like unknown code.

Review:

- requested capabilities;
- included scripts;
- external endpoints;
- mutation behavior;
- provenance.

before installing or running them.

## Security limitations

The current alpha does not yet claim a hardened sandbox.

Policy metadata is a contract for the evolving operator engine, not a security boundary equivalent to operating-system isolation.
