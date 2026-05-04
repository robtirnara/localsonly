# LocalsOnly PRD (v1)

## Product framing

LocalsOnly is a San Diego-first iOS app for food and drink ratings with a lightweight social layer.
Users can browse broadly, but contribution actions require Local Contributor eligibility.
This is not legal residency verification and is not KYC.

## v1 goals

- Strong personal rating workflows (1.0-10.0, notes, tags, filters).
- Lightweight social discovery (friend activity + simple city popular feed).
- Local access controls based on locality confidence, trust, and abuse risk.

## Eligibility model

The system calculates independent signals and derives `interactionEligibilityState`.

- `accountTrustScore`: account persistence and anti-spam confidence.
- `localityScore`: confidence user is active in San Diego.
- `abuseRiskScore`: manipulation/spam risk likelihood (higher is worse).
- `interactionEligibilityState`: one of `browse_only`, `provisional_local`, `verified_local`, `restricted`, `under_review`.

## Tier capabilities

- `browse_only`: read-only browsing.
- `provisional_local`: limited posting and capped social actions.
- `verified_local`: full contribution capabilities.
- `restricted`: browse and account management only.
- `under_review`: browse while contribution and aggregate impact are constrained.

## v1 analytics scope

Only these profile analytics are in-scope:

- average score
- number of ratings
- tag breakdown
- score distribution
- top places

## v1 feed scope

Only these feed outputs are in-scope:

- friend activity feed
- place aggregate summary
- simple city popular/trending list

No advanced ranking engine or ML-heavy scoring in v1.
