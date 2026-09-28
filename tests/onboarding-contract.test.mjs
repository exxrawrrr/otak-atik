import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";

const required = [
  "docs/SETUP-DECISION-TREE.md",
  "docs/SETUP-WINDOWS.md",
  "docs/REMOTE-DESKTOP-COMMANDER.md",
  "docs/BROWSER-BRIDGE.md",
  "docs/AI-CLIENTS.md",
  "scripts/windows/start-remote-desktop.ps1",
  "scripts/windows/start-browser-bridge.ps1",
  "scripts/windows/status.ps1",
  "scripts/windows/install-launchers.ps1",
  "config/browser-bridge/mcp-superassistant.json"
];

test("end-to-end onboarding assets exist", () => {
  for (const path of required) {
    assert.equal(fs.existsSync(path), true, `missing ${path}`);
  }
});

test("README clearly says both MCP paths are not mandatory", () => {
  const readme = fs.readFileSync("README.md", "utf8");
  assert.match(readme, /Do I need both\?/);
  assert.match(readme, /\*\*No\.\*\*/);
  assert.match(readme, /MCP SuperAssistant browser bridge — optional/i);
});

test("browser bridge config uses local Desktop Commander", () => {
  const config = JSON.parse(
    fs.readFileSync("config/browser-bridge/mcp-superassistant.json", "utf8")
  );

  const dc = config.mcpServers?.["desktop-commander"];
  assert.equal(dc.command, "npx");
  assert.ok(dc.args.includes("@wonderwhy-er/desktop-commander@latest"));
});

test("Windows launcher installer creates the recommended remote launcher", () => {
  const script = fs.readFileSync("scripts/windows/install-launchers.ps1", "utf8");
  assert.match(script, /01 - START REMOTE DESKTOP\.bat/);
  assert.match(script, /04 - START BROWSER BRIDGE - OPTIONAL\.bat/);
});
