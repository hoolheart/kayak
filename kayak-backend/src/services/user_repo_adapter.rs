//! 用户服务仓库适配器
//!
//! 将现有的UserRepository适配为用户服务的UserRepository trait

use async_trait::async_trait;
use uuid::Uuid;

use crate::core::error::AppError;
use crate::db::repository::user_repo::UserRepository as DbUserRepository;
use crate::models::entities::user::User;
use crate::services::user::service::UserRepository;
use crate::services::user::types::UpdateUserEntity;

/// 用户服务仓库适配器
pub struct UserServiceRepositoryAdapter {
    inner: DbUserRepository,
}

impl UserServiceRepositoryAdapter {
    pub fn new(inner: DbUserRepository) -> Self {
        Self { inner }
    }
}

#[async_trait]
impl UserRepository for UserServiceRepositoryAdapter {
    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError> {
        self.inner.find_by_id(id).await.map_err(AppError::from)
    }

    async fn update(&self, id: Uuid, updates: &UpdateUserEntity) -> Result<User, AppError> {
        self.inner.update_with_entity(id, updates).await.map_err(AppError::from)
    }

    async fn update_password(&self, id: Uuid, password_hash: &str) -> Result<(), AppError> {
        self.inner.update_password(id, password_hash).await.map_err(AppError::from)
    }

    async fn exists_by_username(&self, username: &str) -> Result<bool, AppError> {
        self.inner.exists_by_username(username).await.map_err(AppError::from)
    }

    async fn exists_by_username_except_user(&self, username: &str, user_id: Uuid) -> Result<bool, AppError> {
        self.inner.exists_by_username_except_user(username, user_id).await.map_err(AppError::from)
    }
}
