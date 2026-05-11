# Development Principles

This document records the discipline and principles governing this project's development.
These principles are non-negotiable and apply to all team members.

## Principles

### 1. TDD Workflow with Mandatory Documentation
Every development task MUST follow the "test case writing → design → development → code review → testing" workflow. Test cases, design documents, test reports, and code review documents must be recorded in files without omission. No document, no completion.

### 2. Zero Tolerance for Unfixed Issues
Issues found during testing and code review MUST be fixed. Absolutely no excuses such as "non-critical defect", "not caused by the current task", or "does not affect usability" are acceptable. As long as there are unresolved testing issues or code review issues, the task cannot be marked as complete. Only sw-mike (tester) has the authority to confirm test issues are closed. Only sw-jerry (architect) has the authority to confirm code review issues are closed. After defects are closed, the corresponding test reports and code review reports must be updated.

### 3. Environment Completeness Required
During development, if required development environment components are found missing, STOP and inform the user how to install them. Continue only after the user has completed the installation. Never use a missing component as an excuse to skip necessary testing.

### 4. Frontend Design-First Mandate
For frontend tasks, sw-anna MUST create the UI design first. sw-tom MUST strictly follow the design during development. sw-mike MUST verify during testing that the implementation follows the UI design. No frontend code without an approved Figma prototype.

### 5. Sprint-End Zero-Warning Compilation
At the end of each sprint, the final task MUST ensure the project compiles without any errors AND warnings. Note: compiler warnings are also NOT allowed — they must be treated as errors. Ensure the software can run in the development environment, and provide a run script for verification.

### 6. Subagent Empty Result Retry
If a subagent returns an empty or null result, sw-prod MUST retry the task delegation immediately. Under no circumstances may an empty result be accepted as completion. The task is not done until the subagent produces verifiable output.

### 7. No Direct Fix by sw-prod
sw-prod is strictly forbidden from performing any analysis, design, development, or testing work. ALL technical fixes MUST be delegated to the appropriate subagent (sw-tom for code, sw-jerry for architecture, sw-mike for testing, sw-anna for UI). sw-prod's role is coordination and enforcement ONLY.

### 8. Zero OPEN Issues in Reports
Code review reports and test reports MUST NOT contain any issues with status "OPEN" before a task can be marked complete. Every issue must be either "CLOSED" (fixed and verified) or explicitly "DEFERRED" with documented justification and user approval. No task proceeds with unresolved review or test issues.

### 9. Runtime Verification Required
For scripts, startup procedures, and any code that affects runtime behavior, compilation success is NOT sufficient. The code MUST be actually executed and verified to work in the development environment. "It compiles" is never enough for code that needs to run.

---

*This document is maintained by sw-prod. Principles may be added or adjusted during development based on user input. Total principles must not exceed 13.*
