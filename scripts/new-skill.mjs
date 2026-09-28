import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const name = process.argv[2];
const category = process.argv[3] || "community";

if (!name || !/^[a-z0-9-]+$/.test(name)) {
  console.error("Usage: node scripts/new-skill.mjs <kebab-case-name> [category]");
  process.exit(1);
}

if (!/^[a-z0-9-]+$/.test(category)) {
  console.error("Category must be kebab-case.");
  process.exit(1);
}

const target = path.join(root, "skills", category, name);
if (fs.existsSync(target)) {
  console.error(`Skill already exists: ${target}`);
  process.exit(1);
}

const template = fs.readFileSync(path.join(root, "templates", "skill", "SKILL.md"), "utf8");
const body = template
  .replace("name: replace-me", `name: ${name}`)
  .replace("# Replace Me", `# ${name}`);

fs.mkdirSync(target, { recursive: true });
fs.writeFileSync(path.join(target, "SKILL.md"), body, "utf8");

console.log(`Created skills/${category}/${name}/SKILL.md`);
console.log("Add it to registries/skills.json before publishing.");
