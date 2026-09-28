# Generic MCP adapter

The generic MCP adapter exists to avoid building one core integration per server.

A future adapter loader should:

1. discover server tools;
2. require an explicit mapping from provider tool to canonical capability;
3. validate risk metadata;
4. expose health/discovery status;
5. refuse ambiguous mutation mappings.

Automatic guessing of tool semantics is not a safe default.
