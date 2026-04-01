-- 创建方法表
CREATE TABLE IF NOT EXISTS methods (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    process_definition TEXT NOT NULL,
    parameter_schema TEXT NOT NULL,
    version INTEGER DEFAULT 1,
    created_by TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_methods_created_by ON methods(created_by);
CREATE INDEX IF NOT EXISTS idx_methods_created_at ON methods(created_at);
