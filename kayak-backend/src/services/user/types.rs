//! 用户服务类型定义
//!
//! 定义用户更新等数据结构

use serde::{Deserialize, Serialize};

/// 用户更新实体
///
/// 用于在服务层和仓库层之间传递用户更新数据
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct UpdateUserEntity {
    /// 更新后的用户名
    pub username: Option<String>,
    /// 更新后的头像URL
    pub avatar_url: Option<String>,
}
