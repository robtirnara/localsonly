CREATE TABLE IF NOT EXISTS saved_places (
    user_id UUID NOT NULL REFERENCES users(id),
    place_id UUID NOT NULL REFERENCES places(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, place_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_places_user ON saved_places(user_id);
