//! 环节执行引擎数据类型定义
//!
//! 包含所有引擎使用的数据结构：环节类型、环节定义、过程定义、
//! 执行上下文、执行结果、错误类型等。

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

use crate::drivers::core::{DriverError, PointValue};

// ============================================================================
// StepType
// ============================================================================

/// 环节类型
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "UPPERCASE")]
pub enum StepType {
    /// 开始环节：标记试验开始，初始化执行上下文
    Start,
    /// 读取环节：从设备测点读取值，存入执行上下文
    Read,
    /// 控制环节：向设备测点写入控制值
    Control,
    /// 延迟环节：暂停执行指定时长
    Delay,
    /// 结束环节：标记试验结束
    End,
}

impl std::fmt::Display for StepType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            StepType::Start => write!(f, "Start"),
            StepType::Read => write!(f, "Read"),
            StepType::Control => write!(f, "Control"),
            StepType::Delay => write!(f, "Delay"),
            StepType::End => write!(f, "End"),
        }
    }
}

// ============================================================================
// StepDefinition
// ============================================================================

/// 环节定义
///
/// 从 JSON 过程定义解析得到的单个环节。
/// 使用 serde 的 tagged enum 反序列化，根据 type 字段自动映射到对应变体。
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "UPPERCASE")]
pub enum StepDefinition {
    /// 开始环节
    Start { id: String, name: String },
    /// 读取环节
    Read {
        id: String,
        name: String,
        /// 测点 UUID（字符串格式，执行时解析为 Uuid）
        point_id: String,
        /// 目标变量名（读取的值存入执行上下文的此变量）
        target_var: String,
    },
    /// 控制环节
    Control {
        id: String,
        name: String,
        /// 测点 UUID（字符串格式）
        point_id: String,
        /// 要写入的值
        value: PointValue,
    },
    /// 延迟环节
    Delay {
        id: String,
        name: String,
        /// 延迟时长（毫秒），必须 >= 0
        duration_ms: u64,
    },
    /// 结束环节
    End { id: String, name: String },
}

impl StepDefinition {
    /// 获取环节 ID
    pub fn id(&self) -> &str {
        match self {
            StepDefinition::Start { id, .. } => id,
            StepDefinition::Read { id, .. } => id,
            StepDefinition::Control { id, .. } => id,
            StepDefinition::Delay { id, .. } => id,
            StepDefinition::End { id, .. } => id,
        }
    }

    /// 获取环节名称
    pub fn name(&self) -> &str {
        match self {
            StepDefinition::Start { name, .. } => name,
            StepDefinition::Read { name, .. } => name,
            StepDefinition::Control { name, .. } => name,
            StepDefinition::Delay { name, .. } => name,
            StepDefinition::End { name, .. } => name,
        }
    }

    /// 获取环节类型
    pub fn step_type(&self) -> StepType {
        match self {
            StepDefinition::Start { .. } => StepType::Start,
            StepDefinition::Read { .. } => StepType::Read,
            StepDefinition::Control { .. } => StepType::Control,
            StepDefinition::Delay { .. } => StepType::Delay,
            StepDefinition::End { .. } => StepType::End,
        }
    }
}

// ============================================================================
// ProcessDefinition
// ============================================================================

/// 过程定义
///
/// 从 Method.process_definition 解析得到的完整过程定义。
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProcessDefinition {
    /// 过程定义版本
    pub version: String,
    /// 环节列表（按执行顺序排列）
    pub steps: Vec<StepDefinition>,
}

impl ProcessDefinition {
    /// 从 JSON Value 解析过程定义
    ///
    /// # Errors
    /// 返回 `ParseError` 如果：
    /// - JSON 格式无效
    /// - 缺少必填字段
    /// - 环节类型未知
    /// - 存在重复的步骤 ID
    /// - 结构验证失败（第一个步骤不是 Start、最后一个步骤不是 End）
    pub fn from_json(value: serde_json::Value) -> Result<Self, ParseError> {
        let def: ProcessDefinition =
            serde_json::from_value(value).map_err(|e| ParseError::InvalidJson(e.to_string()))?;

        // 验证步骤 ID 不重复
        let mut seen_ids = std::collections::HashSet::new();
        for step in &def.steps {
            let id = step.id();
            if !seen_ids.insert(id.to_string()) {
                return Err(ParseError::DuplicateStepId(id.to_string()));
            }
        }

        // 结构验证：第一个步骤必须是 Start
        if let Some(first) = def.steps.first() {
            if !matches!(first, StepDefinition::Start { .. }) {
                return Err(ParseError::InvalidStructure(
                    "First step must be Start".to_string(),
                ));
            }
        }

        // 结构验证：最后一个步骤必须是 End
        if let Some(last) = def.steps.last() {
            if !matches!(last, StepDefinition::End { .. }) {
                return Err(ParseError::InvalidStructure(
                    "Last step must be End".to_string(),
                ));
            }
        }

        Ok(def)
    }

    /// 从 JSON 字符串解析过程定义
    pub fn from_json_str(json: &str) -> Result<Self, ParseError> {
        let value: serde_json::Value =
            serde_json::from_str(json).map_err(|e| ParseError::InvalidJson(e.to_string()))?;
        Self::from_json(value)
    }
}

// ============================================================================
// ExecutionStatus
// ============================================================================

/// 执行状态
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExecutionStatus {
    /// 初始状态
    Initialized,
    /// 已开始（Start 环节已执行）
    Running,
    /// 已完成（End 环节已执行或所有步骤执行完毕）
    Completed,
    /// 执行失败
    Failed,
}

// ============================================================================
// StepStatus
// ============================================================================

/// 步骤执行状态
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub enum StepStatus {
    /// 执行成功
    Success,
    /// 执行失败
    Failed,
}

// ============================================================================
// StepLogEntry
// ============================================================================

/// 环节执行日志条目
#[derive(Debug, Clone, Serialize)]
pub struct StepLogEntry {
    /// 步骤 ID
    pub step_id: String,
    /// 步骤类型
    pub step_type: StepType,
    /// 步骤名称
    pub step_name: String,
    /// 开始时间
    pub start_time: DateTime<Utc>,
    /// 结束时间
    pub end_time: DateTime<Utc>,
    /// 执行状态
    pub status: StepStatus,
    /// 执行耗时（毫秒）
    pub duration_ms: u64,
    /// 错误信息（仅失败时有值）
    pub error_message: Option<String>,
}

// ============================================================================
// ExecutionContext
// ============================================================================

/// 执行上下文
///
/// 引擎在执行过程中维护的状态容器，包含变量存储、执行状态和日志。
/// 每次执行都创建新的 ExecutionContext 实例，确保执行间隔离（TC-035）。
#[derive(Debug)]
pub struct ExecutionContext {
    /// 变量存储：Read 环节的输出存入此映射
    pub variables: HashMap<String, PointValue>,
    /// 过程开始时间（由 Start 环节设置）
    pub start_time: Option<DateTime<Utc>>,
    /// 执行状态
    pub status: ExecutionStatus,
    /// 环节执行日志
    pub logs: Vec<StepLogEntry>,
}

impl ExecutionContext {
    /// 创建新的执行上下文（初始状态）
    pub fn new() -> Self {
        Self {
            variables: HashMap::new(),
            start_time: None,
            status: ExecutionStatus::Initialized,
            logs: Vec::new(),
        }
    }

    /// 记录环节执行日志
    #[allow(clippy::too_many_arguments)]
    pub fn log_step(
        &mut self,
        step_id: String,
        step_type: StepType,
        step_name: String,
        start_time: DateTime<Utc>,
        end_time: DateTime<Utc>,
        status: StepStatus,
        error_message: Option<String>,
    ) {
        let duration_ms = (end_time - start_time).num_milliseconds().max(0) as u64;
        self.logs.push(StepLogEntry {
            step_id,
            step_type,
            step_name,
            start_time,
            end_time,
            status,
            duration_ms,
            error_message,
        });
    }

    /// 获取变量值
    pub fn get_variable(&self, name: &str) -> Option<&PointValue> {
        self.variables.get(name)
    }

    /// 设置变量值（后写入覆盖先写入，TC-034）
    pub fn set_variable(&mut self, name: String, value: PointValue) {
        self.variables.insert(name, value);
    }
}

impl Default for ExecutionContext {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================================
// StepResult
// ============================================================================

/// 环节执行结果
#[derive(Debug, Clone)]
pub struct StepResult {
    /// 执行耗时（毫秒）
    pub duration_ms: u64,
    /// 附加数据（可选，用于环节间传递信息）
    pub data: Option<PointValue>,
}

// ============================================================================
// ExecutionError
// ============================================================================

/// 执行错误类型
#[derive(Debug, Clone)]
pub enum ExecutionError {
    /// 设备驱动错误
    DriverError(String),
    /// 环节配置错误（如缺少必填字段）
    ConfigError(String),
    /// 解析错误
    ParseError(String),
    /// 内部错误
    InternalError(String),
}

impl std::fmt::Display for ExecutionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ExecutionError::DriverError(msg) => write!(f, "Driver error: {}", msg),
            ExecutionError::ConfigError(msg) => write!(f, "Config error: {}", msg),
            ExecutionError::ParseError(msg) => write!(f, "Parse error: {}", msg),
            ExecutionError::InternalError(msg) => write!(f, "Internal error: {}", msg),
        }
    }
}

impl std::error::Error for ExecutionError {}

impl From<DriverError> for ExecutionError {
    fn from(err: DriverError) -> Self {
        ExecutionError::DriverError(err.to_string())
    }
}

// ============================================================================
// ParseError
// ============================================================================

/// 解析错误类型
#[derive(Debug, Clone)]
pub enum ParseError {
    /// JSON 格式无效
    InvalidJson(String),
    /// 未知的环节类型
    UnknownStepType(String),
    /// 缺少必填字段
    MissingField { field: String, step_type: String },
    /// 重复的步骤 ID
    DuplicateStepId(String),
    /// 结构验证失败（如第一个步骤不是 Start、最后一个步骤不是 End）
    InvalidStructure(String),
}

impl std::fmt::Display for ParseError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ParseError::InvalidJson(msg) => write!(f, "Invalid JSON: {}", msg),
            ParseError::UnknownStepType(t) => write!(f, "Unknown step type: {}", t),
            ParseError::MissingField { field, step_type } => {
                write!(
                    f,
                    "Missing required field '{}' in step type '{}'",
                    field, step_type
                )
            }
            ParseError::DuplicateStepId(id) => write!(f, "Duplicate step ID: {}", id),
            ParseError::InvalidStructure(msg) => {
                write!(f, "Invalid process structure: {}", msg)
            }
        }
    }
}

impl std::error::Error for ParseError {}

// ============================================================================
// ProcessResult
// ============================================================================

/// 过程执行结果
///
/// 可从 ExecutionContext 派生，用于向外部报告执行摘要。
#[derive(Debug, Clone)]
pub struct ProcessResult {
    /// 执行是否成功
    pub success: bool,
    /// 总步骤数
    pub total_steps: usize,
    /// 已完成的步骤数
    pub completed_steps: usize,
    /// 最终执行状态
    pub status: ExecutionStatus,
    /// 错误信息（仅失败时有值）
    pub error: Option<ExecutionError>,
}

impl ProcessResult {
    /// 从 ExecutionContext 和总步骤数构建 ProcessResult
    pub fn from_context(context: &ExecutionContext, total_steps: usize) -> Self {
        let completed_steps = context
            .logs
            .iter()
            .filter(|log| log.status == StepStatus::Success)
            .count();

        Self {
            success: context.status == ExecutionStatus::Completed,
            total_steps,
            completed_steps,
            status: context.status,
            error: context
                .logs
                .iter()
                .find(|log| log.status == StepStatus::Failed)
                .and_then(|log| log.error_message.as_ref())
                .map(|msg| ExecutionError::InternalError(msg.clone())),
        }
    }
}

// ============================================================================
// EngineError
// ============================================================================

/// 引擎执行错误
///
/// 封装引擎执行过程中的错误，包含执行上下文以便调用方获取失败时的完整状态。
#[derive(Debug)]
pub enum EngineError {
    /// 执行失败：包含失败时的执行上下文和原始错误
    ///
    /// 调用方可通过此变体获取失败时的 ExecutionContext，
    /// 包括已执行步骤的日志、变量状态等。
    ExecutionFailed {
        /// 失败时的执行上下文
        context: ExecutionContext,
        /// 导致失败的原始错误
        source_error: ExecutionError,
    },
    /// 设备未找到
    DeviceNotFound(Uuid),
    /// 获取驱动锁失败
    LockError(String),
}

impl std::fmt::Display for EngineError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            EngineError::ExecutionFailed { source_error, .. } => {
                write!(f, "Execution failed: {}", source_error)
            }
            EngineError::DeviceNotFound(id) => write!(f, "Device not found: {}", id),
            EngineError::LockError(msg) => write!(f, "Lock error: {}", msg),
        }
    }
}

impl std::error::Error for EngineError {}
