//! 试验方法服务
//!
//! 提供试验方法的业务逻辑

use crate::db::repository::method_repo::MethodRepository;
use crate::db::repository::method_error::MethodRepositoryError;
use crate::models::dto::method_dto::{CreateMethodRequest, MethodDto, MethodListResponse, UpdateMethodRequest};
use uuid::Uuid;

#[derive(Debug)]
pub enum MethodServiceError {
    Validation(String),
    NotFound,
    Repository(MethodRepositoryError),
}

impl From<MethodRepositoryError> for MethodServiceError {
    fn from(err: MethodRepositoryError) -> Self {
        MethodServiceError::Repository(err)
    }
}

pub struct MethodService<R: MethodRepository> {
    repository: R,
}

impl<R: MethodRepository> MethodService<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    /// 创建方法
    pub async fn create_method(
        &self,
        request: CreateMethodRequest,
        user_id: Uuid,
    ) -> Result<MethodDto, MethodServiceError> {
        // 验证请求
        self.validate_create_request(&request)?;

        // 创建实体
        let method = crate::models::entities::Method::new(
            request.name,
            request.description,
            request.process_definition,
            request.parameter_schema,
            user_id,
        );

        // 保存到数据库
        let created = self.repository.create(&method).await?;

        Ok(created.into())
    }

    /// 获取方法
    pub async fn get_method(&self, id: Uuid) -> Result<MethodDto, MethodServiceError> {
        let method = self.repository.get_by_id(id).await?;
        match method {
            Some(m) => Ok(m.into()),
            None => Err(MethodServiceError::NotFound),
        }
    }

    /// 更新方法
    pub async fn update_method(
        &self,
        id: Uuid,
        request: UpdateMethodRequest,
    ) -> Result<MethodDto, MethodServiceError> {
        // 验证请求
        if let Some(ref name) = request.name {
            if name.is_empty() || name.len() > 255 {
                return Err(MethodServiceError::Validation("名称长度必须在1-255之间".to_string()));
            }
        }

        let updated = self.repository.update(
            id,
            request.name,
            request.description,
            request.process_definition,
            request.parameter_schema,
        ).await?;

        Ok(updated.into())
    }

    /// 删除方法
    pub async fn delete_method(&self, id: Uuid) -> Result<(), MethodServiceError> {
        self.repository.delete(id).await?;
        Ok(())
    }

    /// 列出用户的方法
    pub async fn list_methods(
        &self,
        user_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<MethodListResponse, MethodServiceError> {
        let (methods, total) = self.repository.list_by_user(user_id, page, size).await?;

        Ok(MethodListResponse {
            items: methods.into_iter().map(|m| m.into()).collect(),
            total,
            page,
            size,
        })
    }

    /// 验证创建请求
    fn validate_create_request(&self, request: &CreateMethodRequest) -> Result<(), MethodServiceError> {
        // 名称长度验证
        if request.name.is_empty() || request.name.len() > 255 {
            return Err(MethodServiceError::Validation("名称长度必须在1-255之间".to_string()));
        }

        // JSON格式验证
        if !request.process_definition.is_object() {
            return Err(MethodServiceError::Validation("过程定义必须是JSON对象".to_string()));
        }

        if !request.parameter_schema.is_object() {
            return Err(MethodServiceError::Validation("参数Schema必须是JSON对象".to_string()));
        }

        Ok(())
    }

    /// 验证过程定义
    pub fn validate_process_definition(
        &self,
        process_definition: &serde_json::Value,
    ) -> crate::api::handlers::method::ValidationResult {
        let mut errors = Vec::new();

        // 检查必须是对象
        if !process_definition.is_object() {
            return crate::api::handlers::method::ValidationResult {
                valid: false,
                errors: vec!["过程定义必须是JSON对象".to_string()],
            };
        }

        // 检查nodes字段
        let nodes = match process_definition.get("nodes") {
            Some(serde_json::Value::Array(nodes)) => nodes,
            Some(_) => {
                errors.push("'nodes'字段必须是数组".to_string());
                return crate::api::handlers::method::ValidationResult {
                    valid: false,
                    errors,
                };
            }
            None => {
                errors.push("缺少'nodes'字段".to_string());
                return crate::api::handlers::method::ValidationResult {
                    valid: false,
                    errors,
                };
            }
        };

        // 有效节点类型
        let valid_types = [
            "Start", "Read", "Control", "Delay", "Decision",
            "Branch", "Wait", "Record", "Config", "Subprocess", "End",
        ];

        let mut has_start = false;
        let mut has_end = false;
        let mut node_ids = std::collections::HashSet::new();

        for node in nodes {
            // 检查节点类型
            if let Some(node_type) = node.get("type").and_then(|v| v.as_str()) {
                if !valid_types.contains(&node_type) {
                    let node_id = node.get("id").and_then(|v| v.as_str()).unwrap_or("unknown");
                    errors.push(format!("节点'{}'的类型'{}'无效", node_id, node_type));
                }
                if node_type == "Start" {
                    has_start = true;
                }
                if node_type == "End" {
                    has_end = true;
                }
            } else {
                errors.push("节点缺少'type'字段".to_string());
            }

            // 检查节点ID唯一性
            if let Some(node_id) = node.get("id").and_then(|v| v.as_str()) {
                if !node_ids.insert(node_id.to_string()) {
                    errors.push(format!("节点ID'{}'重复", node_id));
                }
            }
        }

        if !has_start {
            errors.push("缺少Start节点".to_string());
        }
        if !has_end {
            errors.push("缺少End节点".to_string());
        }

        crate::api::handlers::method::ValidationResult {
            valid: errors.is_empty(),
            errors,
        }
    }
}
