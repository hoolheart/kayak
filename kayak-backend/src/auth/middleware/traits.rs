//! 认证中间件接口定义
//!
//! 定义JWT认证中间件的抽象行为，便于测试和扩展
//! 遵循依赖倒置原则（DIP）

use axum::http::request::Parts;

/// 认证中间件核心接口
///
/// 定义JWT认证中间件的抽象行为，便于测试和扩展
///
/// # 实现要求
///
/// 1. Clone: 中间件可能在多个请求间共享
/// 2. Send + Sync: 异步运行时要求
/// 3. 'static: 可能在异步上下文中使用
pub trait AuthMiddleware: Clone + Send + Sync + 'static {
    /// 验证Token并返回用户上下文
    ///
    /// # Arguments
    /// * `token` - JWT Token字符串（不含Bearer前缀）
    ///
    /// # Returns
    /// * `Ok(UserContext)` - 验证成功，返回用户上下文
    /// * `Err(AuthError)` - 验证失败
    fn authenticate(
        &self,
        token: &str,
    ) -> impl std::future::Future<
        Output = Result<super::context::UserContext, crate::core::error::AppError>,
    > + Send;
}

/// Token提取器接口
///
/// 从HTTP请求中提取Token，支持不同提取策略
///
/// # 实现要求
///
/// 需要实现Clone以便中间件可以安全地在多个请求间共享
pub trait TokenExtractor: Send + Sync {
    /// 从请求中提取Token
    ///
    /// # Returns
    /// * `Some(String)` - 提取到Token
    /// * `None` - 未找到Token
    fn extract(&self, parts: &mut Parts) -> Option<String>;
}

impl Clone for Box<dyn TokenExtractor> {
    fn clone(&self) -> Self {
        // This is a workaround for cloning boxed trait objects
        // In practice, implementations should be cloneable
        panic!("TokenExtractor implementations must use concrete types for cloning")
    }
}

/// 认证配置接口
///
/// 定义认证中间件的行为配置
pub trait AuthConfig: Send + Sync {
    /// 是否允许匿名访问（可选认证）
    fn allow_anonymous(&self) -> bool;

    /// 获取WWW-Authenticate响应头值
    fn www_authenticate_header(&self) -> Option<String>;
}
