export const riskOrder = ["low", "medium", "high", "critical"];

export function evaluateRisk({ risk, approval }) {
  const action = approval?.[risk] ?? "confirm";
  if (!riskOrder.includes(risk)) {
    return { allowed: false, action: "deny", reason: "unknown-risk" };
  }
  return {
    allowed: action !== "deny",
    action,
    reason: action === "deny" ? "policy-deny" : "policy-allow"
  };
}

export function pathWithinRoots(candidate, roots = []) {
  if (!roots.length) return false;
  const normalize = (p) => p.replaceAll("\\", "/").replace(/\/+$/, "").toLowerCase();
  const target = normalize(candidate);
  return roots.some((root) => {
    const base = normalize(root);
    return target === base || target.startsWith(base + "/");
  });
}
