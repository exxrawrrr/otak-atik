import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const ignoredDirs = new Set([
  ".git", "node_modules", "dist", "build", ".next", "coverage",
  ".venv", "venv", "target", "vendor", ".cache", ".turbo"
]);

const importantNames = new Set([
  "package.json", "package-lock.json", "pnpm-lock.yaml", "yarn.lock",
  "pyproject.toml", "requirements.txt", "Cargo.toml", "go.mod",
  "README.md", "CONTRIBUTING.md", "Dockerfile", "docker-compose.yml",
  "tsconfig.json", "vite.config.js", "vite.config.ts", "next.config.js",
  "next.config.mjs", ".env.example", "SKILL.md"
]);

function safeStat(file) {
  try {
    return fs.statSync(file);
  } catch {
    return null;
  }
}

function relative(root, file) {
  return path.relative(root, file).replaceAll("\\", "/") || ".";
}

function gitInfo(root) {
  const inside = spawnSync("git", ["-C", root, "rev-parse", "--is-inside-work-tree"], {
    encoding: "utf8"
  });
  if (inside.status !== 0 || inside.stdout.trim() !== "true") return null;

  const branch = spawnSync("git", ["-C", root, "branch", "--show-current"], {
    encoding: "utf8"
  }).stdout.trim();

  const status = spawnSync("git", ["-C", root, "status", "--short"], {
    encoding: "utf8"
  }).stdout.trim();

  return {
    branch: branch || null,
    dirty: Boolean(status),
    changed_entries: status ? status.split(/\r?\n/).length : 0
  };
}

export function createWorkspaceSnapshot(inputPath = ".", options = {}) {
  const root = path.resolve(inputPath);
  const rootStat = safeStat(root);
  if (!rootStat?.isDirectory()) {
    throw new Error("Snapshot target must be a directory.");
  }

  const maxFiles = Number(options.maxFiles ?? 5000);
  const maxDepth = Number(options.maxDepth ?? 8);

  const result = {
    schema_version: 1,
    root_name: path.basename(root),
    files: 0,
    directories: 0,
    total_bytes: 0,
    truncated: false,
    extensions: {},
    important_files: [],
    top_level: [],
    git: gitInfo(root)
  };

  const stack = [{ dir: root, depth: 0 }];

  while (stack.length) {
    const { dir, depth } = stack.pop();
    if (depth > maxDepth) continue;

    let entries = [];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }

    for (const entry of entries) {
      if (result.files >= maxFiles) {
        result.truncated = true;
        break;
      }

      if (entry.name === ".DS_Store") continue;
      const full = path.join(dir, entry.name);
      const rel = relative(root, full);

      if (entry.isDirectory()) {
        if (ignoredDirs.has(entry.name)) continue;
        result.directories += 1;
        if (depth === 0) result.top_level.push(entry.name + "/");
        stack.push({ dir: full, depth: depth + 1 });
        continue;
      }

      if (!entry.isFile()) continue;

      const stat = safeStat(full);
      if (!stat) continue;

      result.files += 1;
      result.total_bytes += stat.size;
      if (depth === 0) result.top_level.push(entry.name);

      const ext = path.extname(entry.name).toLowerCase() || "(none)";
      result.extensions[ext] = (result.extensions[ext] || 0) + 1;

      if (importantNames.has(entry.name)) {
        result.important_files.push(rel);
      }
    }

    if (result.truncated) break;
  }

  result.top_level.sort();
  result.important_files.sort();
  result.extensions = Object.fromEntries(
    Object.entries(result.extensions)
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
      .slice(0, 20)
  );

  return result;
}
