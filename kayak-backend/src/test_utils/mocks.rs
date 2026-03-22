//! Mock 工具
//!
//! 提供测试用的 Mock 实现

use crate::models::entities::*;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use uuid::Uuid;

/// 内存用户 Repository Mock
pub struct MockUserRepository {
    users: Arc<Mutex<HashMap<Uuid, User>>>,
}

impl MockUserRepository {
    pub fn new() -> Self {
        Self {
            users: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn insert(&self, user: User) {
        self.users.lock().unwrap().insert(user.id, user);
    }

    pub fn find_by_id(&self, id: Uuid) -> Option<User> {
        self.users.lock().unwrap().get(&id).cloned()
    }

    pub fn find_by_email(&self, email: &str) -> Option<User> {
        self.users
            .lock()
            .unwrap()
            .values()
            .find(|u| u.email == email)
            .cloned()
    }
}

impl Default for MockUserRepository {
    fn default() -> Self {
        Self::new()
    }
}

/// Mock 时间提供者
pub struct MockTimeProvider {
    fixed_time: Option<chrono::DateTime<chrono::Utc>>,
}

impl MockTimeProvider {
    pub fn new() -> Self {
        Self { fixed_time: None }
    }

    pub fn with_fixed_time(time: chrono::DateTime<chrono::Utc>) -> Self {
        Self {
            fixed_time: Some(time),
        }
    }

    pub fn now(&self) -> chrono::DateTime<chrono::Utc> {
        self.fixed_time.unwrap_or_else(chrono::Utc::now)
    }
}

impl Default for MockTimeProvider {
    fn default() -> Self {
        Self::new()
    }
}

/// Mock UUID 生成器
pub struct MockUuidGenerator {
    fixed_uuid: Option<Uuid>,
    sequence: Arc<Mutex<Vec<Uuid>>>,
}

impl MockUuidGenerator {
    pub fn new() -> Self {
        Self {
            fixed_uuid: None,
            sequence: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn with_fixed_uuid(uuid: Uuid) -> Self {
        Self {
            fixed_uuid: Some(uuid),
            sequence: Arc::new(Mutex::new(Vec::new())),
        }
    }

    pub fn with_sequence(uuids: Vec<Uuid>) -> Self {
        Self {
            fixed_uuid: None,
            sequence: Arc::new(Mutex::new(uuids)),
        }
    }

    pub fn generate(&self) -> Uuid {
        if let Some(uuid) = self.fixed_uuid {
            return uuid;
        }

        let mut sequence = self.sequence.lock().unwrap();
        if !sequence.is_empty() {
            sequence.remove(0)
        } else {
            Uuid::new_v4()
        }
    }
}

impl Default for MockUuidGenerator {
    fn default() -> Self {
        Self::new()
    }
}
