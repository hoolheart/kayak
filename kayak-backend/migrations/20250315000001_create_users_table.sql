-- Migration: Create users table
-- Created: 2026-03-15

-- Create users table
CREATE TABLE users (
    id TEXT PRIMARY KEY,                                    -- UUID主键
    email TEXT NOT NULL UNIQUE,                             -- 邮箱，唯一标识
    password_hash TEXT NOT NULL,                            -- bcrypt密码哈希
    username TEXT,                                          -- 显示名称
    avatar_url TEXT,                                        -- 头像URL
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),  -- 账户状态
    created_at TEXT NOT NULL,                               -- 创建时间 (ISO 8601)
    updated_at TEXT NOT NULL                                -- 更新时间 (ISO 8601)
);

-- Create email index for faster login lookups
CREATE INDEX idx_users_email ON users(email);
