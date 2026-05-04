ALTER TABLE ratings
    ADD COLUMN item_name TEXT NOT NULL DEFAULT 'Untitled item';

ALTER TABLE ratings
    ADD COLUMN item_category TEXT NOT NULL DEFAULT 'general';
