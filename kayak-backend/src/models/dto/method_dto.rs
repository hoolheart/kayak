//! 试验方法DTO
//!
//! 定义试验方法的请求和响应数据结构

use crate::models::entities::Method;
use serde::{Deserialize, Serialize};

/// 创建方法请求DTO
#[derive(Debug, Clone, Deserialize)]
pub struct CreateMethodRequest {
    pub name: String,
    pub description: Option<String>,
    pub process_definition: serde_json::Value,
    pub parameter_schema: serde_json::Value,
}

/// 更新方法请求DTO
#[derive(Debug, Clone, Deserialize)]
pub struct UpdateMethodRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub process_definition: Option<serde_json::Value>,
    pub parameter_schema: Option<serde_json::Value>,
}

/// 方法响应DTO
#[derive(Debug, Clone, Serialize)]
pub struct MethodDto {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub process_definition: serde_json::Value,
    pub parameter_schema: serde_json::Value,
    pub version: i32,
    pub created_by: String,
    pub created_at: String,
    pub updated_at: String,
}

impl From<Method> for MethodDto {
    fn from(method: Method) -> Self {
        Self {
            id: method.id.to_string(),
            name: method.name,
            description: method.description,
            process_definition: method.process_definition,
            parameter_schema: method.parameter_schema,
            version: method.version,
            created_by: method.created_by.to_string(),
            created_at: method.created_at.to_rfc3339(),
            updated_at: method.updated_at.to_rfc3339(),
        }
    }
}

/// 方法列表响应DTO
#[derive(Debug, Clone, Serialize)]
pub struct MethodListResponse {
    pub items: Vec<MethodDto>,
    pub total: i64,
    pub page: i64,
    pub size: i64,
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    #[test]
    fn test_method_dto_from_method() {
        let method = Method::new(
            "测试方法".to_string(),
            Some("描述".to_string()),
            serde_json::json!({"steps": []}),
            serde_json::json!({"type": "object"}),
            Uuid::new_v4(),
        );

        let dto: MethodDto = method.clone().into();

        assert_eq!(dto.name, method.name);
        assert_eq!(dto.description, method.description);
        assert_eq!(dto.version, method.version);
        assert_eq!(dto.id, method.id.to_string());
    }
}
