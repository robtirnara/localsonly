CREATE TABLE IF NOT EXISTS cosigns (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    rating_id UUID NOT NULL REFERENCES ratings(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, rating_id)
);

CREATE INDEX IF NOT EXISTS idx_cosigns_rating ON cosigns(rating_id);
CREATE INDEX IF NOT EXISTS idx_cosigns_user ON cosigns(user_id);
