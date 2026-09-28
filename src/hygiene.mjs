import fs from "node:fs";
import path from "node:path";

const ignoredDirs = new Set([
  ".git", "node_modules", "dist", "build", ".next", "coverage",
  ".venv", "venv", "target", "vendor", ".cache"
]);

const textExtensions = new Set([
  ".txt", ".md", ".json", ".yaml", ".yml", ".toml", ".ini", ".env",
  ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".py", ".ps1", ".bat",
  ".cmd", ".sh", ".zsh", ".bash", ".xml", ".html", ".css", ".scss",
  ".properties", ".conf", ".config"
]);

const detectors = [
  { type: "PRIVATE_KEY", severity: "HIGH", regex: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { type: "GITHUB_TOKEN", severity: "HIGH", regex: /\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b/ },
  { type: "OPENAI_STYLE_KEY", severity: "HIGH", regex: /\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b/ },
  { type: "SLACK_TOKEN", severity: "HIGH", regex: /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/ },
  { type: "AWS_ACCESS_KEY_ID", severity: "HIGH", regex: /\bAKIA[0-9A-Z]{16}\b/ },
  { type: "BEARER_TOKEN", severity: "MEDIUM", regex: /\bBearer\s+[A-Za-z0-9._~+\/-]{24,}=*/i },
  {
    type: "SENSITIVE_ASSIGNMENT",
    severity: "MEDIUM",
    regex: /\b(?:API[_-]?KEY|ACCESS[_-]?TOKEN|AUTH[_-]?TOKEN|CLIENT[_-]?SECRET|PASSWORD|PRIVATE[_-]?KEY)\b\s*[:=]\s*["']?([^\s"'#,;]{8,})/i
  }
];

function looksPlaceholder(line) {
  return /(example|placeholder|your[_-]|replace[_-]?me|changeme|dummy|xxxx|<[^>]+>)/i.test(line);
}

function isTextCandidate(file, stat) {
  if (stat.size > 1024 * 1024) return false;
  const base = path.basename(file);
  if (base === ".env" || base.startsWith(".env.")) return true;
  return textExtensions.has(path.extname(file).toLowerCase());
}

function rel(root, file) {
  return path.relative(root, file).replaceAll("\\", "/");
}

export function scanSecretHygiene(inputPath = ".", options = {}) {
  const root = path.resolve(inputPath);
  const stat = fs.statSync(root);
  const files = [];
  const maxFiles = Number(options.maxFiles ?? 5000);

  if (stat.isFile()) {
    files.push(root);
  } else if (stat.isDirectory()) {
    const stack = [root];
    while (stack.length && files.length < maxFiles) {
      const dir = stack.pop();
      let entries = [];
      try {
        entries = fs.readdirSync(dir, { withFileTypes: true });
      } catch {
        continue;
      }

      for (const entry of entries) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          if (!ignoredDirs.has(entry.name)) stack.push(full);
        } else if (entry.isFile()) {
          const itemStat = fs.statSync(full);
          if (isTextCandidate(full, itemStat)) files.push(full);
        }
        if (files.length >= maxFiles) break;
      }
    }
  } else {
    throw new Error("Hygiene target must be a file or directory.");
  }

  const findings = [];

  for (const file of files) {
    let text = "";
    try {
      text = fs.readFileSync(file, "utf8");
    } catch {
      continue;
    }

    const lines = text.split(/\r?\n/);
    lines.forEach((line, index) => {
      if (looksPlaceholder(line)) return;

      for (const detector of detectors) {
        if (detector.regex.test(line)) {
          findings.push({
            file: stat.isFile() ? path.basename(file) : rel(root, file),
            line: index + 1,
            type: detector.type,
            severity: detector.severity
          });
        }
      }
    });
  }

  return {
    schema_version: 1,
    scanned_files: files.length,
    findings,
    summary: {
      high: findings.filter((x) => x.severity === "HIGH").length,
      medium: findings.filter((x) => x.severity === "MEDIUM").length
    },
    note: "Potential secrets are reported by type and location only; matched values are intentionally not printed."
  };
}
