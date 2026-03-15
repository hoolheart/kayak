//! 用户实体模型
//!
//! 定义用户表的数据结构和相关枚举

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt::Display;
use uuid::Uuid;

/// 用户账户状态枚举
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum UserStatus {
    /// 正常激活状态
    #[default]
    Active,
    /// 已禁用
    Inactive,
    /// 已封禁
    Banned,
}

impl Display for UserStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserStatus::Active => write!(f, "active"),
            UserStatus::Inactive => write!(f, "inactive"),
            UserStatus::Banned => write!(f, "banned"),
        }
    }
}

impl From<String> for UserStatus {
    fn from(s: String) -> Self {
        match s.as_str() {
            "active" => UserStatus::Active,
            "inactive" => UserStatus::Inactive,
            "banned" => UserStatus::Banned,
            _ => UserStatus::Active,
        }
    }
}

/// 用户实体
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    /// 用户ID (UUID)
    pub id: Uuid,
    /// 邮箱地址
    pub email: String,
    /// bcrypt密码哈希
    pub password_hash: String,
    /// 显示名称
    pub username: Option<String>,
    /// 头像URL
    pub avatar_url: Option<String>,
    /// 账户状态
    pub status: String,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl User {
    /// 创建新用户
    pub fn new(email: String, password_hash: String, username: Option<String>) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            email,
            password_hash,
            username,
            avatar_url: None,
            status: UserStatus::Active.to_string(),
            created_at: now,
            updated_at: now,
        }
    }
}

/// 创建用户请求DTO
#[derive(Debug, Deserialize)]
pub struct CreateUserRequest {
    pub email: String,
    pub password_hash: String,
    pub username: Option<String>,
}

/// 更新用户请求DTO
#[derive(Debug, Deserialize, Default)]
pub struct UpdateUserRequest {
    pub username: Option<String>,
    pub avatar_url: Option<String>,
    pub status: Option<UserStatus>,
}

/// 用户响应DTO
#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub avatar_url: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            username: user.username,
            avatar_url: user.avatar_url,
            status: user.status,
            created_at: user.created_at,
            updated_at: user.updated_at,
        }
    }
}
