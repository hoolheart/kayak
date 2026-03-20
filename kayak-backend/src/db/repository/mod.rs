//! 数据访问层 (Repository)
//!
//! 提供实体的CRUD操作

pub mod user_repo;
pub mod workbench_repo;

// 基础Repository trait
use async_trait::async_trait;
use sqlx::Error;
use uuid::Uuid;

/// 基础Repository接口
#[async_trait]
pub trait Repository<T> {
    /// 根据ID查找实体
    async fn find_by_id(&self, id: Uuid) -> Result<Option<T>, Error>;

    /// 查找所有实体
    async fn find_all(&self) -> Result<Vec<T>, Error>;

    /// 创建实体
    async fn create(&self, entity: T) -> Result<T, Error>;

    /// 更新实体
    async fn update(&self, id: Uuid, entity: T) -> Result<T, Error>;

    /// 删除实体
    async fn delete(&self, id: Uuid) -> Result<u64, Error>;
}
