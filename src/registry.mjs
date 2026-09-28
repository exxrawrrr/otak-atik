export function indexById(items, key = "id") {
  return new Map(items.map((item) => [item[key], item]));
}

export function resolveCapabilities(skill, capabilityRegistry) {
  const index = indexById(capabilityRegistry.capabilities || []);
  const required = skill.requires?.capabilities || [];
  return required.map((id) => ({
    id,
    available: index.has(id),
    definition: index.get(id) || null
  }));
}

export function selectCandidateSkills(query, skills) {
  const terms = String(query).toLowerCase().split(/\W+/).filter(Boolean);
  return (skills || [])
    .map((skill) => {
      const haystack = `${skill.name} ${skill.description || ""}`.toLowerCase();
      const score = terms.reduce((n, term) => n + (haystack.includes(term) ? 1 : 0), 0);
      return { skill, score };
    })
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score || a.skill.name.localeCompare(b.skill.name));
}
