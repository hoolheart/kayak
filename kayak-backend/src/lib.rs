//! Kayak Backend - 科学研究支持平台后端
//!
//! 提供试验设备管理、试验过程控制、数据采集和存储等功能。

pub mod api {
    pub mod handlers;
    pub mod middleware;
    pub mod routes;
}

pub mod core {
    pub mod config;
    pub mod error;
    pub mod log;
    pub mod result;
}

pub mod auth;
pub mod db;
pub mod models;
pub mod services;

#[cfg(test)]
pub mod test_utils;

// 重新导出常用类型
pub use core::error::AppError;
pub use core::config::AppConfig;
