-- Migration: Add owner_type and owner_id to experiments table
-- Strategy: Three-step safe migration
-- Created: 2026-05-11

PRAGMA foreign_keys = ON;

-- Step 1: Add columns allowing NULL (backward compatible)
ALTER TABLE experiments ADD COLUMN owner_type TEXT;
ALTER TABLE experiments ADD COLUMN owner_id TEXT;

-- Step 2: Backfill existing data
-- All existing experiments are personal resources owned by the user who created them
UPDATE experiments
SET owner_type = 'personal',
    owner_id = user_id
WHERE owner_type IS NULL;

-- Step 3: Recreate table with constraints (SQLite doesn't support ALTER TABLE ADD CONSTRAINT)
CREATE TABLE experiments_new (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    method_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE', 'RUNNING', 'PAUSED', 'COMPLETED', 'ABORTED')),
    owner_type TEXT NOT NULL CHECK (owner_type IN ('personal', 'team')),
    owner_id TEXT NOT NULL,
    started_at TEXT,
    ended_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (method_id) REFERENCES methods(id)
);

-- Copy data
INSERT INTO experiments_new
SELECT id, user_id, method_id, name, description, status,
       owner_type, owner_id, started_at, ended_at, created_at, updated_at
FROM experiments;

-- Drop old table and rename
DROP TABLE experiments;
ALTER TABLE experiments_new RENAME TO experiments;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_experiments_user_id ON experiments(user_id);
CREATE INDEX IF NOT EXISTS idx_experiments_status ON experiments(status);
CREATE INDEX IF NOT EXISTS idx_experiments_started_at ON experiments(started_at);
CREATE INDEX IF NOT EXISTS idx_experiments_method_id ON experiments(method_id);
CREATE INDEX IF NOT EXISTS idx_experiments_owner ON experiments(owner_type, owner_id);
