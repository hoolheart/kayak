# S2-011 Design Review

## Verdict: APPROVED

## Review Checklist

| Item | Status | Notes |
|------|--------|-------|
| All API endpoints covered | ✅ | Load, Start, Pause, Resume, Stop, GetStatus all present in Section 2.1 |
| WebSocket design | ✅ | Sections 2.2, 3.3, 6 cover connection, heartbeat, subscription, broadcast |
| Permission model | ✅ | Section 4 covers rules, check flow, and error responses |
| StateMachine/StepEngine integration | ✅ | Section 5 provides detailed integration with operation flows |
| Mermaid diagrams | ✅ | State diagram (1.3) and sequence diagram (Section 8) |

## Detailed Assessment

### 1. API Endpoints (Section 2.1)
All 6 endpoints are properly defined with correct HTTP methods and paths:
- `POST /api/v1/experiments/{id}/load` - Load
- `POST /api/v1/experiments/{id}/start` - Start
- `POST /api/v1/experiments/{id}/pause` - Pause
- `POST /api/v1/experiments/{id}/resume` - Resume
- `POST /api/v1/experiments/{id}/stop` - Stop
- `GET /api/v1/experiments/{id}/status` - GetStatus

### 2. WebSocket Design (Sections 2.2, 3.3, 6)
Complete WebSocket specification including:
- Endpoint: `WS /ws/experiments/{id}`
- Connection establishment with JWT auth
- Heartbeat mechanism (30s ping/pong, 60s timeout)
- Message subscription and broadcast mechanisms
- Message formats for status_change and error types

### 3. Permission Model (Section 4)
Clear permission rules:
- Owner and Admin: all operations allowed
- Other users: GetStatus only (based on table, though description says "只有试验的所有者或管理员可以执行控制操作" - suggesting only owner/admin can perform control operations)
- Permission check flow well defined (5 steps)
- Error response format provided (403)

### 4. StateMachine/StepEngine Integration (Section 5)
Detailed integration for each operation:
- StateMachine used for transition validation
- StepEngine operations for Load, Start, Pause, Resume, Stop clearly defined
- StateChangeLog table structure documented
- Error handling mapped to HTTP status codes

### 5. Mermaid Diagrams
Two Mermaid diagrams present:
- **State diagram (1.3)**: Shows Idle → Loaded → Running → Paused states with all transitions
- **Sequence diagram (Section 8)**: Shows full API flow from client request through auth, service, state machine, repository, and WebSocket notification

## Minor Observations (Non-blocking)

1. **Permission table inconsistency**: Section 4.1 table shows GetStatus as accessible by all roles, but description in 4.1 says only owner/admin can perform control operations. The table is technically correct (GetStatus is a read operation), but could be clearer.

2. **Reset operation**: The state diagram shows Reset → Idle transition but there's no API endpoint defined for Reset in Section 2.1. This appears intentional (Reset may be internal), but worth noting.

3. **Section numbering**: The document uses Chinese numbering (1, 2, 3...) which is consistent but unconventional.

## Conclusion

The design document is comprehensive, well-structured, and covers all required aspects. The integration between components (StateMachine, StepEngine, WebSocket) is clearly documented with specific operation flows. The Mermaid diagrams effectively illustrate the state machine and API processing flow.

**Recommendation**: APPROVED for implementation.
