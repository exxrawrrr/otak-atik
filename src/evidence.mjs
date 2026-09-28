export const evidenceStatuses = [
  "PASS",
  "FAIL",
  "CHANGED",
  "COULD_NOT_VERIFY"
];

export function createEvidence({
  check,
  status,
  source = "unknown",
  detail = "",
  artifacts = []
}) {
  if (!evidenceStatuses.includes(status)) {
    throw new Error("Invalid evidence status: " + status);
  }

  return {
    check,
    status,
    source,
    detail,
    artifacts,
    recorded_at: new Date().toISOString()
  };
}

export function summarizeEvidence(items = []) {
  const counts = Object.fromEntries(
    evidenceStatuses.map((status) => [status, 0])
  );

  for (const item of items) {
    if (counts[item.status] === undefined) {
      throw new Error("Unknown evidence status: " + item.status);
    }
    counts[item.status] += 1;
  }

  const verified =
    counts.FAIL === 0 &&
    counts.COULD_NOT_VERIFY === 0 &&
    items.length > 0;

  return {
    verified,
    counts,
    total: items.length
  };
}
