-- LocalsOnly v1 base schema (modular monolith)
-- Terminology intentionally uses Local Contributor eligibility (not legal residency/KYC).

CREATE TABLE users (
    id UUID PRIMARY KEY,
    phone_e164 TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    bio TEXT NOT NULL DEFAULT '',
    avatar_url TEXT,
    home_city TEXT NOT NULL DEFAULT 'SanDiego',
    inviter_user_id UUID REFERENCES users(id),
    is_posting_frozen BOOLEAN NOT NULL DEFAULT FALSE,
    is_under_review BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE invites (
    id UUID PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    inviter_user_id UUID NOT NULL REFERENCES users(id),
    invitee_user_id UUID REFERENCES users(id),
    status TEXT NOT NULL CHECK (status IN ('issued', 'redeemed', 'revoked')),
    redeemed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE places (
    id UUID PRIMARY KEY,
    external_source TEXT,
    external_id TEXT,
    name TEXT NOT NULL,
    neighborhood TEXT,
    category TEXT NOT NULL CHECK (category IN ('food', 'drink', 'both')),
    city TEXT NOT NULL DEFAULT 'SanDiego',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ratings (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    place_id UUID NOT NULL REFERENCES places(id),
    score NUMERIC(3,1) NOT NULL CHECK (score >= 1.0 AND score <= 10.0),
    notes TEXT NOT NULL DEFAULT '',
    visit_date DATE,
    privacy TEXT NOT NULL CHECK (privacy IN ('public', 'friends', 'private')),
    is_suppressed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE tags (
    id UUID PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL
);

CREATE TABLE rating_tags (
    rating_id UUID NOT NULL REFERENCES ratings(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (rating_id, tag_id)
);

CREATE TABLE friendships (
    requester_user_id UUID NOT NULL REFERENCES users(id),
    addressee_user_id UUID NOT NULL REFERENCES users(id),
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (requester_user_id, addressee_user_id)
);

CREATE TABLE feed_events (
    id UUID PRIMARY KEY,
    actor_user_id UUID NOT NULL REFERENCES users(id),
    event_type TEXT NOT NULL,
    subject_type TEXT NOT NULL,
    subject_id UUID NOT NULL,
    city TEXT NOT NULL DEFAULT 'SanDiego',
    visibility TEXT NOT NULL CHECK (visibility IN ('friends', 'public')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
