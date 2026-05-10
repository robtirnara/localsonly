# Phase X — [Name]

> Copy this file when starting a new phase or feature plan. Keep section order and the `## References` block first — that block is how the master plan's link-back rule (D4 in [`README.md`](README.md)) is mechanically enforced.

## References

- **Master plan (the bible):** [`/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md`](/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md)
  - Repo mirror: [`docs/master-plan-localsonly-ux.md`](../master-plan-localsonly-ux.md)
  - Cite the section IDs you implement, e.g. `§3.1 Tab jobs`, `§6 Phase N`.
- **Other source-of-truth bibles (do not duplicate; link only):**
  - [`docs/prd.md`](../prd.md)
  - [`docs/local-contributor-eligibility.md`](../local-contributor-eligibility.md)
  - [`docs/moderation-operations.md`](../moderation-operations.md)
  - [`docs/location-privacy-retention.md`](../location-privacy-retention.md)
  - [`docs/mvp-smoke-test.md`](../mvp-smoke-test.md)
- **Decision log:** [`docs/plans/DECISION_LOG.md`](DECISION_LOG.md) — record any decision that contradicts or extends the master plan.

## Problem statement

One short paragraph: what is broken or missing today, and which master-plan section IDs (`§N.M`, `UX-NN`) it maps to. State it from the user's point of view, not the implementation's.

## Scope

**In**

- Bullet list of what this plan will deliver. Be specific (files, screens, endpoints).

**Out**

- Bullet list of what this plan will NOT do, especially adjacent things readers might assume are included. Cite the phase/plan that owns each excluded item.

## Design decisions

Number them `D1`, `D2`, … . For each: the decision, the alternatives rejected, and the master section it relates to. These rows must be added to [`docs/plans/DECISION_LOG.md`](DECISION_LOG.md) when the plan ships.

- **D1 — [Title].** Decision. Rejected: alternatives. (Master §N)
- **D2 — [Title].** …

## Implementation tasks

- [ ] Concrete, atomic, code-level task.
- [ ] …

Match these 1:1 with the plan's `todos:` frontmatter so the Cursor plan UI stays in sync.

## Files touched (complete list)

- New: `path/to/new/file.swift`
- Edit: `path/to/existing/file.swift` (one-line reason)
- …

If a file is edited, link it; if new, just list the path. Use repo paths, not absolute paths.

## API changes

If none: write "None." If any: list each new/changed endpoint with method, path, request shape, response shape, and the migration (if any). Trigger Phase 5 review for backend additions.

## Acceptance criteria

**From master §[N] (verbatim):**

- [ ] Copy the master criteria here exactly. Do not paraphrase.

**Plan additions (mechanical or measurable):**

- [ ] Add what's needed to make the master criteria checkable in this plan's scope.

## Verification steps

Numbered manual or automated steps a reviewer can run to confirm the acceptance criteria. Include `make test`, smoke-test items, and any device/screen matrix.

1. …
2. …

If primary navigation changes, update [`docs/mvp-smoke-test.md`](../mvp-smoke-test.md) in the same change set (D5 in [`README.md`](README.md)).

## Rollback / feature flags

State the rollback path (revert commit, flip flag, run reverse migration). If a feature flag is used, name it and the default value.
