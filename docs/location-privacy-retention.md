# Location Privacy and Retention (v1)

## Principles

- Use precise location transiently to evaluate a local access check.
- Persist coarse summaries and decision outputs only.
- Minimize retained sensitive location detail.

## What is processed

- transient request-time coordinates to evaluate geofence eligibility
- metadata needed to explain a decision (timestamp, reason code, source)

## What is stored

- coarse geofence result (for example: in-city, near-boundary, outside-city)
- confidence delta and source type
- derived `interactionEligibilityState` and input score snapshots
- audit trail entries for eligibility and moderation transitions

## What is not stored durably

- full GPS trails
- historical point-by-point coordinate logs

## Retention posture

- raw location payloads: do not persist in durable tables
- event pipeline/log residues: short TTL only, with explicit purge policy
- eligibility snapshots and moderation records: retain for operations, abuse handling, and appeals

## Operational checks

- scheduled purge jobs for any temporary location artifacts
- periodic audit that raw coordinates are absent from persisted domain tables
- schema review gate to prevent accidental precise-location retention
