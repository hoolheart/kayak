-- Migration: Add partial index on team_invitations for pending invitations
-- Created: 2026-05-11
-- Fixes ME-004: Missing partial index on team_invitations

PRAGMA foreign_keys = ON;

-- Partial index for efficiently querying pending (unused) invitations
CREATE INDEX IF NOT EXISTS idx_invitations_used ON team_invitations(used_at) WHERE used_at IS NULL;
