-- Migration: Normalize workbenches owner_type from 'user' to 'personal'
-- Created: 2026-05-11
-- Fixes HI-004: Inconsistent owner_type values across tables

PRAGMA foreign_keys = ON;

-- Update existing workbenches to use 'personal' instead of 'user'
UPDATE workbenches SET owner_type = 'personal' WHERE owner_type = 'user';

-- Note: SQLite does not support ALTER TABLE to modify CHECK constraints.
-- The application layer and new inserts should use 'personal'/'team'.
-- For existing tables, the CHECK constraint allows both 'user' and 'team'.
