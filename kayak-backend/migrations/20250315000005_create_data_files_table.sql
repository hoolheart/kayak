-- Migration: Create data_files table
-- Created: 2026-03-15

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Create data_files table
CREATE TABLE data_files (
    id TEXT PRIMARY KEY,                                    -- UUID主键
    file_path TEXT NOT NULL,                                -- 文件存储路径
    file_hash TEXT NOT NULL,                                -- 文件哈希（SHA-256）
    experiment_id TEXT,                                     -- 关联试验ID（可选）
    source_type TEXT CHECK (source_type IN ('experiment', 'analysis', 'import')),  -- 来源类型
    owner_type TEXT DEFAULT 'user' CHECK (owner_type IN ('user', 'team')),  -- 所有者类型
    owner_id TEXT NOT NULL,                                 -- 所有者ID
    data_size_bytes INTEGER,                                -- 文件大小（字节）
    record_count INTEGER,                                   -- 记录数量
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'deleted')),  -- 状态
    created_at TEXT NOT NULL,                               -- 创建时间
    updated_at TEXT NOT NULL,                               -- 更新时间
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Create indexes for data_files
CREATE INDEX idx_data_files_owner ON data_files(owner_id, owner_type);
CREATE INDEX idx_data_files_experiment ON data_files(experiment_id);
CREATE INDEX idx_data_files_status ON data_files(status);
