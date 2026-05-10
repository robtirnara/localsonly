# LocalsOnly decision log

Append-only record of decisions that shape the LocalsOnly product/UX plan. Columns mirror master plan §11. Add a row whenever a phase plan locks a choice that contradicts or extends the master plan, or whenever you adopt a convention future plans must follow.

| Date       | Decision                                                                 | Alternatives rejected                                                                            | Section                  |
|------------|--------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|--------------------------|
| 2026-05-09 | D1 — Mirror, don't move. Master plan stays in `/Users/rob/.cursor/plans/localsonly_state_and_ux_a8bc3736.plan.md`; `docs/master-plan-localsonly-ux.md` is a read-only mirror. | Full move into repo (loses Cursor plan affordances); no mirror at all (PR reviewers cannot deep-link sections). | Master §intro, §6 Phase 0 |
| 2026-05-09 | D2 — Child plans live in the Cursor plans folder using `<slug>_<hash>.plan.md`; `docs/plans/` only holds template, README, and this log. | Storing child plans in `docs/plans/` (duplicates Cursor plan UI; harder to keep todos in sync). | Master §6 Phase 0, §10   |
| 2026-05-09 | D3 — Decision log is one checked-in markdown table at `docs/plans/DECISION_LOG.md`. | Per-decision ADR files (overhead too high for v1).                                              | Master §11               |
| 2026-05-09 | D4 — Section IDs are the link contract. Every child plan begins with a `## References` section linking master section anchors. Enforced by template copy-paste. | Free-form references (links rot, plans drift from master).                                      | Master §intro, §10       |
| 2026-05-09 | D5 — Smoke test is the nav-change canary. Any phase plan changing tab IA, primary nav, or rating/feed flow must update `docs/mvp-smoke-test.md` in the same change set. | Treating smoke test as separate QA work (drifts from app reality between phases).               | Master §6 Phase 0, §8.1  |
