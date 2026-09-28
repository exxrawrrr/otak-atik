import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const errors = [];

function readJson(rel) {
  try {
    return JSON.parse(fs.readFileSync(path.join(root, rel), "utf8"));
  } catch (error) {
    errors.push(`${rel}: ${error.message}`);
    return null;
  }
}

const capabilities = readJson("registries/capabilities.json");
const skills = readJson("registries/skills.json");
const recipes = readJson("registries/recipes.json");

if (capabilities) {
  const ids = new Set();
  for (const item of capabilities.capabilities || []) {
    if (!item.id) errors.push("Capability without id");
    if (ids.has(item.id)) errors.push(`Duplicate capability: ${item.id}`);
    ids.add(item.id);
  }
}

if (skills) {
  const names = new Set();
  for (const skill of skills.skills || []) {
    if (names.has(skill.name)) errors.push(`Duplicate skill: ${skill.name}`);
    names.add(skill.name);
    const full = path.join(root, skill.path);
    if (!fs.existsSync(full)) {
      errors.push(`Missing skill file: ${skill.path}`);
      continue;
    }
    const body = fs.readFileSync(full, "utf8");
    if (!body.startsWith("---")) errors.push(`${skill.path}: missing frontmatter`);
    if (!body.includes(`name: ${skill.name}`)) errors.push(`${skill.path}: registry/frontmatter name mismatch`);
  }
}

if (recipes) {
  for (const recipe of recipes.recipes || []) {
    if (!fs.existsSync(path.join(root, recipe.path))) errors.push(`Missing recipe: ${recipe.path}`);
  }
}

const forbidden = ["D:\\RAFDI_DATA", "C:\\Users\\User", "prodrive.co.id"];
for (const rel of ["README.md", "docs/product/PRD.md", "config/default.json"]) {
  const body = fs.readFileSync(path.join(root, rel), "utf8");
  for (const token of forbidden) {
    if (body.includes(token)) errors.push(`${rel}: private/project-specific token detected: ${token}`);
  }
}

if (errors.length) {
  console.error("Validation failed:\n");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("Validation passed.");
