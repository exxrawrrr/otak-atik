import fs from "node:fs";
import path from "node:path";
import { createWorkspaceSnapshot } from "./workspace-snapshot.mjs";
import { scanSecretHygiene } from "./hygiene.mjs";

function readJsonIfExists(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return null;
  }
}

export function createHandoff(inputPath = ".", options = {}) {
  const root = path.resolve(inputPath);
  const snapshot = createWorkspaceSnapshot(root, { maxFiles: options.maxFiles ?? 3000 });
  const hygiene = scanSecretHygiene(root, { maxFiles: options.maxFiles ?? 3000 });
  const pkg = readJsonIfExists(path.join(root, "package.json"));

  return {
    schema_version: 1,
    generated_at: new Date().toISOString(),
    task: options.task || null,
    project: {
      name: pkg?.name || snapshot.root_name,
      version: pkg?.version || null,
      snapshot
    },
    commands: pkg?.scripts || {},
    hygiene: {
      scanned_files: hygiene.scanned_files,
      findings_count: hygiene.findings.length,
      high: hygiene.summary.high,
      medium: hygiene.summary.medium,
      note: "Secret values are never embedded in handoff output."
    },
    handoff_notes: [
      "Inspect project-specific instructions before editing.",
      "Preserve unrelated user changes.",
      "Verify mutations before reporting success.",
      "Treat hygiene findings as leads, not automatic proof of leaked credentials."
    ]
  };
}
