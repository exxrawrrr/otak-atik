import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

function run(args) {
  return spawnSync(process.execPath, ["./bin/otak-atik.mjs", ...args], {
    encoding: "utf8"
  });
}

test("route command selects local MCP", () => {
  const result = run(["route", "--local"]);
  assert.equal(result.status, 0);
  const body = JSON.parse(result.stdout);
  assert.equal(body.id, "desktop-commander-local");
});

test("route command exposes low-quota warning", () => {
  const result = run(["route", "--remote", "--quota", "500"]);
  assert.equal(result.status, 0);
  const body = JSON.parse(result.stdout);
  assert.match(body.warning, /quota is low/i);
});

test("plan command compiles an executable contract", () => {
  const result = run([
    "plan",
    "fix",
    "failing",
    "project",
    "and",
    "run",
    "tests",
    "--local"
  ]);

  assert.equal(result.status, 0);
  const body = JSON.parse(result.stdout);
  assert.equal(body.transport.id, "desktop-commander-local");
  assert.equal(body.verification.required, true);
  assert.ok(body.execution_contract.includes("verify"));
});

test("lab command exposes partial-failure experiment", () => {
  const result = run(["lab"]);
  assert.equal(result.status, 0);
  assert.match(result.stdout, /PARTIAL_FAILURE/);
  assert.match(result.stdout, /mcp-superassistant/i);
});
