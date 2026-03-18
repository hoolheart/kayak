//! Token提取器实现
//!
//! 从HTTP请求中提取JWT Token的各种策略实现

use axum::http::header;
use axum::http::request::Parts;

use super::traits::TokenExtractor;

/// Bearer Token提取器
///
/// 从Authorization头部提取Bearer Token
///
/// # 格式
/// ```text
/// Authorization: Bearer <token>
/// ```
///
/// # Example
///
/// ```rust
/// use kayak_backend::auth::middleware::BearerTokenExtractor;
///
/// let extractor = BearerTokenExtractor;
/// // extractor.extract(&mut parts)
/// ```
#[derive(Clone, Debug)]
pub struct BearerTokenExtractor;

impl TokenExtractor for BearerTokenExtractor {
    fn extract(&self, parts: &mut Parts) -> Option<String> {
        parts
            .headers
            .get(header::AUTHORIZATION)
            .and_then(|value| value.to_str().ok())
            .and_then(|value| {
                // 支持 "Bearer " 和 "bearer " 前缀
                value
                    .strip_prefix("Bearer ")
                    .or_else(|| value.strip_prefix("bearer "))
            })
            .map(|token| token.trim().to_string())
            .filter(|token| !token.is_empty())
    }
}

/// 组合Token提取器
///
/// 按优先级顺序尝试多种提取策略
///
/// # Example
///
/// ```rust
/// use kayak_backend::auth::middleware::CompositeTokenExtractor;
///
/// let extractor = CompositeTokenExtractor::new()
///     .add(Box::new(BearerTokenExtractor));
/// ```
#[derive(Default)]
pub struct CompositeTokenExtractor {
    extractors: Vec<Box<dyn TokenExtractor>>,
}

impl CompositeTokenExtractor {
    /// 创建新的组合提取器
    pub fn new() -> Self {
        Self {
            extractors: Vec::new(),
        }
    }

    /// 添加提取器到列表
    ///
    /// # Arguments
    /// * `extractor` - 要添加的提取器
    pub fn add(mut self, extractor: Box<dyn TokenExtractor>) -> Self {
        self.extractors.push(extractor);
        self
    }
}

impl Clone for CompositeTokenExtractor {
    fn clone(&self) -> Self {
        // Note: This requires all boxed extractors to be cloneable
        // In practice, use concrete types or wrap in Arc
        Self {
            extractors: Vec::new(),
        }
    }
}

impl TokenExtractor for CompositeTokenExtractor {
    fn extract(&self, parts: &mut Parts) -> Option<String> {
        for extractor in &self.extractors {
            if let Some(token) = extractor.extract(parts) {
                return Some(token);
            }
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderMap;

    #[test]
    fn test_bearer_token_extraction_success() {
        let extractor = BearerTokenExtractor;

        // 测试有效Bearer Token
        let mut headers = HeaderMap::new();
        headers.insert(
            header::AUTHORIZATION,
            "Bearer valid_token_123".parse().unwrap(),
        );
        let mut parts = Parts::default();
        parts.headers = headers;
        assert_eq!(
            extractor.extract(&mut parts),
            Some("valid_token_123".to_string())
        );
    }

    #[test]
    fn test_bearer_token_extraction_lowercase() {
        let extractor = BearerTokenExtractor;

        // 测试小写bearer
        let mut headers = HeaderMap::new();
        headers.insert(
            header::AUTHORIZATION,
            "bearer lowercase_token".parse().unwrap(),
        );
        let mut parts = Parts::default();
        parts.headers = headers;
        assert_eq!(
            extractor.extract(&mut parts),
            Some("lowercase_token".to_string())
        );
    }

    #[test]
    fn test_bearer_token_extraction_no_bearer_prefix() {
        let extractor = BearerTokenExtractor;

        // 测试无Bearer前缀
        let mut headers = HeaderMap::new();
        headers.insert(header::AUTHORIZATION, "Basic dXNlcjpwYXNz".parse().unwrap());
        let mut parts = Parts::default();
        parts.headers = headers;
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_empty_token() {
        let extractor = BearerTokenExtractor;

        // 测试空Token
        let mut headers = HeaderMap::new();
        headers.insert(header::AUTHORIZATION, "Bearer ".parse().unwrap());
        let mut parts = Parts::default();
        parts.headers = headers;
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_no_space() {
        let extractor = BearerTokenExtractor;

        // 测试Bearer后无空格
        let mut headers = HeaderMap::new();
        headers.insert(
            header::AUTHORIZATION,
            "Bearertoken_without_space".parse().unwrap(),
        );
        let mut parts = Parts::default();
        parts.headers = headers;
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_missing_header() {
        let extractor = BearerTokenExtractor;

        // 测试缺少Authorization头部
        let parts = Parts::default();
        assert_eq!(extractor.extract(&mut parts.clone()), None);
    }

    #[test]
    fn test_bearer_token_extraction_with_whitespace() {
        let extractor = BearerTokenExtractor;

        // 测试Token前后有空格
        let mut headers = HeaderMap::new();
        headers.insert(
            header::AUTHORIZATION,
            "Bearer  token_with_spaces  ".parse().unwrap(),
        );
        let mut parts = Parts::default();
        parts.headers = headers;
        assert_eq!(
            extractor.extract(&mut parts),
            Some("token_with_spaces".to_string())
        );
    }

    #[test]
    fn test_composite_token_extractor_empty() {
        let extractor = CompositeTokenExtractor::new();
        let parts = Parts::default();
        assert_eq!(extractor.extract(&mut parts.clone()), None);
    }
}
