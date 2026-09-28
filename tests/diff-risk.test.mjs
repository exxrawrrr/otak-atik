import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { analyzeDiffRisk } from "../src/diff-risk.mjs";

function run(cwd, args) {
  const result = spawnSync("git", args, { cwd, encoding: "utf8" });
  if (result.status !== 0) throw new Error(result.stderr);
}

function repo() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "otak-atik-diff-"));
  run(dir, ["init"]);
  run(dir, ["config", "user.email", "test@example.com"]);
  run(dir, ["config", "user.name", "Test"]);
  fs.writeFileSync(path.join(dir, "app.js"), "console.log('a')\n");
  fs.writeFileSync(path.join(dir, "package.json"), "{}\n");
  run(dir, ["add", "."]);
  run(dir, ["commit", "-m", "initial"]);
  return dir;
}

test("normal source edit stays low risk", () => {
  const dir = repo();
  fs.writeFileSync(path.join(dir, "app.js"), "console.log('b')\n");
  const result = analyzeDiffRisk(dir);
  assert.equal(result.changed_files, 1);
  assert.equal(result.overall_risk, "LOW");
});

test("dependency manifest edit is medium risk", () => {
  const dir = repo();
  fs.writeFileSync(path.join(dir, "package.json"), "{\"private\":true}\n");
  const result = analyzeDiffRisk(dir);
  assert.equal(result.overall_risk, "MEDIUM");
});

test("deletion is high risk", () => {
  const dir = repo();
  fs.unlinkSync(path.join(dir, "app.js"));
  const result = analyzeDiffRisk(dir);
  assert.equal(result.overall_risk, "HIGH");
  assert.ok(result.changes[0].reasons.includes("file deletion"));
});
