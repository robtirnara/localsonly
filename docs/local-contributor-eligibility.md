# Local Contributor Eligibility (v1)

## Purpose

This policy controls contribution permissions in LocalsOnly.
It is designed for local access confidence and abuse prevention, not legal residency verification.

## Input signals

### `accountTrustScore` (0-100)

Represents account persistence and trustworthiness.
Example inputs:

- successful phone reachability checks
- account age and consistency
- inviter lineage quality
- low spam-like behavior

### `localityScore` (0-100)

Represents confidence that the user is locally active in San Diego.
Example inputs:

- coarse geofence check outcomes
- recurring local activity patterns
- invite network locality
- weak phone region hint (non-decisive)

### `abuseRiskScore` (0-100, higher is worse)

Represents suspected spam or manipulation risk.
Example inputs:

- rapid account graph growth anomalies
- repeated suspicious posting patterns
- device/account inconsistency signals

## Derived state

`interactionEligibilityState` is derived by policy rules and thresholds:

- hard overrides first (`restricted`, `under_review`)
- then score bands (`verified_local`, `provisional_local`)
- fallback to `browse_only`

## Action matrix (v1)

- `browse_only`: no posting, no reaction, no friend requests.
- `provisional_local`: limited posting rate, capped friend requests, reduced public aggregate weight.
- `verified_local`: standard posting and interaction permissions.
- `restricted`: blocked from contribution actions until cleared.
- `under_review`: contribution blocked or constrained while moderation resolves risk.

## Phone verification policy

Phone verification is treated as:

- reachable-account proof
- anti-spam/persistence signal
- weak locality hint

Phone number region is never a decisive local proof.
