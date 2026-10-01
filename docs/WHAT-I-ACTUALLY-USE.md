# What I actually use

This page exists because the machine accumulated multiple MCP, browser, tunnel, and remote-control experiments. Installed does not mean required.

## 1. Direct interactive path — Remote Desktop Commander

For ad-hoc interactive computer work, Remote Desktop Commander remains useful:

```text
ChatGPT
→ Remote Desktop Commander
→ GROWTH
```

It is convenient for:

- direct filesystem/terminal inspection;
- troubleshooting;
- development work that needs broad interactive access;
- an independent control path while Remote GROWTH itself is being restarted or upgraded.

## 2. Self-built operator path — Remote GROWTH Stable

The self-built operator is no longer only a backup experiment.

```text
ChatGPT
→ Composio Custom MCP
→ Remote GROWTH Stable Gateway v0.7.0
→ 64 tools
→ GROWTH
```

The 64-tool surface includes Windows primitives plus Fast Local, Document, Developer/Git, FileOps, SystemOps, and Workflow engines.

This path has survived authentication, recovery, reboot, and regression testing.

## 3. Native ChatGPT path — focused Remote GROWTH plugin

For direct ChatGPT app/plugin use:

```text
ChatGPT private MCP app/plugin
→ OpenAI Secure MCP Tunnel
→ loopback-only native facade
→ 12 focused tools
→ trusted Remote GROWTH engines
```

This native facade intentionally excludes raw PowerShell, raw filesystem mutation, and raw UI automation.

The native app is registered and callable. Remaining Phase 10 work is behavioral acceptance and recovery testing.

## 4. Local engineering — Desktop Commander local MCP

When the AI client and Windows machine are already local:

```text
Codex / local AI
→ Desktop Commander local MCP
→ Windows
```

There is little value in sending a local task through a remote relay when a local MCP path is available.

Example:

```powershell
codex mcp add desktop-commander -- npx -y @wonderwhy-er/desktop-commander@latest
```

## 5. MCP SuperAssistant — historical / partial failure

The Chrome-extension experiment remains documented because it taught useful lessons.

The historical stack looked roughly like:

```text
MCP SuperAssistant
→ local compatibility proxy
→ local agent
→ Windows
```

During inspection, discovery traffic worked, but reliable normal `tools/call` execution was not proven as a daily path.

Status:

```text
PARTIAL_FAILURE
```

Do not rebuild this historical complexity unless you specifically need the browser experiment.

## Current decision rule

```text
DIRECT INTERACTIVE COMPUTER WORK
→ Remote Desktop Commander

SELF-BUILT 64-TOOL OPERATOR
→ Remote GROWTH Stable through Composio

FOCUSED CHATGPT-NATIVE WORK
→ Remote GROWTH native plugin

LOCAL ENGINEERING
→ Desktop Commander local MCP

BROWSER EXPERIMENT
→ MCP SuperAssistant only when intentionally testing it
```

## Why keep multiple paths?

Because each one solves a different failure mode.

The project no longer treats “one universal transport” as the goal.

The rule is:

> use the least complicated path that gives the required capability, safety boundary, and verification.

## Current recommendation for new users

If you only want practical remote control, start with the simplest provider that already works for you.

If you want to reproduce the native-plugin pattern, use:

```text
examples/remote-growth-native/
```

Every user must supply their own tunnel, runtime credential, and ChatGPT app binding.

Do not copy private machine names, bearer keys, tunnel identities, app IDs, encrypted credential blobs, or local paths from somebody else's setup.

And do not recreate every historical experiment just because it exists in this repository.
