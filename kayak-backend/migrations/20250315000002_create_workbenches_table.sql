-- Migration: Create workbenches table
-- Created: 2026-03-15

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Create workbenches table
CREATE TABLE workbenches (
    id TEXT PRIMARY KEY,                                    -- UUID主键
    name TEXT NOT NULL,                                     -- 工作台名称
    description TEXT,                                       -- 描述
    owner_id TEXT NOT NULL,                                 -- 所有者ID
    owner_type TEXT DEFAULT 'user' CHECK (owner_type IN ('user', 'team')),  -- 所有者类型
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),  -- 状态
    created_at TEXT NOT NULL,                               -- 创建时间
    updated_at TEXT NOT NULL,                               -- 更新时间
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for workbenches
CREATE INDEX idx_workbenches_owner ON workbenches(owner_id, owner_type);
CREATE INDEX idx_workbenches_status ON workbenches(status);
