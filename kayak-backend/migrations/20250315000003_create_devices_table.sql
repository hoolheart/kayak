-- Migration: Create devices table
-- Created: 2026-03-15

-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Create devices table
CREATE TABLE devices (
    id TEXT PRIMARY KEY,                                    -- UUID主键
    workbench_id TEXT NOT NULL,                             -- 所属工作台ID
    parent_id TEXT,                                         -- 父设备ID（支持嵌套）
    name TEXT NOT NULL,                                     -- 设备名称
    protocol_type TEXT NOT NULL,                            -- 协议类型
    protocol_params TEXT,                                   -- 协议参数（JSON格式）
    address TEXT,                                           -- 设备地址/连接信息
    serial_number TEXT,                                     -- 序列号
    manufacturer TEXT,                                      -- 制造商
    description TEXT,                                       -- 设备描述
    status TEXT DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'error', 'maintenance')),  -- 设备状态
    created_at TEXT NOT NULL,                               -- 创建时间
    updated_at TEXT NOT NULL,                               -- 更新时间
    FOREIGN KEY (workbench_id) REFERENCES workbenches(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES devices(id) ON DELETE CASCADE
);

-- Create indexes for devices
CREATE INDEX idx_devices_workbench ON devices(workbench_id);
CREATE INDEX idx_devices_parent ON devices(parent_id);
CREATE INDEX idx_devices_protocol ON devices(protocol_type);
