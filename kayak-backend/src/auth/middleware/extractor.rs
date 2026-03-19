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
    use axum::http::Request;

    fn create_parts_with_auth(auth_value: &str) -> Parts {
        let request = Request::builder()
            .uri("/test")
            .header(header::AUTHORIZATION, auth_value)
            .body(())
            .unwrap();
        request.into_parts().0
    }

    fn create_empty_parts() -> Parts {
        let request = Request::builder().uri("/test").body(()).unwrap();
        request.into_parts().0
    }

    #[test]
    fn test_bearer_token_extraction_success() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_parts_with_auth("Bearer valid_token_123");
        assert_eq!(
            extractor.extract(&mut parts),
            Some("valid_token_123".to_string())
        );
    }

    #[test]
    fn test_bearer_token_extraction_lowercase() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_parts_with_auth("bearer lowercase_token");
        assert_eq!(
            extractor.extract(&mut parts),
            Some("lowercase_token".to_string())
        );
    }

    #[test]
    fn test_bearer_token_extraction_no_bearer_prefix() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_parts_with_auth("Basic dXNlcjpwYXNz");
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_empty_token() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_parts_with_auth("Bearer ");
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_no_space() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_parts_with_auth("Bearertoken_without_space");
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_missing_header() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_empty_parts();
        assert_eq!(extractor.extract(&mut parts), None);
    }

    #[test]
    fn test_bearer_token_extraction_with_whitespace() {
        let extractor = BearerTokenExtractor;
        let mut parts = create_parts_with_auth("Bearer  token_with_spaces  ");
        assert_eq!(
            extractor.extract(&mut parts),
            Some("token_with_spaces".to_string())
        );
    }

    #[test]
    fn test_composite_token_extractor_empty() {
        let extractor = CompositeTokenExtractor::new();
        let mut parts = create_empty_parts();
        assert_eq!(extractor.extract(&mut parts), None);
    }
}
