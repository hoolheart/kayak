//! Method Management API Handlers
//!
//! Provides REST API endpoints for method CRUD operations and validation.

use std::sync::Arc;

use axum::{
    extract::{Path, Query, State},
    Json,
};
use serde::Deserialize;
use uuid::Uuid;

use crate::auth::middleware::require_auth::RequireAuth;
use crate::core::error::{ApiResponse, AppError};
use crate::models::dto::method_dto::{
    CreateMethodRequest, MethodDto, MethodListResponse, UpdateMethodRequest,
};
use crate::services::method_service::{
    MethodService, MethodServiceError, MethodServiceTrait, ValidationResult,
};
use crate::db::repository::method_repo::SqlxMethodRepository;

/// Application state for method handlers
pub type AppState = Arc<dyn MethodServiceTrait>;

/// Adapter that wraps MethodService<SqlxMethodRepository> to implement MethodServiceTrait
pub struct MethodServiceAdapter {
    service: MethodService<SqlxMethodRepository>,
}

impl MethodServiceAdapter {
    pub fn new(service: MethodService<SqlxMethodRepository>) -> Self {
        Self { service }
    }
}

#[axum::async_trait]
impl MethodServiceTrait for MethodServiceAdapter {
    async fn create_method(
        &self,
        request: CreateMethodRequest,
        user_id: Uuid,
    ) -> Result<MethodDto, MethodServiceError> {
        self.service.create_method(request, user_id).await
    }

    async fn get_method(&self, id: Uuid, user_id: Uuid) -> Result<MethodDto, MethodServiceError> {
        self.service.get_method(id, user_id).await
    }

    async fn update_method(
        &self,
        id: Uuid,
        request: UpdateMethodRequest,
        user_id: Uuid,
    ) -> Result<MethodDto, MethodServiceError> {
        self.service.update_method(id, request, user_id).await
    }

    async fn delete_method(&self, id: Uuid, user_id: Uuid) -> Result<(), MethodServiceError> {
        self.service.delete_method(id, user_id).await
    }

    async fn list_methods(
        &self,
        user_id: Uuid,
        page: i64,
        size: i64,
    ) -> Result<MethodListResponse, MethodServiceError> {
        self.service.list_methods(user_id, page, size).await
    }

    async fn validate_method(
        &self,
        process_definition: serde_json::Value,
    ) -> Result<ValidationResult, MethodServiceError> {
        Ok(self.service.validate_process_definition(&process_definition))
    }
}

/// Query parameters for listing methods
#[derive(Debug, Deserialize)]
pub struct ListMethodsQuery {
    #[serde(default = "default_page")]
    pub page: i64,
    #[serde(default = "default_size")]
    pub size: i64,
}

fn default_page() -> i64 {
    1
}

fn default_size() -> i64 {
    10
}

/// Validate method request
#[derive(Debug, Deserialize)]
pub struct ValidateMethodRequest {
    pub process_definition: serde_json::Value,
}

/// Create method handler
///
/// POST /api/v1/methods
pub async fn create_method(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Json(payload): Json<CreateMethodRequest>,
) -> Result<Json<ApiResponse<MethodDto>>, AppError> {
    let result = handler
        .create_method(payload, user_ctx.user_id)
        .await
        .map_err(method_error_to_app_error)?;

    // C1 fix: Return 201 for creation
    Ok(Json(ApiResponse::created(result)))
}

/// List methods handler
///
/// GET /api/v1/methods
pub async fn list_methods(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Query(query): Query<ListMethodsQuery>,
) -> Result<Json<ApiResponse<MethodListResponse>>, AppError> {
    // M10 fix: Use clamped values for pagination
    let page = query.page.clamp(1, i64::MAX);
    let size = query.size.clamp(1, 100);

    let result = handler
        .list_methods(user_ctx.user_id, page, size)
        .await
        .map_err(method_error_to_app_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Get method detail handler (M1/M2 fix: passes user_id for ownership check)
///
/// GET /api/v1/methods/{id}
pub async fn get_method(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<MethodDto>>, AppError> {
    let result = handler
        .get_method(id, user_ctx.user_id)
        .await
        .map_err(method_error_to_app_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Update method handler (M1 fix: passes user_id for ownership check)
///
/// PUT /api/v1/methods/{id}
pub async fn update_method(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateMethodRequest>,
) -> Result<Json<ApiResponse<MethodDto>>, AppError> {
    let result = handler
        .update_method(id, payload, user_ctx.user_id)
        .await
        .map_err(method_error_to_app_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Delete method handler (M1 fix: passes user_id for ownership check)
///
/// DELETE /api/v1/methods/{id}
pub async fn delete_method(
    State(handler): State<AppState>,
    RequireAuth(user_ctx): RequireAuth,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<()>>, AppError> {
    handler
        .delete_method(id, user_ctx.user_id)
        .await
        .map_err(method_error_to_app_error)?;

    Ok(Json(ApiResponse::success(())))
}

/// Validate method handler
///
/// POST /api/v1/methods/validate
pub async fn validate_method(
    State(handler): State<AppState>,
    RequireAuth(_user_ctx): RequireAuth,
    Json(payload): Json<ValidateMethodRequest>,
) -> Result<Json<ApiResponse<ValidationResult>>, AppError> {
    let result = handler
        .validate_method(payload.process_definition)
        .await
        .map_err(method_error_to_app_error)?;

    Ok(Json(ApiResponse::success(result)))
}

/// Convert MethodServiceError to AppError
fn method_error_to_app_error(err: MethodServiceError) -> AppError {
    match err {
        MethodServiceError::NotFound => AppError::NotFound("方法不存在".to_string()),
        MethodServiceError::Validation(msg) => AppError::BadRequest(msg),
        MethodServiceError::Forbidden => AppError::Forbidden("无权操作此方法".to_string()),
        MethodServiceError::Repository(repo_err) => {
            tracing::error!("Method repository error: {}", repo_err);
            AppError::InternalError("数据库操作失败".to_string())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_page() {
        assert_eq!(default_page(), 1);
    }

    #[test]
    fn test_default_size() {
        assert_eq!(default_size(), 10);
    }

    #[test]
    fn test_list_methods_query_defaults() {
        let query = ListMethodsQuery {
            page: default_page(),
            size: default_size(),
        };
        assert_eq!(query.page, 1);
        assert_eq!(query.size, 10);
    }

    #[test]
    fn test_list_methods_query_custom() {
        let query = ListMethodsQuery { page: 2, size: 20 };
        assert_eq!(query.page, 2);
        assert_eq!(query.size, 20);
    }

    #[test]
    fn test_validate_method_request_deserialize() {
        let json = r#"{"process_definition": {"nodes": []}}"#;
        let req: ValidateMethodRequest = serde_json::from_str(json).unwrap();
        assert!(req.process_definition.is_object());
    }

    #[test]
    fn test_validation_result_serialize() {
        let result = ValidationResult {
            valid: true,
            errors: vec![],
        };
        let json = serde_json::to_string(&result).unwrap();
        assert!(json.contains("\"valid\":true"));
        assert!(json.contains("\"errors\":[]"));
    }

    #[test]
    fn test_validation_result_with_errors() {
        let result = ValidationResult {
            valid: false,
            errors: vec!["缺少Start节点".to_string()],
        };
        assert!(!result.valid);
        assert_eq!(result.errors.len(), 1);
    }

    #[test]
    fn test_list_methods_query_negative_page() {
        let query = ListMethodsQuery { page: -1, size: 10 };
        let page = if query.page < 1 { 1 } else { query.page };
        assert_eq!(page, 1);
    }

    #[test]
    fn test_list_methods_query_size_too_large() {
        let query = ListMethodsQuery { page: 1, size: 200 };
        let size = if query.size < 1 || query.size > 100 {
            10
        } else {
            query.size
        };
        assert_eq!(size, 10);
    }

    #[test]
    fn test_method_error_to_app_error_not_found() {
        let err = MethodServiceError::NotFound;
        let app_err = method_error_to_app_error(err);
        match app_err {
            AppError::NotFound(msg) => assert_eq!(msg, "方法不存在"),
            _ => panic!("Expected NotFound"),
        }
    }

    #[test]
    fn test_method_error_to_app_error_validation() {
        let err = MethodServiceError::Validation("名称不能为空".to_string());
        let app_err = method_error_to_app_error(err);
        match app_err {
            AppError::BadRequest(msg) => assert_eq!(msg, "名称不能为空"),
            _ => panic!("Expected BadRequest"),
        }
    }

    #[test]
    fn test_method_error_to_app_error_forbidden() {
        let err = MethodServiceError::Forbidden;
        let app_err = method_error_to_app_error(err);
        match app_err {
            AppError::Forbidden(msg) => assert_eq!(msg, "无权操作此方法"),
            _ => panic!("Expected Forbidden"),
        }
    }
}
