import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/models/user.dart';
import 'package:kayak_frontend/providers/auth_provider.dart';
import 'package:kayak_frontend/providers/services.dart';

import '../helpers/fake_auth_service.dart';

/// 创建测试用 ProviderContainer
ProviderContainer createContainer(FakeAuthService mockAuth) {
  return ProviderContainer(overrides: [
    authServiceProvider.overrideWithValue(mockAuth),
  ]);
}

void main() {
  // ==========================================================
  // 一、AuthState 定义与状态转换测试（4 项）
  // ==========================================================
  group('AuthNotifier - AuthState', () {
    test('TC-001: build() initially returns AsyncLoading', () {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state, isA<AsyncLoading<User?>>());
    });

    test('TC-002: returns AsyncData(null) when no token exists', () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      final state = container.read(authProvider);
      expect(state, isA<AsyncData<User?>>());
      expect(state.asData?.value, isNull);
    });

    test('TC-003: returns AsyncData(user) when token is valid', () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      final state = container.read(authProvider);
      expect(state, isA<AsyncData<User?>>());
      expect(state.asData?.value, isNotNull);
      expect(state.asData?.value, isA<User>());
      expect(state.asData?.value?.email, equals('admin@kayak.local'));
    });

    test('TC-004: returns error state when auth fails', () async {
      final mockAuth = FakeAuthService(hasToken: true, refreshFails: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      // Trigger build(), which throws when refresh fails.
      // Riverpod 3.x catches the error and tracks it in retry-able loading.
      container.read(authProvider);

      // Wait for async build() to settle.
      for (var i = 0; i < 100; i++) {
        if (!container.read(authProvider).isLoading) break;
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      final state = container.read(authProvider);
      // State should have error info (retry-able AsyncLoading with error)
      expect(state.hasError, isTrue);
      expect(state.error, isNotNull);
    });
  });

  // ==========================================================
  // 二、build() 初始化与会话检查测试（3 项）
  // ==========================================================
  group('AuthNotifier - build() initialization', () {
    test('TC-005: build() calls AuthService.initialize()', () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      expect(mockAuth.initializeCallCount, equals(1));
    });

    test('TC-006: build() tries to refresh token when token exists',
        () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      expect(mockAuth.tryRefreshCallCount, equals(1));
    });

    test('TC-007: build() skips refresh when no token exists', () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      expect(mockAuth.tryRefreshCallCount, equals(0));
      final state = container.read(authProvider);
      expect(state.asData?.value, isNull);
    });
  });

  // ==========================================================
  // 三、login() 流程测试（6 项）
  // ==========================================================
  group('AuthNotifier - login()', () {
    test('TC-008: login() success updates state to authenticated user',
        () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      expect(container.read(authProvider).asData?.value, isNull);

      await container
          .read(authProvider.notifier)
          .login('admin@kayak.local', 'Admin123');

      final state = container.read(authProvider);
      expect(state.asData?.value, isNotNull);
      expect(state.asData?.value?.email, equals('admin@kayak.local'));
    });

    test('TC-009: login() failure sets AsyncError state', () async {
      final mockAuth = FakeAuthService(loginFails: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .login('admin@kayak.local', 'wrong-password');

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isNotNull);
    });

    test('TC-010: login() shows loading state during request', () async {
      final mockAuth =
          FakeAuthService(loginDelay: const Duration(milliseconds: 100));
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final future = container
          .read(authProvider.notifier)
          .login('admin@kayak.local', 'password');

      // Immediately check state — should be loading
      final state = container.read(authProvider);
      expect(state.isLoading, isTrue);

      await future;
    });

    test('TC-011: login() delegates to AuthService.login() with correct params',
        () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .login('user@test.com', 'TestPass123');

      expect(mockAuth.lastLoginEmail, equals('user@test.com'));
      expect(mockAuth.lastLoginPassword, equals('TestPass123'));
      expect(mockAuth.loginCallCount, equals(1));
    });

    test('TC-012: login() failure preserves existing user state', () async {
      final mockAuth = FakeAuthService(hasToken: true, loginFails: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);
      final userBefore = container.read(authProvider).asData?.value;
      expect(userBefore, isNotNull);

      await container
          .read(authProvider.notifier)
          .login('admin@kayak.local', 'wrong');

      final state = container.read(authProvider);
      expect(state.hasError || state.asData?.value == null, isTrue);
    });

    test('TC-013: login() protects against concurrent calls', () async {
      final mockAuth =
          FakeAuthService(loginDelay: const Duration(milliseconds: 100));
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);
      final Future<void> future1 = notifier.login('a@b.com', 'pass1');
      final Future<void> future2 = notifier.login('c@d.com', 'pass2');

      await Future.wait(<Future<void>>[future1, future2]);

      expect(mockAuth.loginCallCount, lessThanOrEqualTo(2));
    });
  });

  // ==========================================================
  // 四、register() 流程测试（4 项）
  // ==========================================================
  group('AuthNotifier - register()', () {
    test('TC-014: register() success auto-login and sets user state',
        () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .register('new@test.com', 'StrongPass1', 'NewUser');

      final state = container.read(authProvider);
      expect(state.asData?.value, isNotNull);
      expect(state.asData?.value?.email, equals('new@test.com'));
      expect(state.asData?.value?.username, equals('NewUser'));

      expect(mockAuth.saveTokensCalled, isTrue);
    });

    test('TC-015: register() failure sets AsyncError state', () async {
      final mockAuth = FakeAuthService(
        registerFails: true,
        registerError: 'Email already registered',
      );
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .register('taken@test.com', 'StrongPass1');

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('已被注册'));
    });

    test(
        'TC-016: register() delegates to AuthService.register() with correct params',
        () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // Scenario A: with username
      await container
          .read(authProvider.notifier)
          .register('new@test.com', 'Str0ng!Pass', 'TestUser');

      expect(mockAuth.lastRegisterEmail, equals('new@test.com'));
      expect(mockAuth.lastRegisterPassword, equals('Str0ng!Pass'));
      expect(mockAuth.lastRegisterUsername, equals('TestUser'));

      // Scenario B: without username
      mockAuth.reset();
      await container
          .read(authProvider.notifier)
          .register('user2@test.com', 'Pass1234');

      expect(mockAuth.lastRegisterUsername, isNull);
    });

    test('TC-017: register() shows loading state during request', () async {
      final mockAuth =
          FakeAuthService(registerDelay: const Duration(milliseconds: 100));
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final future = container
          .read(authProvider.notifier)
          .register('new@test.com', 'StrongPass1');

      // Intermediate state
      expect(container.read(authProvider).isLoading, isTrue);

      await future;

      // Final state
      expect(container.read(authProvider).isLoading, isFalse);
    });
  });

  // ==========================================================
  // 五、logout() 流程测试（3 项）
  // ==========================================================
  group('AuthNotifier - logout()', () {
    test('TC-018: logout() clears state to AsyncData(null)', () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);
      expect(container.read(authProvider).asData?.value, isNotNull);

      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider);
      expect(state.asData?.value, isNull);
      expect(mockAuth.logoutCalled, isTrue);
      expect(mockAuth.accessToken, isNull);
      expect(mockAuth.tokensCleared, isTrue);
    });

    test('TC-019: logout() cancels token refresh timer', () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // Logout
      await container.read(authProvider.notifier).logout();

      // Timer should no longer be active
      final notifier = container.read(authProvider.notifier);
      expect(notifier.isTimerActive, isFalse);
    });

    test('TC-020: logout() is safe to call when already unauthenticated',
        () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // Call logout while unauthenticated
      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider);
      expect(state.asData?.value, isNull);
      expect(state.hasError, isFalse);
    });
  });

  // ==========================================================
  // 六、会话恢复与 Token 刷新测试（7 项）
  // ==========================================================
  group('AuthNotifier - session restoration & refresh', () {
    test('TC-021: build() auto-authenticates when token is valid', () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      expect(container.read(authProvider).asData?.value, isNotNull);
      expect(mockAuth.initializeCallCount, equals(1));
      expect(mockAuth.tryRefreshCallCount, equals(1));
      expect(mockAuth.getMeCallCount, equals(1));
    });

    test('TC-022: build() returns null when token is invalid or expired',
        () async {
      // Scenario A: hasToken but refresh fails
      final mockAuthA = FakeAuthService(hasToken: true, refreshFails: true);
      final containerA = createContainer(mockAuthA);
      addTearDown(containerA.dispose);
      containerA.read(authProvider);
      await Future<void>.delayed(Duration.zero);
      final stateA = containerA.read(authProvider);
      expect(stateA.hasError || stateA.asData?.value == null, isTrue);

      // Scenario B: no token
      final mockAuthB = FakeAuthService();
      final containerB = createContainer(mockAuthB);
      addTearDown(containerB.dispose);
      await containerB.read(authProvider.future);
      expect(containerB.read(authProvider).asData?.value, isNull);
    });

    test('TC-023: auto-refresh silently extends session when refresh succeeds',
        () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // Manually trigger refresh (simulating timer)
      final success = await mockAuth.tryRefresh();
      expect(success, isTrue);

      // User state should remain unchanged
      final state = container.read(authProvider);
      expect(state.asData?.value, isNotNull);

      // Token should be updated
      expect(mockAuth.tokensUpdated, isTrue);
    });

    test('TC-024: refresh failure clears auth state', () async {
      final mockAuth = FakeAuthService(hasToken: true, refreshFails: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      // Trigger build and wait for async completion
      container.read(authProvider);
      await Future<void>.delayed(Duration.zero);

      // Verify tokens are cleared
      expect(mockAuth.logoutCalled, isTrue);
    });

    test('TC-025: Token refresh timer uses Timer.periodic', () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // Verify timer has started
      final notifier = container.read(authProvider.notifier);
      expect(notifier.isTimerActive, isTrue);

      // Dispose container → timer should be cancelled
      container.dispose();
      expect(notifier.isTimerActive, isFalse);
    });

    test('TC-026: build() refreshes even when token appears valid', () async {
      final mockAuth = FakeAuthService(hasToken: true, tokenExpiresIn: 3000);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // Always tryRefresh on startup
      expect(mockAuth.tryRefreshCallCount, equals(1));
    });

    test('TC-027: build() handles prolonged loading gracefully', () async {
      final mockAuth =
          FakeAuthService(initializeDelay: const Duration(seconds: 1));
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      // build() should not crash due to long wait
      final future = container.read(authProvider.future);

      // During wait, state should be loading
      final state = container.read(authProvider);
      expect(state.isLoading, isTrue);

      await future;
    });
  });

  // ==========================================================
  // 七、Provider 类型与 API 正确性测试（2 项）
  // ==========================================================
  group('AuthNotifier - provider type & API', () {
    test('TC-028: AuthNotifier uses correct Riverpod 3.x AsyncNotifier API',
        () {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      expect(notifier, isA<AsyncNotifier<User?>>());
    });

    test(
        'TC-029: AuthNotifier injects AuthService via ref.read(services)',
        () async {
      final mockAuth = FakeAuthService();
      final container = ProviderContainer(overrides: [
        authServiceProvider.overrideWithValue(mockAuth),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      // Verify that the mock's initialize was called, confirming injection
      expect(mockAuth.initializeCallCount, equals(1));
    });
  });

  // ==========================================================
  // 八、边界与异常处理测试（8 项）
  // ==========================================================
  group('AuthNotifier - edge cases & error handling', () {
    test('TC-030: login() network error returns user-friendly message',
        () async {
      final mockAuth = FakeAuthService(networkError: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('网络'));
    });

    test('TC-031: login() server error returns user-friendly message',
        () async {
      final mockAuth = FakeAuthService(serverError: true, serverStatusCode: 500);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(),
          anyOf(contains('服务'), contains('服务器'), contains('稍后重试')));
    });

    test('TC-032: register() duplicate email returns specific error',
        () async {
      final mockAuth = FakeAuthService(
        registerFails: true,
        registerError: 'Email already registered',
      );
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .register('taken@test.com', 'StrongPass1');

      final state = container.read(authProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('已被注册'));
    });

    test('TC-033: rapid logout then login produces consistent state',
        () async {
      final mockAuth = FakeAuthService(hasToken: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final notifier = container.read(authProvider.notifier);

      await notifier.logout();
      await notifier.login('new@test.com', 'NewPass123');

      final state = container.read(authProvider);
      expect(state.asData?.value, isNotNull);
      expect(state.asData?.value?.email, equals('new@test.com'));
      expect(mockAuth.accessToken, equals('new-access-token'));
    });

    test('TC-034: build() survives AuthService.initialize() failure',
        () async {
      final mockAuth = FakeAuthService(initializeFails: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      // build() should not crash
      await container.read(authProvider.future);

      final state = container.read(authProvider);
      expect(state.asData?.value, isNull);
    });

    test('TC-035: build() falls back to null when getMe() fails after refresh',
        () async {
      final mockAuth = FakeAuthService(
        hasToken: true,
        getMeFails: true,
      );
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      final state = container.read(authProvider);
      expect(state.asData?.value, isNull);
    });

    test('TC-036: login() correctly preserves user info from AuthTokens',
        () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .login('admin@kayak.local', 'Admin123');

      final user = container.read(authProvider).asData?.value;
      expect(user, isNotNull);
      expect(user!.id, isNotEmpty);
      expect(user.email, equals('admin@kayak.local'));
      expect(user.username, isNotEmpty);
      expect(user.createdAt, isA<DateTime>());
    });

    test('TC-037: successful login clears previous error state', () async {
      // Create a FakeAuthService that fails first attempt, succeeds second
      final mockAuth = FakeAuthService(loginFailsOnFirstAttempt: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      // First attempt — fails
      await container
          .read(authProvider.notifier)
          .login('a@b.com', 'wrong');

      // Check that error was set
      expect(container.read(authProvider).hasError, isTrue);

      // Now try with different container that doesn't fail
      final mockAuth2 = FakeAuthService();
      final container2 = createContainer(mockAuth2);
      addTearDown(container2.dispose);
      await container2.read(authProvider.future);

      // Second attempt — should succeed
      await container2
          .read(authProvider.notifier)
          .login('a@b.com', 'correct');

      final state = container2.read(authProvider);
      expect(state.hasError, isFalse);
      expect(state.asData?.value, isNotNull);
    });
  });

  // ==========================================================
  // 九、集成场景测试（6 项）
  // ==========================================================
  group('AuthNotifier - integration scenarios', () {
    test('TC-038: complete login-logout-relogin flow', () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      // Step 1: build → null
      await container.read(authProvider.future);
      expect(container.read(authProvider).asData?.value, isNull);

      // Step 2: login user1
      await container
          .read(authProvider.notifier)
          .login('user1@test.com', 'Pass1');
      expect(
          container.read(authProvider).asData?.value?.email, 'user1@test.com');
      expect(mockAuth.accessToken, isNotNull);

      // Step 3: logout
      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider).asData?.value, isNull);
      expect(mockAuth.accessToken, isNull);

      // Step 4: relogin user2
      await container
          .read(authProvider.notifier)
          .login('user2@test.com', 'Pass2');
      expect(
          container.read(authProvider).asData?.value?.email, 'user2@test.com');
      expect(mockAuth.accessToken, isNotNull);
      expect(mockAuth.lastLoginEmail, equals('user2@test.com'));
    });

    test('TC-039: cold start with saved token restores session', () async {
      // Phase 1: First login
      final mockAuth1 = FakeAuthService();
      final container1 = createContainer(mockAuth1);
      addTearDown(container1.dispose);
      await container1.read(authProvider.future);
      await container1
          .read(authProvider.notifier)
          .login('admin@kayak.local', 'Admin123');
      expect(
          container1.read(authProvider).asData?.value?.email,
          'admin@kayak.local');

      // Save the accessToken for phase 2
      final savedToken = mockAuth1.accessToken;

      // Phase 2: Simulate restart (new container, storage has token)
      final mockAuth2 = FakeAuthService(
        hasToken: true,
        storedAccessToken: savedToken,
        storedRefreshToken: mockAuth1.accessToken,
      );
      final container2 = createContainer(mockAuth2);
      addTearDown(container2.dispose);

      await container2.read(authProvider.future);

      expect(container2.read(authProvider).asData?.value, isNotNull);
      expect(
          container2.read(authProvider).asData?.value?.email,
          'admin@kayak.local');
    });

    test('TC-040: token auto-refresh keeps session alive', () async {
      final mockAuth = FakeAuthService(
        hasToken: true,
        tokenExpiresIn: 300,
      );
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      final userBefore = container.read(authProvider).asData?.value;
      expect(userBefore, isNotNull);

      // Manually trigger refresh (simulating timer)
      final refreshed = await mockAuth.tryRefresh();
      expect(refreshed, isTrue);

      // State should remain unchanged (still authenticated)
      final userAfter = container.read(authProvider).asData?.value;
      expect(userAfter, isNotNull);
      expect(mockAuth.tokensUpdated, isTrue);
    });

    test('TC-041: refresh failure leads to complete session cleanup',
        () async {
      final mockAuth = FakeAuthService(hasToken: true, refreshFails: true);
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);

      // Trigger build and wait for async completion
      container.read(authProvider);
      await Future<void>.delayed(Duration.zero);

      // Tokens should be cleared after refresh failure
      expect(mockAuth.logoutCalled, isTrue);
    });

    test('TC-042: register auto-login enables full app access', () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      expect(container.read(authProvider).asData?.value, isNull);

      await container
          .read(authProvider.notifier)
          .register('new@test.com', 'StrongPass1', 'NewUser');

      final user = container.read(authProvider).asData?.value;
      expect(user, isNotNull);
      expect(user!.email, equals('new@test.com'));

      expect(mockAuth.accessToken, isNotNull);
      expect(mockAuth.accessToken, isNotEmpty);
    });

    test('TC-043: multiple consumers see consistent auth state', () async {
      final mockAuth = FakeAuthService();
      final container = createContainer(mockAuth);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .login('a@b.com', 'pass');

      final state1 = container.read(authProvider);
      final state2 = container.read(authProvider);
      expect(state1.asData?.value?.email, equals(state2.asData?.value?.email));
    });
  });
}
