//! 用户Repository
//!
//! 提供用户实体的数据访问操作

use crate::db::connection::DbPool;
use crate::models::entities::user::{
    CreateUserRequest, UpdateUserRequest as EntityUpdateUserRequest, User,
};
use crate::services::user::UpdateUserEntity;
use chrono::Utc;
use sqlx::{Error, Row};
use uuid::Uuid;

pub struct UserRepository {
    pool: DbPool,
}

impl UserRepository {
    pub fn new(pool: DbPool) -> Self {
        Self { pool }
    }

    /// 根据ID查找用户
    pub async fn find_by_id(&self, id: Uuid) -> Result<Option<User>, Error> {
        let row = sqlx::query(
            r#"
            SELECT id, email, password_hash, username, avatar_url, status, created_at, updated_at
            FROM users
            WHERE id = ?
            "#,
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| User {
            id: Uuid::parse_str(r.get::<String, _>("id").as_str()).unwrap_or_default(),
            email: r.get("email"),
            password_hash: r.get("password_hash"),
            username: r.get("username"),
            avatar_url: r.get("avatar_url"),
            status: r.get("status"),
            created_at: r.get("created_at"),
            updated_at: r.get("updated_at"),
        }))
    }

    /// 根据邮箱查找用户
    pub async fn find_by_email(&self, email: &str) -> Result<Option<User>, Error> {
        let row = sqlx::query(
            r#"
            SELECT id, email, password_hash, username, avatar_url, status, created_at, updated_at
            FROM users
            WHERE email = ?
            "#,
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| User {
            id: Uuid::parse_str(r.get::<String, _>("id").as_str()).unwrap_or_default(),
            email: r.get("email"),
            password_hash: r.get("password_hash"),
            username: r.get("username"),
            avatar_url: r.get("avatar_url"),
            status: r.get("status"),
            created_at: r.get("created_at"),
            updated_at: r.get("updated_at"),
        }))
    }

    /// 查找所有用户
    pub async fn find_all(&self) -> Result<Vec<User>, Error> {
        let rows = sqlx::query(
            r#"
            SELECT id, email, password_hash, username, avatar_url, status, created_at, updated_at
            FROM users
            ORDER BY created_at DESC
            "#,
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows
            .into_iter()
            .map(|r| User {
                id: Uuid::parse_str(r.get::<String, _>("id").as_str()).unwrap_or_default(),
                email: r.get("email"),
                password_hash: r.get("password_hash"),
                username: r.get("username"),
                avatar_url: r.get("avatar_url"),
                status: r.get("status"),
                created_at: r.get("created_at"),
                updated_at: r.get("updated_at"),
            })
            .collect())
    }

    /// 创建用户
    pub async fn create(&self, req: CreateUserRequest) -> Result<User, Error> {
        let user = User::new(req.email, req.password_hash, req.username);

        sqlx::query(
            r#"
            INSERT INTO users (id, email, password_hash, username, avatar_url, status, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            "#,
        )
        .bind(user.id.to_string())
        .bind(&user.email)
        .bind(&user.password_hash)
        .bind(&user.username)
        .bind(&user.avatar_url)
        .bind(&user.status)
        .bind(user.created_at)
        .bind(user.updated_at)
        .execute(&self.pool)
        .await?;

        Ok(user)
    }

    /// 更新用户信息（使用EntityUpdateUserRequest，用于auth模块）
    pub async fn update(&self, id: Uuid, req: &EntityUpdateUserRequest) -> Result<User, Error> {
        let existing = self.find_by_id(id).await?;
        if existing.is_none() {
            return Err(Error::RowNotFound);
        }

        let mut user = existing.unwrap();

        if let Some(username) = &req.username {
            user.username = Some(username.clone());
        }
        if let Some(avatar_url) = &req.avatar_url {
            user.avatar_url = Some(avatar_url.clone());
        }
        if let Some(status) = &req.status {
            user.status = status.to_string();
        }

        sqlx::query(
            r#"
            UPDATE users
            SET username = ?, avatar_url = ?, status = ?
            WHERE id = ?
            "#,
        )
        .bind(&user.username)
        .bind(&user.avatar_url)
        .bind(&user.status)
        .bind(id.to_string())
        .execute(&self.pool)
        .await?;

        Ok(user)
    }

    /// 更新用户信息（使用UpdateUserEntity，用于用户服务模块）
    pub async fn update_with_entity(
        &self,
        id: Uuid,
        updates: &UpdateUserEntity,
    ) -> Result<User, Error> {
        // 检查是否有更新
        if updates.username.is_none() && updates.avatar_url.is_none() {
            // 没有更新，直接返回当前用户
            return self.find_by_id(id).await?.ok_or(Error::RowNotFound);
        }

        let now = Utc::now();

        // 构建更新查询
        sqlx::query(
            r#"
            UPDATE users
            SET updated_at = ?, username = COALESCE(?, username), avatar_url = COALESCE(?, avatar_url)
            WHERE id = ?
            "#,
        )
        .bind(now)
        .bind(&updates.username)
        .bind(&updates.avatar_url)
        .bind(id.to_string())
        .execute(&self.pool)
        .await?;

        // 返回更新后的用户
        self.find_by_id(id).await?.ok_or(Error::RowNotFound)
    }

    /// 更新用户密码
    pub async fn update_password(&self, id: Uuid, password_hash: &str) -> Result<(), Error> {
        let now = Utc::now();
        sqlx::query(
            r#"
            UPDATE users
            SET password_hash = ?, updated_at = ?
            WHERE id = ?
            "#,
        )
        .bind(password_hash)
        .bind(now)
        .bind(id.to_string())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    /// 检查用户名是否存在
    pub async fn exists_by_username(&self, username: &str) -> Result<bool, Error> {
        let exists: bool =
            sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM users WHERE username = ?)")
                .bind(username)
                .fetch_one(&self.pool)
                .await?;

        Ok(exists)
    }

    /// 检查用户名是否存在（排除指定用户）
    pub async fn exists_by_username_except_user(
        &self,
        username: &str,
        user_id: Uuid,
    ) -> Result<bool, Error> {
        let exists: bool =
            sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM users WHERE username = ? AND id != ?)")
                .bind(username)
                .bind(user_id.to_string())
                .fetch_one(&self.pool)
                .await?;

        Ok(exists)
    }

    /// 删除用户
    pub async fn delete(&self, id: Uuid) -> Result<u64, Error> {
        let result = sqlx::query("DELETE FROM users WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::connection::init_db_without_migrations;
    use crate::services::user::UpdateUserEntity;

    /// 手动创建测试数据库schema
    async fn create_test_schema(pool: &sqlx::Pool<sqlx::Sqlite>) -> Result<(), sqlx::Error> {
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS users (
                id TEXT PRIMARY KEY,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                username TEXT,
                avatar_url TEXT,
                status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
            "#
        )
        .execute(pool)
        .await?;
        Ok(())
    }

    #[tokio::test]
    async fn test_user_repository() {
        // 使用临时文件数据库，避免迁移问题
        let temp_dir = std::env::temp_dir();
        let db_path = temp_dir.join(format!("test_user_repo_{}.db", uuid::Uuid::new_v4()));
        let pool = init_db_without_migrations(&format!("sqlite:{}", db_path.display()))
            .await
            .unwrap();
        
        // 手动创建schema
        create_test_schema(&pool).await.unwrap();
        
        let repo = UserRepository::new(pool);

        // 创建用户
        let req = CreateUserRequest {
            email: "test@example.com".to_string(),
            password_hash: "hashed_password".to_string(),
            username: Some("Test User".to_string()),
        };

        let user = repo.create(req).await.unwrap();
        assert_eq!(user.email, "test@example.com");

        // 查找用户
        let found = repo.find_by_id(user.id).await.unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().email, "test@example.com");

        // 更新用户
        let update_req = UpdateUserEntity {
            username: Some("Updated Name".to_string()),
            avatar_url: None,
        };
        let updated = repo.update_with_entity(user.id, &update_req).await.unwrap();
        assert_eq!(updated.username, Some("Updated Name".to_string()));

        // 删除用户
        let deleted = repo.delete(user.id).await.unwrap();
        assert_eq!(deleted, 1);

        let not_found = repo.find_by_id(user.id).await.unwrap();
        assert!(not_found.is_none());
    }

    #[tokio::test]
    async fn test_exists_by_username() {
        // 使用临时文件数据库，避免迁移问题
        let temp_dir = std::env::temp_dir();
        let db_path = temp_dir.join(format!("test_exists_{}.db", uuid::Uuid::new_v4()));
        let pool = init_db_without_migrations(&format!("sqlite:{}", db_path.display()))
            .await
            .unwrap();
        
        // 手动创建schema
        create_test_schema(&pool).await.unwrap();
        
        let repo = UserRepository::new(pool);

        // 创建用户
        let req = CreateUserRequest {
            email: "test@example.com".to_string(),
            password_hash: "hashed_password".to_string(),
            username: Some("uniqueuser".to_string()),
        };
        let user = repo.create(req).await.unwrap();

        // 检查用户名存在
        let exists = repo.exists_by_username("uniqueuser").await.unwrap();
        assert!(exists);

        // 检查不存在的用户名
        let exists = repo.exists_by_username("nonexistent").await.unwrap();
        assert!(!exists);

        // 检查用户名排除自身
        let exists = repo
            .exists_by_username_except_user("uniqueuser", user.id)
            .await
            .unwrap();
        assert!(!exists);

        // 创建另一个用户使用相同用户名
        let req2 = CreateUserRequest {
            email: "test2@example.com".to_string(),
            password_hash: "hashed_password".to_string(),
            username: Some("uniqueuser".to_string()),
        };
        let _ = repo.create(req2).await.unwrap();

        // 现在检查应该返回true
        let exists = repo
            .exists_by_username_except_user("uniqueuser", user.id)
            .await
            .unwrap();
        assert!(exists);
    }
}
