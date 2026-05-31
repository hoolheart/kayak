# Freezed Alternative Comparison — Top 3 Recommendations

> **Author**: sw-jerry (Software Architect)  
> **Date**: 2026-05-31  
> **Context**: freezed 3.2.5 generates `.freezed.dart` files that fail to compile — the generated `_$Xxx` mixin declares abstract getters that `User` (a non-abstract `with _$User` class) does not directly implement. Pattern-matching methods (`map`, `when`, `maybeWhen`) also break due to mixin/class hierarchy mismatches.

---

## Summary of Top 3

| Rank | Option | Verdict |
|------|--------|---------|
| **🥇 1st** | **json_serializable + manual copyWith** | Best stability/cost ratio for this project |
| **🥈 2nd** | **built_value** | Mature, proven, but high boilerplate |
| **🥉 3rd** | **dart_mappable** | Modern, clean API, but less battle-tested |

---

## Multi-Dimension Comparison

| Dimension | json_serializable + manual copyWith | built_value | dart_mappable | freezed 2.x (stay) | equatable + manual | Dart 3 sealed + manual |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|
| **Maturity** | ★★★★★ | ★★★★★ | ★★★☆☆ | ★★★★☆ | ★★★★☆ | ★★★★★ (native) |
| **Maintenance** | ★★★★★ | ★★★☆☆ | ★★★★☆ | ★☆☆☆☆ (EOL) | ★★★★☆ | ★★★★★ |
| **License** | BSD-3 | BSD-3 | MIT | MIT | MIT | BSD-3 (native) |
| **Immutable** | ✅ (manual `final` fields) | ✅ (built-in) | ✅ (built-in) | ✅ (built-in) | ✅ (via equatable) | ✅ (built-in) |
| **copyWith** | ⚠️ (manual impl) | ✅ (built-in) | ✅ (built-in) | ✅ (built-in) | ⚠️ (manual impl) | ⚠️ (manual impl) |
| **JSON (fromJson/toJson)** | ✅ (json_serializable) | ✅ (built-in) | ✅ (built-in) | ✅ (json_serializable) | ❌ (separate) | ❌ (separate) |
| **Enum support** | ✅ (via json_annotation) | ✅ | ✅ | ✅ | ❌ (manual) | ❌ (manual) |
| **Union/sealed types** | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ (native) |
| **Generics support** | ✅ (json_serializable supports genericArgumentFactories) | ✅ | ✅ | ✅ (genericArgumentFactories) | N/A | N/A |
| **Code generation stability** | ★★★★★ (json_serializable is rock-solid) | ★★★★☆ | ★★★★☆ | ★★★☆☆ (freezed 2 is stable, 3 breaks) | ★★★★★ (no generation) | ★★★★★ (no generation) |
| **Riverpod compat** | ★★★★★ | ★★★★☆ | ★★★★☆ | ★★★★☆ | ★★★★★ | ★★★★★ |
| **Compile speed** | ★★★★☆ (one generator) | ★★★☆☆ (two generators) | ★★★★☆ | ★★★☆☆ (two generators) | ★★★★★ | ★★★★★ |
| **Runtime overhead** | ★★★★★ (zero) | ★★★☆☆ (builder pattern) | ★★★★☆ (minimal) | ★★★★☆ (minimal) | ★★★★★ (zero) | ★★★★★ (zero) |
| **Learning curve** | ★★★★★ (trivial) | ★★★☆☆ (steep) | ★★★★☆ (moderate) | ★★★★☆ (moderate) | ★★★★★ (trivial) | ★★★★★ (trivial) |
| **Migration from freezed** | ★★★★☆ (moderate) | ★★☆☆☆ (heavy) | ★★★★★ (easy) | ★★★★★ (trivial) | ★★☆☆☆ (heavy) | ★★☆☆☆ (heavy) |
| **GitHub Stars** | 1.4k (json_serializable) | 2.3k | 1.3k | 2.1k | 1.8k | N/A |
| **Latest Version** | 6.9.4 (Apr 2025) | 5.12.0 (Dec 2024) | 4.0.2 (May 2025) | 2.5.3 (Oct 2024, EOL) | 2.0.7 (2024) | N/A |
| **Pub Points** | 160 | 130 | 150 | 140 | 140 | N/A |

> ★★★★★ = Excellent, ★★★★☆ = Good, ★★★☆☆ = Adequate, ★★☆☆☆ = Poor, ★☆☆☆☆ = Bad

---

## 🥇 1st: json_serializable + Manual copyWith

### Why 1st?

This approach **eliminates the code generation fragility entirely** while retaining `json_serializable` — the most stable code generation package in the Dart ecosystem. The `copyWith` method is manually implemented, which is trivial for the project's current models (most have 5–15 fields).

### Architecture

```
lib/models/
├── user.dart              # Model definition + manual copyWith
├── user.g.dart            # Generated (json_serializable)
├── common.dart
├── common.g.dart
└── ...
```

### Code Example

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? username;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Manual copyWith — typed, null-aware
  User copyWith({
    String? id,
    String? email,
    // Use a sentinel for nullable fields
    Object? username = _sentinel,
    Object? avatarUrl = _sentinel,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: identical(username, _sentinel) ? this.username : username as String?,
      avatarUrl: identical(avatarUrl, _sentinel) ? this.avatarUrl : avatarUrl as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const _sentinel = Object();

  // Equality — auto by Dart for const+final fields with identical values
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username &&
          avatarUrl == other.avatarUrl &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id, email, username, avatarUrl, status, createdAt, updatedAt,
      );

  @override
  String toString() =>
      'User(id: $id, email: $email, username: $username, status: $status)';
}
```

For generic types like `ApiResponse<T>`:

```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final int code;
  final String message;
  final T data;
  final String? timestamp;

  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  ApiResponse<T> copyWith({
    int? code,
    String? message,
    T? data,
    Object? timestamp = _sentinel,
  }) {
    return ApiResponse<T>(
      code: code ?? this.code,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: identical(timestamp, _sentinel) ? this.timestamp : timestamp as String?,
    );
  }

  static const _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResponse<T> &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          data == other.data &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(code, message, data, timestamp);

  @override
  String toString() =>
      'ApiResponse<$T>(code: $code, message: $message, data: $data)';
}
```

### Pros

| # | Advantage |
|---|-----------|
| 1 | **Zero code generation fragility** — `json_serializable` is the most battle-tested Dart code generator, maintained by Google, used by thousands of projects |
| 2 | **Drops freezed_annotation dependency** — removes one coordination point between annotation and generator versions |
| 3 | **Full control** — manual `copyWith`, `==`, `hashCode`, `toString` are explicit, debuggable, and trivially customizable |
| 4 | **Instant compile feedback** — no hidden generated code; errors point to your actual source lines |
| 5 | **Team-friendly** — any Dart developer understands `const` constructors with `final` fields |
| 6 | **Native Dart 3 immutable** — `const` constructor + `final` fields = true immutability |
| 7 | **Riverpod compatibility** — no issues; classes are plain Dart objects |
| 8 | **Preserves JSON contract** — keeps `fromJson`/`toJson` exactly as before |

### Cons

| # | Disadvantage | Mitigation |
|---|-------------|------------|
| 1 | `copyWith` is manual boilerplate | Templates or `@CopyWith()` code generation can help if needed |
| 2 | Pattern matching (`map`/`when`) lost | Not currently used by project's code; unlikely needed |
| 3 | No sealed union classes | ProtocolConfig is the only sealed class (3 variants); manual enum + switch is simpler |
| 4 | `==` / `hashCode` are manual | One-off per class; rarely changes |

### Migration Complexity: ★★★☆☆ (Moderate)

- **9 source files** to rewrite (8 model files + 1 that imports them)
- **11 `@freezed` classes** to convert
- **~3 hours** estimated total migration time
- **Risk**: Low. json_serializable annotations are nearly identical. Only `copyWith` must be added manually.
- **Rollback**: Easy — keep old freezed files in git history.

### pubspec.yaml Changes

```yaml
dependencies:
  # REMOVE:
  # freezed_annotation: ^3.0.0
  # KEEP:
  json_annotation: ^4.12.0

dev_dependencies:
  # REMOVE:
  # freezed: ^3.2.5
  # KEEP:
  build_runner: ^2.4.15
  json_serializable: ^6.9.4
```

---

## 🥈 2nd: built_value

### Why 2nd?

Google's official immutable value type package. Extremely mature (released 2017), with a proven track record in large-scale Dart projects (e.g., Google internal, Fuchsia). Provides **everything** freezed provides plus serialization — at the cost of significant boilerplate.

### Architecture

```
lib/models/
├── user.dart              # Abstract class + builder
├── user.g.dart            # Generated (built_value)
└── serializers.dart       # Global serializer registry
```

### Code Example

```dart
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';

part 'user.g.dart';

abstract class User implements Built<User, UserBuilder> {
  String get id;
  String get email;
  @nullable
  String? get username;
  @BuiltValueField(wireName: 'avatar_url')
  @nullable
  String? get avatarUrl;
  String get status;
  @BuiltValueField(wireName: 'created_at')
  DateTime get createdAt;
  @BuiltValueField(wireName: 'updated_at')
  DateTime get updatedAt;

  User._();
  factory User([void Function(UserBuilder) updates]) = _$User;

  static Serializer<User> get serializer => _$userSerializer;
}
```

```dart
// serializers.dart — required global registry
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';

part 'serializers.g.dart';

@SerializersFor([User, AuthTokens, /* ... every model ... */])
final Serializers serializers = (_$serializers.toBuilder()
      ..addPlugin(StandardJsonPlugin()))
    .build();
```

### Pros

| # | Advantage |
|---|-----------|
| 1 | **Proven at Google scale** — used in large production Dart codebases for 5+ years |
| 2 | **Full feature parity** — immutable, copyWith (via `rebuild()`), JSON, sealed unions, enums |
| 3 | **StandardJsonPlugin** — interoperates with standard JSON (no custom wire format) |
| 4 | **Type-safe builders** — `rebuild((b) => b..email = 'new@email.com')` is compile-time checked |
| 5 | **Deep immutability** — built_collection provides immutable lists/maps |
| 6 | **No freezed version fragility** — independent, mature codebase |

### Cons

| # | Disadvantage | Impact |
|---|-------------|--------|
| 1 | **Heavy boilerplate** — abstract class + builder + serializer registration per model | High |
| 2 | **Serializer registry mandatory** — every model must be registered in `serializers.dart` | Maintenance burden |
| 3 | **built_collection dependency** — immutable lists require wrapping in `BuiltList<T>` | Changes usage patterns |
| 4 | **Two code generators** — `built_value_generator` + `built_value` both run | Slower builds |
| 5 | **Learning curve steep** — builder pattern, serializer registry, nullable annotations | Onboarding cost |
| 6 | **JsonSerializable annotations differ** — `@BuiltValueField(wireName:)` vs `@JsonKey(name:)` | More migration work |
| 7 | **Nullable marking** — requires `@nullable` annotation on every nullable field | Verbose |
| 8 | **Update cadence slowing** — last significant update Dec 2024; community perception of declining activity |

### Migration Complexity: ★★★★☆ (Heavy)

- Requires **serializer registry** setup
- All JSON field names change from `@JsonKey` to `@BuiltValueField`
- `built_collection` replaces `List<T>` with `BuiltList<T>`
- `rebuild()` replaces `copyWith()`
- All consuming code (pages, services) must update field access patterns
- **~6 hours** estimated migration time
- **Risk**: Medium — significant API surface changes

### pubspec.yaml Changes

```yaml
dependencies:
  built_value: ^8.9.0
  built_collection: ^5.1.0

dev_dependencies:
  build_runner: ^2.4.15
  built_value_generator: ^8.9.0
```

---

## 🥉 3rd: dart_mappable

### Why 3rd?

The most modern alternative. Clean API, inspired by freezed's best ideas but with a fresh implementation. Actively maintained with rapid iteration. Good migration path — the annotated syntax is very similar to freezed.

### Architecture

```
lib/models/
├── user.dart              # @MappableClass annotated
├── user.mapper.dart       # Generated (dart_mappable)
└── ...
```

### Code Example

```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'user.mapper.dart';

@MappableClass()
class User with UserMappable {
  final String id;
  final String email;
  final String? username;
  @MappableField(key: 'avatar_url')
  final String? avatarUrl;
  final String status;
  @MappableField(key: 'created_at')
  final DateTime createdAt;
  @MappableField(key: 'updated_at')
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.avatarUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Generated via build_runner — no manual factory needed
  // factory User.fromJson(Map<String, dynamic> json) => UserMapper.fromJson(json);
  // factory User.fromMap(Map<String, dynamic> map) => UserMapper.fromMap(map);

  static const fromJson = UserMapper.fromJson;
}
```

For generic types:

```dart
@MappableClass(genericTypes: ['T'])
class ApiResponse<T> with ApiResponseMappable<T> {
  final int code;
  final String message;
  final T data;
  final String? timestamp;

  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    this.timestamp,
  });

  static const fromJson = ApiResponseMapper.fromJson;
}
```

### Pros

| # | Advantage |
|---|-----------|
| 1 | **Clean, modern API** — syntax closest to freezed among alternatives |
| 2 | **Single annotation + single generator** — `@MappableClass()` generates everything |
| 3 | **Active maintenance** — latest release May 2025, active issue resolution |
| 4 | **Easy migration** — `@MappableClass()` replaces `@freezed`, `@MappableField(key:)` replaces `@JsonKey(name:)` |
| 5 | **Several serialization formats** — JSON, YAML, CSV, TOML — beyond JSON |
| 6 | **Immutable + copyWith + == + hashCode + toString** — all generated |
| 7 | **Sealed unions supported** — `@MappableClass(discriminatorKey: 'type')` for sealed classes |
| 8 | **Well-documented** — good README and API docs |

### Cons

| # | Disadvantage | Impact |
|---|-------------|--------|
| 1 | **Younger than alternatives** — released 2023, less battle-tested than built_value or json_serializable | Medium |
| 2 | **Single maintainer risk** — primarily maintained by one developer | Medium |
| 3 | **API churn** — rapid version iteration may introduce breaking changes | Low-Medium |
| 4 | **Not Google/Flutter team endorsed** — third-party package with no official backing | Perception |
| 5 | **FIle extension changes** — `.mapper.dart` instead of `.g.dart` + `.freezed.dart` | Migration work |
| 6 | **Riverpod integration** — no known conflicts, but not as widely verified as json_serializable | Low |

### Migration Complexity: ★★☆☆☆ (Easy-Medium)

- Annotations are very similar to current freezed setup
- `@MappableClass()` replaces `@freezed`, `@MappableField(key:)` replaces `@JsonKey(name:)`
- Part files change: `part 'user.mapper.dart'` instead of `part 'user.freezed.dart'` + `part 'user.g.dart'`
- `.g.dart` files can be deleted after migration
- **~2–3 hours** estimated migration time
- **Risk**: Low-Medium — API is intuitive, but package is younger

### pubspec.yaml Changes

```yaml
dependencies:
  dart_mappable: ^4.0.2
  # REMOVE: freezed_annotation

dev_dependencies:
  build_runner: ^2.4.15
  dart_mappable_builder: ^4.0.2
  # REMOVE: freezed, json_serializable (dart_mappable replaces both)
```

---

## Feature Coverage Matrix — Project Requirements

| Requirement | json_serializable + manual | built_value | dart_mappable | freezed 2.x |
|-------------|:---:|:---:|:---:|:---:|
| `User`, `Workbench`, `Device` (simple data classes) | ✅ | ✅ | ✅ | ✅ |
| `ApiResponse<T>` (generic) | ✅ | ✅ | ✅ | ✅ |
| `PaginatedResponse<T>` (generic + List) | ✅ | ✅ | ✅ | ✅ |
| `AuthTokens` (nested object: contains `User`) | ✅ | ✅ | ✅ | ✅ |
| `ProtocolConfig` (sealed union, 3 variants) | ⚠️ switch on enum | ✅ | ✅ | ✅ |
| `ProtocolType` enum (JsonValue) | ✅ | ✅ | ✅ | ✅ |
| `ExperimentStatus` enum (UPPERCASE JsonValue) | ✅ | ✅ | ✅ | ✅ |
| `DataType` / `AccessType` enums | ✅ | ✅ | ✅ | ✅ |
| `DeviceTreeNode` (recursive self-reference) | ⚠️ manual | ✅ | ✅ | ✅ |
| `@Default([])` List default | ⚠️ manual | ✅ (via builder) | ✅ | ✅ |
| SPA fallback (Flutter Web) | ✅ (no change) | ✅ (no change) | ✅ (no change) | ✅ |
| `flutter_riverpod` 3.3.1 compat | ✅ | ✅ | ✅ | ✅ |
| `go_router` 17.x compat | ✅ | ✅ | ✅ | ✅ |
| `dio` 5.x compat | ✅ | ✅ | ✅ | ✅ |
| `flutter_secure_storage` 10.x compat | ✅ | ✅ | ✅ | ✅ |

---

## Detailed Migration Effort Estimate

### Option 1: json_serializable + manual copyWith

| Task | Effort | Risk |
|------|--------|------|
| Remove freezed/freezed_annotation from pubspec | 5 min | None |
| Rewrite `user.dart` (User, LoginRequest, RegisterRequest) | 20 min | Low |
| Rewrite `common.dart` (ApiResponse<T>, PaginatedResponse<T>, AuthTokens) | 25 min | Low-Medium (generics) |
| Rewrite `workbench.dart` (Workbench, CreateWorkbenchRequest) | 15 min | Low |
| Rewrite `device.dart` (Device, DeviceTreeNode) | 20 min | Low (recursive) |
| Rewrite `experiment.dart` (Experiment, ExperimentStatus enum) | 15 min | Low |
| Rewrite `protocol.dart` (ProtocolConfig sealed — manual enum) | 15 min | Low |
| Rewrite `method.dart` (Method, MethodParameter) | 15 min | Low |
| Rewrite `team.dart` (Team) | 10 min | Low |
| Rewrite `point.dart` (Point, PointValue, enums) | 15 min | Low |
| Delete all `.freezed.dart` files | 2 min | None |
| Regenerate `.g.dart` files | 2 min | None |
| Fix compilation errors (field access changes) | 30 min | Low |
| Fix/update tests | 30 min | Low |
| Run full test suite + CI | 10 min | Low |
| **Total** | **~3 hours** | **Low** |

### Option 2: built_value

| Task | Effort | Risk |
|------|--------|------|
| Add dependencies (built_value, built_collection, built_value_generator) | 5 min | None |
| Create `serializers.dart` registry | 15 min | Medium |
| Rewrite each model as abstract class + builder | 30 min × 11 = 5.5 hrs | Medium |
| Update all consuming code (pages, services, tests) | 2 hours | Medium |
| Handle `BuiltList<T>` for list fields | 30 min | Low |
| Delete old generated files, regenerate | 5 min | None |
| Fix compilation errors | 1 hour | Medium |
| **Total** | **~9 hours** | **Medium** |

### Option 3: dart_mappable

| Task | Effort | Risk |
|------|--------|------|
| Add/replace dependencies | 5 min | None |
| Rewrite annotations (freezed → MappableClass) | 10 min × 11 = 2 hrs | Low |
| Replace part directives | 5 min | None |
| Regenerate | 2 min | None |
| Fix compilation errors | 30 min | Low-Medium |
| Fix/update tests | 30 min | Low |
| **Total** | **~3 hours** | **Low-Medium** |

---

## Riverpod Compatibility Analysis

| Option | StateNotifierProvider | StateProvider | FutureProvider | StreamProvider |
|--------|:---:|:---:|:---:|:---:|
| json_serializable + manual | ✅ | ✅ | ✅ | ✅ |
| built_value | ✅ (requires rebuild for mutations) | ✅ | ✅ | ✅ |
| dart_mappable | ✅ | ✅ | ✅ | ✅ |

All three options use standard Dart classes with `const` constructors — fully compatible with Riverpod. The only consideration is:

- **built_value**: mutations go through `rebuild()`, which creates a new instance. This actually **aligns well** with Riverpod's immutable state paradigm, but developers must learn the builder pattern.
- **json_serializable + manual**: `copyWith` returns new instances (standard pattern), trivially compatible.
- **dart_mappable**: Generated `copyWith` returns new instances, same as freezed.

---

## CI/CD Pipeline Impact

| Impact | json_serializable + manual | built_value | dart_mappable |
|--------|---------------------------|-------------|---------------|
| Code generation command | `build_runner build` | `build_runner build` | `build_runner build` |
| Generated files to commit | `.g.dart` only | `.g.dart` | `.mapper.dart` |
| Number of generators | 1 (json_serializable) | 2 (built_value + serializer) | 1 (dart_mappable_builder) |
| Generator stability | ★★★★★ | ★★★★☆ | ★★★★☆ |
| `.gitignore` changes | Remove `*.freezed.dart` | New patterns | Replace patterns |

---

## Final Recommendation (sw-jerry)

### Primary: **json_serializable + manual copyWith** 🥇

For this project specifically, the "manual" approach is actually **the most sustainable** choice:

1. **The project has only 11 data classes** — none are huge. manual `copyWith` is 5–15 lines each. This is minimal overhead.
2. **No sealed union usage in business logic** — `ProtocolConfig` is the only sealed type, and a manual enum-based approach is both simpler and more explicit.
3. **Eliminates an entire class of bugs** — freezed version coordination (annotation vs generator) is a recurring pain point. Removing it reduces CI failures to zero in this category.
4. **json_serializable is Google-maintained and will outlast all alternatives** — it's been stable since 2017 with no breaking changes at the annotation level.
5. **Lowest total cost of ownership** — zero risk of package abandonment, zero coordination between annotation and generator versions, full developer control.

### Fallback: **dart_mappable** 🥉

If the team strongly prefers code generation for `copyWith`/`==`/`hashCode`, `dart_mappable` is the best third-party choice. But I recommend waiting until it reaches v5.0 (indicating API stability) before adopting it for a production system.

### Not Recommended: **built_value** 🚫

Too much boilerplate for a team that has already expressed preference for concise DSLs (freezed). The migration cost and ongoing maintenance burden (serializer registry, `BuiltList`) outweigh the benefits for this project's scale.

### Not Recommended: **freezed 2.x stay** 🚫

This is a **dead-end path**. freezed 2.x will never receive updates for new Dart features, and the project is already on Dart 3.8. The version coordination bug will recur whenever dependent packages update.

---

## Appendix: Project Model Inventory

| File | Classes | Fields (avg) | Special features |
|------|---------|-------------|------------------|
| `user.dart` | 3 (User, LoginRequest, RegisterRequest) | 5–8 | None |
| `common.dart` | 3 (ApiResponse<T>, PaginatedResponse<T>, AuthTokens) | 4–6 | Generics, nested User |
| `workbench.dart` | 2 (Workbench, CreateWorkbenchRequest) | 6–9 | None |
| `device.dart` | 3 (Device, DeviceTreeNode, ProtocolType enum) | 10–14 | Recursive, enum, List |
| `experiment.dart` | 2 (Experiment, ExperimentStatus enum) | 10 | Enum |
| `protocol.dart` | 1 (ProtocolConfig — sealed) | 4–7 per variant | Sealed union |
| `method.dart` | 2 (Method, MethodParameter) | 7–9 | None |
| `team.dart` | 1 (Team) | 6 | None |
| `point.dart` | 4 (Point, PointValue, DataType enum, AccessType enum) | 10 | Enums, loose Object |
| **Total** | **21 entities** | — | — |
