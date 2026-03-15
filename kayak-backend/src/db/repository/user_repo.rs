//! 用户Repository
//!
//! 提供用户实体的数据访问操作

use crate::db::connection::DbPool;
use crate::models::entities::user::{CreateUserRequest, UpdateUserRequest, User};
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
    pub async fn find_by_email(
        &self,
        email: &str,
    ) -> Result<Option<User>, Error> {
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
    pub async fn find_all(&self,
    ) -> Result<Vec<User>, Error> {
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
    pub async fn create(
        &self,
        req: CreateUserRequest,
    ) -> Result<User, Error> {
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

    /// 更新用户
    pub async fn update(
        &self,
        id: Uuid,
        req: UpdateUserRequest,
    ) -> Result<Option<User>, Error> {
        let existing = self.find_by_id(id).await?;
        if existing.is_none() {
            return Ok(None);
        }

        let mut user = existing.unwrap();

        if let Some(username) = req.username {
            user.username = Some(username);
        }
        if let Some(avatar_url) = req.avatar_url {
            user.avatar_url = Some(avatar_url);
        }
        if let Some(status) = req.status {
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

        Ok(Some(user))
    }

    /// 删除用户
    pub async fn delete(
        &self,
        id: Uuid,
    ) -> Result<u64, Error> {
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
    use crate::db::connection::init_db;

    #[tokio::test]
    async fn test_user_repository() {
        let pool = init_db("sqlite::memory:").await.unwrap();
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
        let update_req = UpdateUserRequest {
            username: Some("Updated Name".to_string()),
            ..Default::default()
        };
        let updated = repo.update(user.id, update_req).await.unwrap();
        assert!(updated.is_some());
        assert_eq!(updated.unwrap().username, Some("Updated Name".to_string()));

        // 删除用户
        let deleted = repo.delete(user.id).await.unwrap();
        assert_eq!(deleted, 1);

        let not_found = repo.find_by_id(user.id).await.unwrap();
        assert!(not_found.is_none());
    }
}
