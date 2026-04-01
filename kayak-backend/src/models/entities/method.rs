//! 试验方法实体
//!
//! 定义试验方法的数据结构和相关操作

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 试验方法实体
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Method {
    /// 方法ID (UUID)
    pub id: Uuid,
    /// 方法名称
    pub name: String,
    /// 方法描述
    pub description: Option<String>,
    /// 过程定义 (JSON格式)
    pub process_definition: serde_json::Value,
    /// 参数表Schema (JSON格式)
    pub parameter_schema: serde_json::Value,
    /// 版本号 (预留扩展点)
    pub version: i32,
    /// 创建者用户ID
    pub created_by: Uuid,
    /// 创建时间
    pub created_at: DateTime<Utc>,
    /// 更新时间
    pub updated_at: DateTime<Utc>,
}

impl Method {
    /// 创建新方法
    pub fn new(
        name: String,
        description: Option<String>,
        process_definition: serde_json::Value,
        parameter_schema: serde_json::Value,
        created_by: Uuid,
    ) -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4(),
            name,
            description,
            process_definition,
            parameter_schema,
            version: 1, // 初始版本
            created_by,
            created_at: now,
            updated_at: now,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_method_new() {
        let method = Method::new(
            "测试方法".to_string(),
            Some("描述".to_string()),
            serde_json::json!({"steps": []}),
            serde_json::json!({"type": "object"}),
            Uuid::new_v4(),
        );

        assert_eq!(method.name, "测试方法");
        assert_eq!(method.description, Some("描述".to_string()));
        assert_eq!(method.version, 1);
    }

    #[test]
    fn test_method_serialization() {
        let method = Method::new(
            "温度循环试验".to_string(),
            Some("测试温度循环过程".to_string()),
            serde_json::json!({"steps": [{"type": "Start"}]}),
            serde_json::json!({"type": "object", "properties": {}}),
            Uuid::new_v4(),
        );

        let json = serde_json::to_string(&method).unwrap();
        let deserialized: Method = serde_json::from_str(&json).unwrap();

        assert_eq!(deserialized.name, method.name);
        assert_eq!(deserialized.description, method.description);
    }
}
