-- DEV ONLY: wipes application content tables. Preserves tags vocabulary (0009_seed_tags.sql).
-- Never run against production or shared staging with real users.
-- Run seed_bootstrap_san_diego.sql after this to repopulate demo data.

BEGIN;

TRUNCATE TABLE
    notifications,
    cosigns,
    feed_events,
    list_items,
    lists,
    saved_places,
    rating_tags,
    rating_moderation,
    ratings,
    invites,
    user_sessions,
    friendships,
    appeals,
    moderation_actions,
    eligibility_evidence,
    eligibility_snapshots,
    users,
    places
RESTART IDENTITY CASCADE;

COMMIT;
