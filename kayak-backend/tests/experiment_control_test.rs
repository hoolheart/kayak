//! Experiment Control API Integration Tests
//!
//! Tests the experiment control service using in-memory database

use kayak_backend::db::connection::init_db;
use kayak_backend::db::repository::experiment_repo::{ExperimentRepository, SqlxExperimentRepository};
use kayak_backend::db::repository::method_repo::{MethodRepository, SqlxMethodRepository};
use kayak_backend::db::repository::state_change_log_repo::SqlxStateChangeLogRepository;
use kayak_backend::models::entities::experiment::{Experiment, ExperimentStatus};
use kayak_backend::models::entities::method::Method;
use kayak_backend::services::experiment_control::{ExperimentControlError, ExperimentControlService};
use uuid::Uuid;

/// Helper to create an experiment with specific status by direct SQL
/// This is needed because Experiment::new() always creates with Idle status
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
           VALUES (?, ?, ?, ?, ?, ?, ?)"#
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
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Load", ExperimentStatus::Idle).await;

    let method = create_test_method(&pool, user_id).await;
    
    let result = service.load(exp.id, method.id, user_id).await;
    assert!(result.is_ok());
    let dto = result.unwrap();
    assert_eq!(dto.status, "LOADED");
}

#[tokio::test]
async fn test_load_experiment_not_found() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let result = service.load(Uuid::new_v4(), Uuid::new_v4(), Uuid::new_v4()).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::NotFound(_)));
}

#[tokio::test]
async fn test_load_experiment_forbidden() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        method_repo, 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let owner_id = Uuid::new_v4();
    let other_user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, owner_id, "Test Forbidden", ExperimentStatus::Idle).await;
    let method = create_test_method(&pool, owner_id).await;
    
    let result = service.load(exp.id, method.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::Forbidden(_)));
}

#[tokio::test]
async fn test_start_experiment_success() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    
    // First create experiment and load method
    let exp = create_experiment_with_status(&pool, user_id, "Test Start", ExperimentStatus::Idle).await;
    let method = create_test_method(&pool, user_id).await;
    service.load(exp.id, method.id, user_id).await.unwrap();
    
    // Now start
    let result = service.start(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");
}

#[tokio::test]
async fn test_start_experiment_invalid_transition() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Invalid", ExperimentStatus::Idle).await;

    let result = service.start(exp.id, user_id).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::InvalidTransition(_)));
}

// ===== State Machine Tests =====

#[tokio::test]
async fn test_state_transition_idle_to_loaded() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Idle->Loaded", ExperimentStatus::Idle).await;
    let method = create_test_method(&pool, user_id).await;
    
    let result = service.load(exp.id, method.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "LOADED");
}

#[tokio::test]
async fn test_state_transition_loaded_to_running() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Loaded->Running", ExperimentStatus::Loaded).await;
    
    let result = service.start(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");
}

#[tokio::test]
async fn test_state_transition_running_to_paused() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Running->Paused", ExperimentStatus::Running).await;
    
    let result = service.pause(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "PAUSED");
}

#[tokio::test]
async fn test_state_transition_paused_to_running() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Paused->Running", ExperimentStatus::Paused).await;
    
    let result = service.resume(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "RUNNING");
}

#[tokio::test]
async fn test_state_transition_running_to_loaded() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Running->Loaded", ExperimentStatus::Running).await;
    
    let result = service.stop(exp.id, user_id).await;
    assert!(result.is_ok());
    assert_eq!(result.unwrap().status, "LOADED");
}

#[tokio::test]
async fn test_invalid_transition_idle_to_running() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Idle->Running", ExperimentStatus::Idle).await;
    
    let result = service.start(exp.id, user_id).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::InvalidTransition(_)));
}

// ===== Permission Tests =====

#[tokio::test]
async fn test_permission_non_owner_load() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        method_repo, 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let owner_id = Uuid::new_v4();
    let other_user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, owner_id, "Test NonOwner Load", ExperimentStatus::Idle).await;
    let method = create_test_method(&pool, owner_id).await;
    
    let result = service.load(exp.id, method.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::Forbidden(_)));
}

#[tokio::test]
async fn test_permission_non_owner_pause() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let owner_id = Uuid::new_v4();
    let other_user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, owner_id, "Test NonOwner Pause", ExperimentStatus::Running).await;
    
    let result = service.pause(exp.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::Forbidden(_)));
}

#[tokio::test]
async fn test_permission_non_owner_stop() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let owner_id = Uuid::new_v4();
    let other_user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, owner_id, "Test NonOwner Stop", ExperimentStatus::Running).await;
    
    let result = service.stop(exp.id, other_user_id).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::Forbidden(_)));
}

// ===== Status and History Tests =====

#[tokio::test]
async fn test_get_status_success() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test GetStatus", ExperimentStatus::Running).await;
    
    let result = service.get_status(exp.id).await;
    assert!(result.is_ok());
    let status = result.unwrap();
    assert_eq!(status.status, "RUNNING");
    assert_eq!(status.id, exp.id.to_string());
}

#[tokio::test]
async fn test_get_status_not_found() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let service = ExperimentControlService::new(
        exp_repo, 
        SqlxMethodRepository::new(pool.clone()), 
        SqlxStateChangeLogRepository::new(pool.clone())
    );

    let result = service.get_status(Uuid::new_v4()).await;
    assert!(result.is_err());
    assert!(matches!(result.unwrap_err(), ExperimentControlError::NotFound(_)));
}

// ===== Full Lifecycle Test =====

#[tokio::test]
async fn test_full_lifecycle() {
    let db_id = Uuid::new_v4().to_string();
    let pool = init_db(&format!("sqlite:file:{}?mode=memory&cache=shared", db_id))
        .await
        .unwrap();

    let exp_repo = SqlxExperimentRepository::new(pool.clone());
    let method_repo = SqlxMethodRepository::new(pool.clone());
    let log_repo = SqlxStateChangeLogRepository::new(pool.clone());
    let service = ExperimentControlService::new(exp_repo, method_repo, log_repo);

    let user_id = Uuid::new_v4();
    let exp = create_experiment_with_status(&pool, user_id, "Test Full Lifecycle", ExperimentStatus::Idle).await;
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
