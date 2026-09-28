import test from "node:test";
import assert from "node:assert/strict";
import { compileOperatorPlan } from "../src/plan-compiler.mjs";

const registry = {
  capabilities: [
    { id: "filesystem.read", risk: "low", mutating: false },
    { id: "filesystem.write", risk: "medium", mutating: true },
    { id: "terminal.execute", risk: "high", mutating: true }
  ]
};

const skills = [
  {
    name: "project-debugger",
    status: "stable",
    description: "debug failing software project"
  },
  {
    name: "safe-file-editor",
    status: "stable",
    description: "controlled file edits"
  },
  {
    name: "evidence-verifier",
    status: "stable",
    description: "verify execution evidence"
  },
  {
    name: "mcp-topology-diagnoser",
    status: "stable",
    description: "identify failing MCP transport layer"
  },
  {
    name: "desktop-inspector",
    status: "stable",
    description: "inspect machine workspace"
  }
];

test("compiler produces a deterministic operator plan", () => {
  const input = {
    task: "fix failing project and run tests",
    context: { sameMachine: true },
    skills,
    capabilityRegistry: registry
  };

  const a = compileOperatorPlan(input);
  const b = compileOperatorPlan(input);

  assert.equal(a.plan_id, b.plan_id);
  assert.equal(a.transport.id, "desktop-commander-local");
  assert.equal(a.policy.mutating, true);
  assert.equal(a.verification.required, true);
  assert.ok(a.capabilities.some((x) => x.id === "filesystem.write"));
  assert.ok(a.capabilities.some((x) => x.id === "terminal.execute"));
  assert.equal(a.skills[0].name, "project-debugger");
  assert.ok(a.skills.some((x) => x.name === "safe-file-editor"));
  assert.ok(a.skills.some((x) => x.name === "evidence-verifier"));
  assert.ok(!a.skills.some((x) => x.name === "mcp-topology-diagnoser"));
});

test("read-only plan does not require mutation verification", () => {
  const result = compileOperatorPlan({
    task: "inspect workspace",
    context: { sameMachine: true },
    skills,
    capabilityRegistry: registry
  });

  assert.equal(result.policy.mutating, false);
  assert.equal(result.verification.required, false);
});
