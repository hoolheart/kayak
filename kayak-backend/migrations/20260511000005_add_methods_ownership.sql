-- Migration: Add owner_type and owner_id to methods table
-- Created: 2026-05-11
-- Fixes CR-001: methods table missing ownership columns

PRAGMA foreign_keys = ON;

-- Add ownership columns to methods table
ALTER TABLE methods ADD COLUMN owner_type TEXT DEFAULT 'personal' CHECK (owner_type IN ('personal', 'team'));
ALTER TABLE methods ADD COLUMN owner_id TEXT;

-- Backfill existing data: set owner_id to created_by
UPDATE methods SET owner_id = created_by WHERE owner_id IS NULL;

-- Create index for ownership queries
CREATE INDEX IF NOT EXISTS idx_methods_owner ON methods(owner_type, owner_id);
