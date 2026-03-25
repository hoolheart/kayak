//! 用户仓库适配器
//!
//! 将现有的UserRepository适配为auth模块的UserRepository trait

use async_trait::async_trait;
use uuid::Uuid;

use crate::auth::traits::UserRepository as UserRepositoryTrait;
use crate::core::error::AppError;
use crate::db::repository::user_repo::UserRepository;
use crate::models::entities::user::User;

/// 用户仓库适配器
pub struct UserRepositoryAdapter {
    inner: UserRepository,
}

impl UserRepositoryAdapter {
    pub fn new(inner: UserRepository) -> Self {
        Self { inner }
    }
}

#[async_trait]
impl UserRepositoryTrait for UserRepositoryAdapter {
    async fn find_by_email(&self, email: &str) -> Result<Option<User>, AppError> {
        self.inner
            .find_by_email(email)
            .await
            .map_err(AppError::from)
    }

    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError> {
        self.inner.find_by_id(id).await.map_err(AppError::from)
    }

    async fn create(&self, user: &User) -> Result<(), AppError> {
        // 将User转换为CreateUserRequest
        let req = crate::models::entities::user::CreateUserRequest {
            email: user.email.clone(),
            password_hash: user.password_hash.clone(),
            username: user.username.clone(),
        };

        self.inner.create(req).await.map_err(AppError::from)?;
        Ok(())
    }

    async fn update(&self, user: &User) -> Result<(), AppError> {
        let req = crate::models::entities::user::UpdateUserRequest {
            username: user.username.clone(),
            avatar_url: user.avatar_url.clone(),
            status: Some(crate::models::entities::user::UserStatus::from(
                user.status.clone(),
            )),
        };

        self.inner
            .update(user.id, &req)
            .await
            .map_err(AppError::from)?;
        Ok(())
    }
}
