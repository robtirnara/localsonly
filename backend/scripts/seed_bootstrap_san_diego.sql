-- LocalsOnly: San Diego demo bootstrap seed (v1)
-- Idempotent: safe to re-run on empty DB or after migrations. Uses fixed UUIDs + ON CONFLICT.
-- Run after all schema migrations. Does not modify the tags vocabulary table.
--
-- Production: run once when bringing an environment online with psql or CI.
-- Local dev full reset: use seed_dev_reset.sql first, then this file.
--
-- Photo URLs: Wikimedia Commons (stable hotlinks) + Unsplash IDs verified to return HTTP 200
-- via images.unsplash.com. Many older Unsplash photo-* IDs were retired from Imgix (404), which
-- caused empty images in the app. Not official venue photography.

BEGIN;

-- -----------------------------------------------------------------------------
-- Users (includes migration 0005 seed user + three demo contributors)
-- -----------------------------------------------------------------------------
INSERT INTO users (id, phone_e164, display_name, bio, home_city, inviter_user_id, avatar_url)
VALUES
    (
        '00000000-0000-0000-0000-000000000001',
        '+10000000000',
        'Seed User',
        'North Park regular. Coffee first, questions later.',
        'SanDiego',
        NULL,
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=400&q=85'
    ),
    (
        '00000000-0000-0000-0000-000000000003',
        '+15555550101',
        'Maya Chen',
        'Matcha obsessive. Weekends on 30th Street.',
        'SanDiego',
        '00000000-0000-0000-0000-000000000001',
        'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg'
    ),
    (
        '00000000-0000-0000-0000-000000000004',
        '+15555550102',
        'Jordan Diaz',
        'Cocktails, vinyl, and late-night burgers.',
        'SanDiego',
        '00000000-0000-0000-0000-000000000001',
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=400&q=85'
    ),
    (
        '00000000-0000-0000-0000-000000000005',
        '+15555550103',
        'Sam Okonkwo',
        'Little Italy walks and patio season.',
        'SanDiego',
        '00000000-0000-0000-0000-000000000001',
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&w=400&q=85'
    )
ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    bio = EXCLUDED.bio,
    home_city = EXCLUDED.home_city,
    avatar_url = EXCLUDED.avatar_url,
    inviter_user_id = COALESCE(users.inviter_user_id, EXCLUDED.inviter_user_id);

-- Test invite (same as 0005_seed_test_invite.sql; keeps smoke-test flow)
INSERT INTO invites (id, code, inviter_user_id, status)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'LOCALS2026',
    '00000000-0000-0000-0000-000000000001',
    'issued'
)
ON CONFLICT (code) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Places
-- -----------------------------------------------------------------------------
INSERT INTO places (
    id, name, neighborhood, category, city,
    latitude, longitude, external_source, external_id,
    cover_photo_url,
    created_at, updated_at
)
VALUES
    ('10000000-0000-4000-8000-000000000001', 'Lovesong', 'North Park', 'both', 'SanDiego', 32.7569, -117.1305, 'seed', 'sd-lovesong', 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000002', 'Heartwork Coffee Bar', 'North Park', 'drink', 'SanDiego', 32.7489, -117.1305, 'seed', 'sd-heartwork', 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000003', 'Superbloom Coffee', 'Normal Heights', 'drink', 'SanDiego', 32.7631, -117.1365, 'seed', 'sd-superbloom', 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000004', 'Craft & Commerce', 'Little Italy', 'both', 'SanDiego', 32.7244, -117.1696, 'seed', 'sd-craft-commerce', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&w=1600&q=85', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000005', 'Balboa Burger', 'Mission Beach', 'food', 'SanDiego', 32.7736, -117.2534, 'seed', 'sd-balboa-burger', 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000006', 'The Friendly', 'North Park', 'food', 'SanDiego', 32.7617, -117.1345, 'seed', 'sd-friendly', 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000007', 'James Coffee Co.', 'Little Italy', 'drink', 'SanDiego', 32.7234, -117.1684, 'seed', 'sd-james-coffee', 'https://upload.wikimedia.org/wikipedia/commons/4/45/A_small_cup_of_coffee.JPG', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000008', 'Youngblood', 'Little Italy', 'food', 'SanDiego', 32.7248, -117.1693, 'seed', 'sd-youngblood', 'https://upload.wikimedia.org/wikipedia/commons/c/c8/Burrito.jpg', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000009', 'Communal Coffee', 'North Park', 'drink', 'SanDiego', 32.7475, -117.1298, 'seed', 'sd-communal', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&w=1600&q=85', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000010', 'Polite Provisions', 'North Park', 'drink', 'SanDiego', 32.7482, -117.1294, 'seed', 'sd-polite', 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000011', 'Wayfarer Bread & Pastry', 'Bird Rock', 'food', 'SanDiego', 32.7996, -117.2557, 'seed', 'sd-wayfarer', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&w=1600&q=85', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000012', 'Campfire', 'Carlsbad', 'food', 'SanDiego', 33.1592, -117.3506, 'seed', 'sd-campfire', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&w=1600&q=85', NOW(), NOW()),
    ('10000000-0000-4000-8000-000000000013', 'Morning Glory', 'Little Italy', 'food', 'SanDiego', 32.7228, -117.1699, 'seed', 'sd-morning-glory', 'https://upload.wikimedia.org/wikipedia/commons/9/93/Tim_Hortons_Pancakes.jpg', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    neighborhood = EXCLUDED.neighborhood,
    category = EXCLUDED.category,
    city = EXCLUDED.city,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    external_source = EXCLUDED.external_source,
    external_id = EXCLUDED.external_id,
    cover_photo_url = EXCLUDED.cover_photo_url,
    updated_at = NOW();

-- -----------------------------------------------------------------------------
-- Ratings (20 public item ratings) + feed_events
-- -----------------------------------------------------------------------------
INSERT INTO ratings (
    id, user_id, place_id, score, notes, visit_date, privacy, is_suppressed,
    item_name, item_category, photo_url, created_at, updated_at
)
VALUES
    ('20000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000001', 9.2, 'Lavender honey matcha — floral without being soap-y.', '2025-11-02', 'public', FALSE, 'Lavender Honey Matcha', 'matcha', 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg', '2026-01-10 18:30:00+00', '2026-01-10 18:30:00+00'),
    ('20000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000003', '10000000-0000-4000-8000-000000000002', 8.7, 'Strawberry matcha that actually tastes like fruit.', '2025-11-08', 'public', FALSE, 'Strawberry Matcha', 'matcha', 'https://upload.wikimedia.org/wikipedia/commons/7/72/Strawberry_milkshake.jpg', '2026-01-11 16:00:00+00', '2026-01-11 16:00:00+00'),
    ('20000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000004', '10000000-0000-4000-8000-000000000003', 9.0, 'Ceremonial grade, smooth finish.', '2025-12-01', 'public', FALSE, 'Ceremonial Matcha', 'matcha', 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg', '2026-01-12 14:15:00+00', '2026-01-12 14:15:00+00'),
    ('20000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000004', 8.5, 'Old Fashioned done right — balanced bitters.', '2025-10-20', 'public', FALSE, 'Old Fashioned', 'cocktail', 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85', '2026-01-08 22:00:00+00', '2026-01-08 22:00:00+00'),
    ('20000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000003', '10000000-0000-4000-8000-000000000005', 7.8, 'Classic beach-town burger after a long walk.', '2025-09-14', 'public', FALSE, 'Classic Burger', 'burger', 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg', '2026-01-05 19:45:00+00', '2026-01-05 19:45:00+00'),
    ('20000000-0000-4000-8000-000000000006', '00000000-0000-0000-0000-000000000005', '10000000-0000-4000-8000-000000000006', 9.1, 'Smash patty, crispy edges, ridiculous.', '2025-12-18', 'public', FALSE, 'Smash Burger', 'burger', 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg', '2026-01-14 20:10:00+00', '2026-01-14 20:10:00+00'),
    ('20000000-0000-4000-8000-000000000007', '00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000007', 8.0, 'Bright and bitter in the best way.', '2025-11-21', 'public', FALSE, 'Espresso Tonic', 'coffee', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=1600&q=85', '2026-01-06 09:30:00+00', '2026-01-06 09:30:00+00'),
    ('20000000-0000-4000-8000-000000000008', '00000000-0000-0000-0000-000000000004', '10000000-0000-4000-8000-000000000008', 8.4, 'Huge, messy, worth the nap after.', '2025-10-05', 'public', FALSE, 'Breakfast Burrito', 'breakfast', 'https://upload.wikimedia.org/wikipedia/commons/c/c8/Burrito.jpg', '2026-01-04 11:00:00+00', '2026-01-04 11:00:00+00'),
    ('20000000-0000-4000-8000-000000000009', '00000000-0000-0000-0000-000000000003', '10000000-0000-4000-8000-000000000009', 8.2, 'Honey latte with patio people-watching.', '2025-12-07', 'public', FALSE, 'Honey Latte', 'coffee', 'https://upload.wikimedia.org/wikipedia/commons/4/45/A_small_cup_of_coffee.JPG', '2026-01-13 15:40:00+00', '2026-01-13 15:40:00+00'),
    ('20000000-0000-4000-8000-000000000010', '00000000-0000-0000-0000-000000000005', '10000000-0000-4000-8000-000000000010', 8.9, 'Margarita with depth — not just sweet.', '2025-11-15', 'public', FALSE, 'Margarita', 'cocktail', 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85', '2026-01-09 21:30:00+00', '2026-01-09 21:30:00+00'),
    ('20000000-0000-4000-8000-000000000011', '00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000011', 9.0, 'Sourdough worth driving for.', '2025-08-30', 'public', FALSE, 'Country Sourdough Loaf', 'bakery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&w=1600&q=85', '2026-01-03 08:20:00+00', '2026-01-03 08:20:00+00'),
    ('20000000-0000-4000-8000-000000000012', '00000000-0000-0000-0000-000000000004', '10000000-0000-4000-8000-000000000012', 8.3, 'Campfire dessert energy without the smoke in your eyes.', '2025-12-22', 'public', FALSE, 'S''mores Tart', 'dessert', 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&w=1600&q=85', '2026-01-15 17:50:00+00', '2026-01-15 17:50:00+00'),
    ('20000000-0000-4000-8000-000000000013', '00000000-0000-0000-0000-000000000003', '10000000-0000-4000-8000-000000000013', 9.3, 'Souffle pancakes that jiggle accordingly.', '2025-10-12', 'public', FALSE, 'Japanese Souffle Pancakes', 'brunch', 'https://upload.wikimedia.org/wikipedia/commons/9/93/Tim_Hortons_Pancakes.jpg', '2026-01-07 10:05:00+00', '2026-01-07 10:05:00+00'),
    ('20000000-0000-4000-8000-000000000014', '00000000-0000-0000-0000-000000000005', '10000000-0000-4000-8000-000000000001', 8.1, 'Paloma on draft — crushable.', '2025-11-29', 'public', FALSE, 'Paloma', 'cocktail', 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85', '2026-01-16 19:00:00+00', '2026-01-16 19:00:00+00'),
    ('20000000-0000-4000-8000-000000000015', '00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000002', 8.6, 'Iced oat latte, dialed in.', '2025-12-10', 'public', FALSE, 'Iced Oat Latte', 'coffee', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=1600&q=85', '2026-01-11 08:45:00+00', '2026-01-11 08:45:00+00'),
    ('20000000-0000-4000-8000-000000000016', '00000000-0000-0000-0000-000000000005', '10000000-0000-4000-8000-000000000003', 8.4, 'Seasonal cold brew, crisp finish.', '2025-12-28', 'public', FALSE, 'Seasonal Cold Brew', 'coffee', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=1600&q=85', '2026-01-12 12:20:00+00', '2026-01-12 12:20:00+00'),
    ('20000000-0000-4000-8000-000000000017', '00000000-0000-0000-0000-000000000004', '10000000-0000-4000-8000-000000000004', 8.0, 'Late-night burger from the same kitchen.', '2025-11-03', 'public', FALSE, 'Late Burger', 'burger', 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg', '2026-01-10 23:15:00+00', '2026-01-10 23:15:00+00'),
    ('20000000-0000-4000-8000-000000000018', '00000000-0000-0000-0000-000000000003', '10000000-0000-4000-8000-000000000006', 7.5, 'Crispy shoestring situation.', '2025-09-22', 'public', FALSE, 'Shoestring Fries', 'sides', 'https://upload.wikimedia.org/wikipedia/commons/4/42/French_fries.jpg', '2026-01-02 13:10:00+00', '2026-01-02 13:10:00+00'),
    ('20000000-0000-4000-8000-000000000019', '00000000-0000-0000-0000-000000000005', '10000000-0000-4000-8000-000000000007', 8.7, 'Morning bun + espresso stop.', '2025-12-15', 'public', FALSE, 'Morning Bun', 'bakery', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&w=1600&q=85', '2026-01-13 09:00:00+00', '2026-01-13 09:00:00+00'),
    ('20000000-0000-4000-8000-000000000020', '00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000010', 9.0, 'Old Pal — rye-forward, serious.', '2025-10-30', 'public', FALSE, 'Old Pal', 'cocktail', 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85', '2026-01-14 22:45:00+00', '2026-01-14 22:45:00+00')
ON CONFLICT (id) DO UPDATE SET
    score = EXCLUDED.score,
    notes = EXCLUDED.notes,
    visit_date = EXCLUDED.visit_date,
    item_name = EXCLUDED.item_name,
    item_category = EXCLUDED.item_category,
    photo_url = EXCLUDED.photo_url,
    privacy = EXCLUDED.privacy,
    is_suppressed = EXCLUDED.is_suppressed,
    updated_at = EXCLUDED.updated_at;

-- Backfill: bind each seeded rating id to its photo (fixes legacy rows with dead Imgix URLs).
UPDATE ratings AS r
SET
    photo_url = v.photo_url,
    updated_at = NOW()
FROM (VALUES
    ('20000000-0000-4000-8000-000000000001'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg'),
    ('20000000-0000-4000-8000-000000000002'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/7/72/Strawberry_milkshake.jpg'),
    ('20000000-0000-4000-8000-000000000003'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/4/4d/Green_tea_latte.jpg'),
    ('20000000-0000-4000-8000-000000000004'::uuid, 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000005'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg'),
    ('20000000-0000-4000-8000-000000000006'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg'),
    ('20000000-0000-4000-8000-000000000007'::uuid, 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000008'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/c/c8/Burrito.jpg'),
    ('20000000-0000-4000-8000-000000000009'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/4/45/A_small_cup_of_coffee.JPG'),
    ('20000000-0000-4000-8000-000000000010'::uuid, 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000011'::uuid, 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000012'::uuid, 'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000013'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/9/93/Tim_Hortons_Pancakes.jpg'),
    ('20000000-0000-4000-8000-000000000014'::uuid, 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000015'::uuid, 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000016'::uuid, 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000017'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/e/e8/Hamburger_sandwich.jpg'),
    ('20000000-0000-4000-8000-000000000018'::uuid, 'https://upload.wikimedia.org/wikipedia/commons/4/42/French_fries.jpg'),
    ('20000000-0000-4000-8000-000000000019'::uuid, 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&w=1600&q=85'),
    ('20000000-0000-4000-8000-000000000020'::uuid, 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&w=1600&q=85')
) AS v(id, photo_url)
WHERE r.id = v.id;

INSERT INTO feed_events (id, actor_user_id, event_type, subject_type, subject_id, city, visibility, created_at)
VALUES
    ('30000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000001', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000001', 'SanDiego', 'public', '2026-01-10 18:30:00+00'),
    ('30000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000003', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000002', 'SanDiego', 'public', '2026-01-11 16:00:00+00'),
    ('30000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000004', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000003', 'SanDiego', 'public', '2026-01-12 14:15:00+00'),
    ('30000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000001', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000004', 'SanDiego', 'public', '2026-01-08 22:00:00+00'),
    ('30000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000003', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000005', 'SanDiego', 'public', '2026-01-05 19:45:00+00'),
    ('30000000-0000-4000-8000-000000000006', '00000000-0000-0000-0000-000000000005', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000006', 'SanDiego', 'public', '2026-01-14 20:10:00+00'),
    ('30000000-0000-4000-8000-000000000007', '00000000-0000-0000-0000-000000000001', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000007', 'SanDiego', 'public', '2026-01-06 09:30:00+00'),
    ('30000000-0000-4000-8000-000000000008', '00000000-0000-0000-0000-000000000004', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000008', 'SanDiego', 'public', '2026-01-04 11:00:00+00'),
    ('30000000-0000-4000-8000-000000000009', '00000000-0000-0000-0000-000000000003', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000009', 'SanDiego', 'public', '2026-01-13 15:40:00+00'),
    ('30000000-0000-4000-8000-000000000010', '00000000-0000-0000-0000-000000000005', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000010', 'SanDiego', 'public', '2026-01-09 21:30:00+00'),
    ('30000000-0000-4000-8000-000000000011', '00000000-0000-0000-0000-000000000001', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000011', 'SanDiego', 'public', '2026-01-03 08:20:00+00'),
    ('30000000-0000-4000-8000-000000000012', '00000000-0000-0000-0000-000000000004', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000012', 'SanDiego', 'public', '2026-01-15 17:50:00+00'),
    ('30000000-0000-4000-8000-000000000013', '00000000-0000-0000-0000-000000000003', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000013', 'SanDiego', 'public', '2026-01-07 10:05:00+00'),
    ('30000000-0000-4000-8000-000000000014', '00000000-0000-0000-0000-000000000005', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000014', 'SanDiego', 'public', '2026-01-16 19:00:00+00'),
    ('30000000-0000-4000-8000-000000000015', '00000000-0000-0000-0000-000000000001', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000015', 'SanDiego', 'public', '2026-01-11 08:45:00+00'),
    ('30000000-0000-4000-8000-000000000016', '00000000-0000-0000-0000-000000000005', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000016', 'SanDiego', 'public', '2026-01-12 12:20:00+00'),
    ('30000000-0000-4000-8000-000000000017', '00000000-0000-0000-0000-000000000004', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000017', 'SanDiego', 'public', '2026-01-10 23:15:00+00'),
    ('30000000-0000-4000-8000-000000000018', '00000000-0000-0000-0000-000000000003', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000018', 'SanDiego', 'public', '2026-01-02 13:10:00+00'),
    ('30000000-0000-4000-8000-000000000019', '00000000-0000-0000-0000-000000000005', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000019', 'SanDiego', 'public', '2026-01-13 09:00:00+00'),
    ('30000000-0000-4000-8000-000000000020', '00000000-0000-0000-0000-000000000001', 'rating_created', 'rating', '20000000-0000-4000-8000-000000000020', 'SanDiego', 'public', '2026-01-14 22:45:00+00')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Lists
-- -----------------------------------------------------------------------------
INSERT INTO lists (id, user_id, name, description, is_public, created_at, updated_at)
VALUES
    (
        '40000000-0000-4000-8000-000000000001',
        '00000000-0000-0000-0000-000000000003',
        'North Park matcha crawl',
        'Ceremonial speeds only.',
        TRUE,
        NOW(),
        NOW()
    ),
    (
        '40000000-0000-4000-8000-000000000002',
        '00000000-0000-0000-0000-000000000004',
        'Little Italy cocktail night',
        'Start polite, end messy.',
        TRUE,
        NOW(),
        NOW()
    )
ON CONFLICT (id) DO NOTHING;

INSERT INTO list_items (list_id, place_id, sort_order, note, created_at)
VALUES
    ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001', 0, 'Lavender honey moment', NOW()),
    ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 1, 'Strawberry matcha pit stop', NOW()),
    ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000003', 2, 'Ceremonial close-out', NOW()),
    ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000009', 3, 'Honey latte reset', NOW()),
    ('40000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000004', 0, 'Old Fashioned baseline', NOW()),
    ('40000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000010', 1, 'Margarita interlude', NOW()),
    ('40000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 2, 'Paloma nightcap', NOW())
ON CONFLICT (list_id, place_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Saved places (primary demo user)
-- -----------------------------------------------------------------------------
INSERT INTO saved_places (user_id, place_id, created_at)
VALUES
    ('00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000001', NOW()),
    ('00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000002', NOW()),
    ('00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000004', NOW()),
    ('00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000006', NOW()),
    ('00000000-0000-0000-0000-000000000001', '10000000-0000-4000-8000-000000000010', NOW())
ON CONFLICT (user_id, place_id) DO NOTHING;

COMMIT;
