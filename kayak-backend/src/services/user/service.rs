//! 用户服务接口与实现
//!
//! 实现用户信息获取、更新和密码修改功能

use std::sync::Arc;
use async_trait::async_trait;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use serde::{Serialize, Deserialize};
use validator::Validate;

use crate::auth::PasswordHasher;
use crate::models::entities::user::User;
use crate::core::error::AppError;

use super::error::UserError;
use super::types::UpdateUserEntity;

/// 用户DTO
#[derive(Debug, Clone, Serialize)]
pub struct UserDto {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub avatar: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<User> for UserDto {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            username: user.username,
            avatar: user.avatar_url,
            status: user.status,
            created_at: user.created_at,
            updated_at: user.updated_at,
        }
    }
}

/// 更新用户信息请求
#[derive(Debug, Deserialize, Validate)]
pub struct UpdateUserRequest {
    #[validate(length(min = 3, max = 50, message = "Username must be 3-50 characters"))]
    pub username: Option<String>,
    
    #[validate(url(message = "Invalid avatar URL format"))]
    #[validate(length(max = 2048, message = "Avatar URL must be at most 2048 characters"))]
    pub avatar: Option<String>,
}

/// 修改密码请求
#[derive(Debug, Deserialize, Validate)]
pub struct ChangePasswordRequest {
    #[validate(length(min = 1, message = "Old password is required"))]
    pub old_password: String,
    
    #[validate(length(min = 8, message = "New password must be at least 8 characters"))]
    pub new_password: String,
}

/// 用户仓库接口
#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError>;
    async fn update(&self, id: Uuid, updates: &UpdateUserEntity) -> Result<User, AppError>;
    async fn update_password(&self, id: Uuid, password_hash: &str) -> Result<(), AppError>;
    async fn exists_by_username(&self, username: &str) -> Result<bool, AppError>;
    async fn exists_by_username_except_user(&self, username: &str, user_id: Uuid) -> Result<bool, AppError>;
}

/// 用户服务接口
#[async_trait]
pub trait UserService: Send + Sync {
    /// 获取当前用户信息
    async fn get_current_user(&self, user_id: Uuid) -> Result<UserDto, UserError>;

    /// 更新用户信息
    async fn update_user(&self, user_id: Uuid, updates: UpdateUserRequest) -> Result<UserDto, UserError>;

    /// 修改密码
    async fn change_password(&self, user_id: Uuid, req: ChangePasswordRequest) -> Result<(), UserError>;
}

/// 用户服务实现
pub struct UserServiceImpl {
    user_repo: Arc<dyn UserRepository>,
    password_service: Arc<dyn PasswordHasher>,
}

impl UserServiceImpl {
    pub fn new(
        user_repo: Arc<dyn UserRepository>,
        password_service: Arc<dyn PasswordHasher>,
    ) -> Self {
        Self {
            user_repo,
            password_service,
        }
    }

    /// 验证密码强度
    fn validate_password_strength(&self, password: &str) -> Result<(), UserError> {
        if password.len() < 8 {
            return Err(UserError::WeakPassword(
                "Password must be at least 8 characters".to_string(),
            ));
        }
        if password.len() > 128 {
            return Err(UserError::WeakPassword(
                "Password must be at most 128 characters".to_string(),
            ));
        }
        Ok(())
    }
}

#[async_trait]
impl UserService for UserServiceImpl {
    async fn get_current_user(&self, user_id: Uuid) -> Result<UserDto, UserError> {
        let user = self
            .user_repo
            .find_by_id(user_id)
            .await
            .map_err(|e| UserError::Internal(e.to_string()))?
            .ok_or(UserError::UserNotFound)?;

        Ok(UserDto {
            id: user.id,
            email: user.email,
            username: user.username,
            avatar: user.avatar_url,
            status: user.status,
            created_at: user.created_at,
            updated_at: user.updated_at,
        })
    }

    async fn update_user(
        &self,
        user_id: Uuid,
        updates: UpdateUserRequest,
    ) -> Result<UserDto, UserError> {
        let mut update_entity = UpdateUserEntity::default();

        if let Some(ref username) = updates.username {
            // 验证用户名唯一性
            let exists = self
                .user_repo
                .exists_by_username_except_user(username, user_id)
                .await
                .map_err(|e| UserError::Internal(e.to_string()))?;

            if exists {
                return Err(UserError::UsernameAlreadyExists);
            }
            update_entity.username = Some(username.clone());
        }

        if updates.avatar.is_some() {
            update_entity.avatar_url = updates.avatar.clone();
        }

        // 执行更新
        let user = self
            .user_repo
            .update(user_id, &update_entity)
            .await
            .map_err(|e| UserError::Internal(e.to_string()))?;

        Ok(UserDto {
            id: user.id,
            email: user.email,
            username: user.username,
            avatar: user.avatar_url,
            status: user.status,
            created_at: user.created_at,
            updated_at: user.updated_at,
        })
    }

    async fn change_password(
        &self,
        user_id: Uuid,
        req: ChangePasswordRequest,
    ) -> Result<(), UserError> {
        // 获取用户
        let user = self
            .user_repo
            .find_by_id(user_id)
            .await
            .map_err(|e| UserError::Internal(e.to_string()))?
            .ok_or(UserError::UserNotFound)?;

        // 验证旧密码
        let password_valid = self
            .password_service
            .verify_password(&req.old_password, &user.password_hash)
            .map_err(|e| UserError::Internal(e.to_string()))?;

        if !password_valid {
            return Err(UserError::InvalidOldPassword);
        }

        // 验证新旧密码不同
        if req.old_password == req.new_password {
            return Err(UserError::PasswordSameAsOld);
        }

        // 验证新密码强度
        self.validate_password_strength(&req.new_password)?;

        // 哈希新密码并存储
        let new_hash = self
            .password_service
            .hash_password(&req.new_password)
            .map_err(|e| UserError::Internal(e.to_string()))?;

        self.user_repo
            .update_password(user_id, &new_hash)
            .await
            .map_err(|e| UserError::Internal(e.to_string()))?;

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::auth::PasswordHasher;
    use crate::auth::services::BcryptPasswordHasher;
    use crate::models::entities::user::{User, UserStatus};
    use chrono::Utc;
    use std::sync::RwLock;

    struct MockUserRepository {
        users: RwLock<std::collections::HashMap<Uuid, User>>,
    }

    impl MockUserRepository {
        fn new() -> Self {
            Self {
                users: RwLock::new(std::collections::HashMap::new()),
            }
        }

        fn add_user(&self, user: User) {
            self.users.write().unwrap().insert(user.id, user);
        }
    }

    #[async_trait]
    impl UserRepository for MockUserRepository {
        async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, AppError> {
            Ok(self.users.read().unwrap().get(&id).cloned())
        }

        async fn update(&self, id: Uuid, updates: &UpdateUserEntity) -> Result<User, AppError> {
            let user = self.users.read().unwrap().get(&id).cloned().unwrap();
            let updated = User {
                username: updates.username.clone().or(user.username),
                avatar_url: updates.avatar_url.clone().or(user.avatar_url),
                ..user
            };
            Ok(updated)
        }

        async fn update_password(&self, id: Uuid, password_hash: &str) -> Result<(), AppError> {
            if let Some(user) = self.users.write().unwrap().get_mut(&id) {
                user.password_hash = password_hash.to_string();
            }
            Ok(())
        }

        async fn exists_by_username(&self, username: &str) -> Result<bool, AppError> {
            Ok(self.users.read().unwrap().values().any(|u| u.username.as_ref() == Some(&username.to_string())))
        }

        async fn exists_by_username_except_user(&self, username: &str, user_id: Uuid) -> Result<bool, AppError> {
            Ok(self.users.read().unwrap().values().any(|u| u.username.as_ref() == Some(&username.to_string()) && u.id != user_id))
        }
    }

    #[tokio::test]
    async fn test_get_current_user_success() {
        let mock_repo = MockUserRepository::new();
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash: "hash".to_string(),
            username: Some("testuser".to_string()),
            avatar_url: Some("https://example.com/avatar.jpg".to_string()),
            status: UserStatus::Active.to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        mock_repo.add_user(user.clone());

        let service = UserServiceImpl::new(
            Arc::new(mock_repo),
            Arc::new(BcryptPasswordHasher),
        );

        let result = service.get_current_user(user.id).await;
        assert!(result.is_ok());
        let dto = result.unwrap();
        assert_eq!(dto.email, "test@example.com");
        assert_eq!(dto.username, Some("testuser".to_string()));
    }

    #[tokio::test]
    async fn test_get_current_user_not_found() {
        let mock_repo = MockUserRepository::new();
        let service = UserServiceImpl::new(
            Arc::new(mock_repo),
            Arc::new(BcryptPasswordHasher),
        );

        let result = service.get_current_user(Uuid::new_v4()).await;
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UserError::UserNotFound));
    }

    #[tokio::test]
    async fn test_change_password_success() {
        let mock_repo = MockUserRepository::new();
        let password_hasher = BcryptPasswordHasher;
        let password_hash = password_hasher.hash_password("OldPass123!").unwrap();
        
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash,
            username: Some("testuser".to_string()),
            avatar_url: None,
            status: UserStatus::Active.to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        mock_repo.add_user(user.clone());

        let service = UserServiceImpl::new(
            Arc::new(mock_repo),
            Arc::new(password_hasher),
        );

        let result = service.change_password(
            user.id,
            ChangePasswordRequest {
                old_password: "OldPass123!".to_string(),
                new_password: "NewPass456!".to_string(),
            },
        ).await;

        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_change_password_invalid_old() {
        let mock_repo = MockUserRepository::new();
        let password_hasher = BcryptPasswordHasher;
        let password_hash = password_hasher.hash_password("OldPass123!").unwrap();
        
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash,
            username: Some("testuser".to_string()),
            avatar_url: None,
            status: UserStatus::Active.to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        mock_repo.add_user(user.clone());

        let service = UserServiceImpl::new(
            Arc::new(mock_repo),
            Arc::new(password_hasher),
        );

        let result = service.change_password(
            user.id,
            ChangePasswordRequest {
                old_password: "WrongPass123!".to_string(),
                new_password: "NewPass456!".to_string(),
            },
        ).await;

        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UserError::InvalidOldPassword));
    }

    #[tokio::test]
    async fn test_change_password_same_as_old() {
        let mock_repo = MockUserRepository::new();
        let password_hasher = BcryptPasswordHasher;
        let password_hash = password_hasher.hash_password("SamePass123!").unwrap();
        
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash,
            username: Some("testuser".to_string()),
            avatar_url: None,
            status: UserStatus::Active.to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        mock_repo.add_user(user.clone());

        let service = UserServiceImpl::new(
            Arc::new(mock_repo),
            Arc::new(password_hasher),
        );

        let result = service.change_password(
            user.id,
            ChangePasswordRequest {
                old_password: "SamePass123!".to_string(),
                new_password: "SamePass123!".to_string(),
            },
        ).await;

        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UserError::PasswordSameAsOld));
    }

    #[tokio::test]
    async fn test_change_password_too_short() {
        let mock_repo = MockUserRepository::new();
        let password_hasher = BcryptPasswordHasher;
        let password_hash = password_hasher.hash_password("OldPass123!").unwrap();
        
        let user = User {
            id: Uuid::new_v4(),
            email: "test@example.com".to_string(),
            password_hash,
            username: Some("testuser".to_string()),
            avatar_url: None,
            status: UserStatus::Active.to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        };
        mock_repo.add_user(user.clone());

        let service = UserServiceImpl::new(
            Arc::new(mock_repo),
            Arc::new(password_hasher),
        );

        let result = service.change_password(
            user.id,
            ChangePasswordRequest {
                old_password: "OldPass123!".to_string(),
                new_password: "short".to_string(),
            },
        ).await;

        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), UserError::WeakPassword(_)));
    }
}
