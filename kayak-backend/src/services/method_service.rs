//! 试验方法服务
//!
//! 提供试验方法的业务逻辑

use crate::db::repository::method_repo::MethodRepository;
use crate::db::repository::method_error::MethodRepositoryError;
use crate::models::dto::method_dto::{CreateMethodRequest, MethodDto, MethodListResponse, UpdateMethodRequest};
use serde::Serialize;
use uuid::Uuid;

#[derive(Debug)]
pub enum MethodServiceError {
    Validation(String),
    NotFound,
    Forbidden,
    Repository(MethodRepositoryError),
}

impl From<MethodRepositoryError> for MethodServiceError {
    fn from(err: MethodRepositoryError) -> Self {
        MethodServiceError::Repository(err)
    }
}

/// Validation result for method process definitions (C3 fix: defined in service layer, not handler)
#[derive(Debug, Serialize)]
pub struct ValidationResult {
    pub valid: bool,
    pub errors: Vec<String>,
}

/// Method service trait (M4 fix: defined in service layer, not handler)
#[axum::async_trait]
pub trait MethodServiceTrait: Send + Sync {
    async fn create_method(
        &self,
        request: CreateMethodRequest,
        user_id: Uuid,
    ) -> Result<MethodDto, MethodServiceError>;
    async fn get_method(&self, id: Uuid, user_id: Uuid) -> Result<MethodDto, MethodServiceError>;
    async fn update_method(
        &self,
        id: Uuid,
        request: UpdateMethodRequest,
        user_id: Uuid,
    ) -> Result<MethodDto, MethodServiceError>;
    async fn delete_method(&self, id: Uuid, user_id: Uuid) -> Result<(), MethodServiceError>;
    async fn list_methods(
        &self,
        user_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<MethodListResponse, MethodServiceError>;
    async fn validate_method(
        &self,
        process_definition: serde_json::Value,
    ) -> Result<ValidationResult, MethodServiceError>;
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

    /// 获取方法 (M1/M2 fix: with ownership check)
    pub async fn get_method(&self, id: Uuid, user_id: Uuid) -> Result<MethodDto, MethodServiceError> {
        let method = self.repository.get_by_id(id).await?;
        match method {
            Some(m) => {
                if m.created_by != user_id {
                    return Err(MethodServiceError::Forbidden);
                }
                Ok(m.into())
            }
            None => Err(MethodServiceError::NotFound),
        }
    }

    /// 更新方法 (M1 fix: with ownership check)
    pub async fn update_method(
        &self,
        id: Uuid,
        request: UpdateMethodRequest,
        user_id: Uuid,
    ) -> Result<MethodDto, MethodServiceError> {
        // 验证请求
        if let Some(ref name) = request.name {
            if name.is_empty() || name.len() > 255 {
                return Err(MethodServiceError::Validation("名称长度必须在1-255之间".to_string()));
            }
        }

        // Ownership check
        let existing = self.repository.get_by_id(id).await?;
        match existing {
            Some(m) if m.created_by != user_id => {
                return Err(MethodServiceError::Forbidden);
            }
            None => return Err(MethodServiceError::NotFound),
            _ => {}
        }

        // m8 fix: Treat empty description string as None for consistency
        let description = request.description.filter(|d| !d.is_empty());

        let updated = self.repository.update(
            id,
            request.name,
            description,
            request.process_definition,
            request.parameter_schema,
        ).await?;

        Ok(updated.into())
    }

    /// 删除方法 (M1 fix: with ownership check)
    pub async fn delete_method(&self, id: Uuid, user_id: Uuid) -> Result<(), MethodServiceError> {
        // Ownership check
        let existing = self.repository.get_by_id(id).await?;
        match existing {
            Some(m) if m.created_by != user_id => {
                return Err(MethodServiceError::Forbidden);
            }
            None => return Err(MethodServiceError::NotFound),
            _ => {}
        }

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

    /// 验证过程定义 (C3 fix: returns service-layer ValidationResult)
    pub fn validate_process_definition(
        &self,
        process_definition: &serde_json::Value,
    ) -> ValidationResult {
        let mut errors = Vec::new();

        // 检查必须是对象
        if !process_definition.is_object() {
            return ValidationResult {
                valid: false,
                errors: vec!["过程定义必须是JSON对象".to_string()],
            };
        }

        // 检查nodes字段
        let nodes = match process_definition.get("nodes") {
            Some(serde_json::Value::Array(nodes)) => nodes,
            Some(_) => {
                errors.push("'nodes'字段必须是数组".to_string());
                return ValidationResult {
                    valid: false,
                    errors,
                };
            }
            None => {
                errors.push("缺少'nodes'字段".to_string());
                return ValidationResult {
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

        ValidationResult {
            valid: errors.is_empty(),
            errors,
        }
    }
}
