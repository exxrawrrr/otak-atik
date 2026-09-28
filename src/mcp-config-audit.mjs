import fs from "node:fs";

function finding(level, server, message) {
  return { level, server, message };
}

export function auditMcpConfig(filePath) {
  let body;
  try {
    body = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    return {
      valid: false,
      findings: [finding("ERROR", null, "Invalid JSON: " + error.message)],
      servers: 0
    };
  }

  const servers = body.mcpServers;
  if (!servers || typeof servers !== "object" || Array.isArray(servers)) {
    return {
      valid: false,
      findings: [finding("ERROR", null, "Expected an mcpServers object.")],
      servers: 0
    };
  }

  const findings = [];

  for (const [name, config] of Object.entries(servers)) {
    if (!config || typeof config !== "object" || Array.isArray(config)) {
      findings.push(finding("ERROR", name, "Server config must be an object."));
      continue;
    }

    const hasCommand = typeof config.command === "string" && config.command.trim();
    const hasUrl = typeof config.url === "string" && config.url.trim();

    if (!hasCommand && !hasUrl) {
      findings.push(finding("ERROR", name, "Server needs either command or url."));
    }

    if (hasCommand && hasUrl) {
      findings.push(finding("WARN", name, "Both command and url are set; verify the client schema expects this."));
    }

    if (config.args !== undefined && (!Array.isArray(config.args) || config.args.some((x) => typeof x !== "string"))) {
      findings.push(finding("ERROR", name, "args must be an array of strings."));
    }

    if (config.env !== undefined && (typeof config.env !== "object" || Array.isArray(config.env))) {
      findings.push(finding("ERROR", name, "env must be an object."));
    }

    if (hasUrl) {
      try {
        const url = new URL(config.url);
        if (!["http:", "https:"].includes(url.protocol)) {
          findings.push(finding("WARN", name, "Unusual URL protocol: " + url.protocol));
        }
        if (url.protocol === "http:" && !["localhost", "127.0.0.1", "::1"].includes(url.hostname)) {
          findings.push(finding("WARN", name, "Remote MCP URL uses plain HTTP."));
        }
      } catch {
        findings.push(finding("ERROR", name, "url is not a valid URL."));
      }
    }

    if (config.env && typeof config.env === "object") {
      for (const [key, value] of Object.entries(config.env)) {
        if (/(TOKEN|SECRET|PASSWORD|API[_-]?KEY)/i.test(key) && typeof value === "string" && value.length >= 8) {
          if (!/^\$\{|^%|^\$[A-Z_]/.test(value)) {
            findings.push(finding("WARN", name, "Sensitive env key " + key + " appears to contain an inline value."));
          }
        }
      }
    }
  }

  return {
    valid: !findings.some((x) => x.level === "ERROR"),
    servers: Object.keys(servers).length,
    findings
  };
}
