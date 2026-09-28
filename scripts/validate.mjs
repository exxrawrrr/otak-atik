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
const packs = readJson("registries/packs.json");
const providers = readJson("registries/providers.json");
const experiments = readJson("labs/experiments.json");
readJson("schemas/operator-plan.schema.json");
readJson("schemas/evidence.schema.json");

if (capabilities) {
  const ids = new Set();
  for (const item of capabilities.capabilities || []) {
    if (!item.id) errors.push("Capability without id");
    if (ids.has(item.id)) errors.push(`Duplicate capability: ${item.id}`);
    ids.add(item.id);
  }
}

const skillNames = new Set();
if (skills) {
  for (const skill of skills.skills || []) {
    if (skillNames.has(skill.name)) errors.push(`Duplicate skill: ${skill.name}`);
    skillNames.add(skill.name);
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
    if (!fs.existsSync(path.join(root, recipe.path))) {
      errors.push(`Missing recipe: ${recipe.path}`);
      continue;
    }
    const body = readJson(recipe.path);
    for (const skill of body?.skills || []) {
      if (!skillNames.has(skill)) errors.push(`${recipe.path}: unknown skill ${skill}`);
    }
  }
}

if (packs) {
  for (const pack of packs.packs || []) {
    const full = path.join(root, pack.path);
    if (!fs.existsSync(full)) {
      errors.push(`Missing pack: ${pack.path}`);
      continue;
    }
    const body = readJson(pack.path);
    for (const skill of body?.skills || []) {
      if (!skillNames.has(skill)) errors.push(`${pack.path}: unknown skill ${skill}`);
    }
  }
}

if (providers) {
  const allowed = new Set([
    "AUTHOR_PRIMARY",
    "SUPPORTED_PATH",
    "PARTIAL_FAILURE",
    "CANDIDATE_UNVERIFIED",
    "DEPRECATED"
  ]);
  const ids = new Set();

  for (const provider of providers.providers || []) {
    if (!provider.id) errors.push("Provider without id");
    if (ids.has(provider.id)) errors.push("Duplicate provider: " + provider.id);
    ids.add(provider.id);
    if (!allowed.has(provider.status)) {
      errors.push("Unknown provider status: " + provider.status);
    }
  }
}

if (experiments) {
  for (const experiment of experiments.experiments || []) {
    if (!experiment.id) errors.push("Experiment without id");
    if (!experiment.report) {
      errors.push("Experiment missing report: " + experiment.id);
      continue;
    }
    if (!fs.existsSync(path.join(root, experiment.report))) {
      errors.push("Missing experiment report: " + experiment.report);
    }
  }
}

const requiredProfiles = ["observe", "workspace", "developer", "operator", "power"];
for (const profile of requiredProfiles) {
  const rel = `config/profiles/${profile}.json`;
  if (!fs.existsSync(path.join(root, rel))) errors.push(`Missing policy profile: ${rel}`);
  else readJson(rel);
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
