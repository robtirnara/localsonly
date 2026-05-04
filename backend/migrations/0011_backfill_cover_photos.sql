UPDATE places SET cover_photo_url = sub.photo_url
FROM (
    SELECT DISTINCT ON (r.place_id) r.place_id, r.photo_url
    FROM ratings r
    WHERE r.photo_url IS NOT NULL
      AND r.is_suppressed = FALSE
      AND r.privacy = 'public'
    ORDER BY r.place_id, r.score DESC
) sub
WHERE places.id = sub.place_id
  AND places.cover_photo_url IS NULL;
