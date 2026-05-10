# LocalsOnly — agent guide

Conventions for agents (and humans) working in this repository. Keep this file short; deep references live under [`docs/`](docs/).

## Planning conventions

LocalsOnly uses one master product/UX plan as the source of truth, with phase/feature child plans branching off it.

- **Master plan (the bible):** [`/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md`](/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md). Read-only repo mirror at [`docs/master-plan-localsonly-ux.md`](docs/master-plan-localsonly-ux.md).
- **Other source-of-truth bibles:** [`docs/prd.md`](docs/prd.md), [`docs/local-contributor-eligibility.md`](docs/local-contributor-eligibility.md), [`docs/moderation-operations.md`](docs/moderation-operations.md), [`docs/location-privacy-retention.md`](docs/location-privacy-retention.md), [`docs/mvp-smoke-test.md`](docs/mvp-smoke-test.md). Do not duplicate them in plans — link.
- **How to write a child plan:** copy [`docs/plans/CHILD_PLAN_TEMPLATE.md`](docs/plans/CHILD_PLAN_TEMPLATE.md) into a new Cursor plan and follow the workflow in [`docs/plans/README.md`](docs/plans/README.md).
- **Link-back rule:** every child plan must begin with a `## References` section linking the master-plan section IDs it implements (e.g. `§3.1`, `§6 Phase 1`).
- **Decision log:** record any decision that contradicts or extends the master plan in [`docs/plans/DECISION_LOG.md`](docs/plans/DECISION_LOG.md).
- **Smoke-test canary:** any change to tab IA, primary navigation, or the rating/feed flow must update [`docs/mvp-smoke-test.md`](docs/mvp-smoke-test.md) in the same change set.

## Build and test

See [`docs/mvp-smoke-test.md`](docs/mvp-smoke-test.md) for the canonical start/test guide. Quickstart from repo root:

```sh
make up
make run
make test
make ios
```
