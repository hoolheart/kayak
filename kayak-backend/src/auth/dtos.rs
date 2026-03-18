//! 认证相关数据传输对象
//!
//! 定义请求和响应的DTO结构

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::{Validate, ValidationError};

/// 用户注册请求
#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    /// 邮箱地址
    #[validate(email(message = "Invalid email format"))]
    pub email: String,

    /// 密码（至少8位，包含大小写字母和数字）
    #[validate(custom(function = validate_password))]
    pub password: String,

    /// 用户名（可选）
    #[validate(length(
        min = 2,
        max = 50,
        message = "Username must be between 2 and 50 characters"
    ))]
    pub username: Option<String>,
}

/// 用户登录请求
#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    /// 邮箱地址
    #[validate(email(message = "Invalid email format"))]
    pub email: String,

    /// 密码
    #[validate(length(min = 1, message = "Password is required"))]
    pub password: String,
}

/// Token刷新请求
#[derive(Debug, Deserialize, Validate)]
pub struct TokenRefreshRequest {
    /// 刷新Token
    #[validate(length(min = 1, message = "Refresh token is required"))]
    pub refresh_token: String,
}

/// Token对响应
#[derive(Debug, Serialize)]
pub struct TokenPair {
    /// 访问Token
    pub access_token: String,
    /// 刷新Token
    pub refresh_token: String,
    /// Token类型
    pub token_type: String,
    /// Access Token过期时间（秒）
    pub expires_in: i64,
}

/// Token响应DTO
#[derive(Debug, Serialize)]
pub struct TokenResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub user: UserAuthInfo,
}

/// 用户认证信息
#[derive(Debug, Serialize)]
pub struct UserAuthInfo {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
}

impl From<crate::models::entities::user::User> for UserAuthInfo {
    fn from(user: crate::models::entities::user::User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            username: user.username,
        }
    }
}

/// 注册用户响应
#[derive(Debug, Serialize)]
pub struct RegisterResponse {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

/// 密码验证函数
fn validate_password(password: &str) -> Result<(), ValidationError> {
    if password.len() < 8 {
        return Err(ValidationError::new(
            "password must be at least 8 characters long",
        ));
    }
    if !password.chars().any(|c| c.is_ascii_uppercase()) {
        return Err(ValidationError::new(
            "password must contain at least one uppercase letter",
        ));
    }
    if !password.chars().any(|c| c.is_ascii_lowercase()) {
        return Err(ValidationError::new(
            "password must contain at least one lowercase letter",
        ));
    }
    if !password.chars().any(|c| c.is_ascii_digit()) {
        return Err(ValidationError::new(
            "password must contain at least one digit",
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_password_validation() {
        // Valid password
        assert!(validate_password("Valid123!").is_ok());
        assert!(validate_password("MyP@ssw0rd").is_ok());

        // Too short
        assert!(validate_password("Short1!").is_err());

        // No uppercase
        assert!(validate_password("lowercase123").is_err());

        // No lowercase
        assert!(validate_password("UPPERCASE123").is_err());

        // No digit
        assert!(validate_password("NoDigitsHere").is_err());
    }

    #[test]
    fn test_register_request_validation() {
        let valid_req = RegisterRequest {
            email: "test@example.com".to_string(),
            password: "Valid123!".to_string(),
            username: Some("testuser".to_string()),
        };
        assert!(valid_req.validate().is_ok());

        let invalid_email = RegisterRequest {
            email: "invalid-email".to_string(),
            password: "Valid123!".to_string(),
            username: None,
        };
        assert!(invalid_email.validate().is_err());
    }
}
