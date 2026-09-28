#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { chooseTransport } from "../src/transport-router.mjs";
import { compileOperatorPlan } from "../src/plan-compiler.mjs";
import { createWorkspaceSnapshot } from "../src/workspace-snapshot.mjs";
import { scanSecretHygiene } from "../src/hygiene.mjs";
import { auditMcpConfig } from "../src/mcp-config-audit.mjs";
import { lintSkill } from "../src/skill-lint.mjs";
import { createHandoff } from "../src/handoff.mjs";

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
  const res = spawnSync(command, args, {
    encoding: "utf8",
    shell: process.platform === "win32"
  });
  return {
    exists: !res.error && res.status === 0,
    output: (res.stdout || res.stderr || "").trim().split("\n")[0]
  };
}

function parseContextArgs(args) {
  const context = {
    sameMachine: true,
    remoteAccess: false,
    browserOnly: false,
    nativeMcpAvailable: true,
    guiRequired: false,
    remoteQuotaRemaining: null
  };
  const remaining = [];

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];

    if (arg === "--local") {
      context.sameMachine = true;
      context.remoteAccess = false;
    } else if (arg === "--remote") {
      context.sameMachine = false;
      context.remoteAccess = true;
    } else if (arg === "--browser") {
      context.browserOnly = true;
    } else if (arg === "--no-native-mcp") {
      context.nativeMcpAvailable = false;
    } else if (arg === "--gui") {
      context.guiRequired = true;
    } else if (arg === "--quota") {
      const next = Number(args[i + 1]);
      if (!Number.isFinite(next)) throw new Error("--quota requires a number.");
      context.remoteQuotaRemaining = next;
      i += 1;
    } else if (arg.startsWith("--quota=")) {
      const value = Number(arg.split("=")[1]);
      if (!Number.isFinite(value)) throw new Error("--quota requires a number.");
      context.remoteQuotaRemaining = value;
    } else {
      remaining.push(arg);
    }
  }

  return { context, remaining };
}

function takeOption(args, name) {
  const index = args.indexOf(name);
  if (index === -1) return { args, value: null };
  if (index === args.length - 1) throw new Error(name + " requires a value.");
  const next = [...args];
  const value = next[index + 1];
  next.splice(index, 2);
  return { args: next, value };
}

function doctor() {
  console.log("\notak-atik doctor\n");
  const major = Number(process.versions.node.split(".")[0]);
  if (major >= 20) ok("Node.js", process.version);
  else fail("Node.js", process.version + "; Node 20+ required");

  const git = commandExists("git");
  git.exists ? ok("Git", git.output) : warn("Git", "not detected");

  const required = [
    "config/default.json",
    "registries/capabilities.json",
    "registries/skills.json",
    "registries/recipes.json",
    "registries/packs.json",
    "registries/providers.json",
    "labs/experiments.json",
    "src/transport-router.mjs",
    "src/plan-compiler.mjs",
    "src/evidence.mjs",
    "src/workspace-snapshot.mjs",
    "src/hygiene.mjs",
    "src/mcp-config-audit.mjs",
    "src/skill-lint.mjs",
    "src/handoff.mjs",
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
    const providers = readJson("registries/providers.json");
    const experiments = readJson("labs/experiments.json");

    ok("Capability registry", capabilities.capabilities.length + " capabilities");
    ok("Skill registry", skills.skills.length + " skills");
    ok("Recipe registry", recipes.recipes.length + " recipes");
    ok("Pack registry", packs.packs.length + " packs");
    ok("Provider matrix", providers.providers.length + " providers");
    ok("Failure lab", experiments.experiments.length + " experiments");
  } catch (error) {
    healthy = false;
    fail("Registry parse", error.message);
  }

  console.log("\nRESULT: " + (healthy ? "READY" : "NEEDS_ATTENTION") + "\n");
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

function route(args) {
  const { context } = parseContextArgs(args);
  console.log(JSON.stringify(chooseTransport(context), null, 2));
}

function plan(args) {
  const { context, remaining } = parseContextArgs(args);
  const task = remaining.join(" ").trim();
  if (!task) throw new Error("Usage: otak-atik plan <task> [--local|--remote|--browser|--gui]");

  console.log(JSON.stringify(compileOperatorPlan({
    task,
    context,
    skills: readJson("registries/skills.json").skills,
    capabilityRegistry: readJson("registries/capabilities.json")
  }), null, 2));
}

function snapshot(args) {
  const target = args[0] || ".";
  console.log(JSON.stringify(createWorkspaceSnapshot(target), null, 2));
}

function hygiene(args) {
  const strict = args.includes("--strict");
  const target = args.find((x) => x !== "--strict") || ".";
  const result = scanSecretHygiene(target);
  console.log(JSON.stringify(result, null, 2));
  if (strict && result.findings.length) process.exitCode = 2;
}

function mcpCheck(args) {
  if (!args[0]) throw new Error("Usage: otak-atik mcp-check <config.json>");
  const result = auditMcpConfig(args[0]);
  console.log(JSON.stringify(result, null, 2));
  if (!result.valid) process.exitCode = 2;
}

function skillCheck(args) {
  if (!args[0]) throw new Error("Usage: otak-atik skill-check <SKILL.md>");
  const result = lintSkill(args[0]);
  console.log(JSON.stringify(result, null, 2));
  if (!result.valid) process.exitCode = 2;
}

function handoff(args) {
  let parsed = takeOption(args, "--task");
  const task = parsed.value;
  parsed = takeOption(parsed.args, "--out");
  const out = parsed.value;
  const target = parsed.args[0] || ".";
  const result = createHandoff(target, { task });
  const serialized = JSON.stringify(result, null, 2) + "\n";

  if (out) {
    fs.writeFileSync(path.resolve(out), serialized, "utf8");
    console.log("Wrote handoff: " + path.resolve(out));
  } else {
    console.log(serialized.trimEnd());
  }
}

function lab() {
  const data = readJson("labs/experiments.json");
  console.log("\nFailure / research lab\n");
  for (const item of data.experiments) {
    console.log("- " + item.id);
    console.log("  status: " + item.status);
    console.log("  decision: " + item.decision);
    console.log("  report: " + item.report);
  }
  console.log("");
}

function providers() {
  const data = readJson("registries/providers.json");
  console.log("\nProvider matrix\n");
  for (const item of data.providers) {
    console.log("- " + item.name.padEnd(32) + " " + item.status.padEnd(20) + " role=" + item.role);
  }
  console.log("");
}

function help() {
  console.log(`
otak-atik

Useful without any MCP/plugin:
  otak-atik snapshot [workspace]
  otak-atik hygiene [path] [--strict]
  otak-atik mcp-check <config.json>
  otak-atik skill-check <SKILL.md>
  otak-atik handoff [workspace] [--task "<task>"] [--out handoff.json]

Native operator:
  otak-atik doctor
  otak-atik route [--local|--remote|--browser|--gui] [--no-native-mcp] [--quota N]
  otak-atik plan "<task>" [transport flags]
  otak-atik providers
  otak-atik lab

Registry:
  otak-atik capabilities
  otak-atik skills
  otak-atik recipes
  otak-atik packs
  otak-atik policy

Examples:
  otak-atik snapshot .
  otak-atik hygiene . --strict
  otak-atik mcp-check ~/.config/my-client/mcp.json
  otak-atik skill-check ./skills/my-skill/SKILL.md
  otak-atik handoff . --task "fix the build" --out handoff.json
  otak-atik route --remote --quota 500
  otak-atik plan "fix failing project and run tests" --local
`);
}

const command = process.argv[2] || "help";
const args = process.argv.slice(3);

try {
  switch (command) {
    case "doctor": doctor(); break;
    case "route": route(args); break;
    case "plan": plan(args); break;
    case "snapshot": snapshot(args); break;
    case "hygiene": hygiene(args); break;
    case "mcp-check": mcpCheck(args); break;
    case "skill-check": skillCheck(args); break;
    case "handoff": handoff(args); break;
    case "providers": providers(); break;
    case "lab": lab(); break;
    case "capabilities":
      listRegistry("registries/capabilities.json", "capabilities",
        (x) => "- " + x.id.padEnd(28) + " risk=" + x.risk + " mutating=" + x.mutating);
      break;
    case "skills":
      listRegistry("registries/skills.json", "skills",
        (x) => "- " + x.name.padEnd(28) + " " + x.status.padEnd(12) + " " + x.description);
      break;
    case "recipes":
      listRegistry("registries/recipes.json", "recipes",
        (x) => "- " + x.name.padEnd(28) + " " + x.description);
      break;
    case "packs":
      listRegistry("registries/packs.json", "packs",
        (x) => "- " + x.name.padEnd(16) + " " + x.description);
      break;
    case "policy": showPolicy(); break;
    case "version": console.log(readJson("package.json").version); break;
    case "help":
    case "--help":
    case "-h": help(); break;
    default:
      console.error("Unknown command: " + command + "\n");
      help();
      process.exitCode = 1;
  }
} catch (error) {
  console.error("otak-atik: " + error.message);
  process.exitCode = 1;
}
