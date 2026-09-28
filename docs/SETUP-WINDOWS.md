# Windows setup

This is the primary end-to-end onboarding path.

## 1. Requirements

- Windows 10 or 11
- Node.js 20+
- Git recommended
- Chrome only if you want the optional MCP SuperAssistant browser bridge

## 2. Clone

```powershell
git clone https://github.com/exxrawrrr/otak-atik.git
cd otak-atik
```

## 3. Dry run

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -DryRun
```

## 4. Install

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer:

- creates `~/.otak-atik/`;
- preserves an existing config unless `-Force` is used;
- copies Windows helper scripts to the user config directory;
- links the `otak-atik` CLI;
- creates a Desktop folder named `OTAK-ATIK`;
- creates double-click launchers;
- opens setup pages on first install.

## 5. Start remote access

On the Desktop open:

```text
OTAK-ATIK
└── 01 - START REMOTE DESKTOP.bat
```

That launcher checks for an existing Remote Desktop Commander device-agent process before starting another one.

If this is the first run, a browser authorization flow may open.

Complete pairing and keep the device-agent terminal running while remote access is needed.

## 6. Connect the AI client

Remote MCP endpoint:

```text
https://mcp.desktopcommander.app/mcp
```

See [AI clients](AI-CLIENTS.md) for client-specific notes.

## 7. Check status

Double-click:

```text
02 - STATUS.bat
```

The status helper reports:

- Node availability;
- Git availability;
- Remote Desktop Commander process state;
- whether MCP SuperAssistant is detected in Chrome;
- whether the optional browser bridge appears to be running.

## Optional: browser bridge

If you explicitly need MCP SuperAssistant, install the extension and run:

```text
04 - START BROWSER BRIDGE - OPTIONAL.bat
```

Then connect the extension to the local endpoint documented by the launcher.

See [Browser bridge](BROWSER-BRIDGE.md).

## Installer switches

```powershell
# preview only
.\scripts\install.ps1 -DryRun

# replace the stored default config
.\scripts\install.ps1 -Force

# do not create desktop launchers
.\scripts\install.ps1 -NoDesktopLaunchers

# open setup pages even after first install
.\scripts\install.ps1 -OpenSetupPages

# do not open browser pages
.\scripts\install.ps1 -NoOpenSetupPages
```

## Important

The installer does not silently:

- install a Chrome extension;
- sign into an AI account;
- approve OAuth;
- grant browser permissions;
- expose a local MCP server to the public internet.

Those require explicit user action.
