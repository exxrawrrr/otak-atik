import test from "node:test";
import assert from "node:assert/strict";
import { createEvidence, summarizeEvidence } from "../src/evidence.mjs";

test("evidence summary verifies all-pass checks", () => {
  const items = [
    createEvidence({
      check: "tests",
      status: "PASS",
      source: "npm test"
    })
  ];

  const summary = summarizeEvidence(items);
  assert.equal(summary.verified, true);
  assert.equal(summary.counts.PASS, 1);
});

test("could-not-verify prevents verified summary", () => {
  const summary = summarizeEvidence([
    createEvidence({
      check: "visual",
      status: "COULD_NOT_VERIFY"
    })
  ]);

  assert.equal(summary.verified, false);
});
