//! Delay 环节执行器
//!
//! 延迟环节：暂停执行指定时长（毫秒）。

use async_trait::async_trait;

use super::super::executor::{DriverAccess, StepExecutor};
use super::super::types::{ExecutionContext, ExecutionError, StepDefinition, StepResult};

/// Delay 环节执行器
pub struct DelayStepExecutor;

#[async_trait]
impl StepExecutor for DelayStepExecutor {
    fn step_type(&self) -> &str {
        "Delay"
    }

    async fn execute(
        &self,
        step: &StepDefinition,
        _context: &mut ExecutionContext,
        _driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError> {
        let start = std::time::Instant::now();

        if let StepDefinition::Delay { duration_ms, .. } = step {
            tokio::time::sleep(std::time::Duration::from_millis(*duration_ms)).await;

            Ok(StepResult {
                duration_ms: start.elapsed().as_millis() as u64,
                data: None,
            })
        } else {
            Err(ExecutionError::InternalError(
                "Expected Delay step definition".to_string(),
            ))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::core::PointValue;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_delay_waits_for_duration() {
        let mut ctx = ExecutionContext::new();
        let executor = DelayStepExecutor;
        let step = StepDefinition::Delay {
            id: "d1".to_string(),
            name: "Wait 10ms".to_string(),
            duration_ms: 10,
        };

        let before = std::time::Instant::now();
        let result = executor
            .execute(&step, &mut ctx, &MockDriver)
            .await
            .unwrap();
        let elapsed = before.elapsed();

        assert!(elapsed.as_millis() >= 10);
        assert!(result.duration_ms >= 10);
    }

    #[tokio::test]
    async fn test_delay_zero_returns_immediately() {
        let mut ctx = ExecutionContext::new();
        let executor = DelayStepExecutor;
        let step = StepDefinition::Delay {
            id: "d1".to_string(),
            name: "No delay".to_string(),
            duration_ms: 0,
        };

        let result = executor
            .execute(&step, &mut ctx, &MockDriver)
            .await
            .unwrap();
        assert!(result.duration_ms < 50); // Should be very fast
    }

    struct MockDriver;
    impl DriverAccess for MockDriver {
        fn read_point(&self, _point_id: Uuid) -> Result<PointValue, ExecutionError> {
            unreachable!("read_point should not be called in Delay tests")
        }
        fn write_point(&self, _point_id: Uuid, _value: PointValue) -> Result<(), ExecutionError> {
            unreachable!("write_point should not be called in Delay tests")
        }
    }
}
