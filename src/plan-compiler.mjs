import crypto from "node:crypto";
import { chooseTransport } from "./transport-router.mjs";
import { selectCandidateSkills } from "./registry.mjs";

const capabilityRules = [
  { pattern: /\b(read|inspect|find|search|check|audit)\b/i, id: "filesystem.read" },
  { pattern: /\b(edit|fix|change|update|write|create|rename|patch)\b/i, id: "filesystem.write" },
  { pattern: /\b(delete|remove|cleanup|purge)\b/i, id: "filesystem.delete" },
  { pattern: /\b(test|build|run|execute|install|npm|node|python|powershell|shell)\b/i, id: "terminal.execute" },
  { pattern: /\b(git|commit|branch|diff|merge)\b/i, id: "git.read" },
  { pattern: /\b(commit|merge|rebase|push|tag)\b/i, id: "git.write" },
  { pattern: /\b(github|issue|pull request|repository|repo)\b/i, id: "saas.github" },
  { pattern: /\b(drive|google drive)\b/i, id: "saas.drive" },
  { pattern: /\b(browser|website|navigate|page)\b/i, id: "browser.navigate" }
];

export function inferCapabilities(task = "") {
  const found = [];
  for (const rule of capabilityRules) {
    if (rule.pattern.test(task) && !found.includes(rule.id)) found.push(rule.id);
  }
  return found.length ? found : ["filesystem.read"];
}

export function compileOperatorPlan({
  task,
  context = {},
  skills = [],
  capabilityRegistry = { capabilities: [] },
  maxSkills = 3
}) {
  if (!task || !String(task).trim()) {
    throw new Error("Task is required.");
  }

  const transport = chooseTransport(context);
  const requiredCapabilities = inferCapabilities(task);
  const capabilityIndex = new Map(
    (capabilityRegistry.capabilities || []).map((item) => [item.id, item])
  );

  const capabilities = requiredCapabilities.map((id) => ({
    id,
    known: capabilityIndex.has(id),
    risk: capabilityIndex.get(id)?.risk || "unknown",
    mutating: capabilityIndex.get(id)?.mutating ?? null
  }));

  const candidates = selectCandidateSkills(task, skills)
    .slice(0, maxSkills)
    .map(({ skill, score }) => ({
      name: skill.name,
      score,
      status: skill.status
    }));

  const mutating = capabilities.some((item) => item.mutating === true);
  const highestRisk = ["critical", "high", "medium", "low"].find((risk) =>
    capabilities.some((item) => item.risk === risk)
  ) || "unknown";

  const fingerprint = crypto
    .createHash("sha256")
    .update(JSON.stringify({ task, context, requiredCapabilities }))
    .digest("hex")
    .slice(0, 12);

  return {
    schema_version: 1,
    plan_id: "plan_" + fingerprint,
    task: String(task).trim(),
    transport,
    capabilities,
    skills: candidates,
    policy: {
      mutating,
      highest_risk: highestRisk,
      approval_required: ["high", "critical"].includes(highestRisk)
    },
    execution_contract: [
      "inspect",
      "policy-check",
      ...(mutating ? ["mutate-minimally"] : []),
      "verify",
      "report-evidence"
    ],
    verification: {
      required: mutating,
      accepted_statuses: ["PASS", "FAIL", "CHANGED", "COULD_NOT_VERIFY"]
    }
  };
}
