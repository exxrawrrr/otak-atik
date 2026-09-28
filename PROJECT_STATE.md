# Project State

**Current milestone:** V0.1 Foundation / onboarding hardening  
**Repository maturity:** public alpha  
**Current package:** 0.1.0-alpha.2

## Implemented

- repository identity and product documentation;
- zero-dependency CLI baseline;
- doctor command;
- capability/skill/recipe/pack registries;
- conservative default policy;
- Windows installer with dry-run;
- automatic Desktop launcher generation;
- Remote Desktop Commander remote start/status/stop helpers;
- optional MCP SuperAssistant browser bridge;
- Codex local Desktop Commander MCP setup helper;
- transport-selection and remote-usage optimization skills;
- setup decision tree and cost/usage documentation;
- Linux tests plus Windows PowerShell smoke validation;
- 21 official skills;
- 10 passing contract/unit tests;
- security, contribution, ADR, and roadmap documentation.

## Real-world transport status

The original setup currently uses Remote Desktop Commander as the primary ChatGPT → Windows route.

The older MCP SuperAssistant browser bridge remains available as an optional/fallback path.

For local engineering work, especially Codex, the recommended direction is local Desktop Commander MCP so hosted remote quota is reserved for genuinely remote access.

## Next

1. executable adapter interface;
2. automatic user/project skill discovery;
3. declarative recipe executor;
4. local audit ledger + checkpoints;
5. stronger local/remote transport discovery;
6. macOS/Linux installers;
7. optional GUI-control adapter experiments.

## Deliberately deferred

- dashboard;
- cloud control plane;
- marketplace;
- autonomous scheduling;
- large dependency graph.

The architecture continues to expand from contracts and real operator workflows outward, not from UI inward.
