//! End 环节执行器
//!
//! 结束环节：标记试验结束。

use async_trait::async_trait;

use super::super::executor::{DriverAccess, StepExecutor};
use super::super::types::{ExecutionContext, ExecutionError, ExecutionStatus, StepDefinition, StepResult};

/// End 环节执行器
pub struct EndStepExecutor;

#[async_trait]
impl StepExecutor for EndStepExecutor {
    fn step_type(&self) -> &str {
        "End"
    }

    async fn execute(
        &self,
        _step: &StepDefinition,
        context: &mut ExecutionContext,
        _driver: &dyn DriverAccess,
    ) -> Result<StepResult, ExecutionError> {
        let start = std::time::Instant::now();

        context.status = ExecutionStatus::Completed;

        Ok(StepResult {
            duration_ms: start.elapsed().as_millis() as u64,
            data: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::drivers::core::PointValue;
    use uuid::Uuid;

    #[tokio::test]
    async fn test_end_sets_completed_status() {
        let mut ctx = ExecutionContext::new();
        let executor = EndStepExecutor;
        let step = StepDefinition::End {
            id: "e1".to_string(),
            name: "End".to_string(),
        };

        let result = executor.execute(&step, &mut ctx, &MockDriver).await.unwrap();

        assert_eq!(ctx.status, ExecutionStatus::Completed);
        assert!(result.data.is_none());
    }

    struct MockDriver;
    impl DriverAccess for MockDriver {
        fn read_point(&self, _point_id: Uuid) -> Result<PointValue, ExecutionError> {
            unimplemented!()
        }
        fn write_point(&self, _point_id: Uuid, _value: PointValue) -> Result<(), ExecutionError> {
            unimplemented!()
        }
    }
}
