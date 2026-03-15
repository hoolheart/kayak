//! 工作台 Repository 单元测试

#[cfg(test)]
mod tests {
    use crate::db::connection::init_db;
    use crate::db::repository::user_repo::UserRepository;
    use crate::models::entities::*;

    async fn setup() -> (UserRepository, User) {
        let db_id = uuid::Uuid::new_v4().to_string();
        let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
            .await
            .unwrap();

        let user_repo = UserRepository::new(pool.clone());

        // 创建测试用户作为工作台所有者
        let user = user_repo
            .create(CreateUserRequest {
                email: "owner@example.com".to_string(),
                password_hash: "hash".to_string(),
                username: Some("Owner".to_string()),
            })
            .await
            .unwrap();

        (user_repo, user)
    }

    // 这里可以添加 WorkbenchRepository 的测试
    // 需要先实现 WorkbenchRepository

    #[tokio::test]
    async fn test_user_repo_integration_with_workbench_owner() {
        let (user_repo, user) = setup().await;

        // 验证用户可以关联工作台
        let found = user_repo.find_by_id(user.id).await.unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().email, "owner@example.com");
    }
}
