# Moderation and Operations Baseline (v1)

## Moderation capabilities

The backend must support moderation workflows even without a full admin UI.

- flagging a user
- freezing posting
- marking eligibility as under review
- opening and resolving appeals
- suppressing suspicious ratings from public aggregates
- tracking invite lineage (inviter to invitee)

## Operational states

- user-level controls: `is_posting_frozen`, `is_under_review`
- rating-level controls: `is_suppressed_from_public`
- eligibility-level controls: derived `interactionEligibilityState`

## Endpoint hooks (internal/admin-protected)

- `POST /moderation/users/:id/flag`
- `POST /moderation/users/:id/freeze-posting`
- `POST /moderation/users/:id/mark-under-review`
- `POST /moderation/ratings/:id/suppress`

## Appeal support

- users can file appeal requests via `POST /eligibility/appeals`
- appeal records tie to eligibility snapshots for reproducible review
- resolution events are stored in moderation actions

## Public aggregate safety

When a rating is marked suspicious, its contribution is hidden from city/popular aggregates
without deleting the record, preserving auditability and reversal options.
