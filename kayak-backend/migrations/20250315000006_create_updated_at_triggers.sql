-- Migration: Create updated_at triggers
-- Created: 2026-03-15

-- users table trigger
CREATE TRIGGER update_users_timestamp 
AFTER UPDATE ON users
BEGIN
    UPDATE users SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- workbenches table trigger
CREATE TRIGGER update_workbenches_timestamp 
AFTER UPDATE ON workbenches
BEGIN
    UPDATE workbenches SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- devices table trigger
CREATE TRIGGER update_devices_timestamp 
AFTER UPDATE ON devices
BEGIN
    UPDATE devices SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- points table trigger
CREATE TRIGGER update_points_timestamp 
AFTER UPDATE ON points
BEGIN
    UPDATE points SET updated_at = datetime('now') WHERE id = NEW.id;
END;

-- data_files table trigger
CREATE TRIGGER update_data_files_timestamp 
AFTER UPDATE ON data_files
BEGIN
    UPDATE data_files SET updated_at = datetime('now') WHERE id = NEW.id;
END;
