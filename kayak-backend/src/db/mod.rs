//! 数据库模块
//!
//! 提供数据库连接管理和数据访问层

pub mod connection;
pub mod repository;

pub use connection::{init_db, DbPool};
