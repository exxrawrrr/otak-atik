import test from "node:test";
import assert from "node:assert/strict";
import { evaluateRisk, pathWithinRoots } from "../src/policy.mjs";

test("critical actions can be denied", () => {
  const result = evaluateRisk({
    risk: "critical",
    approval: { critical: "deny" }
  });
  assert.equal(result.allowed, false);
  assert.equal(result.action, "deny");
});

test("empty workspace roots grant no path access", () => {
  assert.equal(pathWithinRoots("C:\\Projects\\demo", []), false);
});

test("workspace containment respects path boundary", () => {
  assert.equal(pathWithinRoots("C:\\Projects\\demo", ["C:\\Projects"]), true);
  assert.equal(pathWithinRoots("C:\\Projects-old\\demo", ["C:\\Projects"]), false);
});
