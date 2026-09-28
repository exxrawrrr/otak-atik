import { spawnSync } from "node:child_process";
import path from "node:path";

const highPatterns = [
  /(^|\/)(\.env|\.env\..+)$/i,
  /(^|\/)(auth|security|permissions?)(\/|\.|$)/i,
  /(^|\/)migrations?(\/|$)/i,
  /(^|\/)\.github\/workflows\//i,
  /(^|\/)(Dockerfile|docker-compose\.ya?ml)$/i
];

const mediumPatterns = [
  /(^|\/)(package\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock)$/i,
  /(^|\/)(pyproject\.toml|requirements.*\.txt|Cargo\.toml|go\.mod)$/i,
  /(^|\/)(config|configs?)(\/|\.|$)/i,
  /(^|\/)(schema|schemas?)(\/|\.|$)/i,
  /(^|\/)(\.github\/|scripts?\/)/i
];

function git(root, args) {
  return spawnSync("git", ["-C", root, ...args], {
    encoding: "utf8"
  });
}

export function analyzeDiffRisk(inputPath = ".") {
  const root = path.resolve(inputPath);
  const inside = git(root, ["rev-parse", "--is-inside-work-tree"]);
  if (inside.status !== 0 || inside.stdout.trim() !== "true") {
    throw new Error("diff-risk target must be inside a Git repository.");
  }

  const diff = git(root, ["diff", "HEAD", "--numstat", "--no-renames"]);
  const names = git(root, ["diff", "HEAD", "--name-status", "--no-renames"]);

  if (diff.status !== 0 || names.status !== 0) {
    throw new Error("Unable to read Git diff.");
  }

  const stats = new Map();
  for (const line of diff.stdout.trim().split(/\r?\n/).filter(Boolean)) {
    const [addedRaw, deletedRaw, ...rest] = line.split("\t");
    const file = rest.join("\t");
    const binary = addedRaw === "-" || deletedRaw === "-";
    stats.set(file, {
      added: binary ? 0 : Number(addedRaw || 0),
      deleted: binary ? 0 : Number(deletedRaw || 0),
      binary
    });
  }

  const changes = [];
  for (const line of names.stdout.trim().split(/\r?\n/).filter(Boolean)) {
    const [status, ...rest] = line.split("\t");
    const file = rest.join("\t").replaceAll("\\", "/");
    const stat = stats.get(file) || { added: 0, deleted: 0, binary: false };

    let risk = "LOW";
    const reasons = [];

    if (highPatterns.some((pattern) => pattern.test(file))) {
      risk = "HIGH";
      reasons.push("sensitive or operationally critical path");
    } else if (mediumPatterns.some((pattern) => pattern.test(file))) {
      risk = "MEDIUM";
      reasons.push("dependency/config/schema/script path");
    }

    if (status === "D") {
      risk = "HIGH";
      reasons.push("file deletion");
    }

    if (stat.deleted >= 200 || stat.added >= 500) {
      if (risk === "LOW") risk = "MEDIUM";
      reasons.push("large textual change");
    }

    if (stat.binary) {
      if (risk === "LOW") risk = "MEDIUM";
      reasons.push("binary change cannot be line-reviewed");
    }

    changes.push({
      file,
      status,
      added: stat.added,
      deleted: stat.deleted,
      binary: stat.binary,
      risk,
      reasons
    });
  }

  const order = { LOW: 0, MEDIUM: 1, HIGH: 2 };
  const overall = changes.reduce(
    (current, item) => order[item.risk] > order[current] ? item.risk : current,
    "LOW"
  );

  return {
    schema_version: 1,
    overall_risk: changes.length ? overall : "NONE",
    changed_files: changes.length,
    totals: {
      added: changes.reduce((n, x) => n + x.added, 0),
      deleted: changes.reduce((n, x) => n + x.deleted, 0)
    },
    changes: changes.sort((a, b) => order[b.risk] - order[a.risk] || a.file.localeCompare(b.file)),
    note: "Risk is a review heuristic, not a correctness or security verdict."
  };
}
