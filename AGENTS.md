# AGENTS.md — Kayak

Repository-specific guide for agents working in this codebase.

## Project Structure

Monorepo with two primary packages:

| Directory | Language | Role |
|-----------|----------|------|
| `kayak-backend/` | Rust | Axum HTTP API + WebSocket server, single-port (:8080) |
| `kayak-frontend/` | Flutter (Dart) | Web frontend (default target), Material Design 3 |

Backend also serves Flutter Web static files via `tower-http ServeDir` with SPA fallback to `index.html`.

## CI / GitHub Actions

- **File**: `.github/workflows/ci.yml`
- **Triggers**: push/PR to `main` and `release/**` branches ONLY
- **Stages**: format → lint → test → coverage → build

### CI Gotchas (learned the hard way)

1. **Frontend format check MUST run `flutter pub get` first** — `dart format` reads `analysis_options.yaml` which includes `package:flutter_lints/flutter.yaml`. Without resolved packages, the formatter silently reports 100+ files as "changed" because it falls back to different default rules.

2. **Frontend Linux build needs `libsecret-1-dev`** — `flutter_secure_storage` requires this system library. It's in the `build-frontend` job's Linux dependency install step.

3. **Backend jobs need `libhdf5-dev` and `libudev-dev`** on every Ubuntu runner (format job excluded).

4. **Matrix build strategy**: `build-frontend` builds both `web` and `linux` targets. Linux failure blocks the whole job (web won't run if linux fails).

## Developer Commands

### Backend (Rust)

```bash
cd kayak-backend

# Format
cargo fmt -- --check

# Lint (zero warnings policy — CI uses `-D warnings`)
cargo clippy --all-targets --all-features -- -D warnings

# Test
cargo test --all-features

# Build release
cargo build --release

# Run dev server
cargo run

# Run Modbus simulator (CLI tool, separate binary)
cargo run --bin modbus-simulator
```

### Frontend (Flutter)

```bash
cd kayak-frontend

# Resolve dependencies FIRST (required before format/analyze)
flutter pub get

# Format (must match CI exactly)
dart format --output=none --set-exit-if-changed .

# Analyze
flutter analyze --fatal-infos

# Test (golden tests excluded in CI)
flutter test --exclude-tags golden

# Build web (default deployment target)
flutter build web --release

# Build desktop
flutter build linux --release
```

### Local CI Validation

```bash
./scripts/ci-check.sh   # Runs all format/lint/test/build checks locally
```

### Quick Start (Development)

```bash
./scripts/start-web.sh         # Build backend + frontend, start on :8080
./scripts/stop.sh              # Stop running server
```

## Architecture Notes

- **Single-port deployment**: Backend (:8080) serves REST API, WebSocket, AND Flutter Web static files. No reverse proxy needed.
- **Driver abstraction**: Device protocols implement `DeviceDriver` trait. `AnyDriver` enum wraps `VirtualDriver`, `ModbusTcpDriver`, `ModbusRtuDriver` (zero-cost type erasure, not `Box<dyn>`).
- **State management**: Frontend uses Riverpod (`flutter_riverpod`) with `StateNotifierProvider` pattern.
- **Routing**: Frontend uses `go_router` (declarative). Backend routes prefixed with `/api/v1/`.
- **Data storage**: SQLite for metadata, HDF5 for scientific experiment data.

## Code Generation / Generated Files

- Frontend: `*.g.dart`, `*.freezed.dart`, `lib/generated/**` — excluded from analyzer and should NOT be hand-edited. Regenerate with `flutter pub run build_runner build`.
- **Do NOT commit** `kayak-frontend/linux/flutter/generated_plugins.cmake` — it's a build artifact. Already in `.gitignore` but was accidentally tracked; removed from git.

## Lint / Style Configuration

- **Backend**: `RUSTFLAGS="-D warnings"` in CI. Strict.
- **Frontend**: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` plus many custom rules. Key ones: `prefer_single_quotes`, `require_trailing_commas`, `avoid_print`, `public_member_api_docs: false`.

## Testing Notes

- **Golden tests** exist but are excluded in CI (`--exclude-tags golden`). Run locally with `flutter test` if needed.
- Backend tests run with `RUST_LOG=debug`.
- Coverage: backend uses `cargo-tarpaulin`, frontend uses `flutter test --coverage` + `lcov`/`genhtml`.

## Key Documentation

| File | Content |
|------|---------|
| `arch.md` | Full architecture document (modules, API, deployment, data schema) |
| `README.md` | Setup, deployment, API endpoints |
| `kayak-backend/Cargo.toml` | Rust deps, binaries (main + `modbus-simulator`) |
| `kayak-frontend/pubspec.yaml` | Flutter deps, code generation config |
| `kayak-frontend/analysis_options.yaml` | Dart linter rules |
| `scripts/ci-check.sh` | Local CI validation script |
| `scripts/start-web.sh` | Dev server startup |
| `.github/workflows/ci.yml` | CI pipeline definition |

## Technology Versions

- Rust: 1.75+
- Flutter: 3.19+ (stable channel)
- Dart: 3.3+

## Default Admin Account

When the backend first starts, it auto-creates:
- Email: `admin@kayak.local`
- Password: `Admin123`
