//! Experiment Control API Integration Tests
//!
//! Tests the experiment control service using in-memory database

use kayak_backend::db::connection::init_db_without_migrations;
use kayak_backend::db::repository::experiment_repo::SqlxExperimentRepository;
use kayak_backend::db::repository::method_repo::{MethodRepository, SqlxMethodRepository};
use kayak_backend::db::repository::state_change_log_repo::SqlxStateChangeLogRepository;
use kayak_backend::models::entities::experiment::{Experiment, ExperimentStatus};
use kayak_backend::models::entities::method::Method;
use kayak_backend::services::experiment_control::{
    ExperimentControlError, ExperimentControlService,
};
use uuid::Uuid;

/// 创建测试所需的完整schema
async fn create_test_schema(pool: &sqlx::Pool<sqlx::Sqlite>) -> Result<(), sqlx::Error> {
    // 创建users表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            username TEXT,
            avatar_url TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        "#,
    )
    .execute(pool)
    .await?;

    // 创建methods表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS methods (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            process_definition TEXT NOT NULL,
            parameter_schema TEXT NOT NULL,
            version INTEGER DEFAULT 1,
            created_by TEXT NOT NULL,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        "#,
    )
    .execute(pool)
    .await?;

    // 创建experiments表 - 注意状态值必须使用大写，且需要CHECK约束
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS experiments (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            method_id TEXT,
            name TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE', 'LOADED', 'RUNNING', 'PAUSED', 'COMPLETED', 'ABORTED')),
            started_at TEXT,
            ended_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
        );
        "#
    )
    .execute(pool)
    .await?;

    // 创建state_change_logs表
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS state_change_logs (
            id TEXT PRIMARY KEY,
            experiment_id TEXT NOT NULL,
            previous_state TEXT NOT NULL,
            new_state TEXT NOT NULL,
            operation TEXT NOT NULL,
            user_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            error_message TEXT
        );
        "#,
    )
    .execute(pool)
    .await?;

    Ok(())
}

/// Helper to create a test user
async fn create_test_user(pool: &sqlx::Pool<sqlx::Sqlite>) -> Uuid {
    let user_id = Uuid::new_v4();
    let now = chrono::Utc::now().to_rfc3339();

    sqlx::query(
        r#"INSERT INTO users (id, email, password_hash, status, created_at, updated_at) 
           VALUES (?, ?, ?, 'active', ?, ?)"#,
    )
    .bind(user_id.to_string())
    .bind(format!("test_{}@example.com", user_id))
    .bind("hashed_password")
    .bind(&now)
    .bind(&now)
    .execute(pool)
    .await
    .unwrap();

    user_id
}

/// Helper to create an experiment with specific status by direct SQL
async fn create_experiment_with_status(
    pool: &sqlx::Pool<sqlx::Sqlite>,
    user_id: Uuid,
    name: &str,
    status: ExperimentStatus,
) -> Experiment {
    let exp = Experiment {
        id: Uuid::new_v4(),
        user_id,
        method_id: None,
        name: name.to_string(),
        description: None,
        status,
        started_at: None,
        ended_at: None,
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    };

    let status_str = format!("{:?}", status).to_uppercase();

    sqlx::query(
        r#"INSERT INTO experiments (id, user_id, name, description, status, created_at, updated_at) 
           VALUES (?, ?, ?, ?, ?, ?, ?)"#,
    )
    .bind(exp.id.to_string())
    .bind(user_id.to_string())
    .bind(&exp.name)
    .bind(&exp.description)
    .bind(&status_str)
    .bind(exp.created_at)
    .bind(exp.updated_at)
    .execute(pool)
    .await
    .unwrap();

    exp
}

/// Helper to create a test method
async fn create_test_method(pool: &sqlx::Pool<sqlx::Sqlite>, user_id: Uuid) -> Method {
    let method = Method::new(
        "Test Method".to_string(),
        Some("Test description".to_string()),
        serde_json::json!({}),
        serde_json::json!({}),
        user_id,
    );
    SqlxMethodRepository::new(pool.clone())
        .create(&method)
        .await
        .unwrap()
}

// ===== API Endpoint Tests =====

#[tokio::test]
async fn test_load_experiment_success() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, user_id, "Test Load", ExperimentStatus::Idle).await;
    let method = create_test_method(&pool, user_id).await;

    let result = service.load(exp.id, method.id, user_id).await;
    assert!(result.is_ok());
    let dto = result.unwrap();
    assert_eq!(dto.status, "LOADED");
}

#[tokio::test]
async fn test_load_experiment_not_found() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let result = service
        .load(Uuid::new_v4(), Uuid::new_v4(), Uuid::new_v4())
        .await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::NotFound(_)
    ));
}

#[tokio::test]
async fn test_load_experiment_forbidden() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        method_repo,
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let owner_id = create_test_user(&pool).await;
    let other_user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, owner_id, "Test Forbidden", ExperimentStatus::Idle)
            .await;
    let method = create_test_method(&pool, owner_id).await;

    let result = service.load(exp.id, method.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::Forbidden(_)
    ));
}

#[tokio::test]
async fn test_start_experiment_success() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, user_id, "Test Start", ExperimentStatus::Idle).await;
    let method = create_test_method(&pool, user_id).await;
    service.load(exp.id, method.id, user_id).await.unwrap();

    let result = service.start(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");
}

#[tokio::test]
async fn test_start_experiment_invalid_transition() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, user_id, "Test Invalid", ExperimentStatus::Idle).await;

    let result = service.start(exp.id, user_id).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::InvalidTransition(_)
    ));
}

// ===== State Machine Tests =====

#[tokio::test]
async fn test_state_transition_idle_to_loaded() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, user_id, "Test Idle->Loaded", ExperimentStatus::Idle)
            .await;
    let method = create_test_method(&pool, user_id).await;

    let result = service.load(exp.id, method.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "LOADED");
}

#[tokio::test]
async fn test_state_transition_loaded_to_running() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        user_id,
        "Test Loaded->Running",
        ExperimentStatus::Loaded,
    )
    .await;

    let result = service.start(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");
}

#[tokio::test]
async fn test_state_transition_running_to_paused() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        user_id,
        "Test Running->Paused",
        ExperimentStatus::Running,
    )
    .await;

    let result = service.pause(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "PAUSED");
}

#[tokio::test]
async fn test_state_transition_paused_to_running() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        user_id,
        "Test Paused->Running",
        ExperimentStatus::Paused,
    )
    .await;

    let result = service.resume(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");
}

#[tokio::test]
async fn test_state_transition_running_to_loaded() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        user_id,
        "Test Running->Loaded",
        ExperimentStatus::Running,
    )
    .await;

    let result = service.stop(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "LOADED");
}

#[tokio::test]
async fn test_invalid_transition_idle_to_running() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, user_id, "Test Idle->Running", ExperimentStatus::Idle)
            .await;

    let result = service.start(exp.id, user_id).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::InvalidTransition(_)
    ));
}

// ===== Permission Tests =====

#[tokio::test]
async fn test_permission_non_owner_load() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        method_repo,
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let owner_id = create_test_user(&pool).await;
    let other_user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        owner_id,
        "Test NonOwner Load",
        ExperimentStatus::Idle,
    )
    .await;
    let method = create_test_method(&pool, owner_id).await;

    let result = service.load(exp.id, method.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::Forbidden(_)
    ));
}

#[tokio::test]
async fn test_permission_non_owner_pause() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let owner_id = create_test_user(&pool).await;
    let other_user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        owner_id,
        "Test NonOwner Pause",
        ExperimentStatus::Running,
    )
    .await;

    let result = service.pause(exp.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::Forbidden(_)
    ));
}

#[tokio::test]
async fn test_permission_non_owner_stop() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let owner_id = create_test_user(&pool).await;
    let other_user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        owner_id,
        "Test NonOwner Stop",
        ExperimentStatus::Running,
    )
    .await;

    let result = service.stop(exp.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::Forbidden(_)
    ));
}

// ===== Status and History Tests =====

#[tokio::test]
async fn test_get_status_success() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let user_id = create_test_user(&pool).await;
    let exp =
        create_experiment_with_status(&pool, user_id, "Test GetStatus", ExperimentStatus::Running)
            .await;

    let result = service.get_status(exp.id).await;
    assert!(result.is_ok());
    let status = result.unwrap();
    assert_eq!(status.status, "RUNNING");
    assert_eq!(status.id, exp.id.to_string());
}

#[tokio::test]
async fn test_get_status_not_found() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo,
        SqlxMethodRepository::new(pool.clone()),
        SqlxStateChangeLogRepository::new(pool.clone()),
    );

    let result = service.get_status(Uuid::new_v4()).await;
    assert!(result.is_err());
    assert!(matches!(
        result.unwrap_err(),
        ExperimentControlError::NotFound(_)
    ));
}

// ===== Full Lifecycle Test =====

#[tokio::test]
async fn test_full_lifecycle() {
    // Use file-based temp database to avoid MIGRATOR issues
    let temp_file = std::env::temp_dir().join(format!("test_exp_{}.db", uuid::Uuid::new_v4()));
    let pool = init_db_without_migrations(&format!("sqlite:{}", temp_file.display()))
        .await
        .unwrap();
    create_test_schema(&pool).await.unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = create_test_user(&pool).await;
    let exp = create_experiment_with_status(
        &pool,
        user_id,
        "Test Full Lifecycle",
        ExperimentStatus::Idle,
    )
    .await;
    let method = create_test_method(&pool, user_id).await;

    // Load
    let result = service.load(exp.id, method.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "LOADED");

    // Start
    let result = service.start(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");

    // Pause
    let result = service.pause(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "PAUSED");

    // Resume
    let result = service.resume(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");

    // Stop
    let result = service.stop(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "LOADED");
}
