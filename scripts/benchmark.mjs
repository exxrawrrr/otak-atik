import fs from "node:fs";
import { chooseTransport } from "../src/transport-router.mjs";

const data = JSON.parse(
  fs.readFileSync(new URL("../benchmarks/scenarios.json", import.meta.url), "utf8")
);

let passed = 0;

for (const scenario of data.scenarios) {
  const result = chooseTransport(scenario.context);
  const ok = result.id === scenario.expected_transport;
  if (ok) passed += 1;

  console.log(
    (ok ? "PASS" : "FAIL") +
    " " +
    scenario.id +
    " expected=" +
    scenario.expected_transport +
    " actual=" +
    result.id
  );
}

console.log("");
console.log("Benchmark: " + passed + "/" + data.scenarios.length + " passed");

if (passed !== data.scenarios.length) process.exit(1);
