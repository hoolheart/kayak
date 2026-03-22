//! 用户上下文定义
//!
//! 认证成功后注入到请求Extension中，
//! 包含当前登录用户的基本信息。

use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 用户上下文
///
/// 认证成功后注入到请求Extension中，
/// 包含当前登录用户的基本信息。
///
/// # Example
///
/// ```rust,ignore
/// use axum::extract::Extension;
/// use kayak_backend::auth::UserContext;
///
/// async fn handler(
///     Extension(user_ctx): Extension<UserContext>,
/// ) -> impl IntoResponse {
///     println!("User: {}", user_ctx.email);
/// }
/// ```
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserContext {
    /// 用户ID (UUID)
    pub user_id: Uuid,
    /// 用户邮箱地址
    pub email: String,
}

impl UserContext {
    /// 创建新的用户上下文
    ///
    /// # Arguments
    /// * `user_id` - 用户唯一标识符
    /// * `email` - 用户邮箱地址
    ///
    /// # Example
    ///
    /// ```rust,ignore
    /// use uuid::Uuid;
    /// use kayak_backend::auth::UserContext;
    ///
    /// let user_id = Uuid::new_v4();
    /// let ctx = UserContext::new(user_id, "user@example.com");
    /// ```
    pub fn new(user_id: Uuid, email: impl Into<String>) -> Self {
        Self {
            user_id,
            email: email.into(),
        }
    }
}

impl From<(Uuid, String)> for UserContext {
    fn from((user_id, email): (Uuid, String)) -> Self {
        Self::new(user_id, email)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_user_context_creation() {
        let user_id = Uuid::new_v4();
        let ctx = UserContext::new(user_id, "test@example.com");

        assert_eq!(ctx.user_id, user_id);
        assert_eq!(ctx.email, "test@example.com");
    }

    #[test]
    fn test_user_context_from_tuple() {
        let user_id = Uuid::new_v4();
        let ctx: UserContext = (user_id, "test@example.com".to_string()).into();

        assert_eq!(ctx.user_id, user_id);
        assert_eq!(ctx.email, "test@example.com");
    }

    #[test]
    fn test_user_context_clone() {
        let user_id = Uuid::new_v4();
        let ctx = UserContext::new(user_id, "test@example.com");
        let cloned = ctx.clone();

        assert_eq!(cloned.user_id, ctx.user_id);
        assert_eq!(cloned.email, ctx.email);
    }

    #[test]
    fn test_user_context_serialization() {
        let user_id = Uuid::new_v4();
        let ctx = UserContext::new(user_id, "test@example.com");

        let json = serde_json::to_string(&ctx).unwrap();
        assert!(json.contains(&user_id.to_string()));
        assert!(json.contains("test@example.com"));

        let deserialized: UserContext = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.user_id, user_id);
        assert_eq!(deserialized.email, "test@example.com");
    }
}
