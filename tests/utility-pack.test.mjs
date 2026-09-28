import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { createWorkspaceSnapshot } from "../src/workspace-snapshot.mjs";
import { scanSecretHygiene } from "../src/hygiene.mjs";
import { auditMcpConfig } from "../src/mcp-config-audit.mjs";
import { lintSkill } from "../src/skill-lint.mjs";
import { createHandoff } from "../src/handoff.mjs";

function fixture() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "otak-atik-utils-"));
  fs.writeFileSync(path.join(dir, "package.json"), JSON.stringify({
    name: "demo-project",
    version: "1.0.0",
    scripts: { test: "node test.js" }
  }, null, 2));
  fs.writeFileSync(path.join(dir, "README.md"), "# Demo\n");
  fs.mkdirSync(path.join(dir, "src"));
  fs.writeFileSync(path.join(dir, "src", "index.js"), "console.log('hello')\n");
  return dir;
}

test("workspace snapshot maps a project without reading contents", () => {
  const dir = fixture();
  const result = createWorkspaceSnapshot(dir);
  assert.equal(result.root_name, path.basename(dir));
  assert.ok(result.files >= 3);
  assert.ok(result.important_files.includes("package.json"));
  assert.ok(result.top_level.includes("src/"));
});

test("hygiene scanner reports location but not secret value", () => {
  const dir = fixture();
  const secret = "github_pat_1234567890ABCDEFGHIJKLMNOP";
  fs.writeFileSync(path.join(dir, ".env"), "GITHUB_TOKEN=" + secret + "\n");
  const result = scanSecretHygiene(dir);
  assert.ok(result.findings.length >= 1);
  assert.ok(result.findings.some((x) => x.file === ".env"));
  assert.equal(JSON.stringify(result).includes(secret), false);
});

test("MCP config audit accepts a normal stdio server", () => {
  const dir = fixture();
  const file = path.join(dir, "mcp.json");
  fs.writeFileSync(file, JSON.stringify({
    mcpServers: {
      demo: { command: "npx", args: ["-y", "demo-server"] }
    }
  }));
  const result = auditMcpConfig(file);
  assert.equal(result.valid, true);
  assert.equal(result.servers, 1);
});

test("MCP config audit warns on inline sensitive env", () => {
  const dir = fixture();
  const file = path.join(dir, "mcp.json");
  fs.writeFileSync(file, JSON.stringify({
    mcpServers: {
      demo: {
        command: "node",
        env: { API_KEY: "definitely-a-real-looking-value" }
      }
    }
  }));
  const result = auditMcpConfig(file);
  assert.ok(result.findings.some((x) => /inline value/.test(x.message)));
});

test("skill linter validates a compact portable skill", () => {
  const dir = fixture();
  const skillDir = path.join(dir, "demo-skill");
  fs.mkdirSync(skillDir);
  const file = path.join(skillDir, "SKILL.md");
  fs.writeFileSync(file, [
    "---",
    "name: demo-skill",
    "description: Demonstrate a portable skill.",
    "status: stable",
    "scope: generic",
    "---",
    "",
    "# Demo",
    "",
    "Inspect, act, verify."
  ].join("\n"));
  const result = lintSkill(file);
  assert.equal(result.valid, true);
  assert.equal(result.findings.length, 0);
});

test("handoff contains project facts without secret values", () => {
  const dir = fixture();
  const secret = "sk-proj-ABCDEFGHIJKLMNOPQRSTUVWXYZ123456";
  fs.writeFileSync(path.join(dir, ".env"), "OPENAI_API_KEY=" + secret + "\n");
  const result = createHandoff(dir, { task: "fix the demo" });
  assert.equal(result.project.name, "demo-project");
  assert.equal(result.task, "fix the demo");
  assert.ok(result.hygiene.findings_count >= 1);
  assert.equal(JSON.stringify(result).includes(secret), false);
});

test("CLI standalone utility commands execute", () => {
  const dir = fixture();
  const result = spawnSync(process.execPath, ["./bin/otak-atik.mjs", "snapshot", dir], {
    encoding: "utf8"
  });
  assert.equal(result.status, 0);
  const body = JSON.parse(result.stdout);
  assert.equal(body.root_name, path.basename(dir));
});
