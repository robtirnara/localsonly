-- Minimal delta migration for runtime correctness:
-- include suppress_rating in allowed moderation action types.

ALTER TABLE moderation_actions
DROP CONSTRAINT IF EXISTS moderation_actions_action_type_check;

ALTER TABLE moderation_actions
ADD CONSTRAINT moderation_actions_action_type_check
CHECK (
    action_type IN (
        'flag_user',
        'freeze_posting',
        'unfreeze_posting',
        'mark_under_review',
        'clear_under_review',
        'open_appeal',
        'resolve_appeal',
        'suppress_rating'
    )
);
