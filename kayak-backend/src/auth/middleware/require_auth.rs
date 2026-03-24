use axum::async_trait;
use axum::extract::FromRequestParts;
use axum::http::request::Parts;
use std::ops::Deref;

use super::context::UserContext;
use crate::core::error::AppError;

/// 强制认证提取器
///
/// 用于处理器参数，要求请求必须经过认证。
/// 如果未认证，自动返回401错误。
///
/// # Example
///
/// ```rust,ignore
/// use axum::{Json, extract::Extension};
/// use serde_json::Value;
/// use kayak_backend::auth::{RequireAuth, UserContext};
///
/// async fn profile(
///     RequireAuth(user): RequireAuth,
/// ) -> Json<Value> {
///     Json(json!({"email": user.email}))
/// }
/// ```
pub struct RequireAuth(pub UserContext);

#[async_trait]
impl<S> FromRequestParts<S> for RequireAuth
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        parts
            .extensions
            .get::<UserContext>()
            .cloned()
            .map(RequireAuth)
            .ok_or_else(|| AppError::Unauthorized("Authentication required".to_string()))
    }
}

impl Deref for RequireAuth {
    type Target = UserContext;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

/// 可选认证提取器
///
/// 处理器可以处理已认证和未认证两种情况。
///
/// # Example
///
/// ```rust,ignore
/// use axum::{Json, extract::Extension};
/// use serde_json::Value;
/// use kayak_backend::auth::{OptionalAuth, UserContext};
///
/// async fn public_profile(
///     OptionalAuth(user): OptionalAuth,
/// ) -> Json<Value> {
///     match user {
///         Some(u) => Json(json!({"user": u.email})),
///         None => Json(json!({"user": null})),
///     }
/// }
/// ```
pub struct OptionalAuth(pub Option<UserContext>);

#[async_trait]
impl<S> FromRequestParts<S> for OptionalAuth
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        Ok(OptionalAuth(parts.extensions.get::<UserContext>().cloned()))
    }
}

impl Deref for OptionalAuth {
    type Target = Option<UserContext>;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::Request;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_require_auth_success() {
        let user_id = Uuid::new_v4();
        let user_context = UserContext::new(user_id, "test@example.com");

        let mut parts = Request::builder()
            .uri("/test")
            .body(())
            .unwrap()
            .into_parts()
            .0;

        parts.extensions.insert(user_context.clone());

        let result = RequireAuth::from_request_parts(&mut parts, &()).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().user_id, user_id);
    }

    #[tokio::test]
    async fn test_require_auth_missing() {
        let mut parts = Request::builder()
            .uri("/test")
            .body(())
            .unwrap()
            .into_parts()
            .0;

        let result = RequireAuth::from_request_parts(&mut parts, &()).await;
        assert!(result.is_err());

        match result {
            Err(AppError::Unauthorized(_)) => (), // Expected
            _ => panic!("Expected Unauthorized error"),
        }
    }

    #[tokio::test]
    async fn test_optional_auth_with_user() {
        let user_id = Uuid::new_v4();
        let user_context = UserContext::new(user_id, "test@example.com");

        let mut parts = Request::builder()
            .uri("/test")
            .body(())
            .unwrap()
            .into_parts()
            .0;

        parts.extensions.insert(user_context.clone());

        let result = OptionalAuth::from_request_parts(&mut parts, &()).await;
        assert!(result.is_ok());
        assert!(result.unwrap().0.is_some());
    }

    #[tokio::test]
    async fn test_optional_auth_without_user() {
        let mut parts = Request::builder()
            .uri("/test")
            .body(())
            .unwrap()
            .into_parts()
            .0;

        let result = OptionalAuth::from_request_parts(&mut parts, &()).await;
        assert!(result.is_ok());
        assert!(result.unwrap().0.is_none());
    }

    #[test]
    fn test_require_auth_deref() {
        let user_id = Uuid::new_v4();
        let user_context = UserContext::new(user_id, "test@example.com");
        let require_auth = RequireAuth(user_context);

        // Test Deref
        assert_eq!(require_auth.user_id, user_id);
        assert_eq!(require_auth.email, "test@example.com");
    }

    #[test]
    fn test_optional_auth_deref() {
        let user_id = Uuid::new_v4();
        let user_context = UserContext::new(user_id, "test@example.com");
        let optional_auth = OptionalAuth(Some(user_context));

        // Test Deref
        assert!(optional_auth.is_some());
        assert_eq!(optional_auth.as_ref().unwrap().user_id, user_id);
    }
}
