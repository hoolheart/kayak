# Code Review Report — R1-S2-006 Modbus Simulator CLI

## Review Information

| Field | Value |
|---|---|
| **Reviewer** | sw-jerry |
| **Date** | 2026-05-03 |
| **Branch** | `feature/R1-S2-006-modbus-simulator` |
| **Commit** | `2a2399a3a8e8adb8530758b5243fa97d8a85a344` |
| **Title** | feat: implement Modbus TCP simulator CLI (R1-S2-006) |

## Files Changed

| File | Lines | Description |
|---|---|---|
| `Cargo.toml` | +10 | Added `clap = 4` (derive) and `toml = 0.8` deps plus `[[bin]]` target |
| `Cargo.lock` | +116 | Dependency tree updates |
| `src/bin/modbus-simulator/main.rs` | 113 | CLI entry point, config resolution, logging init, graceful shutdown |
| `src/bin/modbus-simulator/config.rs` | 582 | CLI args (clap), TOML/JSON config loading, multi-layer merge, 17 tests |
| `src/bin/modbus-simulator/server.rs` | 845 | DataStore, TCP listener, per-connection handler, PDU dispatcher, 27 tests |

**Total**: 5 files, +1666 lines

## Summary

| Metric | Result |
|---|---|
| **Status** | **CHANGES_REQUESTED** |
| **Total Issues** | 2 |
| **Critical** | 0 |
| **High** | 0 |
| **Medium** | 2 |
| **Low** | 0 |

---

## Review Focus Areas

### 1. Reuse of MbapHeader/Pdu (PASS with notes)

The simulator correctly imports existing modbus types from `kayak_backend::drivers::modbus`:

```rust
use kayak_backend::drivers::modbus::{
    FunctionCode, MbapHeader, ModbusError, Pdu,
};
```

- **MbapHeader**: `parse()`, `to_bytes()`, `new()`, `pdu_length()` — all reused properly
- **Pdu**: `parse()`, `start_address()`, `quantity()`, factory methods — all reused
- **FunctionCode**: pattern matching on `ReadCoils` / `ReadHoldingRegisters`
- **ModbusError**: used for error-to-exception-code mapping, data store error returns
- **ModbusAddress**: used in test PDU construction via `Pdu::read_coils(ModbusAddress::new(...), ...)`

**Verdict**: No duplicate implementations. Full reuse of existing domain types. ✅

### 2. Concurrency Safety (PASS ✅)

```rust
pub type SharedDataStore = Arc<RwLock<DataStore>>;
```

- `Arc::clone(&datastore)` per connection task in `run_server()` (line 148)
- `datastore.read().await` held only for PDU processing duration in `process_request()` (line 325)
- Handlers (`handle_read_coils`, `handle_read_holding_registers`) take `&DataStore` — pure read-only, lock-safe
- No write operations exist, so no deadlock risk (only `RwLock::read()` is used)
- Lock scope is minimal: single `.read().await` per request, released when handler returns

**Verdict**: Thread-safe, correct `Arc<RwLock<>>` usage. No data races. ✅

### 3. FC01 (Read Coils) Handling (PASS ✅)

**Handler**: `handle_read_coils()` (server.rs:350-388)

- Quantity validation: `quantity == 0 || quantity > 2000` → Illegal Data Value (0x03) ✅
- OOB check: delegated to `DataStore::read_coils()` which returns `IllegalDataAddress` (0x02) ✅
- Coil packing: `coil_bytes[i / 8] |= 1 << (i % 8)` — LSB-first per byte, per Modbus spec ✅
- Byte count: `div_ceil(8)` — correct ceiling division (e.g., 9 coils → 2 bytes) ✅
- Response format: `[0x01, byte_count, coil_data...]` — correct ✅
- Test coverage: 6 tests covering normal, mixed bits, non-zero start address, OOB, and invalid quantity

### 4. FC03 (Read Holding Registers) Handling (PASS ✅)

**Handler**: `handle_read_holding_registers()` (server.rs:398-431)

- Quantity validation: `quantity == 0 || quantity > 125` → Illegal Data Value (0x03) ✅
- OOB check: delegated to `DataStore::read_holding_registers()` ✅
- Register encoding: `reg.to_be_bytes()` — big-endian, per Modbus spec ✅
- Byte count: `quantity * 2` as `u8` — safe (quantity ≤ 125 → max 250 bytes) ✅
- Response format: `[0x03, byte_count, register_data...]` — correct ✅
- Test coverage: 5 tests covering zero, values, multi-register, OOB, and invalid quantity

### 5. Error Handling Completeness (PASS ✅)

| Scenario | Handling | Exception Code |
|---|---|---|
| MBAP parse error | Log warning, disconnect | N/A (connection drop) |
| PDU parse error (`InvalidFunctionCode`) | Exception response | 0x01 (Illegal Function) |
| PDU parse error (`IllegalDataAddress`) | Exception response | 0x02 (via mapping) |
| PDU parse error (`IllegalDataValue`) | Exception response | 0x03 (via mapping) |
| PDU parse error (`IncompleteFrame`/other) | Exception response | 0x04 (Server Device Failure) |
| Zero-length PDU | Exception response | 0x04 (Server Device Failure) |
| Slave/Unit ID mismatch | Silently skip frame | N/A (multi-slave gateway) |
| Address out of data store bounds | Exception response | 0x02 (Illegal Data Address) |
| Quantity exceeds protocol limit | Exception response | 0x03 (Illegal Data Value) |
| Unsupported function code | Exception response | 0x01 (Illegal Function) |
| Client EOF | Graceful disconnect | N/A |
| TCP bind failure | `eprintln!` + `exit(1)` | N/A |

- `exception_code_for_error()` maps `ModbusError` variants to appropriate exception codes with `_ => 0x04` fallback
- All exception responses include correct MBAP header (echoed `transaction_id` and `unit_id`, correct `length`)
- Test coverage: 6 tests for exception byte building, 5 for exception code mapping, 3 for end-to-end PDU processing errors

**Verdict**: Complete and correct. ✅

---

## Issues Found

### [MEDIUM] Issue M1: Clippy `manual_range_contains` warning

- **Location**: `config.rs`, line 230
- **Code**:
  ```rust
  if slave_id < 1 || slave_id > 247 {
      return Err(format!(...));
  }
  ```
- **Description**: Clippy reports that this manual range check can be replaced with the more idiomatic and readable `!(1..=247).contains(&slave_id)`.
- **Impact**: Violates the "cargo clippy zero warnings" requirement. The logic is correct, but the lint must be addressed.
- **Recommendation**: Replace with:
  ```rust
  if !(1..=247).contains(&slave_id) {
      return Err(format!(...));
  }
  ```
  Or run `cargo clippy --fix --bin modbus-simulator`.
- **Status**: OPEN

### [MEDIUM] Issue M2: TOML `log_level` silently overwritten by CLI default

- **Location**: `config.rs`, lines 246–249
- **Code**:
  ```rust
  if cli.verbose {
      config.verbose = true;
      config.log_level = "debug".to_string();
  } else {
      config.log_level = cli.log_level.clone();  // ← always "info" if --log-level not provided
  }
  ```
- **Description**: The `CliArgs.log_level` field uses `default_value = "info"`, so `cli.log_level` is **always** `"info"` when the user does not explicitly pass `--log-level`. The `else` branch unconditionally sets `config.log_level = cli.log_level`, overwriting any `log_level` value loaded from a TOML config file (Layer 2 of the merge). This means setting `log_level = "trace"` in a TOML config file is silently ignored — the simulator always uses `"info"` unless `--log-level` or `--verbose` is explicitly passed on the CLI.

- **Impact**: Users who configure `log_level` via TOML will not get the expected log output. This is a silent configuration bug that affects all TOML-based deployments.

- **Reproduction**:
  1. Create `sim.toml` with `log_level = "trace"`
  2. Run `modbus-simulator --config sim.toml`
  3. Observe: log level is `info` instead of `trace`

- **Recommendation**: Change `CliArgs.log_level` to `Option<String>` (remove `default_value`), and apply the default only when neither TOML nor CLI provide a value:
  ```rust
  // In CliArgs:
  #[arg(long = "log-level", value_name = "LEVEL")]
  pub log_level: Option<String>,

  // In from_cli, Layer 6:
  if cli.verbose {
      config.verbose = true;
      config.log_level = "debug".to_string();
  } else if let Some(ref level) = cli.log_level {
      config.log_level = level.clone();
  }
  // else: keep whatever TOML or default set
  ```
  The default value `"info"` is already set by `SimulatorConfig::default()`.

- **Status**: OPEN

---

## Architecture Compliance

| Check | Status |
|---|---|
| Follows `arch.md` | ✅ Binary is self-contained under `src/bin/`, imports from `kayak_backend` |
| Uses defined interfaces | ✅ Reuses `MbapHeader`, `Pdu`, `FunctionCode`, `ModbusError` |
| Proper error handling | ✅ All error paths return correct Modbus exception codes |
| No code duplication | ✅ No reimplementation of MBAP/PDU parsing or Modbus types |
| Concurrency model | ✅ Per-connection `tokio::spawn` with `Arc<RwLock<>>` shared state |

## Design Quality

| Aspect | Assessment |
|---|---|
| **Separation of concerns** | ✅ config.rs, server.rs, main.rs — clear boundaries |
| **Configuration merge** | 6-layer merge with documented priority — well-structured, but bug M2 |
| **Logging** | Structured with tracing, verbose mode, peer-address-tagged logs |
| **Testability** | `DataStore` handlers take `&DataStore`, testable without async. PDU processing testable with `tokio::runtime`. |
| **Graceful shutdown** | `tokio::select!` on `ctrl_c()` + server task — correct |

## Quality Checks

| Check | Result |
|---|---|
| No compiler errors | ✅ |
| No compiler warnings | ❌ 1 clippy warning (M1) |
| No lint warnings | ❌ 1 clippy warning (M1) |
| Tests pass | ✅ 44/44 simulator tests + 430/430 total |
| Documentation updated | ✅ Module-level docs with usage examples |
| Commit message quality | ✅ Clear, describes what and why |

## Test Coverage Summary

### 44 Unit Tests by Category

| Category | Count | Coverage |
|---|---|---|
| DataStore (create, defaults, init, OOB) | 7 | Constructor, init, boundary, out-of-range |
| FC01 (Read Coils handler) | 6 | Normal, mixed bits, non-zero address, OOB exception, invalid qty exception |
| FC03 (Read Holding Registers handler) | 5 | Zero, values, multi-register, OOB exception, invalid qty exception |
| process_request (PDU dispatch) | 3 | ReadCoils, ReadHoldingRegisters, unsupported FC |
| Exception bytes builder | 4 | All 4 exception codes |
| MBAP exception response builder | 1 | Header + PDU construction |
| Exception code mapping | 5 | All error variants |
| Config (defaults, parsing, merging, CLI) | 13 | CSV, merge, CLI args, invalid slave ID |

**Verdict**: Comprehensive unit test suite. All tests pass. ✅

---

## Approval

| Condition | Status |
|---|---|
| Critical issues resolved | N/A (none) |
| High issues resolved | N/A (none) |
| Medium issues resolved | ❌ M1 and M2 unresolved |
| Code meets standards | ⚠️ 1 clippy warning |
| Tests pass | ✅ |
| Approved for merge | ❌ |

### Final Decision: **CHANGES_REQUESTED**

Both medium-severity issues must be resolved before merge:

1. **M1**: Fix the `manual_range_contains` clippy warning at `config.rs:230`
2. **M2**: Fix the TOML `log_level` overwrite bug in the Layer 6 merge logic at `config.rs:246-249`

After both fixes, re-run `cargo clippy --all-targets --all-features` to confirm zero warnings, and verify the TOML log_level behavior with a quick manual test.
