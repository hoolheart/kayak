-- Migration: Create default admin user
-- Created: 2026-04-06

-- Create default admin user if not exists
-- Default credentials: admin@kayak.local / admin123
INSERT OR IGNORE INTO users (id, email, password_hash, username, status, created_at, updated_at)
SELECT 
    '00000000-0000-0000-0000-000000000001',
    'admin@kayak.local',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.HtJtTHHl3BHJjC',  -- admin123
    'Administrator',
    'active',
    datetime('now'),
    datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@kayak.local');
