# AI client compatibility

## Personally exercised by the project author

### ChatGPT

Primary remote path:

```text
ChatGPT
→ Remote Desktop Commander remote MCP
→ paired computer
```

This is the cleanest web/mobile use case.

### Codex

Primary use:

- local repository work;
- file inspection/editing;
- terminal/test workflows;
- reusable local skills.

Codex does not need a Chrome extension for non-browser operation.

## Other clients

The architecture intentionally targets MCP-compatible clients such as:

- Claude;
- Cursor;
- VS Code / GitHub Copilot;
- Gemini CLI;
- other clients supporting local or remote MCP.

Support level should be described honestly:

```text
documented
≠
personally tested
≠
CI tested
≠
production proven
```

If a client has native MCP support, prefer that before adding a browser injection layer.

## Community reports

Please open an issue with:

- client name/version;
- operating system;
- local vs remote MCP;
- transport;
- what worked;
- what failed;
- minimal reproduction.

Semangat, gess. Compatibility tables become useful only when they contain evidence instead of optimism.
