import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("CLI help exits successfully", () => {
  const result = spawnSync(process.execPath, ["./bin/otak-atik.mjs", "help"], {
    encoding: "utf8"
  });
  assert.equal(result.status, 0);
  assert.match(result.stdout, /otak-atik/);
});

test("doctor does not emit shell deprecation warnings", () => {
  const result = spawnSync(process.execPath, ["--trace-deprecation", "./bin/otak-atik.mjs", "doctor"], {
    encoding: "utf8"
  });
  assert.equal(result.status, 0);
  assert.doesNotMatch(result.stderr, /DEP0190/);
  assert.match(result.stdout, /RESULT: READY/);
});