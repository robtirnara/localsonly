-- Registry of dish/item categories for autocomplete (fed by ratings + search).
CREATE TABLE IF NOT EXISTS item_categories (
    slug TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    usage_count INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_item_categories_display_lower
    ON item_categories (LOWER(display_name));

INSERT INTO item_categories (slug, display_name, usage_count, created_at, updated_at)
SELECT
    LOWER(REGEXP_REPLACE(TRIM(item_category), '\s+', '_', 'g')) AS slug,
    TRIM(item_category) AS display_name,
    COUNT(*)::int AS usage_count,
    NOW(),
    NOW()
FROM ratings
WHERE TRIM(item_category) <> ''
GROUP BY LOWER(REGEXP_REPLACE(TRIM(item_category), '\s+', '_', 'g')), TRIM(item_category)
ON CONFLICT (slug) DO UPDATE SET
    usage_count = GREATEST(item_categories.usage_count, EXCLUDED.usage_count),
    updated_at = NOW();
