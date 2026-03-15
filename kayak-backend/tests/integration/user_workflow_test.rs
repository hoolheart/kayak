//! 集成测试示例
//!
//! 测试多个模块的协作

use kayak_backend::db::connection::init_db;
use kayak_backend::db::repository::user_repo::UserRepository;
use kayak_backend::models::entities::*;

/// 测试用户创建和工作台关联流程
#[tokio::test]
async fn test_user_workbench_workflow() {
    // 初始化测试数据库
    let db_id = uuid::Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let user_repo = UserRepository::new(pool);

    // 1. 创建用户
    let user = user_repo
        .create(CreateUserRequest {
            email: "test@example.com".to_string(),
            password_hash: "hashed".to_string(),
            username: Some("Test User".to_string()),
        })
        .await
        .unwrap();

    assert_eq!(user.email, "test@example.com");

    // 2. 查询用户
    let found = user_repo.find_by_id(user.id).await.unwrap();
    assert!(found.is_some());

    // 3. 更新用户
    let updated = user_repo
        .update(
            user.id,
            UpdateUserRequest {
                username: Some("Updated Name".to_string()),
                ..Default::default()
            },
        )
        .await
        .unwrap();

    assert!(updated.is_some());
    assert_eq!(updated.unwrap().username, Some("Updated Name".to_string()));

    // 4. 删除用户
    let deleted = user_repo.delete(user.id).await.unwrap();
    assert_eq!(deleted, 1);

    // 5. 验证删除
    let not_found = user_repo.find_by_id(user.id).await.unwrap();
    assert!(not_found.is_none());
}

/// 测试错误处理
#[tokio::test]
async fn test_error_handling() {
    let db_id = uuid::Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let user_repo = UserRepository::new(pool);

    // 查询不存在的用户
    let not_found = user_repo.find_by_id(uuid::Uuid::new_v4()).await.unwrap();
    assert!(not_found.is_none());

    // 更新不存在的用户
    let not_updated = user_repo
        .update(
            uuid::Uuid::new_v4(),
            UpdateUserRequest {
                username: Some("Name".to_string()),
                ..Default::default()
            },
        )
        .await
        .unwrap();

    assert!(not_updated.is_none());
}
