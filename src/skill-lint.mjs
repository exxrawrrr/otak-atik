import fs from "node:fs";
import path from "node:path";

function parseFrontmatter(text) {
  if (!text.startsWith("---\n") && !text.startsWith("---\r\n")) return null;
  const normalized = text.replaceAll("\r\n", "\n");
  const end = normalized.indexOf("\n---\n", 4);
  if (end === -1) return null;

  const raw = normalized.slice(4, end);
  const data = {};
  for (const line of raw.split("\n")) {
    const match = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (match) data[match[1]] = match[2].trim().replace(/^["']|["']$/g, "");
  }
  return data;
}

export function lintSkill(filePath) {
  const full = path.resolve(filePath);
  const text = fs.readFileSync(full, "utf8");
  const findings = [];
  const frontmatter = parseFrontmatter(text);

  if (!frontmatter) {
    findings.push({ level: "ERROR", code: "frontmatter", message: "Missing or malformed --- frontmatter." });
  } else {
    if (!frontmatter.name) findings.push({ level: "ERROR", code: "name", message: "Missing name." });
    if (!frontmatter.description) findings.push({ level: "ERROR", code: "description", message: "Missing description." });

    if (frontmatter.name && !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(frontmatter.name)) {
      findings.push({ level: "ERROR", code: "name-format", message: "name should be kebab-case." });
    }

    if (frontmatter.description && frontmatter.description.length > 240) {
      findings.push({ level: "WARN", code: "description-length", message: "description is longer than 240 characters." });
    }

    if (!frontmatter.status) {
      findings.push({ level: "WARN", code: "status", message: "Consider declaring status." });
    }

    if (!frontmatter.scope) {
      findings.push({ level: "WARN", code: "scope", message: "Consider declaring scope." });
    }

    if (path.basename(full).toLowerCase() === "skill.md") {
      const folder = path.basename(path.dirname(full));
      if (frontmatter.name && folder !== frontmatter.name) {
        findings.push({
          level: "WARN",
          code: "folder-name",
          message: "Skill folder name differs from frontmatter name."
        });
      }
    }
  }

  const words = text.split(/\s+/).filter(Boolean).length;
  if (words > 1800) {
    findings.push({
      level: "WARN",
      code: "size",
      message: "SKILL.md is large; consider moving detail into references/ or scripts/."
    });
  }

  if (/[A-Za-z]:\\Users\\[^\\\s]+/i.test(text)) {
    findings.push({
      level: "WARN",
      code: "private-path",
      message: "Contains a user-specific Windows path."
    });
  }

  return {
    valid: !findings.some((x) => x.level === "ERROR"),
    words,
    findings,
    frontmatter
  };
}
