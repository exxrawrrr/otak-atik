import test from "node:test";
import assert from "node:assert/strict";
import { chooseTransport } from "../src/transport-router.mjs";

test("same-machine engineering prefers local MCP", () => {
  const result = chooseTransport({ sameMachine: true });
  assert.equal(result.id, "desktop-commander-local");
});

test("remote work prefers Remote Desktop Commander", () => {
  const result = chooseTransport({
    sameMachine: false,
    remoteAccess: true
  });
  assert.equal(result.id, "remote-desktop-commander");
});

test("browser-only local work can select MCP SuperAssistant", () => {
  const result = chooseTransport({
    sameMachine: true,
    browserOnly: true,
    nativeMcpAvailable: false
  });
  assert.equal(result.id, "mcp-superassistant");
});

test("GUI requirement overrides file/terminal transport", () => {
  const result = chooseTransport({
    sameMachine: false,
    remoteAccess: true,
    guiRequired: true
  });
  assert.equal(result.id, "gui-control-mcp");
});

test("low remote quota produces a warning", () => {
  const result = chooseTransport({
    remoteAccess: true,
    remoteQuotaRemaining: 500
  });
  assert.match(result.warning, /quota is low/i);
});
