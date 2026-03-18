//! 认证服务实现
//!
//! 实现认证相关的服务trait

use std::sync::Arc;

use async_trait::async_trait;
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::core::error::AppError;
use crate::models::entities::user::{User, UserStatus};

use super::{
    dtos::{LoginRequest, RegisterRequest, TokenRefreshRequest},
    error::AuthError,
    traits::{AuthService, LoginResponse, PasswordHasher, TokenClaims, TokenPair, TokenService, TokenType},
};

// JWT配置常量
const ACCESS_TOKEN_EXPIRY_MINUTES: i64 = 15;
const REFRESH_TOKEN_EXPIRY_DAYS: i64 = 7;

/// JWT Token Claims (序列化用)
#[derive(Debug, Serialize, Deserialize)]
struct JwtClaims {
    sub: String,
    email: String,
    token_type: String,
    exp: i64,
    iat: i64,
}

impl From<TokenClaims> for JwtClaims {
    fn from(claims: TokenClaims) -> Self {
        Self {
            sub: claims.sub.to_string(),
            email: claims.email,
            token_type: match claims.token_type {
                TokenType::Access => "access".to_string(),
                TokenType::Refresh => "refresh".to_string(),
            },
            exp: claims.exp,
            iat: claims.iat,
        }
    }
}

/// 认证服务实现
pub struct AuthServiceImpl {
    user_repo: Arc<dyn super::traits::UserRepository>,
    token_service: Arc<dyn TokenService>,
    password_hasher: Arc<dyn PasswordHasher>,
}

impl AuthServiceImpl {
    pub fn new(
        user_repo: Arc<dyn super::traits::UserRepository>,
        token_service: Arc<dyn TokenService>,
        password_hasher: Arc<dyn PasswordHasher>,
    ) -> Self {
        Self {
            user_repo,
            token_service,
            password_hasher,
        }
    }
}

#[async_trait]
impl AuthService for AuthServiceImpl {
    async fn register(&self, req: RegisterRequest) -> Result<User, AppError> {
        // 检查邮箱是否已存在
        if let Some(_) = self.user_repo.find_by_email(&req.email).await? {
            return Err(AuthError::UserAlreadyExists.into());
        }

        // 哈希密码
        let password_hash = self.password_hasher.hash_password(&req.password)?;

        // 创建新用户
        let user = User::new(req.email, password_hash, req.username);

        // 保存到数据库
        self.user_repo.create(&user).await?;

        Ok(user)
    }

    async fn login(&self, req: LoginRequest) -> Result<LoginResponse, AppError> {
        // 查找用户
        let user = self
            .user_repo
            .find_by_email(&req.email)
            .await?
            .ok_or(AuthError::UserNotFound)?;

        // 验证用户状态
        let status = UserStatus::from(user.status.clone());
        if status != UserStatus::Active {
            return Err(AuthError::InactiveUser.into());
        }

        // 验证密码
        let valid = self
            .password_hasher
            .verify_password(&req.password, &user.password_hash)?;

        if !valid {
            return Err(AuthError::InvalidPassword.into());
        }

        // 生成Token对
        let token_pair = self
            .token_service
            .generate_token_pair(user.id, &user.email)?;

        Ok(LoginResponse {
            user_id: user.id,
            email: user.email,
            username: user.username,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
        })
    }

    async fn refresh_token(
        &self,
        req: TokenRefreshRequest,
    ) -> Result<LoginResponse, AppError> {
        // 验证刷新Token
        let claims = self
            .token_service
            .verify_refresh_token(&req.refresh_token)?;

        // 确认Token类型
        if claims.token_type != TokenType::Refresh {
            return Err(AuthError::InvalidTokenType.into());
        }

        // 验证用户是否存在且有效
        let user = self
            .user_repo
            .find_by_id(claims.sub)
            .await?
            .ok_or(AuthError::UserNotFound)?;

        let status = UserStatus::from(user.status.clone());
        if status != UserStatus::Active {
            return Err(AuthError::InactiveUser.into());
        }

        // 生成新的Token对
        let token_pair = self
            .token_service
            .generate_token_pair(user.id, &user.email)?;

        Ok(LoginResponse {
            user_id: user.id,
            email: user.email,
            username: user.username,
            access_token: token_pair.access_token,
            refresh_token: token_pair.refresh_token,
            expires_in: token_pair.expires_in,
        })
    }

    async fn logout(&self, _user_id: Uuid) -> Result<(), AppError> {
        // 在Release 0中，登出操作仅客户端删除Token即可
        // Release 1中可以添加Token黑名单功能
        Ok(())
    }
}

/// JWT Token服务实现
pub struct JwtTokenService {
    access_secret: String,
    refresh_secret: String,
}

impl JwtTokenService {
    pub fn new(access_secret: String, refresh_secret: String) -> Self {
        Self {
            access_secret,
            refresh_secret,
        }
    }
}

impl TokenService for JwtTokenService {
    fn generate_token_pair(
        &self,
        user_id: Uuid,
        email: &str,
    ) -> Result<TokenPair, AppError> {
        let now = Utc::now();

        // 生成Access Token
        let access_exp = now + Duration::minutes(ACCESS_TOKEN_EXPIRY_MINUTES);
        let access_claims = TokenClaims {
            sub: user_id,
            email: email.to_string(),
            token_type: TokenType::Access,
            exp: access_exp.timestamp(),
            iat: now.timestamp(),
        };

        let access_token = encode(
            &Header::default(),
            &JwtClaims::from(access_claims),
            &EncodingKey::from_secret(self.access_secret.as_bytes()),
        )
        .map_err(|e| AppError::InternalError(format!("Token encoding error: {}", e)))?;

        // 生成Refresh Token
        let refresh_exp = now + Duration::days(REFRESH_TOKEN_EXPIRY_DAYS);
        let refresh_claims = TokenClaims {
            sub: user_id,
            email: email.to_string(),
            token_type: TokenType::Refresh,
            exp: refresh_exp.timestamp(),
            iat: now.timestamp(),
        };

        let refresh_token = encode(
            &Header::default(),
            &JwtClaims::from(refresh_claims),
            &EncodingKey::from_secret(self.refresh_secret.as_bytes()),
        )
        .map_err(|e| AppError::InternalError(format!("Token encoding error: {}", e)))?;

        Ok(TokenPair {
            access_token,
            refresh_token,
            token_type: "Bearer".to_string(),
            expires_in: ACCESS_TOKEN_EXPIRY_MINUTES * 60,
        })
    }

    fn verify_access_token(&self,
        token: &str,
    ) -> Result<TokenClaims, AppError> {
        let validation = Validation::default();
        let token_data = decode::<JwtClaims>(
            token,
            &DecodingKey::from_secret(self.access_secret.as_bytes()),
            &validation,
        )
        .map_err(|e| match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                AuthError::TokenExpired
            }
            _ => AuthError::InvalidToken,
        })?;

        let claims = token_data.claims;
        if claims.token_type != "access" {
            return Err(AuthError::InvalidTokenType.into());
        }

        Ok(TokenClaims {
            sub: Uuid::parse_str(&claims.sub)
                .map_err(|_| AuthError::InvalidToken)?,
            email: claims.email,
            token_type: TokenType::Access,
            exp: claims.exp,
            iat: claims.iat,
        })
    }

    fn verify_refresh_token(
        &self,
        token: &str,
    ) -> Result<TokenClaims, AppError> {
        let validation = Validation::default();
        let token_data = decode::<JwtClaims>(
            token,
            &DecodingKey::from_secret(self.refresh_secret.as_bytes()),
            &validation,
        )
        .map_err(|e| match e.kind() {
            jsonwebtoken::errors::ErrorKind::ExpiredSignature => {
                AuthError::TokenExpired
            }
            _ => AuthError::InvalidToken,
        })?;

        let claims = token_data.claims;
        if claims.token_type != "refresh" {
            return Err(AuthError::InvalidTokenType.into());
        }

        Ok(TokenClaims {
            sub: Uuid::parse_str(&claims.sub)
                .map_err(|_| AuthError::InvalidToken)?,
            email: claims.email,
            token_type: TokenType::Refresh,
            exp: claims.exp,
            iat: claims.iat,
        })
    }
}

/// bcrypt密码哈希实现
pub struct BcryptPasswordHasher;

impl PasswordHasher for BcryptPasswordHasher {
    fn hash_password(&self,
        password: &str,
    ) -> Result<String, AppError> {
        hash(password, DEFAULT_COST)
            .map_err(|e| AuthError::HashingError(e.to_string()).into())
    }

    fn verify_password(
        &self,
        password: &str,
        hash: &str,
    ) -> Result<bool, AppError> {
        verify(password, hash)
            .map_err(|e| AuthError::HashingError(e.to_string()).into())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_password_hashing() {
        let hasher = BcryptPasswordHasher;
        let password = "TestPassword123!";

        let hash = hasher.hash_password(password).unwrap();
        assert_ne!(hash, password);
        assert!(hash.starts_with("$2b$"));

        let valid = hasher.verify_password(password, &hash).unwrap();
        assert!(valid);

        let invalid = hasher.verify_password("wrongpassword", &hash).unwrap();
        assert!(!invalid);
    }

    #[test]
    fn test_jwt_token_service() {
        let service = JwtTokenService::new(
            "access_secret_key".to_string(),
            "refresh_secret_key".to_string(),
        );

        let user_id = Uuid::new_v4();
        let email = "test@example.com";

        // Generate token pair
        let pair = service.generate_token_pair(user_id, email).unwrap();
        assert!(!pair.access_token.is_empty());
        assert!(!pair.refresh_token.is_empty());
        assert_eq!(pair.token_type, "Bearer");

        // Verify access token
        let claims = service.verify_access_token(&pair.access_token).unwrap();
        assert_eq!(claims.sub, user_id);
        assert_eq!(claims.email, email);
        assert!(matches!(claims.token_type, TokenType::Access));

        // Verify refresh token
        let claims = service.verify_refresh_token(&pair.refresh_token).unwrap();
        assert_eq!(claims.sub, user_id);
        assert_eq!(claims.email, email);
        assert!(matches!(claims.token_type, TokenType::Refresh));
    }
}
