# Remote GROWTH Native — reusable ChatGPT MCP/plugin bootstrap

This folder is the **public, reusable** version of the native-plugin setup pattern proven on the author's Windows workstation.

It does **not** contain the author's:

- OpenAI runtime API key;
- tunnel ID;
- bearer token;
- generated private ChatGPT app ID;
- local paths/data;
- encrypted credential blob.

Every user supplies their own account-specific values locally.

## What this bootstrap does

For an already-running local MCP server, the Windows helpers can:

1. download the official OpenAI `tunnel-client`;
2. verify its downloaded archive against the release's official `SHA256SUMS.txt`;
3. create a Secure MCP Tunnel profile for the user's own tunnel;
4. keep the runtime API key out of the profile;
5. optionally cache the runtime API key with Windows DPAPI for the current Windows user;
6. run/status/stop the tunnel;
7. build a private plugin ZIP bound to the user's own verified `plugin_asdk_app_...` ID;
8. secret-scan the generated plugin before packaging.

## Important scope

This bootstrap currently assumes that the local MCP server already exists.

For the reference Remote GROWTH layout, the default is:

```text
http://127.0.0.1:18768/mcp
```

The public repo does **not yet** claim that the full 64-tool GROWTH runtime is portable to arbitrary Windows machines. That remains a separate reproducibility milestone.

## Quick start

From a cloned repository on Windows PowerShell:

### 1. Configure the Secure MCP Tunnel

Memory-only runtime key:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\setup-tunnel.ps1
```

Or opt in to a locally encrypted runtime-key cache:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\setup-tunnel.ps1 -PersistEncryptedRuntimeKey
```

The encrypted cache uses Windows PowerShell's current-user DPAPI protection and is written below:

```text
%LOCALAPPDATA%\otak-atik\remote-growth-native\
```

It is not written into the Git checkout.

### 2. Start the tunnel

Foreground:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\run-tunnel.ps1
```

Detached:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\run-tunnel.ps1 -Detached
```

### 3. Check it

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\status-tunnel.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\doctor.ps1
```

### 4. Create your ChatGPT MCP app

In ChatGPT's plugin/developer flow, create an MCP app using the **Tunnel** connection path.

Scan your own MCP tools and verify the expected tool surface.

Do not reuse another person's tunnel or app ID.

### 5. Build your private plugin package

After ChatGPT gives you your own technical app ID:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\build-plugin.ps1
```

The builder prompts for:

```text
plugin_asdk_app_...
```

It creates the final `.app.json` only in a generated local build under:

```text
%LOCALAPPDATA%\otak-atik\remote-growth-native\builds\
```

The generated app ID is **not** written back into this repository.

## Where each sensitive value goes

| Value | Public repo? | Local generated config? | Notes |
|---|---:|---:|---|
| Runtime API key | **Never** | memory or optional DPAPI blob | Secret |
| Tunnel ID | **Never in source** | yes, local tunnel profile | User-specific metadata |
| ChatGPT app technical ID | **Never in source** | generated private plugin build | User-specific binding |
| MCP localhost URL | template/default | yes | Usually non-secret |
| Plugin skills/templates | yes | copied into build | Intended public source |

## Runtime API key storage

The safest mode is memory-only: the user pastes the key when the tunnel starts.

For convenience, `-PersistEncryptedRuntimeKey` stores only the DPAPI-encrypted result returned by `ConvertFrom-SecureString`.

That encrypted value is tied to the current Windows user context and remains outside the repository.

No plaintext key should be written into:

- YAML profiles;
- JSON configuration;
- plugin manifests;
- skill files;
- Git;
- logs.

## Plugin package model

The public source contains:

```text
plugin-template/
  plugin.json
  .app.json.template
  skills/
```

The public `plugin.json` deliberately has **no app binding**.

The builder:

1. copies the template outside the repository;
2. writes a real local `.app.json`;
3. adds `extensions.com.openai.apps` to the generated manifest;
4. validates that obvious secret patterns are absent;
5. creates a ZIP and SHA-256 hash.

This prevents the author's or a contributor's personal app ID from becoming the canonical public configuration.

## Forking / development

Forks should change:

- plugin instructions;
- skill behavior;
- native MCP server implementation;
- tool schemas;
- safety policy;

but should continue to keep account-specific credentials and IDs out of Git.

## Stop

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows\remote-growth-native\stop-tunnel.ps1
```

## Security rule

**Code is portable. Identity and credentials are not.**

A working fork should require each user to supply their own tunnel, runtime credential, and ChatGPT app binding.
