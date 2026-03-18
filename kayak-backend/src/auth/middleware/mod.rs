//! JWT认证中间件模块
//!
//! 提供基于JWT Token的认证中间件实现，支持：
//! - 从Authorization头部提取Bearer Token
//! - Token验证（签名、过期时间、声明）
//! - 用户上下文注入到请求Extension
//! - 强制认证和可选认证两种模式
//!
//! # 基本用法
//!
//! ```rust
//! use kayak_backend::auth::middleware::{AuthLayer, JwtAuthMiddleware};
//! use std::sync::Arc;
//!
//! // 创建认证中间件
//! let auth_middleware = JwtAuthMiddleware::new(token_service);
//! let auth_layer = AuthLayer::new(auth_middleware);
//!
//! // 应用到路由
//! let app = Router::new()
//!     .route("/protected", get(protected_handler))
//!     .layer(auth_layer);
//! ```

pub mod context;
pub mod extractor;
pub mod layer;
pub mod require_auth;
pub mod traits;

// 公共导出
pub use context::UserContext;
pub use extractor::{BearerTokenExtractor, CompositeTokenExtractor, TokenExtractor};
pub use layer::{AuthLayer, AuthMiddlewareService, JwtAuthMiddleware};
pub use require_auth::{OptionalAuth, RequireAuth};
pub use traits::{AuthConfig, AuthMiddleware};
