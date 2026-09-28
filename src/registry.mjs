const stopwords = new Set([
  "a", "an", "and", "the", "to", "of", "in", "on", "for", "with",
  "my", "this", "that", "it", "is", "are", "be", "from"
]);

function tokenize(value) {
  return String(value)
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((token) => token && !stopwords.has(token));
}

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
  const terms = new Set(tokenize(query));

  return (skills || [])
    .map((skill) => {
      const nameTokens = new Set(tokenize(skill.name));
      const descriptionTokens = new Set(tokenize(skill.description || ""));

      let score = 0;
      for (const term of terms) {
        if (nameTokens.has(term)) score += 4;
        if (descriptionTokens.has(term)) score += 1;
      }

      return { skill, score };
    })
    .filter((item) => item.score > 0)
    .sort((a, b) => b.score - a.score || a.skill.name.localeCompare(b.skill.name));
}
