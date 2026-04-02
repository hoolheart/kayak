//! Experiment Process State Machine
//!
//! Pure state machine logic for experiment state transitions.
//! No I/O, no side effects — just state transition validation.
//!
//! State diagram (from PRD 2.3.1):
//! ```text
//!           +---------+
//!           |  IDLE   |
//!           +----+----+
//!                | load
//!                v
//!           +---------+
//!     +---->| LOADED  |<----+
//!     |     +----+----+     |
//!     |          | start    |
//!     |          v          |
//!  pause      +---------+   |
//! +---------->| RUNNING |---+---> error
//! |           +----+----+   |
//! |                | pause  |
//! |                v        |
//! |           +---------+   |
//! +-----------| PAUSED  |---+
//!             +---------+
//! ```

use crate::models::entities::experiment::ExperimentStatus;

/// State machine operation types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StateMachineOperation {
    Load,
    Start,
    Pause,
    Resume,
    Stop,
    Reset,
    Complete,
    Abort,
}

impl StateMachineOperation {
    /// Returns the lowercase string representation of the operation.
    pub fn as_str(&self) -> &'static str {
        match self {
            StateMachineOperation::Load => "load",
            StateMachineOperation::Start => "start",
            StateMachineOperation::Pause => "pause",
            StateMachineOperation::Resume => "resume",
            StateMachineOperation::Stop => "stop",
            StateMachineOperation::Reset => "reset",
            StateMachineOperation::Complete => "complete",
            StateMachineOperation::Abort => "abort",
        }
    }
}

/// State machine error
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum StateMachineError {
    /// The transition from `from` via the given operation is not valid.
    /// Used for non-terminal states where the operation simply doesn't apply.
    InvalidTransition {
        from: ExperimentStatus,
        operation: StateMachineOperation,
    },
    /// The operation is not allowed because the current state is terminal.
    /// Used specifically for Completed and Aborted states.
    OperationNotAllowed {
        operation: StateMachineOperation,
        current_state: ExperimentStatus,
    },
}

impl std::fmt::Display for StateMachineError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            StateMachineError::InvalidTransition { from, operation } => {
                write!(
                    f,
                    "Invalid transition: cannot perform {:?} from {:?}",
                    operation, from
                )
            }
            StateMachineError::OperationNotAllowed {
                operation,
                current_state,
            } => {
                write!(
                    f,
                    "Operation {:?} not allowed in terminal state {:?}",
                    operation, current_state
                )
            }
        }
    }
}

/// Pure state machine — no I/O, no side effects.
/// All state transition logic goes through this struct.
pub struct StateMachine;

impl StateMachine {
    /// Validate and compute the next state for a given operation.
    /// Returns the target state or an error if the transition is invalid.
    pub fn transition(
        current: ExperimentStatus,
        operation: StateMachineOperation,
    ) -> Result<ExperimentStatus, StateMachineError> {
        match (current, operation) {
            // Load: Idle -> Loaded
            (ExperimentStatus::Idle, StateMachineOperation::Load) => Ok(ExperimentStatus::Loaded),
            // Start: Loaded -> Running, Paused -> Running
            (ExperimentStatus::Loaded, StateMachineOperation::Start)
            | (ExperimentStatus::Paused, StateMachineOperation::Start)
            | (ExperimentStatus::Paused, StateMachineOperation::Resume) => {
                Ok(ExperimentStatus::Running)
            }
            // Pause: Running -> Paused
            (ExperimentStatus::Running, StateMachineOperation::Pause) => {
                Ok(ExperimentStatus::Paused)
            }
            // Stop: Running -> Loaded, Paused -> Loaded
            (ExperimentStatus::Running, StateMachineOperation::Stop)
            | (ExperimentStatus::Paused, StateMachineOperation::Stop) => {
                Ok(ExperimentStatus::Loaded)
            }
            // Reset: any non-terminal -> Idle (including Idle itself as no-op per PRD "任意状态")
            (ExperimentStatus::Idle, StateMachineOperation::Reset)
            | (ExperimentStatus::Loaded, StateMachineOperation::Reset)
            | (ExperimentStatus::Running, StateMachineOperation::Reset)
            | (ExperimentStatus::Paused, StateMachineOperation::Reset) => {
                Ok(ExperimentStatus::Idle)
            }
            // Complete: Running -> Completed
            (ExperimentStatus::Running, StateMachineOperation::Complete) => {
                Ok(ExperimentStatus::Completed)
            }
            // Abort: Running -> Aborted, Paused -> Aborted
            (ExperimentStatus::Running, StateMachineOperation::Abort)
            | (ExperimentStatus::Paused, StateMachineOperation::Abort) => {
                Ok(ExperimentStatus::Aborted)
            }
            // All other combinations are invalid
            (_, _) => {
                // Check if we're in a terminal state
                match current {
                    ExperimentStatus::Completed | ExperimentStatus::Aborted => {
                        Err(StateMachineError::OperationNotAllowed {
                            operation,
                            current_state: current,
                        })
                    }
                    _ => Err(StateMachineError::InvalidTransition {
                        from: current,
                        operation,
                    }),
                }
            }
        }
    }

    /// Check if an operation is allowed in the current state.
    pub fn is_allowed(current: ExperimentStatus, operation: StateMachineOperation) -> bool {
        Self::transition(current, operation).is_ok()
    }

    /// Check if a state is terminal (no further transitions allowed).
    pub fn is_terminal(state: ExperimentStatus) -> bool {
        state.is_terminal()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // === TC-001: Valid State Transitions ===

    #[test]
    fn test_load_idle_to_loaded() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Idle, StateMachineOperation::Load),
            Ok(ExperimentStatus::Loaded)
        );
    }

    #[test]
    fn test_start_loaded_to_running() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Loaded, StateMachineOperation::Start),
            Ok(ExperimentStatus::Running)
        );
    }

    #[test]
    fn test_start_paused_to_running() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Paused, StateMachineOperation::Start),
            Ok(ExperimentStatus::Running)
        );
    }

    #[test]
    fn test_pause_running_to_paused() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Running, StateMachineOperation::Pause),
            Ok(ExperimentStatus::Paused)
        );
    }

    #[test]
    fn test_resume_paused_to_running() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Paused, StateMachineOperation::Resume),
            Ok(ExperimentStatus::Running)
        );
    }

    #[test]
    fn test_stop_running_to_loaded() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Running, StateMachineOperation::Stop),
            Ok(ExperimentStatus::Loaded)
        );
    }

    #[test]
    fn test_stop_paused_to_loaded() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Paused, StateMachineOperation::Stop),
            Ok(ExperimentStatus::Loaded)
        );
    }

    #[test]
    fn test_reset_idle_to_idle() {
        // Reset from Idle is allowed (no-op, per PRD "任意状态")
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Idle, StateMachineOperation::Reset),
            Ok(ExperimentStatus::Idle)
        );
    }

    #[test]
    fn test_reset_loaded_to_idle() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Loaded, StateMachineOperation::Reset),
            Ok(ExperimentStatus::Idle)
        );
    }

    #[test]
    fn test_reset_running_to_idle() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Running, StateMachineOperation::Reset),
            Ok(ExperimentStatus::Idle)
        );
    }

    #[test]
    fn test_reset_paused_to_idle() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Paused, StateMachineOperation::Reset),
            Ok(ExperimentStatus::Idle)
        );
    }

    #[test]
    fn test_complete_running_to_completed() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Running, StateMachineOperation::Complete),
            Ok(ExperimentStatus::Completed)
        );
    }

    #[test]
    fn test_abort_running_to_aborted() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Running, StateMachineOperation::Abort),
            Ok(ExperimentStatus::Aborted)
        );
    }

    #[test]
    fn test_abort_paused_to_aborted() {
        assert_eq!(
            StateMachine::transition(ExperimentStatus::Paused, StateMachineOperation::Abort),
            Ok(ExperimentStatus::Aborted)
        );
    }

    // === TC-003: Invalid State Transitions ===

    #[test]
    fn test_invalid_idle_to_running() {
        let result = StateMachine::transition(ExperimentStatus::Idle, StateMachineOperation::Start);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition {
                from: ExperimentStatus::Idle,
                operation: StateMachineOperation::Start,
            })
        ));
    }

    #[test]
    fn test_invalid_idle_to_paused() {
        let result = StateMachine::transition(ExperimentStatus::Idle, StateMachineOperation::Pause);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_loaded_to_paused() {
        let result =
            StateMachine::transition(ExperimentStatus::Loaded, StateMachineOperation::Pause);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_loaded_to_loaded() {
        let result =
            StateMachine::transition(ExperimentStatus::Loaded, StateMachineOperation::Load);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_running_to_running() {
        let result =
            StateMachine::transition(ExperimentStatus::Running, StateMachineOperation::Start);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_paused_to_paused() {
        let result =
            StateMachine::transition(ExperimentStatus::Paused, StateMachineOperation::Pause);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_completed_to_any() {
        for op in [
            StateMachineOperation::Load,
            StateMachineOperation::Start,
            StateMachineOperation::Pause,
            StateMachineOperation::Resume,
            StateMachineOperation::Stop,
            StateMachineOperation::Reset,
            StateMachineOperation::Complete,
            StateMachineOperation::Abort,
        ] {
            let result = StateMachine::transition(ExperimentStatus::Completed, op);
            assert!(
                matches!(
                    result,
                    Err(StateMachineError::OperationNotAllowed {
                        current_state: ExperimentStatus::Completed,
                        ..
                    })
                ),
                "Expected OperationNotAllowed for {:?} from Completed, got {:?}",
                op,
                result
            );
        }
    }

    #[test]
    fn test_invalid_aborted_to_any() {
        for op in [
            StateMachineOperation::Load,
            StateMachineOperation::Start,
            StateMachineOperation::Pause,
            StateMachineOperation::Resume,
            StateMachineOperation::Stop,
            StateMachineOperation::Reset,
            StateMachineOperation::Complete,
            StateMachineOperation::Abort,
        ] {
            let result = StateMachine::transition(ExperimentStatus::Aborted, op);
            assert!(
                matches!(
                    result,
                    Err(StateMachineError::OperationNotAllowed {
                        current_state: ExperimentStatus::Aborted,
                        ..
                    })
                ),
                "Expected OperationNotAllowed for {:?} from Aborted, got {:?}",
                op,
                result
            );
        }
    }

    #[test]
    fn test_invalid_idle_to_completed() {
        let result =
            StateMachine::transition(ExperimentStatus::Idle, StateMachineOperation::Complete);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_idle_to_aborted() {
        let result = StateMachine::transition(ExperimentStatus::Idle, StateMachineOperation::Abort);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_loaded_to_completed() {
        let result =
            StateMachine::transition(ExperimentStatus::Loaded, StateMachineOperation::Complete);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn test_invalid_loaded_to_aborted() {
        let result =
            StateMachine::transition(ExperimentStatus::Loaded, StateMachineOperation::Abort);
        assert!(matches!(
            result,
            Err(StateMachineError::InvalidTransition { .. })
        ));
    }

    // === TC-004: Operation Authorization ===

    #[test]
    fn test_is_allowed_load_only_idle() {
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Load
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Load
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Load
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Load
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Completed,
            StateMachineOperation::Load
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Aborted,
            StateMachineOperation::Load
        ));
    }

    #[test]
    fn test_is_allowed_start_loaded_or_paused() {
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Start
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Start
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Start
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Start
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Completed,
            StateMachineOperation::Start
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Aborted,
            StateMachineOperation::Start
        ));
    }

    #[test]
    fn test_is_allowed_pause_only_running() {
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Pause
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Pause
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Pause
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Pause
        ));
    }

    #[test]
    fn test_is_allowed_resume_only_paused() {
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Resume
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Resume
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Resume
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Resume
        ));
    }

    #[test]
    fn test_is_allowed_stop_running_or_paused() {
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Stop
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Stop
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Stop
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Stop
        ));
    }

    #[test]
    fn test_is_allowed_reset_non_terminal() {
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Reset
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Reset
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Reset
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Reset
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Completed,
            StateMachineOperation::Reset
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Aborted,
            StateMachineOperation::Reset
        ));
    }

    #[test]
    fn test_is_allowed_complete_only_running() {
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Complete
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Complete
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Complete
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Complete
        ));
    }

    #[test]
    fn test_is_allowed_abort_running_or_paused() {
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Idle,
            StateMachineOperation::Abort
        ));
        assert!(!StateMachine::is_allowed(
            ExperimentStatus::Loaded,
            StateMachineOperation::Abort
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Running,
            StateMachineOperation::Abort
        ));
        assert!(StateMachine::is_allowed(
            ExperimentStatus::Paused,
            StateMachineOperation::Abort
        ));
    }

    // === TC-007: Terminal State Enforcement ===

    #[test]
    fn test_terminal_states_are_terminal() {
        assert!(StateMachine::is_terminal(ExperimentStatus::Completed));
        assert!(StateMachine::is_terminal(ExperimentStatus::Aborted));
        assert!(!StateMachine::is_terminal(ExperimentStatus::Idle));
        assert!(!StateMachine::is_terminal(ExperimentStatus::Loaded));
        assert!(!StateMachine::is_terminal(ExperimentStatus::Running));
        assert!(!StateMachine::is_terminal(ExperimentStatus::Paused));
    }

    // === TC-010: Error Types ===

    #[test]
    fn test_error_display_invalid_transition() {
        let err = StateMachineError::InvalidTransition {
            from: ExperimentStatus::Idle,
            operation: StateMachineOperation::Start,
        };
        let msg = format!("{}", err);
        assert!(msg.contains("Invalid transition"));
        assert!(msg.contains("Start"));
        assert!(msg.contains("Idle"));
    }

    #[test]
    fn test_error_display_operation_not_allowed() {
        let err = StateMachineError::OperationNotAllowed {
            operation: StateMachineOperation::Load,
            current_state: ExperimentStatus::Completed,
        };
        let msg = format!("{}", err);
        assert!(msg.contains("not allowed"));
        assert!(msg.contains("Load"));
        assert!(msg.contains("Completed"));
    }

    // === TC-011: Operation as_str ===

    #[test]
    fn test_operation_as_str() {
        assert_eq!(StateMachineOperation::Load.as_str(), "load");
        assert_eq!(StateMachineOperation::Start.as_str(), "start");
        assert_eq!(StateMachineOperation::Pause.as_str(), "pause");
        assert_eq!(StateMachineOperation::Resume.as_str(), "resume");
        assert_eq!(StateMachineOperation::Stop.as_str(), "stop");
        assert_eq!(StateMachineOperation::Reset.as_str(), "reset");
        assert_eq!(StateMachineOperation::Complete.as_str(), "complete");
        assert_eq!(StateMachineOperation::Abort.as_str(), "abort");
    }

    // === Full lifecycle test ===

    #[test]
    fn test_full_lifecycle_idle_loaded_running_paused_running_loaded() {
        let mut state = ExperimentStatus::Idle;

        // Load
        state = StateMachine::transition(state, StateMachineOperation::Load).unwrap();
        assert_eq!(state, ExperimentStatus::Loaded);

        // Start
        state = StateMachine::transition(state, StateMachineOperation::Start).unwrap();
        assert_eq!(state, ExperimentStatus::Running);

        // Pause
        state = StateMachine::transition(state, StateMachineOperation::Pause).unwrap();
        assert_eq!(state, ExperimentStatus::Paused);

        // Resume
        state = StateMachine::transition(state, StateMachineOperation::Resume).unwrap();
        assert_eq!(state, ExperimentStatus::Running);

        // Stop
        state = StateMachine::transition(state, StateMachineOperation::Stop).unwrap();
        assert_eq!(state, ExperimentStatus::Loaded);

        // Reset
        state = StateMachine::transition(state, StateMachineOperation::Reset).unwrap();
        assert_eq!(state, ExperimentStatus::Idle);
    }

    #[test]
    fn test_lifecycle_to_completed() {
        let mut state = ExperimentStatus::Idle;

        state = StateMachine::transition(state, StateMachineOperation::Load).unwrap();
        state = StateMachine::transition(state, StateMachineOperation::Start).unwrap();
        state = StateMachine::transition(state, StateMachineOperation::Complete).unwrap();
        assert_eq!(state, ExperimentStatus::Completed);

        // No further transitions
        assert!(StateMachine::transition(state, StateMachineOperation::Reset).is_err());
    }

    #[test]
    fn test_lifecycle_to_aborted() {
        let mut state = ExperimentStatus::Idle;

        state = StateMachine::transition(state, StateMachineOperation::Load).unwrap();
        state = StateMachine::transition(state, StateMachineOperation::Start).unwrap();
        state = StateMachine::transition(state, StateMachineOperation::Abort).unwrap();
        assert_eq!(state, ExperimentStatus::Aborted);

        // No further transitions
        assert!(StateMachine::transition(state, StateMachineOperation::Reset).is_err());
    }
}
