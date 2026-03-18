//! JWT认证中间件层实现
//!
//! 提供Tower Layer和Service实现，用于Axum路由的认证保护
//!
//! # 主要组件
//!
//! - `JwtAuthMiddleware`: 中间件核心实现
//! - `AuthLayer`: Tower Layer实现
//! - `AuthMiddlewareService`: Tower Service实现
//!
//! # 使用示例
//!
//! ```rust
//! use std::sync::Arc;
//! use kayak_backend::auth::middleware::{JwtAuthMiddleware, AuthLayer};
//! use kayak_backend::auth::services::JwtTokenService;
//!
//! let token_service = Arc::new(JwtTokenService::new(
//!     "access_secret".to_string(),
//!     "refresh_secret".to_string(),
//! ));
//!
//! let middleware = JwtAuthMiddleware::new(token_service);
//! let layer = AuthLayer::new(middleware);
//! ```

use std::convert::Infallible;
use std::sync::Arc;
use std::task::{Context, Poll};

use axum::body::Body;
use axum::extract::Request;
use axum::http::StatusCode;
use axum::response::Response;
use futures::future::BoxFuture;
use tower::{Layer, Service};

use crate::auth::middleware::context::UserContext;
use crate::auth::middleware::extractor::BearerTokenExtractor;
use crate::auth::middleware::traits::{AuthMiddleware, TokenExtractor};
use crate::auth::traits::TokenService;
use crate::core::error::AppError;

/// JWT认证中间件实现
///
/// 核心中间件结构，包含Token服务和Token提取器配置
///
/// # 字段
///
/// - `token_service`: Token服务，用于验证Token有效性
/// - `extractor`: Token提取器，从请求中提取Token
/// - `allow_anonymous`: 是否允许匿名访问
///
/// # 示例
///
/// ```rust
/// use std::sync::Arc;
/// use kayak_backend::auth::middleware::JwtAuthMiddleware;
///
/// let middleware = JwtAuthMiddleware::new(token_service)
///     .allow_anonymous(false);
/// ```
#[derive(Clone)]
pub struct JwtAuthMiddleware {
    token_service: Arc<dyn TokenService>,
    extractor: Arc<dyn TokenExtractor>,
    allow_anonymous: bool,
}

impl JwtAuthMiddleware {
    /// 创建新的认证中间件
    ///
    /// # Arguments
    /// * `token_service` - Token服务，用于验证Token
    ///
    /// # 默认配置
    /// - Token提取器: BearerTokenExtractor
    /// - 允许匿名: false
    pub fn new(token_service: Arc<dyn TokenService>) -> Self {
        Self {
            token_service,
            extractor: Arc::new(BearerTokenExtractor),
            allow_anonymous: false,
        }
    }

    /// 设置Token提取器
    ///
    /// # Arguments
    /// * `extractor` - 自定义Token提取器
    pub fn with_extractor(mut self, extractor: Arc<dyn TokenExtractor>) -> Self {
        self.extractor = extractor;
        self
    }

    /// 设置是否允许匿名访问
    ///
    /// # Arguments
    /// * `allow` - true表示允许匿名访问，false表示需要认证
    pub fn allow_anonymous(mut self, allow: bool) -> Self {
        self.allow_anonymous = allow;
        self
    }

    /// 执行认证逻辑
    ///
    /// 验证Token并返回用户上下文
    ///
    /// # Arguments
    /// * `token` - JWT Token字符串
    ///
    /// # Returns
    /// * `Ok(UserContext)` - 认证成功，返回用户上下文
    /// * `Err(AppError)` - 认证失败
    pub async fn authenticate(&self, token: &str) -> Result<UserContext, AppError> {
        let claims = self.token_service.verify_access_token(token)?;

        Ok(UserContext {
            user_id: claims.sub,
            email: claims.email,
        })
    }
}

impl AuthMiddleware for JwtAuthMiddleware {
    async fn authenticate(&self, token: &str) -> Result<UserContext, AppError> {
        let claims = self.token_service.verify_access_token(token)?;
        Ok(UserContext {
            user_id: claims.sub,
            email: claims.email,
        })
    }
}

/// Tower Layer实现
///
/// 用于将认证中间件应用到Axum路由
///
/// # 使用示例
///
/// ```rust
/// use kayak_backend::auth::middleware::AuthLayer;
///
/// let layer = AuthLayer::new(middleware);
/// router.layer(layer)
/// ```
#[derive(Clone)]
pub struct AuthLayer {
    middleware: JwtAuthMiddleware,
}

impl AuthLayer {
    /// 创建新的认证层
    ///
    /// # Arguments
    /// * `middleware` - JWT认证中间件实例
    pub fn new(middleware: JwtAuthMiddleware) -> Self {
        Self { middleware }
    }
}

impl<S> Layer<S> for AuthLayer {
    type Service = AuthMiddlewareService<S>;

    fn layer(&self, inner: S) -> Self::Service {
        AuthMiddlewareService {
            inner,
            middleware: self.middleware.clone(),
        }
    }
}

/// Tower Service实现
///
/// 包装内部服务，在调用前执行认证
///
/// # 认证流程
///
/// 1. 从请求中提取Token
/// 2. 验证Token有效性
/// 3. 认证成功：注入用户上下文，调用内部服务
/// 4. 认证失败：返回401 Unauthorized响应
#[derive(Clone)]
pub struct AuthMiddlewareService<S> {
    inner: S,
    middleware: JwtAuthMiddleware,
}

impl<S> Service<Request> for AuthMiddlewareService<S>
where
    S: Service<Request, Response = Response, Error = Infallible> + Clone + Send + 'static,
    S::Future: Send + 'static,
{
    type Response = Response;
    type Error = Infallible;
    type Future = BoxFuture<'static, Result<Self::Response, Self::Error>>;

    fn poll_ready(&mut self, cx: &mut Context<'_>) -> Poll<Result<(), Self::Error>> {
        self.inner.poll_ready(cx)
    }

    fn call(&mut self, mut request: Request) -> Self::Future {
        // Clone the inner service and middleware for the async block
        let inner = self.inner.clone();
        let middleware = self.middleware.clone();

        Box::pin(async move {
            // 提取Token
            let (mut parts, body) = request.into_parts();
            let token = middleware.extractor.extract(&mut parts);

            match token {
                Some(token) => {
                    // 验证Token
                    match middleware.authenticate(&token).await {
                        Ok(user_context) => {
                            // 注入用户上下文
                            parts.extensions.insert(user_context);
                            let request = Request::from_parts(parts, body);
                            inner.call(request).await
                        }
                        Err(err) => {
                            // 认证失败，返回401（带WWW-Authenticate头）
                            Ok(create_unauthorized_response(err))
                        }
                    }
                }
                None => {
                    if middleware.allow_anonymous {
                        // 允许匿名访问
                        let request = Request::from_parts(parts, body);
                        inner.call(request).await
                    } else {
                        // 需要认证，返回401（带WWW-Authenticate头）
                        Ok(create_unauthorized_response(
                            AppError::Unauthorized(
                                "Missing authentication token".to_string()
                            )
                        ))
                    }
                }
            }
        })
    }
}

/// 创建401 Unauthorized响应（符合RFC 6750）
///
/// 包含WWW-Authenticate头部和JSON错误体
///
/// # Arguments
/// * `err` - 应用错误
///
/// # Returns
/// HTTP响应，状态码401，包含JSON错误体和WWW-Authenticate头
fn create_unauthorized_response(err: AppError) -> Response {
    use axum::body::Body;
    use axum::response::IntoResponse;
    use serde_json::json;

    let body = Body::from(
        json!({
            "code": 401,
            "message": err.to_string()
        })
        .to_string()
    );

    Response::builder()
        .status(StatusCode::UNAUTHORIZED)
        .header("WWW-Authenticate", "Bearer")
        .header("Content-Type", "application/json")
        .body(body)
        .unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::{header, Request, StatusCode};
    use tower::ServiceExt;

    /// 创建一个模拟的Token服务用于测试
    fn create_mock_token_service() -> Arc<dyn TokenService> {
        // 这里使用实际的JwtTokenService，但使用测试密钥
        use crate::auth::services::JwtTokenService;
        Arc::new(JwtTokenService::new(
            "test_access_secret_key_that_is_at_least_32_bytes_long".to_string(),
            "test_refresh_secret_key_that_is_at_least_32_bytes_long".to_string(),
        ))
    }

    #[tokio::test]
    async fn test_jwt_middleware_new() {
        let token_service = create_mock_token_service();
        let middleware = JwtAuthMiddleware::new(token_service);

        assert!(!middleware.allow_anonymous);
    }

    #[tokio::test]
    async fn test_jwt_middleware_allow_anonymous() {
        let token_service = create_mock_token_service();
        let middleware = JwtAuthMiddleware::new(token_service)
            .allow_anonymous(true);

        assert!(middleware.allow_anonymous);
    }

    #[tokio::test]
    async fn test_missing_token_returns_401() {
        let token_service = create_mock_token_service();
        let middleware = JwtAuthMiddleware::new(token_service);
        let layer = AuthLayer::new(middleware);

        // 创建一个简单的handler
        let handler = || async { 
            Ok::<_, Infallible>(
                Response::builder()
                    .status(StatusCode::OK)
                    .body(Body::from("success"))
                    .unwrap()
            )
        };

        let mut service = layer.layer(handler);

        let request = Request::builder()
            .uri("/test")
            .body(Body::empty())
            .unwrap();

        let response = service.ready().await.unwrap().call(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
        
        // 验证WWW-Authenticate头
        let www_auth = response.headers().get("WWW-Authenticate");
        assert!(www_auth.is_some());
        assert_eq!(www_auth.unwrap(), "Bearer");
    }

    #[tokio::test]
    async fn test_allow_anonymous_allows_missing_token() {
        let token_service = create_mock_token_service();
        let middleware = JwtAuthMiddleware::new(token_service)
            .allow_anonymous(true);
        let layer = AuthLayer::new(middleware);

        let handler = || async { 
            Ok::<_, Infallible>(
                Response::builder()
                    .status(StatusCode::OK)
                    .body(Body::from("success"))
                    .unwrap()
            )
        };

        let mut service = layer.layer(handler);

        let request = Request::builder()
            .uri("/test")
            .body(Body::empty())
            .unwrap();

        let response = service.ready().await.unwrap().call(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
    }

    #[tokio::test]
    async fn test_invalid_token_returns_401() {
        let token_service = create_mock_token_service();
        let middleware = JwtAuthMiddleware::new(token_service);
        let layer = AuthLayer::new(middleware);

        let handler = || async { 
            Ok::<_, Infallible>(
                Response::builder()
                    .status(StatusCode::OK)
                    .body(Body::from("success"))
                    .unwrap()
            )
        };

        let mut service = layer.layer(handler);

        let request = Request::builder()
            .uri("/test")
            .header(header::AUTHORIZATION, "Bearer invalid_token")
            .body(Body::empty())
            .unwrap();

        let response = service.ready().await.unwrap().call(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
    }

    #[test]
    fn test_create_unauthorized_response() {
        let err = AppError::Unauthorized("Test error".to_string());
        let response = create_unauthorized_response(err);

        assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
        assert_eq!(
            response.headers().get("WWW-Authenticate").unwrap(),
            "Bearer"
        );
        assert_eq!(
            response.headers().get("Content-Type").unwrap(),
            "application/json"
        );
    }
}
