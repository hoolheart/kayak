//! Control 环节执行器
//!
//! 控制环节：向设备测点写入控制值。

use async_trait::async_trait;
use uuid::Uuid;

use super::super::executor::{DriverAccess, StepExecutor};
use super::super::types::{ExecutionContext, ExecutionError, StepDefinition, StepResult};

/// Control 环节执行器
pub struct ControlStepExecutor;

#[async_trait]
impl StepExecutor for ControlStepExecutor {
    fn step_type(&self) -> &str {
        "Control"
    }

    async fn execute(
        &self,
        step: &StepDefinition,
        _context: &mut ExecutionContext,
        driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError> {
        let start = std::time::Instant::now();

        if let StepDefinition::Control {
            point_id, value, ..
        } = step
        {
            let point_uuid = Uuid::parse_str(point_id).map_err(|e| {
                ExecutionError::ConfigError(format!("Invalid point_id '{}': {}", point_id, e))
            })?;

            driver.write_point(point_uuid, value.clone())?;

            Ok(StepResult {
                duration_ms: start.elapsed().as_millis() as u64,
                data: None,
            })
        } else {
            Err(ExecutionError::InternalError(
                "Expected Control step definition".to_string(),
            ))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::core::PointValue;
    use std::sync::{Arc, Mutex};

    #[tokio::test]
    async fn test_control_writes_value() {
        let mock = Arc::new(Mutex::new(MockDriver::default()));
        let mut ctx = ExecutionContext::new();
        let executor = ControlStepExecutor;
        let step = StepDefinition::Control {
            id: "c1".to_string(),
            name: "Set Heater".to_string(),
            point_id: "00000000-0000-0000-0000-000000000001".to_string(),
            value: PointValue::Number(75.0),
        };

        let result = executor.execute(&step, &mut ctx, &MockDriverAdapter(mock.clone())).await.unwrap();
        assert!(result.data.is_none());

        let driver = mock.lock().unwrap();
        assert_eq!(driver.last_written_value, Some(PointValue::Number(75.0)));
    }

    #[tokio::test]
    async fn test_control_invalid_point_id() {
        let mut ctx = ExecutionContext::new();
        let executor = ControlStepExecutor;
        let step = StepDefinition::Control {
            id: "c1".to_string(),
            name: "Set Heater".to_string(),
            point_id: "not-a-uuid".to_string(),
            value: PointValue::Number(75.0),
        };

        let result = executor.execute(&step, &mut ctx, &MockDriverAdapter(Arc::new(Mutex::new(MockDriver::default())))).await;
        assert!(result.is_err());
    }

    #[derive(Default)]
    struct MockDriver {
        last_written_value: Option<PointValue>,
    }

    struct MockDriverAdapter(Arc<Mutex<MockDriver>>);
    impl DriverAccess for MockDriverAdapter {
        fn read_point(&self, _point_id: Uuid) -> Result<PointValue, ExecutionError> {
            Ok(PointValue::Number(0.0))
        }
        fn write_point(&self, _point_id: Uuid, value: PointValue) -> Result<(), ExecutionError> {
            let mut driver = self.0.lock().unwrap();
            driver.last_written_value = Some(value);
            Ok(())
        }
    }
}
