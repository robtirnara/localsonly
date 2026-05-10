# LocalsOnly planning conventions

How phase and feature plans relate to the master plan, where they live, and the rules every plan must follow. Established by Phase 0 governance.

## Source of truth (D1)

The **master plan** is the working bible for product, UX, and execution sequencing:

- **Editable source:** [`/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md`](/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md) (Cursor plan).
- **Repo mirror (read-only):** [`docs/master-plan-localsonly-ux.md`](../master-plan-localsonly-ux.md). Use this for PR links and code review. Re-mirror from the Cursor plan whenever the master changes; never edit the mirror directly.

Other source-of-truth bibles (do not duplicate; link from plans):

- [`docs/prd.md`](../prd.md)
- [`docs/local-contributor-eligibility.md`](../local-contributor-eligibility.md)
- [`docs/moderation-operations.md`](../moderation-operations.md)
- [`docs/location-privacy-retention.md`](../location-privacy-retention.md)
- [`docs/mvp-smoke-test.md`](../mvp-smoke-test.md)

## Where child plans live (D2)

Child plans live in the **Cursor plans folder** (`/Users/rob/.cursor/plans/`) using the existing `<slug>_<hash>.plan.md` convention so the Cursor UI manages todos and status. `docs/plans/` only holds shared scaffolding:

- [`CHILD_PLAN_TEMPLATE.md`](CHILD_PLAN_TEMPLATE.md) — copy this when starting a new plan.
- [`DECISION_LOG.md`](DECISION_LOG.md) — append-only log of decisions.
- This README.

## Decision log (D3)

When a plan locks a choice that contradicts or extends the master plan — or adopts a convention future plans must follow — add a row to [`DECISION_LOG.md`](DECISION_LOG.md). Columns: `Date | Decision | Alternatives rejected | Section`. No per-decision ADR files; one log keeps overhead low for v1.

## The link-back rule (D4)

Every child plan **must** begin with a `## References` section that links back to the master-plan section IDs it implements (e.g. `§3.1 Tab jobs`, `§6 Phase 1`). The template enforces this by making `## References` the first section. If your plan does not link to the master, it is not a child plan and reviewers should ask why.

## Smoke-test canary (D5)

Any plan that changes tab IA, primary navigation, or the rating/feed flow **must** update [`docs/mvp-smoke-test.md`](../mvp-smoke-test.md) in the same change set. The smoke test is how we keep release QA aligned with shipping app behavior between phases.

## Quick start: writing a new phase plan

1. Copy [`CHILD_PLAN_TEMPLATE.md`](CHILD_PLAN_TEMPLATE.md) into a new Cursor plan (`<slug>_<hash>.plan.md`).
2. Fill in `## References` with the master section IDs you implement.
3. Mirror the `## Implementation tasks` checkboxes into the plan's frontmatter `todos:`.
4. Copy the master's acceptance criteria verbatim under `## Acceptance criteria`, then add your mechanical checks.
5. When you ship, append your `D#` decisions to [`DECISION_LOG.md`](DECISION_LOG.md) and, if nav changed, update the smoke test.
