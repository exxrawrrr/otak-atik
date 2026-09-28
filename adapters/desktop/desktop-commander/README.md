# Desktop Commander adapter

Status: **reference mapping / pre-runtime adapter**

Desktop Commander can provide desktop-side capabilities to MCP-capable AI clients.

otak-atik treats it as a provider adapter rather than a hard dependency.

Target mapping:

- file reads → `filesystem.read`
- file edits/writes → `filesystem.write`
- shell/process execution → `terminal.execute`
- process inspection → `process.inspect`

The V0.1 repository documents this mapping but does not proxy or reimplement Desktop Commander.

Provider setup and authentication remain provider-owned concerns.
