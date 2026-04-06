//! HDF5数据文件路径策略

use std::path::{Path, PathBuf};

use chrono::{DateTime, Utc};
use uuid::Uuid;

use super::error::Hdf5Error;

/// 路径策略配置
#[derive(Debug, Clone)]
pub struct PathStrategyConfig {
    /// 根数据目录
    pub root_dir: PathBuf,
    /// 是否使用实验ID前缀
    pub use_exp_id_prefix: bool,
    /// 是否按日期组织
    pub use_date_organization: bool,
}

impl Default for PathStrategyConfig {
    fn default() -> Self {
        Self {
            root_dir: PathBuf::from("/tmp/kayak/data"),
            use_exp_id_prefix: true,
            use_date_organization: true,
        }
    }
}

/// 路径策略
#[derive(Debug, Clone)]
pub struct PathStrategy {
    config: PathStrategyConfig,
}

impl PathStrategy {
    /// 创建路径策略
    pub fn new(config: PathStrategyConfig) -> Self {
        Self { config }
    }

    /// 生成实验数据路径
    ///
    /// 路径格式：
    /// - 有日期组织：{root}/{exp_id_prefix}/{YYYY}/{MM}/{DD}/exp.h5
    /// - 无日期组织：{root}/{exp_id_prefix}/exp.h5
    pub fn generate_path(
        &self,
        exp_id: Uuid,
        timestamp: DateTime<Utc>,
    ) -> Result<PathBuf, Hdf5Error> {
        let mut path = self.config.root_dir.clone();

        if self.config.use_exp_id_prefix {
            // 使用实验ID的前8位作为前缀
            path.push(&exp_id.to_string()[..8]);
        }

        if self.config.use_date_organization {
            path.push(format!("{:4}", timestamp.format("%Y")));
            path.push(format!("{:02}", timestamp.format("%m")));
            path.push(format!("{:02}", timestamp.format("%d")));
        }

        path.push("exp.h5");

        Ok(path)
    }

    /// 规范化路径
    ///
    /// 移除多余的斜杠和点号
    pub fn normalize(&self, path: &Path) -> Result<PathBuf, Hdf5Error> {
        let components: Vec<_> = path
            .components()
            .filter(|c| !matches!(c, std::path::Component::ParentDir))
            .collect();

        let normalized: PathBuf = components.into_iter().collect();
        Ok(normalized)
    }

    /// 验证路径是否在允许的根目录下
    pub fn is_under_root(&self, path: &Path) -> bool {
        path.starts_with(&self.config.root_dir)
    }

    /// 获取根目录
    pub fn root_dir(&self) -> &Path {
        &self.config.root_dir
    }
}

impl Default for PathStrategy {
    fn default() -> Self {
        Self::new(PathStrategyConfig::default())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_path_with_date() {
        let strategy = PathStrategy::default();
        let exp_id = Uuid::parse_str("12345678-1234-1234-1234-123456789abc").unwrap();
        let timestamp = DateTime::parse_from_rfc3339("2026-03-26T10:30:00Z")
            .unwrap()
            .with_timezone(&Utc);

        let path = strategy.generate_path(exp_id, timestamp).unwrap();

        let expected = PathBuf::from("/tmp/kayak/data/12345678/2026/03/26/exp.h5");
        assert_eq!(path, expected);
    }

    #[test]
    fn test_generate_path_without_date() {
        let config = PathStrategyConfig {
            root_dir: PathBuf::from("/data"),
            use_exp_id_prefix: true,
            use_date_organization: false,
        };
        let strategy = PathStrategy::new(config);
        let exp_id = Uuid::parse_str("abcdef01-1234-1234-1234-123456789abc").unwrap();
        let timestamp = Utc::now();

        let path = strategy.generate_path(exp_id, timestamp).unwrap();

        let expected = PathBuf::from("/data/abcdef01/exp.h5");
        assert_eq!(path, expected);
    }

    #[test]
    fn test_normalize_path() {
        let strategy = PathStrategy::default();
        let messy = PathBuf::from("/tmp//kayak///data//exp.h5");

        let normalized = strategy.normalize(&messy).unwrap();

        assert_eq!(normalized, PathBuf::from("/tmp/kayak/data/exp.h5"));
    }

    #[test]
    fn test_is_under_root() {
        let strategy = PathStrategy::default();

        let safe_path = PathBuf::from("/tmp/kayak/data/experiment.h5");
        assert!(strategy.is_under_root(&safe_path));

        let unsafe_path = PathBuf::from("/etc/passwd");
        assert!(!strategy.is_under_root(&unsafe_path));
    }
}
