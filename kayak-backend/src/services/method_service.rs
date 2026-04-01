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
}
