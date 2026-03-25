//! 认证服务接口定义
//!
//! 定义认证相关的trait接口，遵循依赖倒置原则

use super::dtos::{LoginRequest, RegisterRequest, TokenRefreshRequest};
use crate::core::error::AppError;
use crate::models::entities::user::User;
use async_trait::async_trait;

/// 认证服务接口
#[async_trait]
pub trait AuthService: Send + Sync {
    /// 用户注册
    async fn register(&self, req: RegisterRequest) -> Result<User, AppError>;

    /// 用户登录
    async fn login(&self, req: LoginRequest) -> Result<LoginResponse, AppError>;

    /// 刷新Token
    async fn refresh_token(&self, req: TokenRefreshRequest) -> Result<LoginResponse, AppError>;

    /// 用户登出
    async fn logout(&self, user_id: uuid::Uuid) -> Result<(), AppError>;
}

/// 登录响应
#[derive(Debug, Clone)]
pub struct LoginResponse {
    pub user_id: uuid::Uuid,
    pub email: String,
    pub username: Option<String>,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

/// Token服务接口
#[async_trait]
pub trait TokenService: Send + Sync {
    /// 生成Token对
    fn generate_token_pair(&self, user_id: uuid::Uuid, email: &str) -> Result<TokenPair, AppError>;

    /// 验证Access Token
    fn verify_access_token(&self, token: &str) -> Result<TokenClaims, AppError>;

    /// 验证Refresh Token
    fn verify_refresh_token(&self, token: &str) -> Result<TokenClaims, AppError>;
}

/// Token对
#[derive(Debug, Clone)]
pub struct TokenPair {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
}

/// Token声明
#[derive(Debug, Clone)]
pub struct TokenClaims {
    pub sub: uuid::Uuid,
    pub email: String,
    pub token_type: TokenType,
    pub exp: i64,
    pub iat: i64,
}

/// Token类型
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TokenType {
    Access,
    Refresh,
}

/// 密码哈希服务接口
pub trait PasswordHasher: Send + Sync {
    /// 哈希密码
    fn hash_password(&self, password: &str) -> Result<String, AppError>;

    /// 验证密码
    fn verify_password(&self, password: &str, hash: &str) -> Result<bool, AppError>;
}

/// 用户仓库接口
#[async_trait]
pub trait UserRepository: Send + Sync {
    /// 根据邮箱查找用户
    async fn find_by_email(&self, email: &str) -> Result<Option<User>, AppError>;

    /// 根据ID查找用户
    async fn find_by_id(&self, id: uuid::Uuid) -> Result<Option<User>, AppError>;

    /// 创建用户
    async fn create(&self, user: &User) -> Result<(), AppError>;

    /// 更新用户
    async fn update(&self, user: &User) -> Result<(), AppError>;
}
