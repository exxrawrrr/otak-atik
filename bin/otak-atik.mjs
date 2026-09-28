#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");

function readJson(rel) {
  return JSON.parse(fs.readFileSync(path.join(root, rel), "utf8"));
}

function ok(label, value = "") {
  console.log(`✓ ${label}${value ? ` — ${value}` : ""}`);
}

function warn(label, value = "") {
  console.log(`! ${label}${value ? ` — ${value}` : ""}`);
}

function fail(label, value = "") {
  console.log(`✗ ${label}${value ? ` — ${value}` : ""}`);
}

function commandExists(command, args = ["--version"]) {
  const res = spawnSync(command, args, { encoding: "utf8", shell: process.platform === "win32" });
  return { exists: !res.error && res.status === 0, output: (res.stdout || res.stderr || "").trim().split("\n")[0] };
}

function doctor() {
  console.log("\notak-atik doctor\n");

  const major = Number(process.versions.node.split(".")[0]);
  if (major >= 20) ok("Node.js", process.version);
  else fail("Node.js", `${process.version}; Node 20+ required`);

  const git = commandExists("git");
  git.exists ? ok("Git", git.output) : warn("Git", "not detected");

  const required = [
    "config/default.json",
    "registries/capabilities.json",
    "registries/skills.json",
    "registries/recipes.json",
    "registries/packs.json",
    "docs/product/PRD.md",
    "SECURITY.md"
  ];

  let healthy = major >= 20;
  for (const rel of required) {
    const exists = fs.existsSync(path.join(root, rel));
    exists ? ok(rel) : fail(rel, "missing");
    healthy &&= exists;
  }

  try {
    const capabilities = readJson("registries/capabilities.json");
    const skills = readJson("registries/skills.json");
    const recipes = readJson("registries/recipes.json");
    const packs = readJson("registries/packs.json");
    ok("Capability registry", `${capabilities.capabilities.length} capabilities`);
    ok("Skill registry", `${skills.skills.length} skills`);
    ok("Recipe registry", `${recipes.recipes.length} recipes`);
    ok("Pack registry", `${packs.packs.length} packs`);
  } catch (error) {
    healthy = false;
    fail("Registry parse", error.message);
  }

  console.log(`\nRESULT: ${healthy ? "READY" : "NEEDS_ATTENTION"}\n`);
  process.exitCode = healthy ? 0 : 1;
}

function listRegistry(rel, key, render) {
  const data = readJson(rel);
  console.log("");
  for (const item of data[key]) console.log(render(item));
  console.log("");
}

function showPolicy() {
  const config = readJson("config/default.json");
  console.log("\nDefault policy\n");
  console.log(JSON.stringify(config.policy, null, 2));
  console.log("");
}

function help() {
  console.log(`
otak-atik

Usage:
  otak-atik doctor
  otak-atik capabilities
  otak-atik skills
  otak-atik recipes
  otak-atik packs
  otak-atik policy
  otak-atik version
  otak-atik help

Author a skill:
  npm run skill:new -- my-skill category

This alpha CLI intentionally stays small.
The AI client remains the reasoning layer.
`);
}

const command = process.argv[2] || "help";
switch (command) {
  case "doctor":
    doctor();
    break;
  case "capabilities":
    listRegistry("registries/capabilities.json", "capabilities",
      (x) => `- ${x.id.padEnd(28)} risk=${x.risk} mutating=${x.mutating}`);
    break;
  case "skills":
    listRegistry("registries/skills.json", "skills",
      (x) => `- ${x.name.padEnd(28)} ${x.status.padEnd(12)} ${x.description}`);
    break;
  case "recipes":
    listRegistry("registries/recipes.json", "recipes",
      (x) => `- ${x.name.padEnd(28)} ${x.description}`);
    break;
  case "packs":
    listRegistry("registries/packs.json", "packs",
      (x) => `- ${x.name.padEnd(16)} ${x.description}`);
    break;
  case "policy":
    showPolicy();
    break;
  case "version":
    console.log(readJson("package.json").version);
    break;
  case "help":
  case "--help":
  case "-h":
    help();
    break;
  default:
    console.error(`Unknown command: ${command}\n`);
    help();
    process.exitCode = 1;
}
