INSERT INTO tags (id, slug, display_name) VALUES
    (gen_random_uuid(), 'date-night', 'Date Night'),
    (gen_random_uuid(), 'outdoor-seating', 'Outdoor Seating'),
    (gen_random_uuid(), 'hidden-gem', 'Hidden Gem'),
    (gen_random_uuid(), 'cash-only', 'Cash Only'),
    (gen_random_uuid(), 'late-night', 'Late Night'),
    (gen_random_uuid(), 'brunch-spot', 'Brunch Spot'),
    (gen_random_uuid(), 'ocean-view', 'Ocean View'),
    (gen_random_uuid(), 'craft-cocktails', 'Craft Cocktails'),
    (gen_random_uuid(), 'local-favorite', 'Local Favorite'),
    (gen_random_uuid(), 'family-friendly', 'Family Friendly'),
    (gen_random_uuid(), 'quick-bite', 'Quick Bite'),
    (gen_random_uuid(), 'happy-hour', 'Happy Hour'),
    (gen_random_uuid(), 'dog-friendly', 'Dog Friendly'),
    (gen_random_uuid(), 'live-music', 'Live Music'),
    (gen_random_uuid(), 'vegan-options', 'Vegan Options')
ON CONFLICT (slug) DO NOTHING;
