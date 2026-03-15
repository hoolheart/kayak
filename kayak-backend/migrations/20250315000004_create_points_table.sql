-- Migration: Create points table
-- Created: 2026-03-15

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Create points table
CREATE TABLE points (
    id TEXT PRIMARY KEY,                                    -- UUID主键
    device_id TEXT NOT NULL,                                -- 所属设备ID
    name TEXT NOT NULL,                                     -- 测点名称
    data_type TEXT NOT NULL CHECK (data_type IN ('Number', 'Integer', 'String', 'Boolean')),  -- 数据类型
    access_type TEXT NOT NULL CHECK (access_type IN ('RO', 'WO', 'RW')),  -- 访问类型
    unit TEXT,                                              -- 单位（如°C, V, A等）
    description TEXT,                                       -- 测点描述
    min_value REAL,                                         -- 最小值（用于验证）
    max_value REAL,                                         -- 最大值（用于验证）
    default_value TEXT,                                     -- 默认值（JSON格式存储）
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),  -- 状态
    created_at TEXT NOT NULL,                               -- 创建时间
    updated_at TEXT NOT NULL,                               -- 更新时间
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- Create indexes for points
CREATE INDEX idx_points_device ON points(device_id);
CREATE INDEX idx_points_access ON points(access_type);
