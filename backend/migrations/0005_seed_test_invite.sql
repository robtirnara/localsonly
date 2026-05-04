-- Seed test inviter user and invite code for local development.
INSERT INTO users (id, phone_e164, display_name)
VALUES ('00000000-0000-0000-0000-000000000001', '+10000000000', 'Seed User')
ON CONFLICT (phone_e164) DO NOTHING;

INSERT INTO invites (id, code, inviter_user_id, status)
VALUES ('00000000-0000-0000-0000-000000000002', 'LOCALS2026', '00000000-0000-0000-0000-000000000001', 'issued')
ON CONFLICT (code) DO NOTHING;
