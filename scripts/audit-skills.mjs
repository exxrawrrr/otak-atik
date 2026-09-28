import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { lintSkill } from "../src/skill-lint.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const registry = JSON.parse(
  fs.readFileSync(path.join(root, "registries", "skills.json"), "utf8")
);

let errors = 0;
let warnings = 0;

for (const skill of registry.skills) {
  const full = path.join(root, skill.path);
  const result = lintSkill(full);
  const skillErrors = result.findings.filter((x) => x.level === "ERROR");
  const skillWarnings = result.findings.filter((x) => x.level === "WARN");

  errors += skillErrors.length;
  warnings += skillWarnings.length;

  for (const item of [...skillErrors, ...skillWarnings]) {
    console.log(
      item.level.padEnd(5) +
      " " +
      skill.name.padEnd(30) +
      " " +
      item.code +
      " — " +
      item.message
    );
  }
}

console.log("");
console.log(
  "Skill audit: " +
  registry.skills.length +
  " skills, " +
  errors +
  " errors, " +
  warnings +
  " warnings"
);

if (errors > 0) process.exit(1);
