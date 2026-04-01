-- Migration: Create experiments table
-- Created: 2026-04-01

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Create experiments table
CREATE TABLE IF NOT EXISTS experiments (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    method_id TEXT,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE', 'RUNNING', 'PAUSED', 'COMPLETED', 'ABORTED')),
    started_at TEXT,
    ended_at TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (method_id) REFERENCES methods(id)
);

-- Create indexes for experiments
CREATE INDEX IF NOT EXISTS idx_experiments_user_id ON experiments(user_id);
CREATE INDEX IF NOT EXISTS idx_experiments_status ON experiments(status);
CREATE INDEX IF NOT EXISTS idx_experiments_started_at ON experiments(started_at);
CREATE INDEX IF NOT EXISTS idx_experiments_method_id ON experiments(method_id);
