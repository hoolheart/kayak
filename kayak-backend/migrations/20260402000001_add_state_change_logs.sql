-- Migration: Add state change logs table and LOADED status
-- Created: 2026-04-02
-- Task: S2-008 Experiment Process State Machine

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- 1. Create state_change_logs table
CREATE TABLE IF NOT EXISTS state_change_logs (
    id TEXT PRIMARY KEY NOT NULL,
    experiment_id TEXT NOT NULL,
    previous_state TEXT NOT NULL,
    new_state TEXT NOT NULL,
    operation TEXT NOT NULL,
    user_id TEXT NOT NULL,
    timestamp TEXT NOT NULL DEFAULT (datetime('now')),
    error_message TEXT,
    FOREIGN KEY (experiment_id) REFERENCES experiments(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create indexes for state_change_logs
CREATE INDEX IF NOT EXISTS idx_state_change_logs_experiment_id 
    ON state_change_logs(experiment_id);
CREATE INDEX IF NOT EXISTS idx_state_change_logs_timestamp 
    ON state_change_logs(timestamp DESC);

-- 2. Update experiments table to include 'LOADED' in status CHECK constraint
-- SQLite doesn't support ALTER TABLE for CHECK constraints, so we recreate the table.

BEGIN TRANSACTION;

-- Create new table with updated constraint
CREATE TABLE experiments_new (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    method_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE', 'LOADED', 'RUNNING', 'PAUSED', 'COMPLETED', 'ABORTED')),
    started_at TEXT,
    ended_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (method_id) REFERENCES methods(id)
);

-- Copy data from old table
INSERT INTO experiments_new (id, user_id, method_id, name, description, status, started_at, ended_at, created_at, updated_at)
SELECT id, user_id, method_id, name, description, status, started_at, ended_at, created_at, updated_at
FROM experiments;

-- Drop old table
DROP TABLE experiments;

-- Rename new table to experiments
ALTER TABLE experiments_new RENAME TO experiments;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_experiments_user_id ON experiments(user_id);
CREATE INDEX IF NOT EXISTS idx_experiments_status ON experiments(status);
CREATE INDEX IF NOT EXISTS idx_experiments_started_at ON experiments(started_at);
CREATE INDEX IF NOT EXISTS idx_experiments_method_id ON experiments(method_id);

COMMIT;
