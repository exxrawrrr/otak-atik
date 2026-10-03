# Portable Remote GROWTH Stable runtime

This directory is the identity-neutral source package for the 64-tool Remote GROWTH Stable gateway.

It contains the same engine families used by the verified GROWTH runtime, but machine-specific paths, the owner's Tailscale hostname, and private credentials are not part of this source tree.

Runtime installation is handled by:

```text
scripts/windows/remote-growth-stable/install-runtime.ps1
```

Installed state belongs under the current user's LocalAppData directory.

The runtime exposes:

- 15 Windows-MCP primitives through the loopback upstream;
- 6 Fast Local tools;
- 6 Document tools;
- 9 Developer/Git tools;
- 10 Safe FileOps tools;
- 12 SystemOps tools;
- 6 Workflow tools.

Expected total: **64 tools**.

The runtime must not be considered ready until authenticated `tools/list` returns exactly 64 entries.
