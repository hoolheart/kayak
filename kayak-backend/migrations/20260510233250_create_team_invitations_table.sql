-- Migration: Create team_invitations table
-- Created: 2026-05-11

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS team_invitations (
    id TEXT PRIMARY KEY NOT NULL,
    team_id TEXT NOT NULL,
    email TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK (role IN ('Admin', 'Member')),
    expires_at TEXT NOT NULL,
    used_at TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_invitations_code ON team_invitations(code);
CREATE INDEX IF NOT EXISTS idx_invitations_team ON team_invitations(team_id);
CREATE INDEX IF NOT EXISTS idx_invitations_expires ON team_invitations(expires_at);
