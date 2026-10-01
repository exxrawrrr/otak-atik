import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";

const required = [
  "docs/SETUP-DECISION-TREE.md",
  "docs/SETUP-WINDOWS.md",
  "docs/REMOTE-DESKTOP-COMMANDER.md",
  "docs/BROWSER-BRIDGE.md",
  "docs/AI-CLIENTS.md",
  "docs/USAGE-AND-COST.md",
  "docs/WHAT-I-ACTUALLY-USE.md",
  "scripts/windows/start-remote-desktop.ps1",
  "scripts/windows/start-browser-bridge.ps1",
  "scripts/windows/setup-codex-local-mcp.ps1",
  "scripts/windows/show-transport-guide.ps1",
  "scripts/windows/status.ps1",
  "scripts/windows/install-launchers.ps1",
  "config/browser-bridge/mcp-superassistant.json"
];

test("end-to-end onboarding assets exist", () => {
  for (const file of required) {
    assert.equal(fs.existsSync(file), true, "missing " + file);
  }
});

test("README preserves Remote Desktop Commander as a working practical route", () => {
  const readme = fs.readFileSync("README.md", "utf8");
  assert.match(readme, /Remote Desktop Commander/);
  assert.match(readme, /still works and remains useful/i);
  assert.match(readme, /Working paths may coexist/i);
});

test("historical usage docs preserve MCP SuperAssistant partial-failure evidence", () => {
  const usage = fs.readFileSync("docs/WHAT-I-ACTUALLY-USE.md", "utf8");
  assert.match(usage, /MCP SuperAssistant/);
  assert.match(usage, /PARTIAL_FAILURE/);
  assert.match(usage, /reliable normal .*tools\/call.* execution was not proven/i);
});

test("README exposes standalone value without requiring MCP", () => {
  const readme = fs.readFileSync("README.md", "utf8");
  assert.match(readme, /otak-atik snapshot/);
  assert.match(readme, /otak-atik hygiene/);
  assert.match(readme, /otak-atik handoff/);
  assert.match(readme, /otak-atik diff-risk/);
});

test("browser bridge config uses local Desktop Commander", () => {
  const config = JSON.parse(
    fs.readFileSync("config/browser-bridge/mcp-superassistant.json", "utf8")
  );

  const dc = config.mcpServers?.["desktop-commander"];
  assert.equal(dc.command, "npx");
  assert.ok(dc.args.includes("@wonderwhy-er/desktop-commander@latest"));
});

test("Windows launcher installer creates remote, browser and local-Codex paths", () => {
  const script = fs.readFileSync("scripts/windows/install-launchers.ps1", "utf8");
  assert.match(script, /01 - START REMOTE DESKTOP\.bat/);
  assert.match(script, /04 - START BROWSER BRIDGE - OPTIONAL\.bat/);
  assert.match(script, /06 - SETUP CODEX LOCAL MCP - NO REMOTE QUOTA\.bat/);
  assert.match(script, /07 - WHICH MODE SHOULD I USE\.bat/);
});
