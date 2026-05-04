-- Eligibility and moderation extensions
-- Privacy posture:
-- 1) Raw GPS payloads are not persisted in durable tables.
-- 2) Only coarse evidence summaries and decision metadata are retained.

CREATE TABLE eligibility_snapshots (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    account_trust_score NUMERIC(5,2) NOT NULL CHECK (account_trust_score >= 0 AND account_trust_score <= 100),
    locality_score NUMERIC(5,2) NOT NULL CHECK (locality_score >= 0 AND locality_score <= 100),
    abuse_risk_score NUMERIC(5,2) NOT NULL CHECK (abuse_risk_score >= 0 AND abuse_risk_score <= 100),
    interaction_eligibility_state TEXT NOT NULL CHECK (
        interaction_eligibility_state IN ('browse_only', 'provisional_local', 'verified_local', 'restricted', 'under_review')
    ),
    reason_codes TEXT[] NOT NULL DEFAULT '{}',
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE TABLE eligibility_evidence (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    source_type TEXT NOT NULL CHECK (
        source_type IN (
            'invite_lineage',
            'phone_reachability',
            'coarse_geofence_result',
            'account_age',
            'device_consistency',
            'behavioral_risk'
        )
    ),
    coarse_area_code TEXT,
    evidence_summary JSONB NOT NULL DEFAULT '{}',
    confidence_delta NUMERIC(5,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE moderation_actions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    action_type TEXT NOT NULL CHECK (
        action_type IN (
            'flag_user',
            'freeze_posting',
            'unfreeze_posting',
            'mark_under_review',
            'clear_under_review',
            'open_appeal',
            'resolve_appeal'
        )
    ),
    actor_type TEXT NOT NULL CHECK (actor_type IN ('system', 'admin', 'moderator')),
    actor_id UUID,
    reason TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE appeals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    eligibility_snapshot_id UUID REFERENCES eligibility_snapshots(id),
    status TEXT NOT NULL CHECK (status IN ('open', 'in_review', 'resolved', 'rejected')),
    user_statement TEXT NOT NULL DEFAULT '',
    resolution_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rating_moderation (
    rating_id UUID PRIMARY KEY REFERENCES ratings(id) ON DELETE CASCADE,
    is_suppressed_from_public BOOLEAN NOT NULL DEFAULT FALSE,
    suppression_reason TEXT NOT NULL DEFAULT '',
    suppressed_at TIMESTAMPTZ
);

CREATE INDEX eligibility_snapshots_user_evaluated_idx
    ON eligibility_snapshots(user_id, evaluated_at DESC);

CREATE INDEX eligibility_evidence_user_source_idx
    ON eligibility_evidence(user_id, source_type, created_at DESC);

CREATE INDEX moderation_actions_user_created_idx
    ON moderation_actions(user_id, created_at DESC);
