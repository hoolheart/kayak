//! Read 环节执行器
//!
//! 读取环节：从设备测点读取值，存入执行上下文。

use async_trait::async_trait;
use uuid::Uuid;

use super::super::executor::{DriverAccess, StepExecutor};
use super::super::types::{ExecutionContext, ExecutionError, StepDefinition, StepResult};

/// Read 环节执行器
pub struct ReadStepExecutor;

#[async_trait]
impl StepExecutor for ReadStepExecutor {
    fn step_type(&self) -> &str {
        "Read"
    }

    async fn execute(
        &self,
        step: &StepDefinition,
        context: &mut ExecutionContext,
        driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError> {
        let start = std::time::Instant::now();

        if let StepDefinition::Read {
            point_id,
            target_var,
            ..
        } = step
        {
            let point_uuid = Uuid::parse_str(point_id).map_err(|e| {
                ExecutionError::ConfigError(format!("Invalid point_id '{}': {}", point_id, e))
            })?;

            let value = driver.read_point(point_uuid)?;
            context.set_variable(target_var.clone(), value.clone());

            Ok(StepResult {
                duration_ms: start.elapsed().as_millis() as u64,
                data: Some(value),
            })
        } else {
            Err(ExecutionError::InternalError(
                "Expected Read step definition".to_string(),
            ))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::core::PointValue;

    #[tokio::test]
    async fn test_read_stores_variable() {
        let mut ctx = ExecutionContext::new();
        let executor = ReadStepExecutor;
        let step = StepDefinition::Read {
            id: "r1".to_string(),
            name: "Read Temp".to_string(),
            point_id: "00000000-0000-0000-0000-000000000001".to_string(),
            target_var: "temperature".to_string(),
        };

        let result = executor.execute(&step, &mut ctx, &MockDriver).await.unwrap();

        assert!(ctx.get_variable("temperature").is_some());
        assert_eq!(ctx.get_variable("temperature").unwrap().to_f64(), Some(42.0));
        assert!(result.data.is_some());
    }

    #[tokio::test]
    async fn test_read_invalid_point_id() {
        let mut ctx = ExecutionContext::new();
        let executor = ReadStepExecutor;
        let step = StepDefinition::Read {
            id: "r1".to_string(),
            name: "Read Temp".to_string(),
            point_id: "not-a-uuid".to_string(),
            target_var: "temperature".to_string(),
        };

        let result = executor.execute(&step, &mut ctx, &MockDriver).await;
        assert!(result.is_err());
    }

    struct MockDriver;
    impl DriverAccess for MockDriver {
        fn read_point(&self, _point_id: Uuid) -> Result<PointValue, ExecutionError> {
            Ok(PointValue::Number(42.0))
        }
        fn write_point(&self, _point_id: Uuid, _value: PointValue) -> Result<(), ExecutionError> {
            Ok(())
        }
    }
}
