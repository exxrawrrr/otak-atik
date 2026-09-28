import test from "node:test";
import assert from "node:assert/strict";
import { selectCandidateSkills } from "../src/registry.mjs";

test("candidate routing prefers matching skill metadata", () => {
  const result = selectCandidateSkills("debug failing project", [
    { name: "desktop-inspector", description: "inspect machine" },
    { name: "project-debugger", description: "debug failing software project" }
  ]);

  assert.equal(result[0].skill.name, "project-debugger");
  assert.ok(result[0].score > 0);
});
